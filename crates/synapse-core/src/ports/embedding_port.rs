//! EmbeddingPort - Trait for text embedding generation.

use async_trait::async_trait;
use crate::CoreError;

/// Port for generating text embeddings.
///
/// Implementations:
/// - `OrtAdapter` (all-MiniLM-L6-v2)
#[async_trait]
pub trait EmbeddingPort: Send + Sync {
    /// Generate embedding for text.
    ///
    /// Returns a vector of floats (384-dim for MiniLM, 768 for others).
    async fn embed(&self, text: &str) -> Result<Vec<f32>, CoreError>;
    
    /// Generate embeddings for multiple texts (batch).
    async fn embed_batch(&self, texts: &[String]) -> Result<Vec<Vec<f32>>, CoreError> {
        let mut results = Vec::with_capacity(texts.len());
        for text in texts {
            results.push(self.embed(text).await?);
        }
        Ok(results)
    }
    
    /// Get the embedding dimension.
    fn dimension(&self) -> usize;
    
    /// Get the model/provider name.
    fn provider_name(&self) -> &str;
}
