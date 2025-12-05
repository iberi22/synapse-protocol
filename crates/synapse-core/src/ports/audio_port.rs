//! AudioPort - Trait for auditory sensory input/output.

use async_trait::async_trait;
use crate::error::Result;

/// Port for auditory I/O (Mic/Speakers).
/// Allows the system to "hear" and "speak" to its human partner.
#[async_trait]
pub trait AudioPort: Send + Sync {
    /// Listen for audio input for a specified duration.
    /// Returns raw audio bytes (PCM).
    async fn listen(&self, duration_ms: u64) -> Result<Vec<u8>>;

    /// Speak text using TTS or play audio bytes.
    async fn speak(&self, text: &str) -> Result<()>;

    /// Play raw audio bytes.
    async fn play_audio(&self, audio: &[u8]) -> Result<()>;
}
