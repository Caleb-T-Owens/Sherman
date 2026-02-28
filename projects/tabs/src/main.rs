use std::{path::Path, sync::Arc};

use anyhow::Context;
use argon2::{
    password_hash::{rand_core::OsRng, PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
    Argon2,
};
use axum::{
    extract::{Form, State},
    http::{header, HeaderValue, StatusCode},
    response::{Html, IntoResponse, Redirect, Response},
    routing::{get, post},
    Router,
};
use axum_extra::extract::cookie::{Cookie, CookieJar, SameSite};
use base64::Engine;
use minijinja::{context, path_loader, AutoEscape, Environment};
use rand::RngCore;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use sqlx::{migrate::Migrator, sqlite::SqlitePoolOptions, Row, SqlitePool};
use thiserror::Error;
use time::Duration;
use tower_http::services::ServeDir;

const SESSION_COOKIE: &str = "session_token";
const SESSION_MAX_AGE_SECS: i64 = 60 * 60 * 24 * 7;

#[derive(Clone)]
struct AppState {
    pool: SqlitePool,
    templates: Arc<Environment<'static>>,
    cookie_secure: bool,
}

#[derive(Debug, Clone, Serialize)]
struct AccountView {
    username: String,
    email: String,
}

#[derive(Debug)]
struct SessionRecord {
    token_hash: String,
    user_id: Option<i64>,
    csrf_token: String,
}

#[derive(Debug, Deserialize, Serialize)]
struct RegisterForm {
    username: String,
    email: String,
    password: String,
    csrf_token: String,
}

#[derive(Debug, Deserialize, Serialize)]
struct LoginForm {
    identity: String,
    password: String,
    csrf_token: String,
}

#[derive(Debug, Deserialize)]
struct LogoutForm {
    csrf_token: String,
}

#[derive(Debug, Error)]
enum AppError {
    #[error("database error")]
    Database(#[from] sqlx::Error),
    #[error("template error")]
    Template(#[from] minijinja::Error),
    #[error("migration error")]
    Migration(#[from] sqlx::migrate::MigrateError),
    #[error("internal error")]
    Internal,
    #[error("bad request")]
    BadRequest(&'static str),
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, message) = match self {
            AppError::BadRequest(msg) => (StatusCode::BAD_REQUEST, msg.to_owned()),
            AppError::Database(_) | AppError::Template(_) | AppError::Migration(_) | AppError::Internal => {
                (StatusCode::INTERNAL_SERVER_ERROR, "internal server error".to_owned())
            }
        };

        (status, message).into_response()
    }
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "sqlite://data/app.db?mode=rwc".to_owned());
    let cookie_secure = std::env::var("COOKIE_SECURE")
        .unwrap_or_else(|_| "false".to_owned())
        .eq_ignore_ascii_case("true");
    let bind_addr = std::env::var("BIND_ADDR").unwrap_or_else(|_| {
        let host = std::env::var("HOST").unwrap_or_else(|_| "127.0.0.1".to_owned());
        let port = std::env::var("PORT").unwrap_or_else(|_| "3000".to_owned());
        format!("{host}:{port}")
    });

    std::fs::create_dir_all("data").context("failed to create data directory")?;

    let pool = SqlitePoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await
        .context("failed to connect to sqlite")?;

    let migrator = Migrator::new(Path::new("./migrations"))
        .await
        .context("failed to load migrations")?;
    migrator.run(&pool).await.context("failed to run migrations")?;

    let mut env = Environment::new();
    env.set_loader(path_loader("templates"));
    env.set_auto_escape_callback(|name| {
        if name.ends_with(".html") {
            AutoEscape::Html
        } else {
            AutoEscape::None
        }
    });

    let state = AppState {
        pool,
        templates: Arc::new(env),
        cookie_secure,
    };

    let app = Router::new()
        .route("/", get(index))
        .route("/register", get(register_form).post(register))
        .route("/login", get(login_form).post(login))
        .route("/logout", post(logout))
        .nest_service("/static", ServeDir::new("static"))
        .with_state(state);

    let listener = tokio::net::TcpListener::bind(&bind_addr)
        .await
        .with_context(|| format!("failed to bind to {bind_addr}"))?;

    axum::serve(listener, app)
        .await
        .context("server exited unexpectedly")?;

    Ok(())
}

async fn index(
    State(state): State<AppState>,
    jar: CookieJar,
) -> Result<(CookieJar, impl IntoResponse), AppError> {
    let (jar, session) = ensure_session(&state, jar).await?;
    let user_id = match session.user_id {
        Some(user_id) => user_id,
        None => return Ok((jar, Redirect::to("/login").into_response())),
    };

    let row = sqlx::query("SELECT username, email FROM users WHERE id = ?")
        .bind(user_id)
        .fetch_optional(&state.pool)
        .await?;

    let Some(row) = row else {
        let new_jar = rotate_session(&state, jar, Some(session.token_hash), None).await?;
        return Ok((new_jar, Redirect::to("/login").into_response()));
    };

    let account = AccountView {
        username: row.get::<String, _>("username"),
        email: row.get::<String, _>("email"),
    };

    let tpl = state.templates.get_template("index.html")?;
    let rendered = tpl.render(context! { account => account, csrf_token => session.csrf_token })?;

    let mut response = Html(rendered).into_response();
    response.headers_mut().insert(
        header::CACHE_CONTROL,
        HeaderValue::from_static("no-store, max-age=0"),
    );

    Ok((jar, response))
}

async fn register_form(
    State(state): State<AppState>,
    jar: CookieJar,
) -> Result<(CookieJar, Response), AppError> {
    let (jar, session) = ensure_session(&state, jar).await?;
    if session_user_exists(&state, &session).await? {
        return Ok((jar, Redirect::to("/").into_response()));
    }

    let tpl = state.templates.get_template("register.html")?;
    let rendered = tpl.render(context! {
        csrf_token => session.csrf_token,
        error => Option::<&str>::None,
        values => context! { username => "", email => "" },
    })?;
    Ok((jar, Html(rendered).into_response()))
}

async fn register(
    State(state): State<AppState>,
    jar: CookieJar,
    Form(form): Form<RegisterForm>,
) -> Result<(CookieJar, Response), AppError> {
    let (jar, session) = ensure_session(&state, jar).await?;
    if let Err(err) = validate_register_form(&form).and_then(|_| verify_csrf(&session, &form.csrf_token)) {
        return render_register_error(&state, jar, session.csrf_token, &form, err).await;
    }

    let password_hash = hash_password(&form.password)?;
    let inserted = sqlx::query("INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)")
        .bind(form.username.trim())
        .bind(form.email.trim().to_ascii_lowercase())
        .bind(password_hash)
        .execute(&state.pool)
        .await;

    let user_id = match inserted {
        Ok(result) => result.last_insert_rowid(),
        Err(sqlx::Error::Database(_)) => {
            return render_register_error(
                &state,
                jar,
                session.csrf_token,
                &form,
                AppError::BadRequest("could not create account"),
            )
            .await;
        }
        Err(err) => return Err(AppError::Database(err)),
    };

    let new_jar = rotate_session(&state, jar, Some(session.token_hash), Some(user_id)).await?;
    Ok((new_jar, Redirect::to("/").into_response()))
}

async fn login_form(
    State(state): State<AppState>,
    jar: CookieJar,
) -> Result<(CookieJar, Response), AppError> {
    let (jar, session) = ensure_session(&state, jar).await?;
    if session_user_exists(&state, &session).await? {
        return Ok((jar, Redirect::to("/").into_response()));
    }

    let tpl = state.templates.get_template("login.html")?;
    let rendered = tpl.render(context! {
        csrf_token => session.csrf_token,
        error => Option::<&str>::None,
        values => context! { identity => "" },
    })?;
    Ok((jar, Html(rendered).into_response()))
}

async fn login(
    State(state): State<AppState>,
    jar: CookieJar,
    Form(form): Form<LoginForm>,
) -> Result<(CookieJar, Response), AppError> {
    let (jar, session) = ensure_session(&state, jar).await?;
    if form.password.len() < 12 {
        return render_login_error(
            &state,
            jar,
            session.csrf_token,
            &form,
            AppError::BadRequest("invalid credentials"),
        )
        .await;
    }
    if let Err(err) = verify_csrf(&session, &form.csrf_token) {
        return render_login_error(&state, jar, session.csrf_token, &form, err).await;
    }

    let identity = form.identity.trim();
    let row = sqlx::query(
        "SELECT id, password_hash FROM users WHERE lower(username) = lower(?) OR lower(email) = lower(?)",
    )
    .bind(identity)
    .bind(identity)
    .fetch_optional(&state.pool)
    .await?;

    let Some(row) = row else {
        return render_login_error(
            &state,
            jar,
            session.csrf_token,
            &form,
            AppError::BadRequest("invalid credentials"),
        )
        .await;
    };

    let user_id = row.get::<i64, _>("id");
    let password_hash = row.get::<String, _>("password_hash");
    if !verify_password(&form.password, &password_hash)? {
        return render_login_error(
            &state,
            jar,
            session.csrf_token,
            &form,
            AppError::BadRequest("invalid credentials"),
        )
        .await;
    }

    let new_jar = rotate_session(&state, jar, Some(session.token_hash), Some(user_id)).await?;
    Ok((new_jar, Redirect::to("/").into_response()))
}

async fn logout(
    State(state): State<AppState>,
    jar: CookieJar,
    Form(form): Form<LogoutForm>,
) -> Result<(CookieJar, impl IntoResponse), AppError> {
    let (jar, session) = ensure_session(&state, jar).await?;
    if session.user_id.is_none() {
        return Ok((jar, Redirect::to("/login")));
    }

    verify_csrf(&session, &form.csrf_token)?;

    sqlx::query("DELETE FROM sessions WHERE token_hash = ?")
        .bind(session.token_hash)
        .execute(&state.pool)
        .await?;

    let expired_cookie = session_cookie(state.cookie_secure, "", 0);
    Ok((jar.remove(expired_cookie), Redirect::to("/login")))
}

fn validate_register_form(form: &RegisterForm) -> Result<(), AppError> {
    let username = form.username.trim();
    if username.len() < 3 || username.len() > 32 {
        return Err(AppError::BadRequest("username must be 3-32 characters"));
    }
    if !username
        .chars()
        .all(|c| c.is_ascii_alphanumeric() || c == '_' || c == '-')
    {
        return Err(AppError::BadRequest(
            "username can only use letters, digits, '_' and '-'",
        ));
    }

    let email = form.email.trim();
    if email.len() < 5
        || email.len() > 254
        || !email.contains('@')
        || email.starts_with('@')
        || email.ends_with('@')
    {
        return Err(AppError::BadRequest("invalid email"));
    }

    if form.password.len() < 12 || form.password.len() > 256 {
        return Err(AppError::BadRequest("password must be between 12 and 256 characters"));
    }

    Ok(())
}

fn hash_password(password: &str) -> Result<String, AppError> {
    let salt = SaltString::generate(&mut OsRng);
    Argon2::default()
        .hash_password(password.as_bytes(), &salt)
        .map(|hash| hash.to_string())
        .map_err(|_| AppError::Internal)
}

fn verify_password(password: &str, password_hash: &str) -> Result<bool, AppError> {
    let parsed = PasswordHash::new(password_hash).map_err(|_| AppError::Internal)?;
    Ok(Argon2::default()
        .verify_password(password.as_bytes(), &parsed)
        .is_ok())
}

fn verify_csrf(session: &SessionRecord, submitted: &str) -> Result<(), AppError> {
    if constant_time_eq(&session.csrf_token, submitted) {
        Ok(())
    } else {
        Err(AppError::BadRequest("invalid csrf token"))
    }
}

async fn ensure_session(
    state: &AppState,
    jar: CookieJar,
) -> Result<(CookieJar, SessionRecord), AppError> {
    cleanup_expired_sessions(state).await?;

    let now = unix_now();
    if let Some(cookie) = jar.get(SESSION_COOKIE) {
        let token = cookie.value().to_owned();
        if let Some(record) = find_session(state, &token, now).await? {
            sqlx::query("UPDATE sessions SET expires_at = ? WHERE token_hash = ?")
                .bind(now + SESSION_MAX_AGE_SECS)
                .bind(&record.token_hash)
                .execute(&state.pool)
                .await?;

            let refreshed = session_cookie(state.cookie_secure, &token, SESSION_MAX_AGE_SECS);
            return Ok((jar.add(refreshed), record));
        }
    }

    let (token, token_hash) = new_token_pair();
    let csrf_token = new_token();
    let expires_at = now + SESSION_MAX_AGE_SECS;

    sqlx::query("INSERT INTO sessions (token_hash, user_id, csrf_token, expires_at) VALUES (?, NULL, ?, ?)")
        .bind(&token_hash)
        .bind(&csrf_token)
        .bind(expires_at)
        .execute(&state.pool)
        .await?;

    let cookie = session_cookie(state.cookie_secure, &token, SESSION_MAX_AGE_SECS);
    Ok((
        jar.add(cookie),
        SessionRecord {
            token_hash,
            user_id: None,
            csrf_token,
        },
    ))
}

async fn find_session(
    state: &AppState,
    token: &str,
    now: i64,
) -> Result<Option<SessionRecord>, AppError> {
    let token_hash = hash_token(token);
    let row = sqlx::query(
        "SELECT token_hash, user_id, csrf_token, expires_at FROM sessions WHERE token_hash = ? AND expires_at > ?",
    )
    .bind(token_hash)
    .bind(now)
    .fetch_optional(&state.pool)
    .await?;

    Ok(row.map(|r| SessionRecord {
        token_hash: r.get::<String, _>("token_hash"),
        user_id: r.try_get::<i64, _>("user_id").ok(),
        csrf_token: r.get::<String, _>("csrf_token"),
    }))
}

async fn session_user_exists(state: &AppState, session: &SessionRecord) -> Result<bool, AppError> {
    let Some(user_id) = session.user_id else {
        return Ok(false);
    };

    let exists = sqlx::query_scalar::<_, i64>("SELECT id FROM users WHERE id = ?")
        .bind(user_id)
        .fetch_optional(&state.pool)
        .await?
        .is_some();

    if exists {
        return Ok(true);
    }

    sqlx::query("UPDATE sessions SET user_id = NULL WHERE token_hash = ?")
        .bind(&session.token_hash)
        .execute(&state.pool)
        .await?;

    Ok(false)
}

async fn rotate_session(
    state: &AppState,
    jar: CookieJar,
    old_token_hash: Option<String>,
    user_id: Option<i64>,
) -> Result<CookieJar, AppError> {
    if let Some(old_hash) = old_token_hash {
        sqlx::query("DELETE FROM sessions WHERE token_hash = ?")
            .bind(old_hash)
            .execute(&state.pool)
            .await?;
    }

    let (token, token_hash) = new_token_pair();
    let csrf_token = new_token();
    let expires_at = unix_now() + SESSION_MAX_AGE_SECS;

    sqlx::query("INSERT INTO sessions (token_hash, user_id, csrf_token, expires_at) VALUES (?, ?, ?, ?)")
        .bind(token_hash)
        .bind(user_id)
        .bind(csrf_token)
        .bind(expires_at)
        .execute(&state.pool)
        .await?;

    Ok(jar.add(session_cookie(
        state.cookie_secure,
        &token,
        SESSION_MAX_AGE_SECS,
    )))
}

async fn cleanup_expired_sessions(state: &AppState) -> Result<(), AppError> {
    sqlx::query("DELETE FROM sessions WHERE expires_at <= ?")
        .bind(unix_now())
        .execute(&state.pool)
        .await?;
    Ok(())
}

fn new_token_pair() -> (String, String) {
    let token = new_token();
    let hash = hash_token(&token);
    (token, hash)
}

fn hash_token(token: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(token.as_bytes());
    let digest = hasher.finalize();
    format!("{:x}", digest)
}

fn new_token() -> String {
    let mut bytes = [0_u8; 32];
    rand::thread_rng().fill_bytes(&mut bytes);
    base64::engine::general_purpose::URL_SAFE_NO_PAD.encode(bytes)
}

fn session_cookie(secure: bool, value: &str, max_age_secs: i64) -> Cookie<'static> {
    Cookie::build((SESSION_COOKIE, value.to_owned()))
        .http_only(true)
        .same_site(SameSite::Lax)
        .path("/")
        .secure(secure)
        .max_age(Duration::seconds(max_age_secs))
        .build()
}

fn unix_now() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs() as i64
}

