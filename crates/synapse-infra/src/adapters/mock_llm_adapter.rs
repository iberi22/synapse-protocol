use async_trait::async_trait;
use synapse_core::ports::LlmPort;
use synapse_core::error::Result;

pub struct MockLlmAdapter;

impl MockLlmAdapter {
    pub fn new() -> Self {
        Self
    }
}

#[async_trait]
impl LlmPort for MockLlmAdapter {
    async fn generate(&self, prompt: &str, _max_tokens: usize) -> Result<String> {
        Ok(format!("Mock response to: {}", prompt))
    }

    async fn generate_with_params(
        &self,
        prompt: &str,
        _max_tokens: usize,
        _temperature: f32,
        _top_p: f32,
    ) -> Result<String> {
        Ok(format!("Mock response (params) to: {}", prompt))
    }
}
