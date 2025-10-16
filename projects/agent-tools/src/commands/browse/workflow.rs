use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use std::path::PathBuf;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Workflow {
    pub name: String,
    pub description: String,
    pub commands: Vec<WorkflowCommand>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub embedding: Option<Vec<f32>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorkflowCommand {
    pub command: String,
    pub args: serde_json::Value,
}

impl Workflow {
    pub fn new(name: String, description: String) -> Self {
        Self {
            name,
            description,
            commands: Vec::new(),
            embedding: None,
        }
    }

    pub fn add_command(&mut self, command: String, args: serde_json::Value) {
        self.commands.push(WorkflowCommand { command, args });
    }

    pub fn set_embedding(&mut self, embedding: Vec<f32>) {
        self.embedding = Some(embedding);
    }
}

/// Get the workflows directory path
pub fn workflows_dir() -> Result<PathBuf> {
    let home = std::env::var("HOME").context("HOME environment variable not set")?;
    let dir = PathBuf::from(home)
        .join(".local")
        .join("share")
        .join("agent-tools")
        .join("workflows");

    std::fs::create_dir_all(&dir).context("Failed to create workflows directory")?;

    Ok(dir)
}

/// Save a workflow to disk
pub async fn save_workflow(workflow: &mut Workflow) -> Result<PathBuf> {
    // Try to generate embedding for the description if we don't have one yet
    if workflow.embedding.is_none() {
        match super::ollama::generate_embedding(&workflow.description).await {
            Ok(embedding) => {
                workflow.set_embedding(embedding);
                tracing::info!("Generated embedding for workflow: {}", workflow.name);
            }
            Err(e) => {
                tracing::warn!("Failed to generate embedding (Ollama may not be running): {}", e);
                // Continue anyway - embedding is optional
            }
        }
    }

    let dir = workflows_dir()?;
    let filename = format!("{}.json", sanitize_filename(&workflow.name));
    let path = dir.join(filename);

    let json = serde_json::to_string_pretty(workflow)?;
    std::fs::write(&path, json)?;

    Ok(path)
}

/// Load a workflow from disk by name
pub fn load_workflow(name: &str) -> Result<Workflow> {
    let dir = workflows_dir()?;
    let filename = format!("{}.json", sanitize_filename(name));
    let path = dir.join(filename);

    let json = std::fs::read_to_string(&path)
        .context(format!("Workflow not found: {}", name))?;
    let workflow: Workflow = serde_json::from_str(&json)?;

    Ok(workflow)
}

/// List all available workflows
pub fn list_workflows() -> Result<Vec<String>> {
    let dir = workflows_dir()?;
    let mut workflows = Vec::new();

    for entry in std::fs::read_dir(dir)? {
        let entry = entry?;
        let path = entry.path();

        if path.extension().and_then(|s| s.to_str()) == Some("json") {
            if let Some(stem) = path.file_stem().and_then(|s| s.to_str()) {
                workflows.push(stem.to_string());
            }
        }
    }

    workflows.sort();
    Ok(workflows)
}

/// Delete a workflow
pub fn delete_workflow(name: &str) -> Result<()> {
    let dir = workflows_dir()?;
    let filename = format!("{}.json", sanitize_filename(name));
    let path = dir.join(filename);

    std::fs::remove_file(&path)
        .context(format!("Failed to delete workflow: {}", name))?;

    Ok(())
}

/// Suggest similar workflows based on a task description
pub async fn suggest_workflows(task_description: &str, limit: usize) -> Result<Vec<(String, f32)>> {
    // Generate embedding for the task
    let task_embedding = super::ollama::generate_embedding(task_description).await?;

    // Load all workflows and calculate similarities
    let workflow_names = list_workflows()?;
    let mut similarities = Vec::new();

    for name in workflow_names {
        let workflow = load_workflow(&name)?;

        if let Some(ref embedding) = workflow.embedding {
            let similarity = super::ollama::cosine_similarity(&task_embedding, embedding);
            similarities.push((name, similarity));
        }
    }

    // Sort by similarity (highest first)
    similarities.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));

    // Take top N
    similarities.truncate(limit);

    Ok(similarities)
}

/// Sanitize a workflow name to be filesystem-safe
fn sanitize_filename(name: &str) -> String {
    name.chars()
        .map(|c| match c {
            'a'..='z' | 'A'..='Z' | '0'..='9' | '-' | '_' => c,
            ' ' => '-',
            _ => '_',
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sanitize_filename() {
        assert_eq!(sanitize_filename("Browse HN"), "Browse-HN");
        assert_eq!(sanitize_filename("test@123!"), "test_123_");
    }
}
