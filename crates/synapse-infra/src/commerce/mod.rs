use async_trait::async_trait;
use synapse_core::error::Result;
use synapse_core::ports::commerce_port::CommercePort;
use synapse_core::entities::wallet::Wallet;
use std::sync::Arc;
use tokio::sync::Mutex;

/// A simple in-memory commerce adapter for testing/MVP.
/// Does not persist data to disk yet.
pub struct InMemoryCommerceAdapter {
    wallet: Arc<Mutex<Wallet>>,
}

impl InMemoryCommerceAdapter {
    pub fn new(address: String) -> Self {
        Self {
            wallet: Arc::new(Mutex::new(Wallet::new(address))),
        }
    }
}

#[async_trait]
impl CommercePort for InMemoryCommerceAdapter {
    async fn get_balance(&self) -> Result<u64> {
        let wallet = self.wallet.lock().await;
        Ok(wallet.balance)
    }

    async fn transfer(&self, to: &str, amount: u64) -> Result<String> {
        let mut wallet = self.wallet.lock().await;
        wallet.debit(amount).map_err(|e| synapse_core::error::Error::Commerce(e))?;

        // In a real implementation, we would update the recipient's wallet here
        // and record the transaction on the blockchain/ledger.
        // For now, we just simulate a transaction hash.
        let tx_hash = format!("tx_{}_{}_{}", wallet.address, to, amount);
        Ok(tx_hash)
    }

    async fn lock_tokens(&self, amount: u64, _duration_days: u64) -> Result<()> {
        let mut wallet = self.wallet.lock().await;
        if wallet.balance < amount {
            return Err(synapse_core::error::Error::Commerce("Insufficient funds to lock".to_string()));
        }
        wallet.balance -= amount;
        wallet.locked_balance += amount;
        Ok(())
    }

    async fn get_proof_of_sentience(&self) -> Result<f32> {
        // Mock implementation
        Ok(0.85)
    }
}
