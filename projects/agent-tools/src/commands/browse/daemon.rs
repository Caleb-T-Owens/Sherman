use crate::commands::browse::DaemonAction;
use crate::common::daemon as daemon_utils;
use anyhow::{Context, Result, bail};
use chromiumoxide::browser::{Browser, BrowserConfig};
use futures::StreamExt;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::{UnixListener, UnixStream};
use tokio::sync::Mutex;
use std::sync::Arc;

const DAEMON_NAME: &str = "browse";

#[derive(Debug, Serialize, Deserialize)]
pub struct Request {
    pub command: String,
    pub args: serde_json::Value,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Response {
    pub success: bool,
    pub data: Option<serde_json::Value>,
    pub error: Option<String>,
}

#[allow(dead_code)]
struct BrowserState {
    browser: Browser,
    tabs: HashMap<String, chromiumoxide::Page>,
    current_tab: Option<String>,
    recording: Option<crate::commands::browse::workflow::Workflow>,
}

pub async fn handle_daemon(action: DaemonAction) -> Result<()> {
    match action {
        DaemonAction::Start { foreground, headed } => start_daemon(foreground, headed).await,
        DaemonAction::Stop => stop_daemon().await,
        DaemonAction::Status => check_status().await,
    }
}

fn cleanup_chrome_locks() -> Result<()> {
    // Try to clean up stale Chrome lock files
    if let Ok(temp_dir) = std::env::var("TMPDIR") {
        let lock_path = std::path::PathBuf::from(temp_dir)
            .join("chromiumoxide-runner")
            .join("SingletonLock");
        if lock_path.exists() {
            let _ = std::fs::remove_file(&lock_path);
        }
    }
    Ok(())
}

async fn start_daemon(foreground: bool, headed: bool) -> Result<()> {
    // Check if already running
    if daemon_utils::is_running(DAEMON_NAME)? {
        bail!("Daemon is already running");
    }

    let socket_path = daemon_utils::socket_path(DAEMON_NAME)?;

    // Clean up old socket if it exists
    if socket_path.exists() {
        std::fs::remove_file(&socket_path)?;
    }

    // Clean up stale Chrome lock files
    cleanup_chrome_locks()?;

    if !foreground {
        println!("Starting browser daemon in background...");
        // TODO: Proper daemonization would go here
        // For now, we'll just run in foreground
    }

    // Write PID file
    daemon_utils::write_pid_file(DAEMON_NAME)?;

    // Start browser - headless by default
    let mut config_builder = BrowserConfig::builder();
    if !headed {
        config_builder = config_builder.no_sandbox();
    } else {
        config_builder = config_builder.with_head();
    }

    let (browser, mut handler) = Browser::launch(
        config_builder
            .build()
            .map_err(|e| anyhow::anyhow!("Failed to build browser config: {}", e))?
    )
    .await
    .context("Failed to launch browser")?;

    // Spawn browser handler
    tokio::spawn(async move {
        while let Some(event) = handler.next().await {
            if let Err(e) = event {
                tracing::error!("Browser event error: {}", e);
            }
        }
    });

    // Create initial tab
    let page = browser.new_page("about:blank")
        .await
        .context("Failed to create initial page")?;

    let mut tabs = HashMap::new();
    let tab_id = "default".to_string();
    tabs.insert(tab_id.clone(), page);

    let state = Arc::new(Mutex::new(BrowserState {
        browser,
        tabs,
        current_tab: Some(tab_id),
        recording: None,
    }));

    // Set up Unix socket listener
    let listener = UnixListener::bind(&socket_path)
        .context("Failed to bind Unix socket")?;

    println!("Browser daemon started on {}", socket_path.display());

    // Set up signal handlers for graceful shutdown
    let state_for_cleanup = Arc::clone(&state);
    let socket_path_for_cleanup = socket_path.clone();

    // Accept connections with signal handling
    let result = tokio::select! {
        _ = async {
            loop {
                match listener.accept().await {
                    Ok((stream, _)) => {
                        let state = Arc::clone(&state);
                        tokio::spawn(async move {
                            if let Err(e) = handle_connection(stream, state).await {
                                tracing::error!("Connection error: {}", e);
                            }
                        });
                    }
                    Err(e) => {
                        tracing::error!("Failed to accept connection: {}", e);
                    }
                }
            }
        } => Ok(()),
        _ = tokio::signal::ctrl_c() => {
            tracing::info!("Received SIGINT, shutting down gracefully...");
            Ok(())
        },
        _ = async {
            let mut sigterm = tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate())?;
            sigterm.recv().await;
            Ok::<(), anyhow::Error>(())
        } => {
            tracing::info!("Received SIGTERM, shutting down gracefully...");
            Ok(())
        }
    };

