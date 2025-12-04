use async_trait::async_trait;
use crate::error::Result;

/// Port for handling economic transactions and wallet management.
#[async_trait]
pub trait CommercePort: Send + Sync {
    /// Get the current balance of the user's wallet.
    async fn get_balance(&self) -> Result<u64>;

    /// Transfer tokens to another address.
    /// Returns the transaction hash.
    async fn transfer(&self, to: &str, amount: u64) -> Result<String>;

    /// Lock tokens for a specific duration (staking/vesting).
    async fn lock_tokens(&self, amount: u64, duration_days: u64) -> Result<()>;

    /// Get the current Proof of Sentience score.
    async fn get_proof_of_sentience(&self) -> Result<f32>;
}
