//! Ports (Traits) for hexagonal architecture.
//!
//! These traits define the boundaries between domain and infrastructure.
//! Implementations live in `synapse-infra`.

pub mod memory_port;
pub mod buffer_port;
pub mod llm_port;
pub mod embedding_port;
pub mod context_port;
pub mod immune_port;
pub mod vision_port;
pub mod audio_port;
pub mod commerce_port;

pub use memory_port::*;
pub use buffer_port::*;
pub use llm_port::*;
pub use embedding_port::*;
pub use context_port::*;
pub use immune_port::*;
pub use vision_port::*;
pub use audio_port::*;
pub use commerce_port::*;