    // Cleanup on shutdown
    cleanup_on_shutdown(state_for_cleanup, socket_path_for_cleanup).await?;

    result
}

async fn cleanup_on_shutdown(state: Arc<Mutex<BrowserState>>, socket_path: std::path::PathBuf) -> Result<()> {
    tracing::info!("Cleaning up browser daemon...");

    // Close the browser (this will kill Chrome processes)
    {
        let mut state_guard = state.lock().await;
        if let Err(e) = state_guard.browser.close().await {
            tracing::warn!("Error closing browser: {}", e);
        }
    }

    // Clean up socket file
    if socket_path.exists() {
        let _ = std::fs::remove_file(&socket_path);
    }

    // Clean up PID file
    let _ = daemon_utils::remove_pid_file(DAEMON_NAME);

    tracing::info!("Browser daemon shutdown complete");
    Ok(())
}

async fn handle_connection(
    stream: UnixStream,
    state: Arc<Mutex<BrowserState>>,
) -> Result<()> {
    let (reader, mut writer) = stream.into_split();
    let mut reader = BufReader::new(reader);
    let mut line = String::new();

    while reader.read_line(&mut line).await? > 0 {
        let request: Request = serde_json::from_str(&line)
            .context("Failed to parse request")?;

        let response = process_request(request, &state).await;

        let response_json = serde_json::to_string(&response)?;
        writer.write_all(response_json.as_bytes()).await?;
        writer.write_all(b"\n").await?;

        line.clear();
    }

    Ok(())
}

async fn process_request(
    request: Request,
    state: &Arc<Mutex<BrowserState>>,
) -> Response {
    // Check if we're recording and log the command (except for workflow management commands)
    let should_record = !matches!(
        request.command.as_str(),
        "record" | "stop_record" | "replay" | "list_workflows" | "delete_workflow"
    );

    if should_record {
        let mut state_guard = state.lock().await;
        if let Some(ref mut workflow) = state_guard.recording {
            workflow.add_command(request.command.clone(), request.args.clone());
        }
        drop(state_guard);
    }

    let result = match request.command.as_str() {
        "navigate" => cmd_navigate(request.args, state).await,
        "screenshot" => cmd_screenshot(request.args, state).await,
        "click" => cmd_click(request.args, state).await,
        "type" => cmd_type(request.args, state).await,
        "extract" => cmd_extract(request.args, state).await,
        "eval" => cmd_eval(request.args, state).await,
        "wait" => cmd_wait(request.args, state).await,
        "tabs_list" => cmd_tabs_list(state).await,
        "tabs_new" => cmd_tabs_new(request.args, state).await,
        "tabs_switch" => cmd_tabs_switch(request.args, state).await,
        "tabs_close" => cmd_tabs_close(request.args, state).await,
        "pdf" => cmd_pdf(request.args, state).await,
        "get_cookies" => cmd_get_cookies(request.args, state).await,
        "set_cookie" => cmd_set_cookie(request.args, state).await,
        "delete_cookies" => cmd_delete_cookies(request.args, state).await,
        "set_user_agent" => cmd_set_user_agent(request.args, state).await,
        "record" => cmd_record(request.args, state).await,
        "stop_record" => cmd_stop_record(state).await,
        "replay" => cmd_replay(request.args, state).await,
        "list_workflows" => cmd_list_workflows().await,
        "delete_workflow" => cmd_delete_workflow(request.args).await,
        "suggest" => cmd_suggest(request.args).await,
        _ => Err(anyhow::anyhow!("Unknown command: {}", request.command)),
    };

    match result {
        Ok(data) => Response {
            success: true,
            data: Some(data),
            error: None,
        },
        Err(e) => Response {
            success: false,
            data: None,
            error: Some(e.to_string()),
        },
    }
}

// Helper to get the current or specified tab
async fn get_page(
    state: &Arc<Mutex<BrowserState>>,
    tab_id: Option<&str>,
) -> Result<chromiumoxide::Page> {
    let state_guard = state.lock().await;

    let tab_to_use = if let Some(id) = tab_id {
        id
    } else if let Some(current) = &state_guard.current_tab {
        current
    } else {
        bail!("No tab specified and no current tab");
    };

    state_guard
        .tabs
        .get(tab_to_use)
        .cloned()
        .ok_or_else(|| anyhow::anyhow!("Tab not found: {}", tab_to_use))
}

