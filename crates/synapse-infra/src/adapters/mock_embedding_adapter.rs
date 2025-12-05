//! Mock embedding adapter for testing.
//!
//! Generates deterministic embeddings based on text hash without requiring ONNX models.

use async_trait::async_trait;
use synapse_core::{error::Error, EmbeddingPort};

/// Mock embedding adapter for unit tests.
///
/// Generates deterministic 384-dimensional embeddings based on text content hash.
pub struct MockEmbeddingAdapter {
    dimension: usize,
}

impl MockEmbeddingAdapter {
    /// Create a new mock adapter with default dimension (384).
    pub fn new() -> Self {
        Self { dimension: 384 }
    }

    /// Create a new mock adapter with custom dimension.
    pub fn with_dimension(dimension: usize) -> Self {
        Self { dimension }
    }
}

impl Default for MockEmbeddingAdapter {
    fn default() -> Self {
        Self::new()
    }
}

#[async_trait]
impl EmbeddingPort for MockEmbeddingAdapter {
    async fn embed(&self, text: &str) -> Result<Vec<f32>, Error> {
        // Generate a deterministic embedding based on text hash
        // This ensures the same text always produces the same embedding
        let mut embedding = vec![0.0f32; self.dimension];

        // Simple hash: sum of character codes with position weighting
        let hash: u64 = text
            .chars()
            .enumerate()
            .map(|(i, c)| (c as u64).wrapping_mul((i + 1) as u64))
            .fold(0u64, |acc, x| acc.wrapping_add(x));

        // Fill embedding vector with pseudo-random values derived from hash
        for (i, val) in embedding.iter_mut().enumerate() {
            // Use different transformations for variety
            let seed = hash.wrapping_add(i as u64).wrapping_mul(0x517cc1b727220a95);
            *val = ((seed % 2000) as f32 / 1000.0) - 1.0; // Range: [-1.0, 1.0]
        }

        // L2 normalize the vector
        let norm: f32 = embedding.iter().map(|x| x * x).sum::<f32>().sqrt();
        if norm > 0.0 {
            for val in embedding.iter_mut() {
                *val /= norm;
            }
        }

        Ok(embedding)
    }

    fn dimension(&self) -> usize {
        self.dimension
    }

    fn provider_name(&self) -> &str {
        "mock"
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_embed_produces_correct_dimension() {
        let adapter = MockEmbeddingAdapter::new();
        let embedding = adapter.embed("Hello world").await.unwrap();
        assert_eq!(embedding.len(), 384);
    }

    #[tokio::test]
    async fn test_embed_is_deterministic() {
        let adapter = MockEmbeddingAdapter::new();
        let e1 = adapter.embed("Same text").await.unwrap();
        let e2 = adapter.embed("Same text").await.unwrap();
        assert_eq!(e1, e2);
    }

    #[tokio::test]
    async fn test_embed_different_texts_produce_different_embeddings() {
        let adapter = MockEmbeddingAdapter::new();
        let e1 = adapter.embed("First text").await.unwrap();
        let e2 = adapter.embed("Second text").await.unwrap();
        assert_ne!(e1, e2);
    }

    #[tokio::test]
    async fn test_embedding_is_normalized() {
        let adapter = MockEmbeddingAdapter::new();
        let embedding = adapter.embed("Test").await.unwrap();

        let norm: f32 = embedding.iter().map(|x| x * x).sum::<f32>().sqrt();
        assert!((norm - 1.0).abs() < 0.001, "Embedding should be L2 normalized");
    }

    #[tokio::test]
    async fn test_custom_dimension() {
        let adapter = MockEmbeddingAdapter::with_dimension(768);
        let embedding = adapter.embed("Test").await.unwrap();
        assert_eq!(embedding.len(), 768);
        assert_eq!(adapter.dimension(), 768);
    }
}
