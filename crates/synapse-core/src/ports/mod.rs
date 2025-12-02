//! Ports (Traits) for hexagonal architecture.
//!
//! These traits define the boundaries between domain and infrastructure.
//! Implementations live in `synapse-infra`.

mod memory_port;
mod buffer_port;
mod llm_port;
mod embedding_port;

pub use memory_port::*;
pub use buffer_port::*;
pub use llm_port::*;
pub use embedding_port::*;
