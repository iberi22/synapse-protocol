use std::sync::Arc;
use synapse_core::ports::{ContextPort, ImmunePort};
use tokio::sync::Mutex;
use tracing::{info, warn, error};

pub struct ImmuneSystem {
    context: Arc<dyn ContextPort>,
    immune_infra: Arc<dyn ImmunePort>,
    is_running: Mutex<bool>,
}

impl ImmuneSystem {
    pub fn new(
        context: Arc<dyn ContextPort>,
        immune_infra: Arc<dyn ImmunePort>,
    ) -> Self {
        Self {
            context,
            immune_infra,
            is_running: Mutex::new(false),
        }
    }

    pub async fn start(&self) {
        let mut running = self.is_running.lock().await;
        if *running {
            return;
        }
        *running = true;
        info!("🛡️ Digital Immune System ACTIVATED");

        // Spawn protection loops
        self.spawn_integrity_loop();
        self.spawn_context_loop();
    }

    fn spawn_integrity_loop(&self) {
        let infra = self.immune_infra.clone();
        tokio::spawn(async move {
            loop {
                match infra.check_integrity().await {
                    Ok(true) => {
                        // Healthy
                    }
                    Ok(false) => {
                        error!("🚨 INTEGRITY BREACH DETECTED! Self-healing initiated...");
                        // TODO: Trigger self-healing or panic
                    }
                    Err(e) => {
                        warn!("Failed to check integrity: {}", e);
                    }
                }
                tokio::time::sleep(tokio::time::Duration::from_secs(60)).await;
            }
        });
    }

    fn spawn_context_loop(&self) {
        let context = self.context.clone();
        let infra = self.immune_infra.clone();

        tokio::spawn(async move {
            loop {
                // Example: Check active window for known threats
                match context.get_active_window().await {
                    Ok(window) => {
                        // Simple heuristic: check if process is in a blacklist (to be implemented)
                        // In real version, we would use the ImmunePort to scan the process
                        match infra.scan_process(&window.process_name).await {
                            Ok(level) => {
                                if level != synapse_core::ports::ThreatLevel::Safe {
                                    warn!("⚠️ Potential threat detected in active window: {} ({:?})", window.process_name, level);
                                }
                            }
                            Err(_) => {}
                        }
                    }
                    Err(_) => {}
                }
                tokio::time::sleep(tokio::time::Duration::from_secs(5)).await;
            }
        });
    }
}
