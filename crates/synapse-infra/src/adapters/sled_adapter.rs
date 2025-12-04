//! Sled adapter for short-term buffer storage.
//!
//! Implements a FIFO queue using Sled embedded database.
//! Keys are monotonically increasing u64 values stored as big-endian bytes
//! to ensure correct lexicographic ordering.

use async_trait::async_trait;
use std::sync::atomic::{AtomicU64, Ordering};
use synapse_core::{BufferPort, error::Error, Interaction};


use crate::error::InfraError;

/// Sled adapter for FIFO buffer storage.
pub struct SledAdapter {
    /// Sled database instance
    db: sled::Db,
    /// Monotonically increasing counter for FIFO ordering
    write_counter: AtomicU64,
    /// Counter for tracking read position (unused but kept for potential optimization)
    #[allow(dead_code)]
    read_counter: AtomicU64,
}

impl SledAdapter {
    /// Create a new Sled adapter.
    ///
    /// # Arguments
    /// * `path` - Path to the Sled database directory
    ///
    /// # Returns
    /// A new SledAdapter or an error if the database cannot be opened
    pub fn new(path: &str) -> Result<Self, InfraError> {
        let db = sled::open(path).map_err(|e| InfraError::Sled(format!("Failed to open: {}", e)))?;

        // Recover counters from existing data
        let (write_counter, read_counter) = Self::recover_counters(&db)?;

        Ok(Self {
            db,
            write_counter: AtomicU64::new(write_counter),
            read_counter: AtomicU64::new(read_counter),
        })
    }

    /// Recover counters from existing database state.
    fn recover_counters(db: &sled::Db) -> Result<(u64, u64), InfraError> {
        // Get the last key to determine write counter
        let write_counter = match db.last() {
            Ok(Some((key, _))) => {
                let mut bytes = [0u8; 8];
                bytes.copy_from_slice(&key);
                u64::from_be_bytes(bytes) + 1
            }
            Ok(None) => 0,
            Err(e) => return Err(InfraError::Sled(format!("Failed to get last key: {}", e))),
        };

        // Get the first key to determine read counter
        let read_counter = match db.first() {
            Ok(Some((key, _))) => {
                let mut bytes = [0u8; 8];
                bytes.copy_from_slice(&key);
                u64::from_be_bytes(bytes)
            }
            Ok(None) => 0,
            Err(e) => return Err(InfraError::Sled(format!("Failed to get first key: {}", e))),
        };

        Ok((write_counter, read_counter))
    }

    /// Generate a key from a counter value.
    fn key_from_counter(counter: u64) -> [u8; 8] {
        counter.to_be_bytes()
    }
}

#[async_trait]
impl BufferPort for SledAdapter {
    async fn push(&self, interaction: Interaction) -> Result<(), Error> {
        let key = Self::key_from_counter(self.write_counter.fetch_add(1, Ordering::SeqCst));
        let value = serde_json::to_vec(&interaction)?;

        self.db.insert(key, value).map_err(|e| Error::Internal {
            message: format!("Failed to insert into Sled: {}", e),
        })?;

        // Flush to ensure durability
        self.db.flush_async().await.map_err(|e| Error::Internal {
            message: format!("Failed to flush Sled: {}", e),
        })?;

        Ok(())
    }

    async fn pop_batch(&self, size: usize) -> Result<Vec<Interaction>, Error> {
        let mut results = Vec::with_capacity(size);

        for item in self.db.iter().take(size) {
            let (key, value) = item.map_err(|e| Error::Internal {
                message: format!("Failed to iterate Sled: {}", e),
            })?;

            let interaction: Interaction = serde_json::from_slice(&value)?;

            results.push(interaction);

            // Remove the item
            self.db.remove(key).map_err(|e| Error::Internal {
                message: format!("Failed to remove from Sled: {}", e),
            })?;
        }

        // Flush to ensure durability
        self.db.flush_async().await.map_err(|e| Error::Internal {
            message: format!("Failed to flush Sled: {}", e),
        })?;

        Ok(results)
    }

    async fn peek(&self, size: usize) -> Result<Vec<Interaction>, Error> {
        let mut results = Vec::with_capacity(size);

        for item in self.db.iter().take(size) {
            let (_, value) = item.map_err(|e| Error::Internal {
                message: format!("Failed to iterate Sled: {}", e),
            })?;

            let interaction: Interaction = serde_json::from_slice(&value)?;

            results.push(interaction);
        }

        Ok(results)
    }

    async fn len(&self) -> Result<usize, Error> {
        Ok(self.db.len())
    }

