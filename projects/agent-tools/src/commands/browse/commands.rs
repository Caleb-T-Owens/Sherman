use crate::commands::browse::{BrowseCommand, TabAction};
use crate::common::daemon as daemon_utils;
use crate::commands::browse::daemon::{Request, Response};
use anyhow::{Context, Result, bail};
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::UnixStream;

const DAEMON_NAME: &str = "browse";

pub async fn handle_command(command: BrowseCommand) -> Result<()> {
    // Ensure daemon is running
    if !daemon_utils::is_running(DAEMON_NAME)? {
        bail!("Browser daemon is not running. Start it with: agent-tools browse daemon start");
    }

    match command {
        BrowseCommand::Navigate { url, tab } => {
            let response = send_request("navigate", serde_json::json!({
                "url": url,
                "tab": tab,
            })).await?;

            if response.success {
                println!("Navigated to: {}", url);
            } else {
                bail!("Navigation failed: {}", response.error.unwrap_or_default());
            }
        }
        BrowseCommand::Screenshot { selector, output, tab } => {
            let response = send_request("screenshot", serde_json::json!({
                "selector": selector,
                "output": output,
                "tab": tab,
            })).await?;

            if response.success {
                if let Some(data) = response.data {
                    println!("Screenshot saved to: {}", data);
                }
            } else {
                bail!("Screenshot failed: {}", response.error.unwrap_or_default());
            }
        }
        BrowseCommand::Click { selector, tab } => {
            let response = send_request("click", serde_json::json!({
                "selector": selector,
                "tab": tab,
            })).await?;

            if response.success {
                println!("Clicked element: {}", selector);
            } else {
                bail!("Click failed: {}", response.error.unwrap_or_default());
            }
        }
        BrowseCommand::Type { selector, text, tab } => {
            let response = send_request("type", serde_json::json!({
                "selector": selector,
                "text": text,
                "tab": tab,
            })).await?;

            if response.success {
                println!("Typed text into: {}", selector);
            } else {
                bail!("Type failed: {}", response.error.unwrap_or_default());
            }
        }
        BrowseCommand::Extract { selector, html, all, tab } => {
            let response = send_request("extract", serde_json::json!({
                "selector": selector,
                "html": html,
                "all": all,
                "tab": tab,
            })).await?;

            if response.success {
                if let Some(data) = response.data {
                    println!("{}", serde_json::to_string_pretty(&data)?);
                }
            } else {
                bail!("Extract failed: {}", response.error.unwrap_or_default());
            }
        }
        BrowseCommand::Eval { js, tab } => {
            let response = send_request("eval", serde_json::json!({
                "js": js,
                "tab": tab,
            })).await?;

            if response.success {
                if let Some(data) = response.data {
                    println!("{}", serde_json::to_string_pretty(&data)?);
                }
            } else {
                bail!("Eval failed: {}", response.error.unwrap_or_default());
            }
        }
        BrowseCommand::Wait { selector, timeout, tab } => {
            let response = send_request("wait", serde_json::json!({
                "selector": selector,
                "timeout": timeout,
                "tab": tab,
            })).await?;

            if response.success {
                println!("Element appeared: {}", selector);
            } else {
                bail!("Wait failed: {}", response.error.unwrap_or_default());
            }
        }
        BrowseCommand::Tabs { action } => {
            handle_tab_action(action).await?;
        }
        BrowseCommand::Pdf { output, tab } => {
            let response = send_request("pdf", serde_json::json!({
                "output": output,
                "tab": tab,
            })).await?;

            if response.success {
                println!("PDF saved to: {}", output);
            } else {
                bail!("PDF generation failed: {}", response.error.unwrap_or_default());
            }
        }
        BrowseCommand::GetCookies { tab } => {
            let response = send_request("get_cookies", serde_json::json!({
                "tab": tab,
            })).await?;

            if response.success {
                if let Some(data) = response.data {
                    println!("{}", serde_json::to_string_pretty(&data)?);
                }
            } else {
                bail!("Get cookies failed: {}", response.error.unwrap_or_default());
            }
        }
        BrowseCommand::SetCookie { name, value, domain, tab } => {
            let response = send_request("set_cookie", serde_json::json!({
                "name": name,
                "value": value,
                "domain": domain,
                "tab": tab,
            })).await?;

            if response.success {
                println!("Cookie set: {}", name);
            } else {
                bail!("Set cookie failed: {}", response.error.unwrap_or_default());
            }
        }
        BrowseCommand::DeleteCookies { name, tab } => {
            let response = send_request("delete_cookies", serde_json::json!({
                "name": name,
                "tab": tab,
            })).await?;

            if response.success {
                if let Some(name) = name {
                    println!("Deleted cookie: {}", name);
                } else {
                    println!("Deleted all cookies");
                }
            } else {
                bail!("Delete cookies failed: {}", response.error.unwrap_or_default());
            }
        }
        BrowseCommand::SetUserAgent { user_agent, tab } => {
            let response = send_request("set_user_agent", serde_json::json!({
                "user_agent": user_agent,
                "tab": tab,
            })).await?;

            if response.success {
                println!("User agent set");
            } else {
                bail!("Set user agent failed: {}", response.error.unwrap_or_default());
            }
        }
        BrowseCommand::Record { name, description } => {
            let response = send_request("record", serde_json::json!({
                "name": name,
                "description": description,
            })).await?;

            if response.success {
                println!("Recording workflow: {}", name);
                if let Some(desc) = description {
                    println!("Description: {}", desc);
                }
            } else {
                bail!("Failed to start recording: {}", response.error.unwrap_or_default());
            }
        }
        BrowseCommand::StopRecord => {
            let response = send_request("stop_record", serde_json::json!({})).await?;

            if response.success {
                if let Some(data) = response.data {
                    println!("Workflow saved!");
                    println!("  Name: {}", data["name"]);
                    println!("  Commands: {}", data["commands"]);
                    println!("  Path: {}", data["path"]);
                }
            } else {
                bail!("Failed to stop recording: {}", response.error.unwrap_or_default());
            }
        }
        BrowseCommand::Replay { name } => {
            let response = send_request("replay", serde_json::json!({
                "name": name,
            })).await?;

            if response.success {
                if let Some(data) = response.data {
                    println!("Replayed workflow: {}", name);
                    println!("  Steps: {}/{}", data["executed_steps"], data["total_steps"]);

                    if let Some(failed) = data["failed_at"].as_u64() {
                        println!("  Failed at step: {}", failed);
                    }
                }
            } else {
                bail!("Failed to replay workflow: {}", response.error.unwrap_or_default());
            }
        }
        BrowseCommand::ListWorkflows => {
            let response = send_request("list_workflows", serde_json::json!({})).await?;

            if response.success {
                if let Some(data) = response.data {
                    let empty_vec = vec![];
                    let workflows = data["workflows"].as_array().unwrap_or(&empty_vec);
                    if workflows.is_empty() {
                        println!("No saved workflows");
                    } else {
                        println!("Saved workflows ({})", workflows.len());
                        for workflow in workflows {
                            println!("  - {}", workflow.as_str().unwrap_or(""));
                        }
                    }
                }
            } else {
                bail!("Failed to list workflows: {}", response.error.unwrap_or_default());
            }
        }
        BrowseCommand::DeleteWorkflow { name } => {
            let response = send_request("delete_workflow", serde_json::json!({
                "name": name,
            })).await?;

            if response.success {
                println!("Deleted workflow: {}", name);
            } else {
                bail!("Failed to delete workflow: {}", response.error.unwrap_or_default());
            }
        }
        BrowseCommand::Suggest { task, limit } => {
            let response = send_request("suggest", serde_json::json!({
                "task": task,
                "limit": limit,
            })).await?;

            if response.success {
                if let Some(data) = response.data {
                    let suggestions = data["suggestions"].as_array();

                    if let Some(suggestions) = suggestions {
                        if suggestions.is_empty() {
                            println!("No workflow suggestions found (Ollama may not be running or no workflows have embeddings)");
                        } else {
                            println!("Suggested workflows for: \"{}\"", task);
                            for suggestion in suggestions {
                                let workflow = suggestion["workflow"].as_str().unwrap_or("");
                                let similarity = suggestion["similarity"].as_f64().unwrap_or(0.0);
                                println!("  {} (similarity: {:.2}%)", workflow, similarity * 100.0);
                            }
                        }
                    }
                }
            } else {
                bail!("Failed to suggest workflows: {}", response.error.unwrap_or_default());
            }
        }
        _ => unreachable!(),
    }

    Ok(())
}

