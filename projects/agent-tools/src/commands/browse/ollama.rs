use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};

const OLLAMA_API_BASE: &str = "http://localhost:11434";
const DEFAULT_MODEL: &str = "nomic-embed-text";

#[derive(Debug, Serialize)]
struct EmbeddingRequest {
    model: String,
    prompt: String,
}

#[derive(Debug, Deserialize)]
struct EmbeddingResponse {
    embedding: Vec<f32>,
}

/// Generate an embedding for a text using Ollama
pub async fn generate_embedding(text: &str) -> Result<Vec<f32>> {
    let client = reqwest::Client::new();

    let request = EmbeddingRequest {
        model: DEFAULT_MODEL.to_string(),
        prompt: text.to_string(),
    };

    let response = client
        .post(format!("{}/api/embeddings", OLLAMA_API_BASE))
        .json(&request)
        .send()
        .await
        .context("Failed to connect to Ollama - is it running?")?;

    if !response.status().is_success() {
        let status = response.status();
        let body = response.text().await.unwrap_or_default();
        anyhow::bail!("Ollama API error ({}): {}", status, body);
    }

    let embedding_response: EmbeddingResponse = response
        .json()
        .await
        .context("Failed to parse Ollama response")?;

    Ok(embedding_response.embedding)
}

/// Calculate cosine similarity between two embedding vectors
pub fn cosine_similarity(a: &[f32], b: &[f32]) -> f32 {
    if a.len() != b.len() {
        return 0.0;
    }

    let dot_product: f32 = a.iter().zip(b.iter()).map(|(x, y)| x * y).sum();
    let magnitude_a: f32 = a.iter().map(|x| x * x).sum::<f32>().sqrt();
    let magnitude_b: f32 = b.iter().map(|x| x * x).sum::<f32>().sqrt();

    if magnitude_a == 0.0 || magnitude_b == 0.0 {
        return 0.0;
    }

    dot_product / (magnitude_a * magnitude_b)
}

/// Check if Ollama is available
pub async fn is_available() -> bool {
    let client = reqwest::Client::new();
    client
        .get(format!("{}/api/tags", OLLAMA_API_BASE))
        .send()
        .await
        .is_ok()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_cosine_similarity() {
        let a = vec![1.0, 0.0, 0.0];
        let b = vec![1.0, 0.0, 0.0];
        assert_eq!(cosine_similarity(&a, &b), 1.0);

        let a = vec![1.0, 0.0];
        let b = vec![0.0, 1.0];
        assert_eq!(cosine_similarity(&a, &b), 0.0);
    }
}
