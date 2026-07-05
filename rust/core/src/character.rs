//! Character data definitions.
//!
//! Defines the `CharacterData` struct representing a character in the Xianke battle game.

use serde::{Deserialize, Serialize};

use crate::types::TypeElement;

/// Core character statistics.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Stats {
    pub hp: u32,
    pub attack: u32,
    pub defense: u32,
    pub speed: u32,
}

impl Stats {
    pub fn new(hp: u32, attack: u32, defense: u32, speed: u32) -> Self {
        Self { hp, attack, defense, speed }
    }
}

/// Data representing a character in the game.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CharacterData {
    pub id: u32,
    pub name: String,
    pub display_name: String,
    pub description: String,
    pub element: TypeElement,
    pub secondary_element: Option<TypeElement>,
    pub base_stats: Stats,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_character_creation() {
        let chara = CharacterData {
            id: 1,
            name: "guan_yu".into(),
            display_name: "関羽".into(),
            description: "A powerful warrior of Shu".into(),
            element: TypeElement::Wood,
            secondary_element: None,
            base_stats: Stats::new(100, 90, 80, 70),
        };
        assert_eq!(chara.id, 1);
        assert_eq!(chara.base_stats.hp, 100);
    }
}
