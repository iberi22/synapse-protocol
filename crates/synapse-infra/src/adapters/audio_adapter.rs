//! Audio adapter using CPAL (Input) and Rodio (Output).

use async_trait::async_trait;
use synapse_core::{Error, AudioPort};


pub struct AudioAdapter;

impl AudioAdapter {
    pub fn new() -> Self {
        Self
    }
}

#[async_trait]
impl AudioPort for AudioAdapter {
    async fn listen(&self, duration_ms: u64) -> Result<Vec<u8>, Error> {
        // TODO: Implement actual recording with CPAL
        // This is complex because CPAL is callback-based and we need to bridge to async.
        // For MVP, we return a mock buffer.

        // Simulating listening delay
        tokio::time::sleep(tokio::time::Duration::from_millis(duration_ms)).await;

        Ok(vec![0; 1024]) // Mock silence
    }

    async fn speak(&self, text: &str) -> Result<(), Error> {
        // TODO: Integrate TTS (e.g., mimic-rs or system TTS)
        println!("🗣️ Synapse says: {}", text);
        Ok(())
    }

    async fn play_audio(&self, _audio: &[u8]) -> Result<(), Error> {
        // TODO: Implement playback with Rodio
        Ok(())
    }
}
