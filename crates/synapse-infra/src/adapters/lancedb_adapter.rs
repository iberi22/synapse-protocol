//! LanceDB adapter for long-term memory storage.
//!
//! TODO: Implement after FEAT_lancedb-adapter issue is picked up.

use async_trait::async_trait;
use synapse_core::{error::Error, MemoryNode, MemoryPort, SearchResult};


/// LanceDB adapter for vector storage.
pub struct LanceDbAdapter {
    // TODO: Add LanceDB connection
    _path: String,
}

impl LanceDbAdapter {
    /// Create a new LanceDB adapter.
    pub fn new(path: &str) -> Self {
        Self {
            _path: path.to_string(),
        }
    }
}

#[async_trait]
impl MemoryPort for LanceDbAdapter {
    async fn store(&self, _node: MemoryNode) -> Result<String, Error> {
        todo!("Implement LanceDB store - see FEAT_lancedb-adapter.md")
    }

    async fn search(&self, _embedding: &[f32], _top_k: usize) -> Result<Vec<SearchResult>, Error> {
        todo!("Implement LanceDB search")
    }

    async fn search_layer(
        &self,
        _embedding: &[f32],
        _layer: u8,
        _top_k: usize,
    ) -> Result<Vec<SearchResult>, Error> {
        todo!("Implement LanceDB search_layer")
    }

    async fn search_namespace(
        &self,
        _embedding: &[f32],
        _namespace: &str,
        _top_k: usize,
    ) -> Result<Vec<SearchResult>, Error> {
        todo!("Implement LanceDB search_namespace")
    }

    async fn get_by_id(&self, _id: &str) -> Result<Option<MemoryNode>, Error> {
        todo!("Implement LanceDB get_by_id")
    }

    async fn get_by_layer(&self, _layer: u8) -> Result<Vec<MemoryNode>, Error> {
        todo!("Implement LanceDB get_by_layer")
    }

    async fn update(&self, _node: MemoryNode) -> Result<(), Error> {
        todo!("Implement LanceDB update")
    }

    async fn delete(&self, _id: &str) -> Result<(), Error> {
        todo!("Implement LanceDB delete")
    }

    async fn count(&self) -> Result<usize, Error> {
        todo!("Implement LanceDB count")
    }

}
