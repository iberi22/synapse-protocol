//! ORT (ONNX Runtime) adapter for embeddings.

use async_trait::async_trait;
use synapse_core::{Error, EmbeddingPort};
use ort::session::{Session, builder::GraphOptimizationLevel};
use std::sync::Arc;
use tokenizers::Tokenizer;
use ndarray::Array2;

use tokio::sync::Mutex;

/// ONNX Runtime adapter for embeddings.
pub struct OrtAdapter {
    session: Arc<Mutex<Session>>,
    tokenizer: Tokenizer,
    dimension: usize,
}


impl OrtAdapter {
    /// Create a new ORT adapter.
    ///
    /// Requires the model file and tokenizer file to be present.
    /// For MVP, we expect them at `./models/all-MiniLM-L6-v2/`
    pub fn new() -> Result<Self, Error> {
        let model_dir = std::path::Path::new("models/all-MiniLM-L6-v2");
        let model_path = model_dir.join("model.onnx");
        let tokenizer_path = model_dir.join("tokenizer.json");

        if !model_path.exists() || !tokenizer_path.exists() {
            return Err(Error::System(format!(
                "Embedding model not found at {:?}. Please run 'synapse init' to download models.",
                model_dir
            )));
        }

        // Load Tokenizer
        let tokenizer = Tokenizer::from_file(&tokenizer_path)
            .map_err(|e| Error::System(format!("Failed to load tokenizer: {}", e)))?;

        // Load ONNX Session
        let session = Session::builder()
            .map_err(|e| Error::System(format!("Failed to create ORT builder: {}", e)))?
            .with_optimization_level(GraphOptimizationLevel::Level3)
            .map_err(|e| Error::System(format!("Failed to set optimization: {}", e)))?
            .with_intra_threads(4)
            .map_err(|e| Error::System(format!("Failed to set threads: {}", e)))?
            .commit_from_file(&model_path)
            .map_err(|e| Error::System(format!("Failed to load ONNX model: {}", e)))?;

        Ok(Self {
            session: Arc::new(Mutex::new(session)),
            tokenizer,
            dimension: 384,
        })

    }
}

#[async_trait]
impl EmbeddingPort for OrtAdapter {
    async fn embed(&self, text: &str) -> Result<Vec<f32>, Error> {
        // 1. Tokenize
        let encoding = self.tokenizer.encode(text, true)
            .map_err(|e| Error::System(format!("Tokenization failed: {}", e)))?;

        let input_ids = encoding.get_ids();
        let attention_mask = encoding.get_attention_mask();
        let token_type_ids = encoding.get_type_ids();
        let batch_size = 1;
        let seq_len = input_ids.len();

        // 2. Prepare Tensors (Convert to i64)
        let input_ids_i64: Vec<i64> = input_ids.iter().map(|&x| x as i64).collect();
        let attention_mask_i64: Vec<i64> = attention_mask.iter().map(|&x| x as i64).collect();
        let token_type_ids_i64: Vec<i64> = token_type_ids.iter().map(|&x| x as i64).collect();

        let input_ids_array = Array2::from_shape_vec((batch_size, seq_len), input_ids_i64)
            .map_err(|e| Error::System(format!("Shape error: {}", e)))?;
        let attention_mask_array = Array2::from_shape_vec((batch_size, seq_len), attention_mask_i64)
            .map_err(|e| Error::System(format!("Shape error: {}", e)))?;
        let token_type_ids_array = Array2::from_shape_vec((batch_size, seq_len), token_type_ids_i64)
            .map_err(|e| Error::System(format!("Shape error: {}", e)))?;

        // 3. Run Inference
        let input_ids_val = ort::value::Value::from_array(input_ids_array)
             .map_err(|e| Error::System(format!("ORT value error: {}", e)))?;
        let attention_mask_val = ort::value::Value::from_array(attention_mask_array)
             .map_err(|e| Error::System(format!("ORT value error: {}", e)))?;
        let token_type_ids_val = ort::value::Value::from_array(token_type_ids_array)
             .map_err(|e| Error::System(format!("ORT value error: {}", e)))?;

        let mut session = self.session.lock().await;
        let outputs = session.run(ort::inputs![
            "input_ids" => input_ids_val,
            "attention_mask" => attention_mask_val,
            "token_type_ids" => token_type_ids_val,
        ])
        .map_err(|e| Error::System(format!("ORT inference failed: {}", e)))?;



        // 4. Extract Embeddings (Mean Pooling)
        // For MiniLM, output[0] is 'last_hidden_state'
        let (shape, data) = outputs["last_hidden_state"].try_extract_tensor::<f32>()
            .map_err(|e| Error::System(format!("Failed to extract tensor: {}", e)))?;

        // shape is [1, seq_len, 384]
        let dim = shape[2] as usize;
        let seq_len = shape[1] as usize;

        // Perform Mean Pooling manually (simplified)
        // Sum vectors where attention_mask is 1, then divide by count
        let mut sum_vec = vec![0.0; dim];
        let mut count = 0.0;

        for i in 0..seq_len {
            if attention_mask[i] == 1 {
                count += 1.0;
                for j in 0..dim {
                    // data is [batch, seq, dim], flattened
                    // index = i * dim + j (since batch=1)
                    let idx = i * dim + j;
                    if idx < data.len() {
                         sum_vec[j] += data[idx];
                    }
                }
            }
        }

        // Normalize
        for j in 0..dim {
            sum_vec[j] /= count;
        }

        // L2 Normalization (optional but recommended for cosine similarity)
        let norm: f32 = sum_vec.iter().map(|x| x * x).sum::<f32>().sqrt();
        if norm > 0.0 {
            for j in 0..dim {
                sum_vec[j] /= norm;
            }
        }

        Ok(sum_vec)
    }

    fn dimension(&self) -> usize {
        self.dimension
    }

    fn provider_name(&self) -> &str {
        "ort-minilm-l6-v2"
    }
}
