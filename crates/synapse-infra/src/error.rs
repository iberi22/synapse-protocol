//! Infrastructure-specific errors.

use thiserror::Error;

/// Infrastructure errors.
#[derive(Error, Debug)]
pub enum InfraError {
    /// LanceDB error
    #[error("LanceDB error: {0}")]
    LanceDb(String),
    
    /// Sled error
    #[error("Sled error: {0}")]
    Sled(String),
    
    /// ORT (ONNX Runtime) error
    #[error("ORT error: {0}")]
    Ort(String),
    
    /// IO error
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
}
