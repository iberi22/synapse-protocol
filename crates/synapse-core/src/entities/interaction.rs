//! Interaction - A user-AI interaction in the buffer.

use serde::{Deserialize, Serialize};
use chrono::Utc;
use uuid::Uuid;

/// A single interaction between user and AI.
///
/// Interactions are stored in the short-term buffer (Sled)
/// before being processed and consolidated into long-term memory.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Interaction {
    /// Unique identifier
    pub id: String,
    
    /// User's input
    pub user_input: String,
    
    /// AI's response
    pub ai_response: String,
    
    /// Unix timestamp
    pub timestamp: i64,
    
    /// Session identifier (for grouping)
    pub session_id: String,
    
    /// Whether this interaction has been processed
    pub processed: bool,
}

impl Interaction {
    /// Create a new interaction.
    pub fn new(user_input: String, ai_response: String) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            user_input,
            ai_response,
            timestamp: Utc::now().timestamp(),
            session_id: String::new(),
            processed: false,
        }
    }
    
    /// Set session ID
    pub fn with_session(mut self, session_id: String) -> Self {
        self.session_id = session_id;
        self
    }
    
    /// Mark as processed
    pub fn mark_processed(&mut self) {
        self.processed = true;
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_new_interaction() {
        let interaction = Interaction::new(
            "Hello".to_string(),
            "Hi there!".to_string(),
        );
        assert!(!interaction.id.is_empty());
        assert_eq!(interaction.user_input, "Hello");
        assert_eq!(interaction.ai_response, "Hi there!");
        assert!(!interaction.processed);
    }
}
