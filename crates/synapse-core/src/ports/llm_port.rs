//! LlmPort - Trait for LLM inference.

use async_trait::async_trait;
use crate::CoreError;

/// Port for LLM text generation.
///
/// Implementations:
/// - `CandleAdapter` (RWKV, Phi-3)
/// - `OrtAdapter` (ONNX models)
#[async_trait]
pub trait LlmPort: Send + Sync {
    /// Generate text completion.
    async fn generate(&self, prompt: &str, max_tokens: usize) -> Result<String, CoreError>;
    
    /// Generate with temperature control.
    async fn generate_with_params(
        &self,
        prompt: &str,
        max_tokens: usize,
        temperature: f32,
        top_p: f32,
    ) -> Result<String, CoreError>;
    
    /// Summarize text (for HiRAG layer creation).
    async fn summarize(&self, text: &str) -> Result<String, CoreError> {
        let prompt = format!(
            "Summarize the following text concisely:\n\n{}\n\nSummary:",
            text
        );
        self.generate(&prompt, 256).await
    }
}
