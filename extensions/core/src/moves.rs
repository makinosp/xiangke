use serde::{Deserialize, Serialize};

use crate::types::{DamageCategory, EffectType, Stat, TypeElement};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MoveData {
    pub id: String,
    pub name: String,
    pub element: TypeElement,
    pub power: u32,
    pub accuracy: u32,
    pub effect: EffectType,
    pub effect_chance: u32,
    pub stat_mod_stat: Option<Stat>,
    pub stat_mod_stage: i32,
    pub hit_count: u32,
    pub recoil: u32,
    pub healing: u32,
    pub damage_category: DamageCategory,
    pub description: String,
}

impl MoveData {
    pub fn has_stat_mod(&self) -> bool {
        self.stat_mod_stat.is_some() && self.stat_mod_stage != 0
    }

    pub fn is_damaging(&self) -> bool {
        self.power > 0
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_move_creation() {
        let move_data = MoveData {
            id: "fire_strike".into(),
            name: "火炎斬".into(),
            element: TypeElement::Fire,
            power: 60,
            accuracy: 95,
            effect: EffectType::Burn,
            effect_chance: 20,
            stat_mod_stat: None,
            stat_mod_stage: 0,
            hit_count: 1,
            recoil: 0,
            healing: 0,
            damage_category: DamageCategory::Physical,
            description: "A fiery strike".into(),
        };
        assert_eq!(move_data.id, "fire_strike");
        assert_eq!(move_data.power, 60);
        assert!(move_data.is_damaging());
        assert!(!move_data.has_stat_mod());
    }

    #[test]
    fn test_move_non_damaging() {
        let move_data = MoveData {
            id: "heal".into(),
            name: "回復".into(),
            element: TypeElement::Water,
            power: 0,
            accuracy: 100,
            effect: EffectType::None,
            effect_chance: 0,
            stat_mod_stat: None,
            stat_mod_stage: 0,
            hit_count: 1,
            recoil: 0,
            healing: 50,
            damage_category: DamageCategory::Physical,
            description: "Heals the user".into(),
        };
        assert!(!move_data.is_damaging());
        assert_eq!(move_data.healing, 50);
    }

    #[test]
    fn test_move_stat_modification() {
        let move_data = MoveData {
            id: "iron_wall".into(),
            name: "鉄壁".into(),
            element: TypeElement::Metal,
            power: 0,
            accuracy: 100,
            effect: EffectType::None,
            effect_chance: 0,
            stat_mod_stat: Some(Stat::Defense),
            stat_mod_stage: 2,
            hit_count: 1,
            recoil: 0,
            healing: 0,
            damage_category: DamageCategory::Physical,
            description: "Raises defense".into(),
        };
        assert!(move_data.has_stat_mod());
    }

    #[test]
    fn test_move_multi_hit() {
        let move_data = MoveData {
            id: "combo_strike".into(),
            name: "連撃".into(),
            element: TypeElement::Wood,
            power: 20,
            accuracy: 90,
            effect: EffectType::None,
            effect_chance: 0,
            stat_mod_stat: None,
            stat_mod_stage: 0,
            hit_count: 3,
            recoil: 0,
            healing: 0,
            damage_category: DamageCategory::Physical,
            description: "A multi-hit attack".into(),
        };
        assert_eq!(move_data.hit_count, 3);
        assert!(move_data.is_damaging());
    }

    #[test]
    fn test_serialization_roundtrip() {
        let move_data = MoveData {
            id: "test_move".into(),
            name: "Test".into(),
            element: TypeElement::Wood,
            power: 50,
            accuracy: 100,
            effect: EffectType::None,
            effect_chance: 0,
            stat_mod_stat: Some(Stat::Attack),
            stat_mod_stage: -1,
            hit_count: 1,
            recoil: 10,
            healing: 0,
            damage_category: DamageCategory::Arts,
            description: "A test move".into(),
        };
        let json = serde_json::to_string(&move_data).unwrap();
        let deserialized: MoveData = serde_json::from_str(&json).unwrap();
        assert_eq!(deserialized.id, "test_move");
        assert_eq!(deserialized.damage_category, DamageCategory::Arts);
        assert_eq!(deserialized.stat_mod_stat, Some(Stat::Attack));
    }
}
