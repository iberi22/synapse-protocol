//! Infrastructure adapters.

mod lancedb_adapter;
mod sled_adapter;
mod ort_adapter;

pub use lancedb_adapter::*;
pub use sled_adapter::*;
pub use ort_adapter::*;
