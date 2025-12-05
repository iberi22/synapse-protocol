//! Layer Consolidation - HiRAG layer summarization.
//!
//! This module implements the consolidation of Layer N nodes into Layer N+1 summary nodes.
//! It's part of the HiRAG (Hierarchical RAG) system for creating hierarchical memory structures.

use crate::error::Result;
use crate::ports::{EmbeddingPort, LlmPort, MemoryPort};
use crate::{MemoryNode, NodeType};
use chrono::Utc;
use std::sync::Arc;
use uuid::Uuid;

/// Layer Consolidator: Summarizes nodes from one layer into higher-level summaries.
pub struct LayerConsolidator {
    memory: Arc<dyn MemoryPort>,
    llm: Arc<dyn LlmPort>,
    embedder: Arc<dyn EmbeddingPort>,
    threshold: usize,
}

impl LayerConsolidator {
    /// Create a new LayerConsolidator.
    ///
    /// # Arguments
    /// * `memory` - Memory port for storing/retrieving nodes
    /// * `llm` - LLM port for summarization
    /// * `embedder` - Embedding port for vector generation
    pub fn new(
        memory: Arc<dyn MemoryPort>,
        llm: Arc<dyn LlmPort>,
        embedder: Arc<dyn EmbeddingPort>,
    ) -> Self {
        Self {
            memory,
            llm,
            embedder,
            threshold: 5, // Default: consolidate when 5+ nodes exist at a layer
        }
    }

    /// Set custom threshold for testing or configuration.
    pub fn with_threshold(mut self, threshold: usize) -> Self {
        self.threshold = threshold;
        self
    }

    /// Consolidate nodes from a specific layer into a higher-layer summary.
    ///
    /// Returns the ID of the created summary node, or None if threshold not met.
    pub async fn consolidate_layer(&self, layer: u8) -> Result<Option<String>> {
        // 1. Check if layer has enough nodes
        let count = self.memory.count_by_layer(layer).await?;
        if count < self.threshold {
            return Ok(None);
        }

        // 2. Get all nodes at this layer
        let nodes = self.memory.get_by_layer(layer).await?;
        if nodes.is_empty() {
            return Ok(None);
        }

        // 3. Combine content for summarization
        let combined_content: String = nodes
            .iter()
            .enumerate()
            .map(|(i, n)| format!("{}. {}", i + 1, n.content))
            .collect::<Vec<_>>()
            .join("\n");

        // 4. Generate summary via LLM
        let prompt = format!(
            "Summarize the following {} items into a concise overview:\n\n{}",
            nodes.len(),
            combined_content
        );
        let summary = self.llm.generate(&prompt, 500).await?;

        // 5. Generate embedding for the summary
        let embedding = self.embedder.embed(&summary).await?;

        // 6. Create Layer N+1 summary node
        let summary_node = MemoryNode {
            id: Uuid::new_v4().to_string(),
            content: summary,
            layer: layer + 1,
            node_type: NodeType::Summary,
            created_at: Utc::now().timestamp(),
            updated_at: Utc::now().timestamp(),
            embedding,
            metadata: std::collections::HashMap::new(),
            namespace: "default".to_string(),
            source: "consolidation".to_string(),
        };

        let summary_id = summary_node.id.clone();
        self.memory.store(summary_node).await?;

        // 7. Create relationships: summary -> summarizes -> each source node
        for node in &nodes {
            self.memory
                .add_relationship(&summary_id, "summarizes", &node.id)
                .await?;
        }

        Ok(Some(summary_id))
    }

