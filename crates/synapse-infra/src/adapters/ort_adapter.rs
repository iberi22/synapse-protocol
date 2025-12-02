//! ORT (ONNX Runtime) adapter for embeddings.
//!
//! TODO: Implement after embedding model is integrated.

use async_trait::async_trait;
use synapse_core::{CoreError, EmbeddingPort};

/// ONNX Runtime adapter for embeddings.
pub struct OrtAdapter {
    dimension: usize,
    // TODO: Add ORT session
}

impl OrtAdapter {
    /// Create a new ORT adapter with default MiniLM settings.
    pub fn new() -> Self {
        Self {
            dimension: 384, // all-MiniLM-L6-v2
        }
    }
    
    /// Create with custom embedding dimension.
    pub fn with_dimension(dimension: usize) -> Self {
        Self { dimension }
    }
}

impl Default for OrtAdapter {
    fn default() -> Self {
        Self::new()
    }
}

#[async_trait]
impl EmbeddingPort for OrtAdapter {
    async fn embed(&self, _text: &str) -> Result<Vec<f32>, CoreError> {
        // TODO: Implement ORT inference
        // For now, return zero vector
        Ok(vec![0.0; self.dimension])
    }
    
    fn dimension(&self) -> usize {
        self.dimension
    }
    
    fn provider_name(&self) -> &str {
        "ort-minilm-l6-v2"
    }
}
