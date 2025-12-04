//! # Synapse Core
//!
//! Domain layer for Synapse Protocol.
//! Contains entities, ports (traits), and business logic.
//!
//! **Hexagonal Architecture Rule**: This crate MUST NOT depend on
//! any infrastructure (LanceDB, Sled, ORT, etc.). Only pure Rust + serde.

pub mod entities;
pub mod error;
pub mod ports;
pub mod logic;


pub use entities::*;
pub use error::*;
pub use ports::*;
