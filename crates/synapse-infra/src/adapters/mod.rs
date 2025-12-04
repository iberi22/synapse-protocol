//! Infrastructure adapters.

pub mod lancedb_adapter;
pub mod sled_adapter;
pub mod ort_adapter;
pub mod context_adapter;
pub mod immune_adapter;
pub mod mock_llm_adapter;
pub mod candle_adapter;
pub mod vision_adapter;
pub mod audio_adapter;







pub use lancedb_adapter::*;
pub use sled_adapter::*;
pub use ort_adapter::*;
