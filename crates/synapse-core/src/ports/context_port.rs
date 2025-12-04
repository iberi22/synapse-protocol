use async_trait::async_trait;
use crate::error::Result;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WindowInfo {
    pub title: String,
    pub process_name: String,
    pub is_visible: bool,
    pub bounds: (i32, i32, u32, u32),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum InputEvent {
    KeyPress(String),
    MouseClick(i32, i32),
    Scroll(i32, i32),
}

/// Deep Context Port (System Access)
/// Allows the system to "see" and "hear" the OS environment.
#[async_trait]
pub trait ContextPort: Send + Sync {
    /// Captures a screenshot of the current screen or active window
    /// Returns raw bytes (png/jpeg)
    async fn capture_screen(&self) -> Result<Vec<u8>>;

    /// Gets information about the currently active window
    async fn get_active_window(&self) -> Result<WindowInfo>;

    /// Gets a list of all running processes (for anomaly detection)
    async fn get_running_processes(&self) -> Result<Vec<String>>;

    /// Analyzes input patterns to detect "Fake Humans" (bots).
    /// Returns a confidence score (0.0 - 1.0) where 1.0 is definitely human.
    async fn analyze_input_pattern(&self, duration_ms: u64) -> Result<f32>;
}

