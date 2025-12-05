//! Configuration management for Synapse CLI.

use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};
use tokio::fs;

/// Synapse configuration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    /// Path to LanceDB database
    pub db_path: PathBuf,

    /// Path to Sled buffer
    pub buffer_path: PathBuf,

    /// Embedding dimension (default: 384 for MiniLM)
    pub embedding_dim: usize,

    /// Genesis Block ethical similarity threshold
    pub ethical_threshold: f32,

    /// Default namespace
    pub default_namespace: String,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            db_path: PathBuf::from("./synapse_data/lancedb"),
            buffer_path: PathBuf::from("./synapse_data/sled_buffer"),
            embedding_dim: 384,
            ethical_threshold: 0.95,
            default_namespace: "default".to_string(),
        }
    }
}

impl Config {
    /// Load configuration from file.
    pub async fn load(path: impl AsRef<Path>) -> Result<Self> {
        let content = fs::read_to_string(path.as_ref())
            .await
            .context("Failed to read config file")?;

        let config: Config = serde_json::from_str(&content)
            .context("Failed to parse config JSON")?;

        Ok(config)
    }

    /// Save configuration to file.
    pub async fn save(&self, path: impl AsRef<Path>) -> Result<()> {
        let json = serde_json::to_string_pretty(self)
            .context("Failed to serialize config")?;

        // Create parent directory if needed
        if let Some(parent) = path.as_ref().parent() {
            fs::create_dir_all(parent)
                .await
                .context("Failed to create config directory")?;
        }

        fs::write(path.as_ref(), json)
            .await
            .context("Failed to write config file")?;

        Ok(())
    }

    /// Get the default config path.
    pub fn default_path() -> PathBuf {
        PathBuf::from("./synapse.json")
    }
}
