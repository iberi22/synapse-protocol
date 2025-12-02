//! NodeType - Types of memory nodes in the graph.

use serde::{Deserialize, Serialize};

/// Types of nodes in the memory graph.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum NodeType {
    /// A base fact or piece of information
    Fact,
    /// A summary of multiple facts (HiRAG layer > 0)
    Summary,
    /// A thought or inference made by the AI
    Thought,
    /// User profile information
    Profile,
    /// System telemetry or metadata
    System,
    /// External source (harvested data)
    External,
}

impl Default for NodeType {
    fn default() -> Self {
        Self::Fact
    }
}

impl std::fmt::Display for NodeType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            NodeType::Fact => write!(f, "fact"),
            NodeType::Summary => write!(f, "summary"),
            NodeType::Thought => write!(f, "thought"),
            NodeType::Profile => write!(f, "profile"),
            NodeType::System => write!(f, "system"),
            NodeType::External => write!(f, "external"),
        }
    }
}
