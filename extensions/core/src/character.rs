use serde::{Deserialize, Serialize};

use crate::types::TypeElement;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Stats {
    pub hp: u32,
    pub attack: u32,
    pub defense: u32,
    pub speed: u32,
    pub intelligence: u32,
    pub spirit: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CharacterData {
    pub id: String,
    pub name: String,
    pub element: TypeElement,
    pub secondary_element: Option<TypeElement>,
    pub base_stats: Stats,
    pub moves: Vec<String>,
    pub description: String,
}

impl CharacterData {
    pub fn has_secondary_type(&self) -> bool {
        self.secondary_element.is_some()
    }

    pub fn get_stat_sum(&self) -> u32 {
        self.base_stats.hp
            + self.base_stats.attack
            + self.base_stats.defense
            + self.base_stats.speed
            + self.base_stats.intelligence
            + self.base_stats.spirit
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_character_creation() {
        let chara = CharacterData {
            id: "guan_yu".into(),
            name: "関羽".into(),
            element: TypeElement::Wood,
            secondary_element: None,
            base_stats: Stats {
                hp: 100,
                attack: 90,
                defense: 80,
                speed: 70,
                intelligence: 60,
                spirit: 50,
            },
            moves: vec![
                "green_slash".into(),
                "fire_strike".into(),
                "healing_wind".into(),
                "iron_wall".into(),
            ],
            description: "A powerful warrior of Shu".into(),
        };
        assert_eq!(chara.id, "guan_yu");
        assert_eq!(chara.base_stats.hp, 100);
        assert!(!chara.has_secondary_type());
        assert_eq!(chara.get_stat_sum(), 450);
    }

    #[test]
    fn test_character_with_secondary_type() {
        let chara = CharacterData {
            id: "zhuge_liang".into(),
            name: "諸葛亮".into(),
            element: TypeElement::Fire,
            secondary_element: Some(TypeElement::Water),
            base_stats: Stats {
                hp: 80,
                attack: 40,
                defense: 50,
                speed: 90,
                intelligence: 120,
                spirit: 100,
            },
            moves: vec![
                "fire_strike".into(),
                "water_blast".into(),
                "confusion".into(),
                "healing_wind".into(),
            ],
            description: "The brilliant strategist of Shu".into(),
        };
        assert!(chara.has_secondary_type());
    }

    #[test]
    fn test_get_stat_sum() {
        let chara = CharacterData {
            id: "test".into(),
            name: "Test".into(),
            element: TypeElement::Wood,
            secondary_element: None,
            base_stats: Stats {
                hp: 100,
                attack: 200,
                defense: 300,
                speed: 400,
                intelligence: 500,
                spirit: 600,
            },
            moves: vec![],
            description: "".into(),
        };
        assert_eq!(chara.get_stat_sum(), 2100);
    }

    #[test]
    fn test_serialization_roundtrip() {
        let chara = CharacterData {
            id: "test_char".into(),
            name: "Test".into(),
            element: TypeElement::Wood,
            secondary_element: Some(TypeElement::Fire),
            base_stats: Stats {
                hp: 100,
                attack: 90,
                defense: 80,
                speed: 70,
                intelligence: 60,
                spirit: 50,
            },
            moves: vec!["move_1".into()],
            description: "A test character".into(),
        };
        let json = serde_json::to_string(&chara).unwrap();
        let deserialized: CharacterData = serde_json::from_str(&json).unwrap();
        assert_eq!(deserialized.id, "test_char");
        assert_eq!(deserialized.base_stats.intelligence, 60);
        assert_eq!(deserialized.moves.len(), 1);
    }

    #[test]
    fn test_character_min_stats() {
        let chara = CharacterData {
            id: "minion".into(),
            name: "Min".into(),
            element: TypeElement::Fire,
            secondary_element: None,
            base_stats: Stats {
                hp: 1,
                attack: 1,
                defense: 1,
                speed: 1,
                intelligence: 1,
                spirit: 1,
            },
            moves: vec![],
            description: "".into(),
        };
        assert_eq!(chara.get_stat_sum(), 6);
        assert!(chara.description.is_empty());
    }

    #[test]
    fn test_character_max_stat_sum_boundary() {
        let chara = CharacterData {
            id: "maximus".into(),
            name: "Max".into(),
            element: TypeElement::Earth,
            secondary_element: Some(TypeElement::Metal),
            base_stats: Stats {
                hp: 500,
                attack: 500,
                defense: 500,
                speed: 500,
                intelligence: 500,
                spirit: 500,
            },
            moves: vec!["a".into(), "b".into(), "c".into(), "d".into()],
            description: "Maximum stat sum".into(),
        };
        assert_eq!(chara.get_stat_sum(), 3000);
        assert!(chara.has_secondary_type());
    }

    #[test]
    fn test_character_serialization_empty_fields() {
        let chara = CharacterData {
            id: "empty".into(),
            name: "Empty".into(),
            element: TypeElement::Yang,
            secondary_element: None,
            base_stats: Stats {
                hp: 100,
                attack: 50,
                defense: 50,
                speed: 50,
                intelligence: 50,
                spirit: 50,
            },
            moves: vec![],
            description: String::new(),
        };
        let json = serde_json::to_string(&chara).unwrap();
        let deserialized: CharacterData = serde_json::from_str(&json).unwrap();
        assert_eq!(deserialized.id, "empty");
        assert!(deserialized.description.is_empty());
        assert!(deserialized.moves.is_empty());
        assert!(!deserialized.has_secondary_type());
    }
}
