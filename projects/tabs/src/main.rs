use std::{path::Path, sync::Arc};

use anyhow::Context;
use axum::{
    extract::{Form, State},
    http::{header, HeaderValue, StatusCode},
    response::{Html, IntoResponse, Redirect, Response},
    routing::{get, post},
    Router,
};
use minijinja::{context, path_loader, Environment};
use serde::{Deserialize, Serialize};
use sqlx::{migrate::Migrator, sqlite::SqlitePoolOptions, Row, SqlitePool};
use thiserror::Error;
use tower_http::services::ServeDir;

#[derive(Clone)]
struct AppState {
    pool: SqlitePool,
    templates: Arc<Environment<'static>>,
}

#[derive(Debug, Clone, Serialize)]
struct Note {
    id: i64,
    body: String,
    created_at: String,
}

#[derive(Debug, Deserialize)]
struct NoteForm {
    body: String,
}

#[derive(Debug, Error)]
enum AppError {
    #[error("database error")]
    Database(#[from] sqlx::Error),
    #[error("template error")]
    Template(#[from] minijinja::Error),
    #[error("migration error")]
    Migration(#[from] sqlx::migrate::MigrateError),
    #[error("bad request: {0}")]
    BadRequest(&'static str),
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, message) = match self {
            AppError::BadRequest(msg) => (StatusCode::BAD_REQUEST, msg.to_owned()),
            AppError::Database(err) => (StatusCode::INTERNAL_SERVER_ERROR, err.to_string()),
            AppError::Template(err) => (StatusCode::INTERNAL_SERVER_ERROR, err.to_string()),
            AppError::Migration(err) => (StatusCode::INTERNAL_SERVER_ERROR, err.to_string()),
        };

        (status, message).into_response()
    }
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "sqlite://data/app.db?mode=rwc".to_owned());

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

    let state = AppState {
        pool,
        templates: Arc::new(env),
    };

    let app = Router::new()
        .route("/", get(index))
        .route("/notes", post(create_note))
        .nest_service("/static", ServeDir::new("static"))
        .with_state(state);

    let listener = tokio::net::TcpListener::bind("127.0.0.1:3000")
        .await
        .context("failed to bind to 127.0.0.1:3000")?;

    axum::serve(listener, app)
        .await
        .context("server exited unexpectedly")?;

    Ok(())
}

async fn index(State(state): State<AppState>) -> Result<impl IntoResponse, AppError> {
    let rows = sqlx::query("SELECT id, body, created_at FROM notes ORDER BY id DESC")
        .fetch_all(&state.pool)
        .await?;

    let notes = rows
        .into_iter()
        .map(|row| Note {
            id: row.get::<i64, _>("id"),
            body: row.get::<String, _>("body"),
            created_at: row.try_get::<String, _>("created_at").unwrap_or_default(),
        })
        .collect::<Vec<_>>();

    let tpl = state.templates.get_template("index.html")?;
    let rendered = tpl.render(context! { notes => notes })?;

    let mut response = Html(rendered).into_response();
    response.headers_mut().insert(
        header::CACHE_CONTROL,
        HeaderValue::from_static("no-store, max-age=0"),
    );

    Ok(response)
}

async fn create_note(
    State(state): State<AppState>,
    Form(form): Form<NoteForm>,
) -> Result<impl IntoResponse, AppError> {
    let body = form.body.trim();
    if body.is_empty() {
        return Err(AppError::BadRequest("note body cannot be empty"));
    }

    sqlx::query("INSERT INTO notes (body) VALUES (?)")
        .bind(body)
        .execute(&state.pool)
        .await?;

    Ok(Redirect::to("/"))
}