    /// Consolidate all layers that meet the threshold.
    ///
    /// Returns the count of new summary nodes created.
    pub async fn consolidate_all(&self) -> Result<usize> {
        let mut created = 0;
        let mut current_layer: u8 = 0;

        loop {
            match self.consolidate_layer(current_layer).await? {
                Some(_) => {
                    created += 1;
                    // Check the next layer as well
                    current_layer += 1;
                }
                None => {
                    // No more consolidation possible at this layer
                    if current_layer == 0 {
                        break;
                    }
                    // Try next layer (up to a reasonable limit)
                    if current_layer < 10 {
                        current_layer += 1;
                    } else {
                        break;
                    }
                }
            }
        }

        Ok(created)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use async_trait::async_trait;
    use crate::ports::SearchResult;
    use tokio::sync::Mutex;

    // === Mock Memory for Testing ===
    struct MockMemory {
        nodes: Mutex<Vec<MemoryNode>>,
        relationships: Mutex<Vec<(String, String, String)>>,
    }

    impl MockMemory {
        fn new() -> Self {
            Self {
                nodes: Mutex::new(Vec::new()),
                relationships: Mutex::new(Vec::new()),
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

        async fn add_relationship(&self, from_id: &str, relation: &str, to_id: &str) -> Result<()> {
            self.relationships.lock().await.push((from_id.to_string(), relation.to_string(), to_id.to_string()));
            Ok(())
        }

        async fn count_by_layer(&self, layer: u8) -> Result<usize> {
            Ok(self.nodes.lock().await.iter().filter(|n| n.layer == layer).count())
        }
    }

    // === Mock LLM ===
    struct MockLlm;

    #[async_trait]
    impl crate::ports::LlmPort for MockLlm {
        async fn generate(&self, _prompt: &str, _max_tokens: usize) -> Result<String> {
            Ok("Mock consolidated summary of multiple items".to_string())
        }

        async fn generate_with_params(&self, _prompt: &str, _max_tokens: usize, _temp: f32, _top_p: f32) -> Result<String> {
            Ok("Mock summary".to_string())
        }
    }

    // === Mock Embedder ===
    struct MockEmbedder;

    #[async_trait]
    impl crate::ports::EmbeddingPort for MockEmbedder {
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
    async fn test_consolidate_below_threshold() {
        let memory = Arc::new(MockMemory::new());
        let llm = Arc::new(MockLlm);
        let embedder = Arc::new(MockEmbedder);

        // Add only 2 nodes (below threshold of 5)
        for i in 0..2 {
            let node = MemoryNode::new(format!("Fact {}", i));
            memory.store(node).await.unwrap();
        }

        let consolidator = LayerConsolidator::new(memory.clone(), llm, embedder);
        let result = consolidator.consolidate_layer(0).await.unwrap();

        assert!(result.is_none(), "Should not consolidate below threshold");
    }

    #[tokio::test]
    async fn test_consolidate_creates_summary() {
        let memory = Arc::new(MockMemory::new());
        let llm = Arc::new(MockLlm);
        let embedder = Arc::new(MockEmbedder);

        // Add 5 nodes (meets threshold)
        for i in 0..5 {
            let node = MemoryNode::new(format!("Fact {}", i));
            memory.store(node).await.unwrap();
        }

        let consolidator = LayerConsolidator::new(memory.clone(), llm, embedder);
        let result = consolidator.consolidate_layer(0).await.unwrap();

        assert!(result.is_some(), "Should create summary");

        // Verify Layer 1 node was created
        let layer1_nodes = memory.get_by_layer(1).await.unwrap();
        assert_eq!(layer1_nodes.len(), 1);
        assert!(matches!(layer1_nodes[0].node_type, NodeType::Summary));
        assert_eq!(layer1_nodes[0].source, "consolidation");

        // Verify relationships were created
        let relationships = memory.relationships.lock().await;
        assert_eq!(relationships.len(), 5, "Should have 5 summarizes relationships");
    }

    #[tokio::test]
    async fn test_consolidate_with_custom_threshold() {
        let memory = Arc::new(MockMemory::new());
        let llm = Arc::new(MockLlm);
        let embedder = Arc::new(MockEmbedder);

        // Add 3 nodes
        for i in 0..3 {
            let node = MemoryNode::new(format!("Fact {}", i));
            memory.store(node).await.unwrap();
        }

        let consolidator = LayerConsolidator::new(memory.clone(), llm, embedder)
            .with_threshold(3); // Lower threshold
        let result = consolidator.consolidate_layer(0).await.unwrap();

        assert!(result.is_some(), "Should consolidate with custom threshold");
    }
}
