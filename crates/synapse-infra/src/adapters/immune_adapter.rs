use async_trait::async_trait;
use synapse_core::ports::{ImmunePort, ThreatLevel, ThreatReport};
use synapse_core::error::Result;

pub struct BasicImmuneAdapter;

impl BasicImmuneAdapter {
    pub fn new() -> Self {
        Self
    }
}

#[async_trait]
impl ImmunePort for BasicImmuneAdapter {
    async fn check_integrity(&self) -> Result<bool> {
        // TODO: Implement hash verification of own binary
        Ok(true)
    }

    async fn scan_process(&self, process_name: &str) -> Result<ThreatLevel> {
        if process_name.contains("malware") {
            Ok(ThreatLevel::Critical)
        } else {
            Ok(ThreatLevel::Safe)
        }
    }

    async fn report_threat(&self, report: ThreatReport) -> Result<()> {
        println!("📡 Reporting threat to network: {:?}", report);
        Ok(())
    }
}
