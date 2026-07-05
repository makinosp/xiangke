//! Move data definitions.
//!
//! Defines the `MoveData` struct representing a battle move.

use serde::{Deserialize, Serialize};

use crate::types::TypeElement;

/// The category of a move.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum MoveCategory {
    Physical,
    Arts, // Special/Arts damage
    Status,
}

/// Data representing a battle move.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MoveData {
    pub id: u32,
    pub name: String,
    pub display_name: String,
    pub element: TypeElement,
    pub category: MoveCategory,
    pub power: u32,
    pub accuracy: f64,
    pub effect_chance: f64,
    pub description: String,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_move_creation() {
        let move_data = MoveData {
            id: 1,
            name: "fire_strike".into(),
            display_name: "火炎斬".into(),
            element: TypeElement::Fire,
            category: MoveCategory::Physical,
            power: 60,
            accuracy: 1.0,
            effect_chance: 0.0,
            description: "A fiery strike".into(),
        };
        assert_eq!(move_data.power, 60);
    }
}
