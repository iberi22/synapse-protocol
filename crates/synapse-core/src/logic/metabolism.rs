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

    /// Set custom threshold for testing.
    pub fn with_threshold(mut self, threshold: usize) -> Self {
        self.threshold = threshold;
        self
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::Interaction;
    use async_trait::async_trait;
    use crate::ports::SearchResult;

    // === Mock Buffer ===
    struct MockBuffer {
        items: tokio::sync::Mutex<Vec<Interaction>>,
    }

    impl MockBuffer {
        fn new() -> Self {
            Self {
                items: tokio::sync::Mutex::new(Vec::new()),
            }
        }
    }

    #[async_trait]
    impl BufferPort for MockBuffer {
        async fn push(&self, interaction: Interaction) -> Result<()> {
            self.items.lock().await.push(interaction);
            Ok(())
        }

        async fn pop_batch(&self, size: usize) -> Result<Vec<Interaction>> {
            let mut items = self.items.lock().await;
            let drain_count = size.min(items.len());
            Ok(items.drain(..drain_count).collect())
        }

        async fn peek(&self, size: usize) -> Result<Vec<Interaction>> {
            let items = self.items.lock().await;
            Ok(items.iter().take(size).cloned().collect())
        }

        async fn len(&self) -> Result<usize> {
            Ok(self.items.lock().await.len())
        }

        async fn is_empty(&self) -> Result<bool> {
            Ok(self.items.lock().await.is_empty())
        }

        async fn clear(&self) -> Result<()> {
            self.items.lock().await.clear();
            Ok(())
        }
    }

    // === Mock Memory ===
    struct MockMemory {
        nodes: tokio::sync::Mutex<Vec<MemoryNode>>,
    }

    impl MockMemory {
        fn new() -> Self {
            Self {
                nodes: tokio::sync::Mutex::new(Vec::new()),
            }
        }
    }

    #[async_trait]
    impl MemoryPort for MockMemory {
        async fn store(&self, node: MemoryNode) -> Result<String> {
            let id = node.id.clone();
            self.nodes.lock().await.push(node);
            Ok(id)
        }

        async fn search(&self, _embedding: &[f32], _top_k: usize) -> Result<Vec<SearchResult>> {
            Ok(vec![])
        }

        async fn search_layer(&self, _embedding: &[f32], _layer: u8, _top_k: usize) -> Result<Vec<SearchResult>> {
            Ok(vec![])
        }

        async fn search_namespace(&self, _embedding: &[f32], _namespace: &str, _top_k: usize) -> Result<Vec<SearchResult>> {
            Ok(vec![])
        }

        async fn get_by_id(&self, id: &str) -> Result<Option<MemoryNode>> {
            Ok(self.nodes.lock().await.iter().find(|n| n.id == id).cloned())
        }

        async fn get_by_layer(&self, layer: u8) -> Result<Vec<MemoryNode>> {
            Ok(self.nodes.lock().await.iter().filter(|n| n.layer == layer).cloned().collect())
        }

        async fn update(&self, _node: MemoryNode) -> Result<()> {
            Ok(())
        }

        async fn delete(&self, _id: &str) -> Result<()> {
            Ok(())
        }

        async fn count(&self) -> Result<usize> {
            Ok(self.nodes.lock().await.len())
        }

        async fn add_relationship(&self, _from_id: &str, _relation: &str, _to_id: &str) -> Result<()> {
            Ok(())
        }

        async fn count_by_layer(&self, layer: u8) -> Result<usize> {
            Ok(self.nodes.lock().await.iter().filter(|n| n.layer == layer).count())
        }
    }

    // === Mock LLM ===
    struct MockLlm;

    #[async_trait]
    impl LlmPort for MockLlm {
        async fn generate(&self, _prompt: &str, _max_tokens: usize) -> Result<String> {
            Ok("Mock summary of conversation".to_string())
        }

        async fn generate_with_params(&self, _prompt: &str, _max_tokens: usize, _temp: f32, _top_p: f32) -> Result<String> {
            Ok("Mock summary".to_string())
        }
    }

    // === Mock Embedder ===
    struct MockEmbedder;

    #[async_trait]
    impl EmbeddingPort for MockEmbedder {
        async fn embed(&self, _text: &str) -> Result<Vec<f32>> {
            Ok(vec![0.1, 0.2, 0.3])
        }

        fn dimension(&self) -> usize {
            3
        }

        fn provider_name(&self) -> &str {
            "mock"
        }
    }

    #[tokio::test]
    async fn test_digest_under_threshold() {
        let buffer = Arc::new(MockBuffer::new());
        let memory = Arc::new(MockMemory::new());
        let llm = Arc::new(MockLlm);
        let embedder = Arc::new(MockEmbedder);

        let metabolism = Metabolism::new(
            buffer.clone(),
            memory.clone(),
            llm,
            embedder,
        ).with_threshold(5);

        // Add only 3 interactions (below threshold of 5)
        for i in 0..3 {
            buffer.push(Interaction::new(
                format!("Question {}", i),
                format!("Answer {}", i),
            )).await.unwrap();
        }

        let digested = metabolism.digest().await.unwrap();
        assert_eq!(digested, 0, "Should not digest when below threshold");
        assert_eq!(buffer.len().await.unwrap(), 3, "Buffer should remain unchanged");
        assert_eq!(memory.count().await.unwrap(), 0, "No memory should be created");
    }

    #[tokio::test]
    async fn test_digest_creates_memory_node() {
        let buffer = Arc::new(MockBuffer::new());
        let memory = Arc::new(MockMemory::new());
        let llm = Arc::new(MockLlm);
        let embedder = Arc::new(MockEmbedder);

        let metabolism = Metabolism::new(
            buffer.clone(),
            memory.clone(),
            llm,
            embedder,
        ).with_threshold(3);

        // Add 5 interactions (exceeds threshold of 3)
        for i in 0..5 {
            buffer.push(Interaction::new(
                format!("Question {}", i),
                format!("Answer {}", i),
            )).await.unwrap();
        }

        let digested = metabolism.digest().await.unwrap();

        assert_eq!(digested, 3, "Should digest threshold amount");
        assert_eq!(buffer.len().await.unwrap(), 2, "Buffer should have remaining items");
        assert_eq!(memory.count().await.unwrap(), 1, "One memory node should be created");

        // Verify the created node
        let nodes = memory.get_by_layer(0).await.unwrap();
        assert_eq!(nodes.len(), 1);
        assert_eq!(nodes[0].node_type, NodeType::Summary);
        assert_eq!(nodes[0].source, "metabolism");
        assert!(!nodes[0].embedding.is_empty());
    }

    #[tokio::test]
    async fn test_digest_full_pipeline() {
        let buffer = Arc::new(MockBuffer::new());
        let memory = Arc::new(MockMemory::new());
        let llm = Arc::new(MockLlm);
        let embedder = Arc::new(MockEmbedder);

        let metabolism = Metabolism::new(
            buffer.clone(),
            memory.clone(),
            llm,
            embedder,
        ).with_threshold(2);

        // Fill buffer and digest multiple times
        for i in 0..6 {
            buffer.push(Interaction::new(
                format!("Q{}", i),
                format!("A{}", i),
            )).await.unwrap();
        }

        // First digest
        let d1 = metabolism.digest().await.unwrap();
        assert_eq!(d1, 2);

        // Second digest
        let d2 = metabolism.digest().await.unwrap();
        assert_eq!(d2, 2);

        // Third digest
        let d3 = metabolism.digest().await.unwrap();
        assert_eq!(d3, 2);

        // Buffer should be empty, 3 memory nodes created
        assert_eq!(buffer.len().await.unwrap(), 0);
        assert_eq!(memory.count().await.unwrap(), 3);
    }
}