fn constant_time_eq(left: &str, right: &str) -> bool {
    if left.len() != right.len() {
        return false;
    }

    let mut diff = 0u8;
    for (&a, &b) in left.as_bytes().iter().zip(right.as_bytes().iter()) {
        diff |= a ^ b;
    }

    diff == 0
}

async fn render_register_error(
    state: &AppState,
    jar: CookieJar,
    csrf_token: String,
    form: &RegisterForm,
    err: AppError,
) -> Result<(CookieJar, Response), AppError> {
    let message = match err {
        AppError::BadRequest(msg) => msg,
        _ => return Err(err),
    };

    let tpl = state.templates.get_template("register.html")?;
    let rendered = tpl.render(context! {
        csrf_token => csrf_token,
        error => message,
        values => context! { username => form.username.trim(), email => form.email.trim() },
    })?;
    Ok((jar, Html(rendered).into_response()))
}

async fn render_login_error(
    state: &AppState,
    jar: CookieJar,
    csrf_token: String,
    form: &LoginForm,
    err: AppError,
) -> Result<(CookieJar, Response), AppError> {
    let message = match err {
        AppError::BadRequest(msg) => msg,
        _ => return Err(err),
    };

    let tpl = state.templates.get_template("login.html")?;
    let rendered = tpl.render(context! {
        csrf_token => csrf_token,
        error => message,
        values => context! { identity => form.identity.trim() },
    })?;
    Ok((jar, Html(rendered).into_response()))
}
