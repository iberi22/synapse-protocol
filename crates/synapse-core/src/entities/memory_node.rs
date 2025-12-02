//! MemoryNode - A node in the memory graph representing a piece of knowledge.

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use uuid::Uuid;
use chrono::Utc;

use crate::NodeType;

/// A node in the memory graph representing a piece of knowledge.
///
/// MemoryNodes form the foundation of the HiRAG (Hierarchical RAG) system.
/// Layer 0 contains base facts, while higher layers contain summaries.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MemoryNode {
    /// Unique identifier (UUID v4)
    pub id: String,
    
    /// The actual content/fact stored
    pub content: String,
    
    /// HiRAG layer: 0 = base fact, 1+ = summary level
    pub layer: u8,
    
    /// Type of node (Fact, Summary, Thought, etc.)
    pub node_type: NodeType,
    
    /// Unix timestamp of creation
    pub created_at: i64,
    
    /// Unix timestamp of last update
    pub updated_at: i64,
    
    /// Embedding vector (384-dim for MiniLM, 768-dim for others)
    pub embedding: Vec<f32>,
    
    /// Additional metadata as JSON
    pub metadata: HashMap<String, serde_json::Value>,
    
    /// Namespace for multi-tenant support
    pub namespace: String,
    
    /// Source of the memory (user, system, harvested, etc.)
    pub source: String,
}

impl MemoryNode {
    /// Create a new MemoryNode with default values
    pub fn new(content: String) -> Self {
        let now = Utc::now().timestamp();
        Self {
            id: Uuid::new_v4().to_string(),
            content,
            layer: 0,
            node_type: NodeType::Fact,
            created_at: now,
            updated_at: now,
            embedding: Vec::new(),
            metadata: HashMap::new(),
            namespace: "default".to_string(),
            source: "user".to_string(),
        }
    }
    
    /// Create a new MemoryNode with a specific layer (for HiRAG)
    pub fn with_layer(content: String, layer: u8) -> Self {
        let mut node = Self::new(content);
        node.layer = layer;
        if layer > 0 {
            node.node_type = NodeType::Summary;
        }
        node
    }
    
    /// Set the embedding vector
    pub fn with_embedding(mut self, embedding: Vec<f32>) -> Self {
        self.embedding = embedding;
        self
    }
    
    /// Set the namespace for multi-tenant support
    pub fn with_namespace(mut self, namespace: String) -> Self {
        self.namespace = namespace;
        self
    }
    
    /// Set metadata key-value pair
    pub fn with_metadata(mut self, key: &str, value: serde_json::Value) -> Self {
        self.metadata.insert(key.to_string(), value);
        self
    }
}

impl Default for MemoryNode {
    fn default() -> Self {
        Self::new(String::new())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_new_memory_node() {
        let node = MemoryNode::new("Test content".to_string());
        assert!(!node.id.is_empty());
        assert_eq!(node.content, "Test content");
        assert_eq!(node.layer, 0);
        assert_eq!(node.namespace, "default");
    }
    
    #[test]
    fn test_with_layer() {
        let node = MemoryNode::with_layer("Summary".to_string(), 1);
        assert_eq!(node.layer, 1);
        assert!(matches!(node.node_type, NodeType::Summary));
    }
    
    #[test]
    fn test_with_embedding() {
        let embedding = vec![0.1, 0.2, 0.3];
        let node = MemoryNode::new("Test".to_string())
            .with_embedding(embedding.clone());
        assert_eq!(node.embedding, embedding);
    }
}