async fn cmd_navigate(args: serde_json::Value, state: &Arc<Mutex<BrowserState>>) -> Result<serde_json::Value> {
    let url = args["url"].as_str().context("Missing url")?;
    let tab = args["tab"].as_str();

    let page = get_page(state, tab).await?;
    page.goto(url).await?;

    Ok(serde_json::json!({ "url": url }))
}

async fn cmd_screenshot(args: serde_json::Value, state: &Arc<Mutex<BrowserState>>) -> Result<serde_json::Value> {
    let tab = args["tab"].as_str();
    let output = args["output"].as_str();
    let selector = args["selector"].as_str();

    let page = get_page(state, tab).await?;

    let screenshot_bytes = if let Some(sel) = selector {
        // Screenshot specific element
        let element = page.find_element(sel).await
            .context("Element not found")?;
        element.screenshot(chromiumoxide::cdp::browser_protocol::page::CaptureScreenshotFormat::Png).await?
    } else {
        // Full page screenshot
        page.screenshot(chromiumoxide::page::ScreenshotParams::default()).await?
    };

    let output_path = if let Some(path) = output {
        path.to_string()
    } else {
        format!("screenshot-{}.png", chrono::Utc::now().timestamp())
    };

    tokio::fs::write(&output_path, screenshot_bytes).await?;

    Ok(serde_json::json!({ "path": output_path }))
}

async fn cmd_click(args: serde_json::Value, state: &Arc<Mutex<BrowserState>>) -> Result<serde_json::Value> {
    let selector = args["selector"].as_str().context("Missing selector")?;
    let tab = args["tab"].as_str();

    let page = get_page(state, tab).await?;
    let element = page.find_element(selector).await
        .context("Element not found")?;
    element.click().await?;

    Ok(serde_json::json!({ "selector": selector }))
}

async fn cmd_type(args: serde_json::Value, state: &Arc<Mutex<BrowserState>>) -> Result<serde_json::Value> {
    let selector = args["selector"].as_str().context("Missing selector")?;
    let text = args["text"].as_str().context("Missing text")?;
    let tab = args["tab"].as_str();

    let page = get_page(state, tab).await?;
    let element = page.find_element(selector).await
        .context("Element not found")?;
    element.click().await?; // Focus the element
    element.type_str(text).await?;

    Ok(serde_json::json!({ "selector": selector, "text": text }))
}

async fn cmd_extract(args: serde_json::Value, state: &Arc<Mutex<BrowserState>>) -> Result<serde_json::Value> {
    let selector = args["selector"].as_str().context("Missing selector")?;
    let html = args["html"].as_bool().unwrap_or(false);
    let all = args["all"].as_bool().unwrap_or(false);
    let tab = args["tab"].as_str();

    let page = get_page(state, tab).await?;

    if all {
        let elements = page.find_elements(selector).await?;
        let mut results = Vec::new();

        for element in elements {
            let content = if html {
                element.inner_html().await?.unwrap_or_default()
            } else {
                element.inner_text().await?.unwrap_or_default()
            };
            results.push(content);
        }

        Ok(serde_json::json!({ "results": results }))
    } else {
        let element = page.find_element(selector).await
            .context("Element not found")?;
        let content = if html {
            element.inner_html().await?.unwrap_or_default()
        } else {
            element.inner_text().await?.unwrap_or_default()
        };

        Ok(serde_json::json!({ "result": content }))
    }
}

async fn cmd_eval(args: serde_json::Value, state: &Arc<Mutex<BrowserState>>) -> Result<serde_json::Value> {
    let js = args["js"].as_str().context("Missing js")?;
    let tab = args["tab"].as_str();

    let page = get_page(state, tab).await?;
    let result = page.evaluate(js).await?;
    let value: serde_json::Value = result.into_value().map_err(|e| anyhow::anyhow!("Failed to get value: {:?}", e))?;

    Ok(serde_json::json!({ "result": value }))
}

