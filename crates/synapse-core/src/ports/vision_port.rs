//! VisionPort - Trait for visual sensory input.

use async_trait::async_trait;
use crate::error::Result;

/// Port for visual input (Camera).
/// Allows the system to "see" its human partner.
#[async_trait]
pub trait VisionPort: Send + Sync {
    /// Capture a single frame from the default camera.
    /// Returns raw bytes (e.g., JPEG/PNG).
    async fn capture_frame(&self) -> Result<Vec<u8>>;

    /// Detect if a human face is present in the camera feed.
    /// Returns true if a face is detected.
    async fn detect_presence(&self) -> Result<bool>;
}
