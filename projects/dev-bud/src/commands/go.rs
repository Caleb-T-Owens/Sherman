use crate::utils::{ensure_bud_dir_exists, get_current_file};
use anyhow::{Result, bail};
use async_openai::{
    Client,
    types::{
        ChatCompletionRequestAssistantMessage, ChatCompletionRequestMessage,
        ChatCompletionRequestSystemMessage, ChatCompletionRequestToolMessage,
        ChatCompletionRequestUserMessage, ChatCompletionTool, ChatCompletionToolType,
        CreateChatCompletionRequest, CreateChatCompletionRequestArgs, FunctionObject,
    },
};
use serde::Deserialize;
use std::path::Path;
use tokio::fs as tokio_fs;

const SYSTEM_PROMPT: &str = "You are a thoughtful and efficient software development assistant. Your role is to help a developer maintain a “headspace” document — a living outline of their intent, reasoning, and plan of action as they work through a task.

The developer is in the Planning or Execution phase of their workflow. They are using a structured document to communicate what they are working on and why. Your job is to support them in writing clear, concise, and useful entries in that document.

The document typically follows this format:

```
# Requirements
Describe the user-facing behavior or functionality that needs to be achieved. Write in plain language or bullet points.

# What this usually looks like
Describe what a high level implementation of the requirements would look like. Use practical examples when helpful.

# What I plan on changing
List the specific changes the developer intends to make — both conceptually and technically. Bullet points are encouraged.

# How I plan on changing it
Explain the concrete steps that will be taken in code, including file/function names or conditions if relevant. This is often more implementation-focused. Use clear bullet points.
```
Each section typically contains short bullet points. The user may add these one at a time as they work.

Your responsibilities:
- Do not extrapolate beyond what the user wrote or implied.
- Do not generate additional bullets or sections unless the user explicitly asks you to.
- Never assume intent. If a user writes “I plan on changing the Testeroni function in go.rs”, you should only reflect that bullet or lightly rephrase it if clarity is needed — nothing more.
- Focus on making small contributions legible and well-structured, not on expanding them.
- Be minimal, precise, and respectful of the user’s pacing.
- If the user’s bullet is clear, don’t rewrite it unless asked.
- If the user asks for help, feedback, or clarification, then assist with care.

When editing, preserve the developer’s voice and intent, but improve clarity, structure, and conciseness

Tone: Professional but conversational. Avoid jargon unless it helps disambiguate technical ideas.

You **may** sometimes:

- Rewrite or reformat existing content for clarity
- Summarize code behavior if the user pastes relevant snippets
- Flag inconsistencies or missing logic in the planning vs implementation description

You **do not** write code for them unless it helps clarify a point in the document.
You **do not** invent implementation details unless the user asks for help doing so.

ONLY make small and precise changes to the document. DO NOT make unrelated changes.

Your purpose is to help the developer think and communicate better — not do the work for them.
";

pub async fn execute_command(bud_dir: &Path, prompt: &str) -> Result<()> {
    ensure_bud_dir_exists(bud_dir).await?;

    let current = get_current_file(bud_dir).await?;
    let file_path = bud_dir.join(format!("{}.md", current));
    if !file_path.exists() {
        bail!("Current file '{}.md' not found in .bud directory", current);
    }

    // Read the current file content
    let file_content = tokio_fs::read_to_string(&file_path).await?;

    let mut messages: Vec<ChatCompletionRequestMessage> = vec![
        ChatCompletionRequestSystemMessage {
            name: None,
            content: SYSTEM_PROMPT.into(),
        }
        .into(),
        ChatCompletionRequestUserMessage {
            name: None,
            content: format!(
                "Please edit the file based on the following prompt: {}

File content: {file_content}",
                prompt
            )
            .into(),
        }
        .into(),
    ];

    let client = Client::new();

    loop {
        let request = build_request(messages.clone())?;
        let response = client.chat().create(request).await?;

        let message = response.choices[0].message.clone();

        if message.tool_calls.is_some() {
            let tool_call = message.tool_calls.clone().unwrap()[0].clone();
            let tool_call_id = tool_call.id.clone();
            let tool_name = tool_call.function.name;

            println!(
                "Running tool call {} with arguments: {}",
                tool_name, tool_call.function.arguments
            );

            let result = handle_tool_call(bud_dir, &tool_name, &tool_call.function.arguments).await;

            println!("Tool call result: {}", result);

            messages.push(
                ChatCompletionRequestAssistantMessage {
                    name: None,
                    content: None,
                    tool_calls: message.tool_calls.clone(),
                    function_call: None,
                    refusal: None,
                    audio: None,
                }
                .into(),
            );
            messages.push(
                ChatCompletionRequestToolMessage {
                    content: result.into(),
                    tool_call_id,
                }
                .into(),
            );
            continue;
        } else {
            println!("{}", message.content.unwrap());
            break;
        }
    }

    Ok(())
}

fn build_request(
    messages: Vec<ChatCompletionRequestMessage>,
) -> Result<CreateChatCompletionRequest> {
    let result = CreateChatCompletionRequestArgs::default()
        .model("gpt-4o-mini")
        .messages(messages)
        .tools(vec![ChatCompletionTool {
            r#type: ChatCompletionToolType::Function,
            function: FunctionObject {
                name: "edit_file".to_string(),
                description: Some("Edit the file".to_string()),
                strict: Some(true),
                parameters: Some(serde_json::json!({
                    "type": "object",
                    "properties": {
                        "content_to_remove": {
                            "type": "string",
                            "description": "All content to remove from the file"
                        },
                        "content_to_add": {
                            "type": "string",
                            "description": "All content to add to the file in place of what was removed"
                        }
                    },
                    "required": ["content_to_remove", "content_to_add"],
                    "additionalProperties": false,
                })),
            },
        }])
        .build()?;

    Ok(result)
}

async fn handle_tool_call(bud_dir: &Path, name: &str, args: &str) -> String {
    match name {
        "edit_file" => match edit_file(bud_dir, args).await {
            Ok(result) => result,
            Err(e) => e.to_string(),
        },
        _ => "Not implemented".to_string(),
    }
}

#[derive(Debug, Deserialize)]
struct EditFileArgs {
    content_to_remove: String,
    content_to_add: String,
}

async fn edit_file(bud_dir: &Path, args: &str) -> Result<String> {
    let args: EditFileArgs = serde_json::from_str(args)?;

    let current = get_current_file(bud_dir).await?;
    let file_path = bud_dir.join(format!("{}.md", current));
    if !file_path.exists() {
        bail!("Current file '{}.md' not found in .bud directory", current);
    }

    // Read the current file content
    let file_content = tokio_fs::read_to_string(&file_path).await?;

    let candidates = file_content.match_indices(&args.content_to_remove).count();
    if candidates > 1 {
        bail!(
            "Multiple candidates found for content to remove. Please provide more content to remove. Remeber that if you provide more contente to remove, it needs to be aded back in the content_to_add field."
        );
    } else if candidates == 0 {
        bail!("Content to remove not found in the file");
    }

    let new_content = file_content.replace(&args.content_to_remove, &args.content_to_add);

    if new_content == file_content {
        bail!("No changes were made to the file");
    }

    tokio_fs::write(&file_path, new_content).await?;

    Ok("Successfully updated the file".to_string())
}
