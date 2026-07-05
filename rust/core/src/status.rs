//! Status effect definitions.
//!
//! Defines status effects that can be applied during battle.

use serde::{Deserialize, Serialize};
use strum::{Display, EnumString, FromRepr};

/// Types of status effects in the battle system.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Display, EnumString, FromRepr)]
#[repr(u8)]
pub enum StatusType {
    Burn,
    Poison,
    Confusion,
    Chain,
    Charm,
}

impl StatusType {
    /// All status types in order.
    pub const ALL: [StatusType; 5] = [
        StatusType::Burn,
        StatusType::Poison,
        StatusType::Confusion,
        StatusType::Chain,
        StatusType::Charm,
    ];
}

/// Data representing a status effect definition.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StatusEffectData {
    pub status_type: StatusType,
    pub name: String,
    pub display_name: String,
    pub duration: u32,
    pub description: String,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_status_display() {
        assert_eq!(StatusType::Burn.to_string(), "Burn");
        assert_eq!(StatusType::Poison.to_string(), "Poison");
    }
}
