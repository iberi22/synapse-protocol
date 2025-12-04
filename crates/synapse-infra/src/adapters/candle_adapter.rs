//! Candle adapter for LLM inference (TinyLlama GGUF).
//!
//! Uses HuggingFace Candle to run Quantized Llama models locally.

use async_trait::async_trait;
use synapse_core::{Error, LlmPort};
use std::sync::Arc;
use tokio::sync::Mutex;

use candle_transformers::models::quantized_llama::ModelWeights as Llama;
use candle_core::{Device, Tensor};
use candle_core::quantized::gguf_file;
use tokenizers::Tokenizer;


/// Candle adapter for TinyLlama (GGUF).
pub struct CandleAdapter {
    model: Arc<Mutex<Llama>>,
    tokenizer: Tokenizer,
    device: Device,
}

impl CandleAdapter {
    pub fn new() -> Result<Self, Error> {
        let model_dir = std::path::Path::new("models/tinyllama-1.1b");
        let model_path = model_dir.join("model.gguf");
        let tokenizer_path = model_dir.join("tokenizer.json");

        if !model_path.exists() {
            return Err(Error::System(format!(
                "TinyLlama model not found at {:?}. Please run 'synapse init' to download models.",
                model_dir
            )));
        }

        let device = Device::Cpu;

        // Load Tokenizer
        // If tokenizer.json is missing, we can try to use a default or fail.
        // TinyLlama usually has one.
        let tokenizer = if tokenizer_path.exists() {
            Tokenizer::from_file(&tokenizer_path)
                .map_err(|e| Error::System(format!("Failed to load tokenizer: {}", e)))?
        } else {
             // Fallback or error
             return Err(Error::System("Tokenizer not found".into()));
        };

        // Load GGUF Model
        let mut file = std::fs::File::open(&model_path)
            .map_err(|e| Error::System(format!("Failed to open model file: {}", e)))?;

        let model_content = gguf_file::Content::read(&mut file)
            .map_err(|e| Error::System(format!("Failed to read GGUF content: {}", e)))?;

        let model = Llama::from_gguf(model_content, &mut file, &device)
            .map_err(|e| Error::System(format!("Failed to create Llama model: {}", e)))?;

        Ok(Self {
            model: Arc::new(Mutex::new(model)),
            tokenizer,
            device,
        })
    }
}

#[async_trait]
impl LlmPort for CandleAdapter {
    async fn generate(&self, prompt: &str, max_tokens: usize) -> Result<String, Error> {
        self.generate_with_params(prompt, max_tokens, 0.8, 0.9).await
    }

    async fn generate_with_params(
        &self,
        prompt: &str,
        max_tokens: usize,
        _temperature: f32,
        _top_p: f32,

    ) -> Result<String, Error> {
        // Format prompt for Chat (TinyLlama format)
        // <|system|>\n{system_prompt}</s>\n<|user|>\n{prompt}</s>\n<|assistant|>
        let formatted_prompt = format!("<|user|>\n{}</s>\n<|assistant|>", prompt);

        let tokens = self.tokenizer.encode(formatted_prompt, true)
            .map_err(|e| Error::System(format!("Tokenization failed: {}", e)))?;
        let input_ids = tokens.get_ids();

        let mut model = self.model.lock().await;

        let mut all_tokens = input_ids.to_vec();
        let mut output_text = String::new();

        let mut next_token = 0;

        // Pre-fill
        // For GGUF Llama, we usually process token by token or chunk.
        // Simple loop:

        // This is a simplified generation loop.
        // In reality, we need to handle KV cache and logits processing.
        // candle-transformers examples usually show how to do this.
        // I'll implement a basic greedy/sampling loop.

        let mut pos = 0;
        for index in 0..input_ids.len() + max_tokens {
            let start_pos = pos;

            let input = if index < input_ids.len() {
                 // We are in prompt
                 // Let's optimize: feed whole prompt at once?
                 // Llama GGUF supports it.
                 if index == 0 {
                     let t = Tensor::new(input_ids, &self.device)
                        .map_err(|e| Error::System(e.to_string()))?
                        .unsqueeze(0)
                        .map_err(|e| Error::System(e.to_string()))?;
                     pos += input_ids.len();
                     t
                 } else {
                     continue; // Already processed
                 }
            } else {
                // Generation
                let t = Tensor::new(&[next_token], &self.device)
                    .map_err(|e| Error::System(e.to_string()))?
                    .unsqueeze(0)
                    .map_err(|e| Error::System(e.to_string()))?;
                pos += 1;
                t
            };

            let logits = model.forward(&input, start_pos)
                .map_err(|e| Error::System(format!("Forward failed: {}", e)))?;

            let logits = logits.squeeze(0)
                .map_err(|e| Error::System(e.to_string()))?;
            let logits = logits.get(logits.dim(0).map_err(|e| Error::System(e.to_string()))? - 1)
                .map_err(|e| Error::System(e.to_string()))?; // Last token logits

            // Sample
            // TODO: Apply temp/top_p
            // Greedy for now
            let next_token_id = logits.argmax(0)
                .map_err(|e| Error::System(e.to_string()))?
                .to_scalar::<u32>()
                .map_err(|e| Error::System(e.to_string()))?;

            next_token = next_token_id;

            if index >= input_ids.len() {
                all_tokens.push(next_token);
                let text = self.tokenizer.decode(&[next_token], true)
                    .map_err(|e| Error::System(e.to_string()))?;
                output_text.push_str(&text);

                if text.contains("</s>") || next_token == 2 { // EOS
                    break;
                }
            }
        }

        Ok(output_text.replace("</s>", ""))
    }
}
