use serde::{Deserialize, Serialize};

/// Represents a user's wallet for the Synapse economy.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Wallet {
    /// Public address (e.g., derived from public key)
    pub address: String,
    /// Current balance in $SYN (Synapse Token)
    pub balance: u64,
    /// Locked tokens (vesting)
    pub locked_balance: u64,
}

impl Wallet {
    pub fn new(address: String) -> Self {
        Self {
            address,
            balance: 0,
            locked_balance: 0,
        }
    }

    pub fn credit(&mut self, amount: u64) {
        self.balance += amount;
    }

    pub fn debit(&mut self, amount: u64) -> Result<(), String> {
        if self.balance >= amount {
            self.balance -= amount;
            Ok(())
        } else {
            Err("Insufficient funds".to_string())
        }
    }
}
