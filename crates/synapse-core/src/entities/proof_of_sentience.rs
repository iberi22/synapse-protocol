use serde::{Deserialize, Serialize};

/// Represents the "Humanity Score" of a node.
/// Used to determine mining rewards and voting power.
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ProofOfSentience {
    /// 10% weight: Quality of hardware (NPU/GPU)
    pub hardware_contribution: f32,
    /// 40% weight: Quality and quantity of data provided
    pub data_contribution: f32,
    /// 50% weight: Verification of human presence (biometrics/behavior)
    pub human_validation: f32,
}

impl ProofOfSentience {
    pub fn new(hardware: f32, data: f32, human: f32) -> Self {
        Self {
            hardware_contribution: hardware.clamp(0.0, 1.0),
            data_contribution: data.clamp(0.0, 1.0),
            human_validation: human.clamp(0.0, 1.0),
        }
    }

    /// Calculates the total score (0.0 to 1.0)
    pub fn total_score(&self) -> f32 {
        (self.hardware_contribution * 0.10)
            + (self.data_contribution * 0.40)
            + (self.human_validation * 0.50)
    }

    /// Returns true if the score is high enough to be considered "Verified Human"
    pub fn is_verified(&self) -> bool {
        self.total_score() > 0.7
    }
}
