//! Vision adapter using Nokhwa.

use async_trait::async_trait;
use synapse_core::{Error, VisionPort};
use nokhwa::{
    pixel_format::RgbFormat,
    utils::{CameraIndex, RequestedFormat, RequestedFormatType},
    Camera,
};

pub struct VisionAdapter;

impl VisionAdapter {
    pub fn new() -> Self {
        Self
    }
}

#[async_trait]
impl VisionPort for VisionAdapter {
    async fn capture_frame(&self) -> Result<Vec<u8>, Error> {
        // Run blocking camera op in a separate thread
        tokio::task::spawn_blocking(move || {
            let index = CameraIndex::Index(0);
            let requested = RequestedFormat::new::<RgbFormat>(RequestedFormatType::AbsoluteHighestFrameRate);

            let mut camera = Camera::new(index, requested)
                .map_err(|e| Error::System(format!("Failed to open camera: {}", e)))?;

            camera.open_stream()
                .map_err(|e| Error::System(format!("Failed to open stream: {}", e)))?;

            let frame = camera.frame()
                .map_err(|e| Error::System(format!("Failed to capture frame: {}", e)))?;

            // Convert to raw bytes (RGB)
            Ok(frame.buffer().to_vec())
        }).await.map_err(|e| Error::System(format!("Join error: {}", e)))?
    }

    async fn detect_presence(&self) -> Result<bool, Error> {
        // Simple heuristic: if we can capture a frame, assume presence (placeholder)
        // Real implementation would use face detection (e.g. via ORT/Candle)
        let _frame = self.capture_frame().await?;
        Ok(true)
    }
}
