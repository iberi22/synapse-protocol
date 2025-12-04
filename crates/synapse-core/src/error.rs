//! Error types for synapse-core.

use thiserror::Error;

/// Core domain errors.
#[derive(Error, Debug)]
pub enum Error {
    /// Ethics violation - action blocked by GenesisBlock
    #[error("Ethics violation: similarity {similarity:.3} below threshold {threshold:.3}")]
    EthicsViolation {
        similarity: f32,
        threshold: f32,
    },

    /// Vector dimension mismatch
    #[error("Dimension mismatch: expected {expected}, got {got}")]
    DimensionMismatch {
        expected: usize,
        got: usize,
    },

    /// Entity not found
    #[error("Entity not found: {id}")]
    NotFound {
        id: String,
    },

    /// Serialization error
    #[error("Serialization error: {0}")]
    Serialization(#[from] serde_json::Error),

    /// Validation error
    #[error("Validation error: {message}")]
    Validation {
        message: String,
    },

    /// System/OS error (Context, IO, etc.)
    #[error("System error: {0}")]
    System(String),

    /// Internal error
    #[error("Internal error: {message}")]
    Internal {
        message: String,
    },

    /// Commerce/Wallet error
    #[error("Commerce error: {0}")]
    Commerce(String),
}

/// Result type alias
pub type Result<T> = std::result::Result<T, Error>;
