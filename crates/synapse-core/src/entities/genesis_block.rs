//! GenesisBlock - Immutable ethical vector filter.
//!
//! The GenesisBlock is the ethical foundation of Synapse Protocol.
//! It contains an immutable embedding vector representing "Do no harm"
//! and filters all AI actions against this ethical baseline.

use serde::{Deserialize, Serialize};
use chrono::Utc;

use crate::error::CoreError;

/// The GenesisBlock is an immutable ethical filter.
///
/// All AI actions are compared against the `ethical_vector` using cosine
/// similarity. Actions with similarity below `threshold` are blocked.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GenesisBlock {
    /// Immutable embedding of "Do no harm" ethical baseline
    pub ethical_vector: Vec<f32>,
    
    /// Cosine similarity threshold (default: 0.95)
    pub threshold: f32,
    
    /// Unix timestamp of creation
    pub created_at: i64,
    
    /// Version of the ethical model
    pub version: String,
}

impl GenesisBlock {
    /// Create a new GenesisBlock with the given ethical vector.
    pub fn new(ethical_vector: Vec<f32>) -> Self {
        Self {
            ethical_vector,
            threshold: 0.95,
            created_at: Utc::now().timestamp(),
            version: "1.0.0".to_string(),
        }
    }
    
    /// Create a GenesisBlock with a custom threshold.
    pub fn with_threshold(mut self, threshold: f32) -> Self {
        self.threshold = threshold;
        self
    }
    
    /// Evaluate if an action is ethical based on cosine similarity.
    ///
    /// Returns `Ok(true)` if the action passes the ethical check,
    /// `Err(CoreError::EthicsViolation)` if it fails.
    pub fn evaluate_intention(&self, action_vector: &[f32]) -> Result<bool, CoreError> {
        if action_vector.len() != self.ethical_vector.len() {
            return Err(CoreError::DimensionMismatch {
                expected: self.ethical_vector.len(),
                got: action_vector.len(),
            });
        }
        
        let similarity = cosine_similarity(&self.ethical_vector, action_vector);
        
        if similarity >= self.threshold {
            Ok(true)
        } else {
            Err(CoreError::EthicsViolation {
                similarity,
                threshold: self.threshold,
            })
        }
    }
}

/// Compute cosine similarity between two vectors.
fn cosine_similarity(a: &[f32], b: &[f32]) -> f32 {
    let dot_product: f32 = a.iter().zip(b.iter()).map(|(x, y)| x * y).sum();
    let norm_a: f32 = a.iter().map(|x| x * x).sum::<f32>().sqrt();
    let norm_b: f32 = b.iter().map(|x| x * x).sum::<f32>().sqrt();
    
    if norm_a == 0.0 || norm_b == 0.0 {
        return 0.0;
    }
    
    dot_product / (norm_a * norm_b)
}

impl Default for GenesisBlock {
    fn default() -> Self {
        // Default 384-dim zero vector (should be replaced with actual ethical embedding)
        Self::new(vec![0.0; 384])
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_cosine_similarity_identical() {
        let a = vec![1.0, 0.0, 0.0];
        let b = vec![1.0, 0.0, 0.0];
        assert!((cosine_similarity(&a, &b) - 1.0).abs() < 0.001);
    }
    
    #[test]
    fn test_cosine_similarity_orthogonal() {
        let a = vec![1.0, 0.0, 0.0];
        let b = vec![0.0, 1.0, 0.0];
        assert!((cosine_similarity(&a, &b)).abs() < 0.001);
    }
    
    #[test]
    fn test_evaluate_intention_pass() {
        let genesis = GenesisBlock::new(vec![1.0, 0.0, 0.0]).with_threshold(0.9);
        let action = vec![0.95, 0.05, 0.05];
        assert!(genesis.evaluate_intention(&action).is_ok());
    }
    
    #[test]
    fn test_evaluate_intention_fail() {
        let genesis = GenesisBlock::new(vec![1.0, 0.0, 0.0]).with_threshold(0.95);
        let action = vec![0.0, 1.0, 0.0]; // Orthogonal
        assert!(genesis.evaluate_intention(&action).is_err());
    }
}
