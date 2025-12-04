use crate::ports::{BufferPort, MemoryPort, LlmPort, EmbeddingPort};
use crate::error::Result;
use crate::{MemoryNode, NodeType};
use std::sync::Arc;
use chrono::Utc;
use uuid::Uuid;

/// Metabolism: The process of digesting short-term buffer into long-term memory.
pub struct Metabolism {
    buffer: Arc<dyn BufferPort>,
    memory: Arc<dyn MemoryPort>,
    llm: Arc<dyn LlmPort>,
    embedder: Arc<dyn EmbeddingPort>,
    threshold: usize,
}

impl Metabolism {
    pub fn new(
        buffer: Arc<dyn BufferPort>,
        memory: Arc<dyn MemoryPort>,
        llm: Arc<dyn LlmPort>,
        embedder: Arc<dyn EmbeddingPort>,
    ) -> Self {
        Self {
            buffer,
            memory,
            llm,
            embedder,
            threshold: 10, // Default threshold
        }
    }

    /// Digest the buffer if it exceeds the threshold.
    pub async fn digest(&self) -> Result<usize> {
        let count = self.buffer.len().await?;
        if count < self.threshold {
            return Ok(0);
        }

        // 1. Pop batch from buffer
        let interactions = self.buffer.pop_batch(self.threshold).await?;
        if interactions.is_empty() {
            return Ok(0);
        }

        // 2. Combine content
        let mut combined_text = String::new();
        for interaction in &interactions {
            combined_text.push_str(&format!("User: {}\nAI: {}\n", interaction.user_input, interaction.ai_response));
        }


        // 3. Summarize via LLM
        let summary = self.llm.summarize(&combined_text).await?;

        // 4. Generate embedding
        let embedding = self.embedder.embed(&summary).await?;

        // 5. Create MemoryNode (Layer 0)
        let node = MemoryNode {
            id: Uuid::new_v4().to_string(),
            content: summary,
            layer: 0,
            node_type: NodeType::Summary,
            created_at: Utc::now().timestamp(),
            updated_at: Utc::now().timestamp(),
            embedding,
            metadata: std::collections::HashMap::new(),
            namespace: "default".to_string(),
            source: "metabolism".to_string(),
        };


        // 6. Store in long-term memory
        self.memory.store(node).await?;

        Ok(interactions.len())
    }
}
