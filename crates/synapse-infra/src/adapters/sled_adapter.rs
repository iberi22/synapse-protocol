//! Sled adapter for short-term buffer storage.
//!
//! TODO: Implement after FEAT_sled-adapter issue is picked up.

use async_trait::async_trait;
use synapse_core::{BufferPort, CoreError, Interaction};

/// Sled adapter for FIFO buffer storage.
pub struct SledAdapter {
    // TODO: Add Sled DB instance
    _path: String,
}

impl SledAdapter {
    /// Create a new Sled adapter.
    pub fn new(path: &str) -> Self {
        Self {
            _path: path.to_string(),
        }
    }
}

#[async_trait]
impl BufferPort for SledAdapter {
    async fn push(&self, _interaction: Interaction) -> Result<(), CoreError> {
        todo!("Implement Sled push - see FEAT_sled-adapter.md")
    }
    
    async fn pop_batch(&self, _size: usize) -> Result<Vec<Interaction>, CoreError> {
        todo!("Implement Sled pop_batch")
    }
    
    async fn peek(&self, _size: usize) -> Result<Vec<Interaction>, CoreError> {
        todo!("Implement Sled peek")
    }
    
    async fn len(&self) -> Result<usize, CoreError> {
        todo!("Implement Sled len")
    }
    
    async fn clear(&self) -> Result<(), CoreError> {
        todo!("Implement Sled clear")
    }
}
