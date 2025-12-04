//! BufferPort - Trait for short-term memory buffer.

use async_trait::async_trait;
use crate::Interaction;
use crate::error::Result;


/// Port for short-term memory buffer (FIFO queue).
///
/// Implementations:
/// - `SledAdapter` (default)
#[async_trait]
pub trait BufferPort: Send + Sync {
    /// Push an interaction to the buffer.
    async fn push(&self, interaction: Interaction) -> Result<()>;

    /// Pop a batch of interactions from the buffer (FIFO).
    async fn pop_batch(&self, size: usize) -> Result<Vec<Interaction>>;

    /// Peek at the next N interactions without removing them.
    async fn peek(&self, size: usize) -> Result<Vec<Interaction>>;

    /// Get the current buffer length.
    async fn len(&self) -> Result<usize>;

    /// Check if buffer is empty.
    async fn is_empty(&self) -> Result<bool> {
        Ok(self.len().await? == 0)
    }

    /// Clear all interactions from the buffer.
    async fn clear(&self) -> Result<()>;

}
