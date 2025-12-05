//! MemoryPort - Trait for long-term semantic memory storage.

use async_trait::async_trait;
use crate::MemoryNode;

use crate::error::Result;


/// Search result from memory query.
#[derive(Debug, Clone)]
pub struct SearchResult {
    /// The matching node
    pub node: MemoryNode,
    /// Distance/similarity score (lower = more similar for L2)
    pub distance: f32,
}

/// Port for long-term semantic memory storage.
///
/// Implementations:
/// - `LanceDbAdapter` (default)
#[async_trait]
pub trait MemoryPort: Send + Sync {
    /// Store a memory node and return its ID.
    async fn store(&self, node: MemoryNode) -> Result<String>;

    /// Search by embedding similarity.
    ///
    /// Returns nodes sorted by similarity (closest first).
    async fn search(&self, embedding: &[f32], top_k: usize) -> Result<Vec<SearchResult>>;

    /// Search within a specific HiRAG layer.
    async fn search_layer(
        &self,
        embedding: &[f32],
        layer: u8,
        top_k: usize,
    ) -> Result<Vec<SearchResult>>;

    /// Search within a specific namespace (multi-tenant).
    async fn search_namespace(
        &self,
        embedding: &[f32],
        namespace: &str,
        top_k: usize,
    ) -> Result<Vec<SearchResult>>;

    /// Get a node by ID.
    async fn get_by_id(&self, id: &str) -> Result<Option<MemoryNode>>;

    /// Get all nodes in a specific layer.
    async fn get_by_layer(&self, layer: u8) -> Result<Vec<MemoryNode>>;

    /// Update an existing node.
    async fn update(&self, node: MemoryNode) -> Result<()>;

    /// Delete a node by ID.
    async fn delete(&self, id: &str) -> Result<()>;

    /// Count total nodes.
    async fn count(&self) -> Result<usize>;

    /// Add a relationship between two nodes (HiRAG graph edge).
    ///
    /// e.g. `add_relationship("summary_id", "summarizes", "fact_id")`
    async fn add_relationship(&self, from_id: &str, relation: &str, to_id: &str) -> Result<()>;

    /// Count nodes at a specific layer (for consolidation thresholds).
    async fn count_by_layer(&self, layer: u8) -> Result<usize>;
}