    async fn clear(&self) -> Result<(), Error> {
        self.db.clear().map_err(|e| Error::Internal {
            message: format!("Failed to clear Sled: {}", e),
        })?;

        // Reset counters
        self.write_counter.store(0, Ordering::SeqCst);
        self.read_counter.store(0, Ordering::SeqCst);

        // Flush to ensure durability
        self.db.flush_async().await.map_err(|e| Error::Internal {
            message: format!("Failed to flush Sled: {}", e),
        })?;

        Ok(())
    }

}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;

    #[tokio::test]
    async fn test_adapter_creation() {
        let temp_dir = tempdir().unwrap();
        let adapter = SledAdapter::new(temp_dir.path().to_str().unwrap());
        assert!(adapter.is_ok());
    }

    #[tokio::test]
    async fn test_push_and_pop() {
        let temp_dir = tempdir().unwrap();
        let adapter = SledAdapter::new(temp_dir.path().to_str().unwrap()).unwrap();

        let interaction = Interaction::new("Hello".to_string(), "Hi there!".to_string());

        adapter.push(interaction.clone()).await.unwrap();

        let len = adapter.len().await.unwrap();
        assert_eq!(len, 1);

        let popped = adapter.pop_batch(1).await.unwrap();
        assert_eq!(popped.len(), 1);
        assert_eq!(popped[0].user_input, "Hello");
        assert_eq!(popped[0].ai_response, "Hi there!");

        let len_after = adapter.len().await.unwrap();
        assert_eq!(len_after, 0);
    }

    #[tokio::test]
    async fn test_fifo_order() {
        let temp_dir = tempdir().unwrap();
        let adapter = SledAdapter::new(temp_dir.path().to_str().unwrap()).unwrap();

        // Push three interactions
        for i in 0..3 {
            let interaction = Interaction::new(
                format!("Question {}", i),
                format!("Answer {}", i),
            );
            adapter.push(interaction).await.unwrap();
        }

        // Pop and verify FIFO order
        let popped = adapter.pop_batch(3).await.unwrap();
        assert_eq!(popped.len(), 3);
        assert_eq!(popped[0].user_input, "Question 0");
        assert_eq!(popped[1].user_input, "Question 1");
        assert_eq!(popped[2].user_input, "Question 2");
    }

    #[tokio::test]
    async fn test_peek() {
        let temp_dir = tempdir().unwrap();
        let adapter = SledAdapter::new(temp_dir.path().to_str().unwrap()).unwrap();

        let interaction = Interaction::new("Test".to_string(), "Response".to_string());
        adapter.push(interaction).await.unwrap();

        // Peek should not remove
        let peeked = adapter.peek(1).await.unwrap();
        assert_eq!(peeked.len(), 1);
        assert_eq!(peeked[0].user_input, "Test");

        // Should still be there
        let len = adapter.len().await.unwrap();
        assert_eq!(len, 1);
    }

    #[tokio::test]
    async fn test_clear() {
        let temp_dir = tempdir().unwrap();
        let adapter = SledAdapter::new(temp_dir.path().to_str().unwrap()).unwrap();

        for i in 0..5 {
            let interaction = Interaction::new(format!("Q{}", i), format!("A{}", i));
            adapter.push(interaction).await.unwrap();
        }

        assert_eq!(adapter.len().await.unwrap(), 5);

        adapter.clear().await.unwrap();

        assert_eq!(adapter.len().await.unwrap(), 0);
    }

    #[tokio::test]
    async fn test_persistence() {
        let temp_dir = tempdir().unwrap();
        let path = temp_dir.path().to_str().unwrap();

        // Create adapter and add data
        {
            let adapter = SledAdapter::new(path).unwrap();
            let interaction = Interaction::new("Persist".to_string(), "Test".to_string());
            adapter.push(interaction).await.unwrap();
        }

        // Reopen and verify data persists
        {
            let adapter = SledAdapter::new(path).unwrap();
            let len = adapter.len().await.unwrap();
            assert_eq!(len, 1);

            let peeked = adapter.peek(1).await.unwrap();
            assert_eq!(peeked[0].user_input, "Persist");
        }
    }

    #[tokio::test]
    async fn test_is_empty() {
        let temp_dir = tempdir().unwrap();
        let adapter = SledAdapter::new(temp_dir.path().to_str().unwrap()).unwrap();

        assert!(adapter.is_empty().await.unwrap());

        let interaction = Interaction::new("Q".to_string(), "A".to_string());
        adapter.push(interaction).await.unwrap();

        assert!(!adapter.is_empty().await.unwrap());
    }

    #[tokio::test]
    async fn test_pop_partial_batch() {
        let temp_dir = tempdir().unwrap();
        let adapter = SledAdapter::new(temp_dir.path().to_str().unwrap()).unwrap();

        // Push only 2 items
        for i in 0..2 {
            let interaction = Interaction::new(format!("Q{}", i), format!("A{}", i));
            adapter.push(interaction).await.unwrap();
        }

        // Request 5 but only 2 should be returned
        let popped = adapter.pop_batch(5).await.unwrap();
        assert_eq!(popped.len(), 2);
    }
}