async fn cmd_wait(args: serde_json::Value, state: &Arc<Mutex<BrowserState>>) -> Result<serde_json::Value> {
    let selector = args["selector"].as_str().context("Missing selector")?;
    let timeout = args["timeout"].as_u64().unwrap_or(30);
    let tab = args["tab"].as_str();

    let page = get_page(state, tab).await?;

    // Wait for element with timeout
    let timeout_duration = std::time::Duration::from_secs(timeout);
    let start = std::time::Instant::now();

    loop {
        if start.elapsed() > timeout_duration {
            bail!("Timeout waiting for element: {}", selector);
        }

        if page.find_element(selector).await.is_ok() {
            break;
        }

        tokio::time::sleep(std::time::Duration::from_millis(100)).await;
    }

    Ok(serde_json::json!({ "selector": selector }))
}

async fn cmd_tabs_list(state: &Arc<Mutex<BrowserState>>) -> Result<serde_json::Value> {
    let state_guard = state.lock().await;
    let tab_ids: Vec<String> = state_guard.tabs.keys().cloned().collect();
    let current = state_guard.current_tab.clone();

    Ok(serde_json::json!({
        "tabs": tab_ids,
        "current": current,
    }))
}

async fn cmd_tabs_new(args: serde_json::Value, state: &Arc<Mutex<BrowserState>>) -> Result<serde_json::Value> {
    let url = args["url"].as_str().unwrap_or("about:blank");

    let mut state_guard = state.lock().await;
    let page = state_guard.browser.new_page(url).await?;

    // Generate tab ID
    let tab_id = format!("tab-{}", state_guard.tabs.len());
    state_guard.tabs.insert(tab_id.clone(), page);
    state_guard.current_tab = Some(tab_id.clone());

    Ok(serde_json::json!({ "id": tab_id, "url": url }))
}

async fn cmd_tabs_switch(args: serde_json::Value, state: &Arc<Mutex<BrowserState>>) -> Result<serde_json::Value> {
    let id = args["id"].as_str().context("Missing id")?;

    let mut state_guard = state.lock().await;
    if !state_guard.tabs.contains_key(id) {
        bail!("Tab not found: {}", id);
    }

    state_guard.current_tab = Some(id.to_string());

    Ok(serde_json::json!({ "id": id }))
}

async fn cmd_tabs_close(args: serde_json::Value, state: &Arc<Mutex<BrowserState>>) -> Result<serde_json::Value> {
    let id = args["id"].as_str().context("Missing id")?;

    let mut state_guard = state.lock().await;
    let page = state_guard.tabs.remove(id)
        .ok_or_else(|| anyhow::anyhow!("Tab not found: {}", id))?;

    page.close().await?;

    // If we closed the current tab, switch to another one
    if state_guard.current_tab.as_deref() == Some(id) {
        state_guard.current_tab = state_guard.tabs.keys().next().cloned();
    }

    Ok(serde_json::json!({ "id": id }))
}

async fn cmd_pdf(args: serde_json::Value, state: &Arc<Mutex<BrowserState>>) -> Result<serde_json::Value> {
    let output = args["output"].as_str().context("Missing output")?;
    let tab = args["tab"].as_str();

    let page = get_page(state, tab).await?;

    // Use CDP command directly
    use chromiumoxide::cdp::browser_protocol::page::PrintToPdfParams;
    let pdf_result = page.execute(PrintToPdfParams::default()).await?;

    // Decode base64 data
    use base64::Engine;
    let pdf_bytes = base64::engine::general_purpose::STANDARD
        .decode(&pdf_result.data)
        .context("Failed to decode PDF base64 data")?;

    tokio::fs::write(output, pdf_bytes).await?;

    Ok(serde_json::json!({ "path": output }))
}

async fn cmd_get_cookies(args: serde_json::Value, state: &Arc<Mutex<BrowserState>>) -> Result<serde_json::Value> {
    let tab = args["tab"].as_str();

    let page = get_page(state, tab).await?;
    let cookies = page.get_cookies().await?;

    let cookie_list: Vec<serde_json::Value> = cookies
        .iter()
        .map(|c| {
            serde_json::json!({
                "name": c.name,
                "value": c.value,
                "domain": c.domain,
                "path": c.path,
                "expires": c.expires,
                "secure": c.secure,
                "http_only": c.http_only,
            })
        })
        .collect();

    Ok(serde_json::json!({ "cookies": cookie_list }))
}

