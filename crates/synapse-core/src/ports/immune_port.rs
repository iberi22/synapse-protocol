use async_trait::async_trait;
use crate::error::Result;

#[derive(Debug, Clone, PartialEq)]
pub enum ThreatLevel {
    Safe,
    Suspicious,
    Malicious,
    Critical,
}

#[derive(Debug, Clone)]
pub struct ThreatReport {
    pub source_id: String,
    pub threat_type: String,
    pub level: ThreatLevel,
    pub description: String,
    pub timestamp: i64,
}

/// Digital Immune System Port
/// Defines how the system protects itself and the host.
#[async_trait]
pub trait ImmunePort: Send + Sync {
    /// Checks the integrity of the Synapse process (anti-tamper)
    async fn check_integrity(&self) -> Result<bool>;

    /// Analyzes a process or file for malicious patterns
    async fn scan_process(&self, process_name: &str) -> Result<ThreatLevel>;

    /// Reports a threat to the collective network
    async fn report_threat(&self, report: ThreatReport) -> Result<()>;
}