async fn handle_tab_action(action: TabAction) -> Result<()> {
    match action {
        TabAction::List => {
            let response = send_request("tabs_list", serde_json::json!({})).await?;
            if response.success {
                if let Some(data) = response.data {
                    println!("{}", serde_json::to_string_pretty(&data)?);
                }
            } else {
                bail!("List tabs failed: {}", response.error.unwrap_or_default());
            }
        }
        TabAction::New { url } => {
            let response = send_request("tabs_new", serde_json::json!({
                "url": url,
            })).await?;

            if response.success {
                if let Some(data) = response.data {
                    println!("Created tab: {}", data);
                }
            } else {
                bail!("New tab failed: {}", response.error.unwrap_or_default());
            }
        }
        TabAction::Switch { id } => {
            let response = send_request("tabs_switch", serde_json::json!({
                "id": id,
            })).await?;

            if response.success {
                println!("Switched to tab: {}", id);
            } else {
                bail!("Switch tab failed: {}", response.error.unwrap_or_default());
            }
        }
        TabAction::Close { id } => {
            let response = send_request("tabs_close", serde_json::json!({
                "id": id,
            })).await?;

            if response.success {
                println!("Closed tab: {}", id);
            } else {
                bail!("Close tab failed: {}", response.error.unwrap_or_default());
            }
        }
    }

    Ok(())
}

async fn send_request(command: &str, args: serde_json::Value) -> Result<Response> {
    let socket_path = daemon_utils::socket_path(DAEMON_NAME)?;
    let mut stream = UnixStream::connect(&socket_path)
        .await
        .context("Failed to connect to daemon")?;

    let request = Request {
        command: command.to_string(),
        args,
    };

    let request_json = serde_json::to_string(&request)?;
    stream.write_all(request_json.as_bytes()).await?;
    stream.write_all(b"\n").await?;

    let mut reader = BufReader::new(&mut stream);
    let mut response_line = String::new();
    reader.read_line(&mut response_line).await?;

    let response: Response = serde_json::from_str(&response_line)
        .context("Failed to parse response")?;

    Ok(response)
}
