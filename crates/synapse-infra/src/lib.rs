//! # Synapse Infrastructure
//!
//! Infrastructure adapters implementing ports defined in `synapse-core`.
//!
//! ## Adapters
//!
//! - `LanceDbAdapter` - Vector storage using LanceDB
//! - `SledAdapter` - Key-value buffer using Sled
//! - `OrtAdapter` - Embeddings using ONNX Runtime

pub mod adapters;
pub mod commerce;
pub mod error;

pub use adapters::*;
pub use commerce::*;
pub use error::*;
