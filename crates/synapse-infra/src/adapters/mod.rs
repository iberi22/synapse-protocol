//! Infrastructure adapters.

pub mod surrealdb_adapter;
pub mod sled_adapter;
pub mod ort_adapter;
pub mod context_adapter;
pub mod immune_adapter;
pub mod mock_llm_adapter;
pub mod mock_embedding_adapter;
pub mod candle_adapter;
pub mod vision_adapter;
pub mod audio_adapter;

pub use surrealdb_adapter::*;
pub use sled_adapter::*;
pub use ort_adapter::*;
pub use mock_llm_adapter::*;
pub use mock_embedding_adapter::*;