async fn cmd_set_cookie(args: serde_json::Value, state: &Arc<Mutex<BrowserState>>) -> Result<serde_json::Value> {
    let name = args["name"].as_str().context("Missing name")?;
    let value = args["value"].as_str().context("Missing value")?;
    let domain = args["domain"].as_str();
    let tab = args["tab"].as_str();

    let page = get_page(state, tab).await?;

    // Get current URL to extract domain if not provided
    let url = page.url().await?.unwrap_or_default();
    let cookie_domain = if let Some(d) = domain {
        d.to_string()
    } else {
        // Extract domain from URL
        url::Url::parse(&url)
            .ok()
            .and_then(|u| u.host_str().map(|h| h.to_string()))
            .unwrap_or_else(|| "localhost".to_string())
    };

    use chromiumoxide::cdp::browser_protocol::network::CookieParam;
    let cookie = CookieParam::builder()
        .name(name)
        .value(value)
        .domain(cookie_domain.clone())
        .build()
        .map_err(|e| anyhow::anyhow!("Failed to build cookie: {}", e))?;

    page.set_cookie(cookie).await?;

    Ok(serde_json::json!({ "name": name, "domain": cookie_domain }))
}

async fn cmd_delete_cookies(args: serde_json::Value, state: &Arc<Mutex<BrowserState>>) -> Result<serde_json::Value> {
    let name = args["name"].as_str();
    let tab = args["tab"].as_str();

    let page = get_page(state, tab).await?;

    if let Some(cookie_name) = name {
        page.delete_cookie(cookie_name).await?;
        Ok(serde_json::json!({ "deleted": cookie_name }))
    } else {
        // Delete all cookies
        let cookies = page.get_cookies().await?;
        for cookie in cookies {
            page.delete_cookie(&cookie.name).await?;
        }
        Ok(serde_json::json!({ "deleted": "all" }))
    }
}

async fn cmd_set_user_agent(args: serde_json::Value, state: &Arc<Mutex<BrowserState>>) -> Result<serde_json::Value> {
    let user_agent = args["user_agent"].as_str().context("Missing user_agent")?;
    let tab = args["tab"].as_str();

    let page = get_page(state, tab).await?;
    page.set_user_agent(user_agent).await?;

    Ok(serde_json::json!({ "user_agent": user_agent }))
}

async fn cmd_record(args: serde_json::Value, state: &Arc<Mutex<BrowserState>>) -> Result<serde_json::Value> {
    let name = args["name"].as_str().context("Missing name")?;
    let description = args["description"]
        .as_str()
        .unwrap_or("No description provided");

    let mut state_guard = state.lock().await;

    if state_guard.recording.is_some() {
        bail!("Already recording a workflow. Stop the current recording first.");
    }

    let workflow = crate::commands::browse::workflow::Workflow::new(
        name.to_string(),
        description.to_string(),
    );

    state_guard.recording = Some(workflow);

    Ok(serde_json::json!({
        "recording": true,
        "name": name,
        "description": description
    }))
}

async fn cmd_stop_record(state: &Arc<Mutex<BrowserState>>) -> Result<serde_json::Value> {
    let mut state_guard = state.lock().await;

    let mut workflow = state_guard.recording.take()
        .context("Not currently recording a workflow")?;

    let command_count = workflow.commands.len();
    let name = workflow.name.clone();

    drop(state_guard); // Release lock before async operation

    // Save the workflow (generates embedding if Ollama is available)
    let path = crate::commands::browse::workflow::save_workflow(&mut workflow).await?;

    Ok(serde_json::json!({
        "saved": true,
        "name": name,
        "commands": command_count,
        "path": path.display().to_string(),
        "has_embedding": workflow.embedding.is_some()
    }))
}

async fn cmd_replay(args: serde_json::Value, state: &Arc<Mutex<BrowserState>>) -> Result<serde_json::Value> {
    let name = args["name"].as_str().context("Missing name")?;

    // Load the workflow
    let workflow = crate::commands::browse::workflow::load_workflow(name)?;

    let mut results = Vec::new();
    let mut failed_at = None;

    // Execute each command in the workflow
    for (index, cmd) in workflow.commands.iter().enumerate() {
        let request = Request {
            command: cmd.command.clone(),
            args: cmd.args.clone(),
        };

        // Execute the command by calling process_request recursively
        // But we need to be careful not to record during replay
        let result = execute_workflow_command(&request, state).await;

        match result {
            Ok(data) => results.push(serde_json::json!({
                "step": index + 1,
                "command": &cmd.command,
                "success": true,
                "data": data
            })),
            Err(e) => {
                failed_at = Some(index + 1);
                results.push(serde_json::json!({
                    "step": index + 1,
                    "command": &cmd.command,
                    "success": false,
                    "error": e.to_string()
                }));
                break;
            }
        }
    }

    Ok(serde_json::json!({
        "workflow": name,
        "total_steps": workflow.commands.len(),
        "executed_steps": results.len(),
        "failed_at": failed_at,
        "results": results
    }))
}

// Helper to execute a workflow command without recording
async fn execute_workflow_command(
    request: &Request,
    state: &Arc<Mutex<BrowserState>>,
) -> Result<serde_json::Value> {
    match request.command.as_str() {
        "navigate" => cmd_navigate(request.args.clone(), state).await,
        "screenshot" => cmd_screenshot(request.args.clone(), state).await,
        "click" => cmd_click(request.args.clone(), state).await,
        "type" => cmd_type(request.args.clone(), state).await,
        "extract" => cmd_extract(request.args.clone(), state).await,
        "eval" => cmd_eval(request.args.clone(), state).await,
        "wait" => cmd_wait(request.args.clone(), state).await,
        "tabs_list" => cmd_tabs_list(state).await,
        "tabs_new" => cmd_tabs_new(request.args.clone(), state).await,
        "tabs_switch" => cmd_tabs_switch(request.args.clone(), state).await,
        "tabs_close" => cmd_tabs_close(request.args.clone(), state).await,
        "pdf" => cmd_pdf(request.args.clone(), state).await,
        "get_cookies" => cmd_get_cookies(request.args.clone(), state).await,
        "set_cookie" => cmd_set_cookie(request.args.clone(), state).await,
        "delete_cookies" => cmd_delete_cookies(request.args.clone(), state).await,
        "set_user_agent" => cmd_set_user_agent(request.args.clone(), state).await,
        _ => Err(anyhow::anyhow!("Unknown command in workflow: {}", request.command)),
    }
}

async fn cmd_list_workflows() -> Result<serde_json::Value> {
    let workflows = crate::commands::browse::workflow::list_workflows()?;

    Ok(serde_json::json!({
        "workflows": workflows,
        "count": workflows.len()
    }))
}

async fn cmd_delete_workflow(args: serde_json::Value) -> Result<serde_json::Value> {
    let name = args["name"].as_str().context("Missing name")?;

    crate::commands::browse::workflow::delete_workflow(name)?;

    Ok(serde_json::json!({
        "deleted": name
    }))
}

async fn cmd_suggest(args: serde_json::Value) -> Result<serde_json::Value> {
    let task = args["task"].as_str().context("Missing task")?;
    let limit = args["limit"].as_u64().unwrap_or(3) as usize;

    let suggestions = crate::commands::browse::workflow::suggest_workflows(task, limit).await?;

    let results: Vec<serde_json::Value> = suggestions
        .iter()
        .map(|(name, similarity)| {
            serde_json::json!({
                "workflow": name,
                "similarity": similarity
            })
        })
        .collect();

    Ok(serde_json::json!({
        "task": task,
        "suggestions": results
    }))
}

async fn stop_daemon() -> Result<()> {
    if !daemon_utils::is_running(DAEMON_NAME)? {
        println!("Daemon is not running");
        return Ok(());
    }

    let pid_file = daemon_utils::pid_file_path(DAEMON_NAME)?;
    let pid_str = std::fs::read_to_string(&pid_file)?;
    let pid: i32 = pid_str.trim().parse()?;

    unsafe {
        libc::kill(pid, libc::SIGTERM);
    }

    // Wait a bit for graceful shutdown
    tokio::time::sleep(tokio::time::Duration::from_secs(2)).await;

    // Force kill if still running
    if daemon_utils::is_running(DAEMON_NAME)? {
        unsafe {
            libc::kill(pid, libc::SIGKILL);
        }
    }

    // Clean up
    daemon_utils::remove_pid_file(DAEMON_NAME)?;
    let socket_path = daemon_utils::socket_path(DAEMON_NAME)?;
    if socket_path.exists() {
        std::fs::remove_file(&socket_path)?;
    }

    println!("Daemon stopped");
    Ok(())
}

async fn check_status() -> Result<()> {
    if daemon_utils::is_running(DAEMON_NAME)? {
        let pid_file = daemon_utils::pid_file_path(DAEMON_NAME)?;
        let pid = std::fs::read_to_string(&pid_file)?;
        println!("Daemon is running (PID: {})", pid.trim());
    } else {
        println!("Daemon is not running");
    }
    Ok(())
}
