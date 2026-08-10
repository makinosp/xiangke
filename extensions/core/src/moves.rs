use serde::{Deserialize, Serialize};

use crate::types::{DamageCategory, EffectType, Stat, StatModTarget, TypeElement};

/// A move definition: stats, element, effect, and other properties.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MoveData {
    /// Unique identifier (e.g. "fire_strike").
    pub id: String,
    /// Display name.
    pub name: String,
    /// Element type of this move.
    pub element: TypeElement,
    /// Base power (0 = non-damaging move).
    pub power: u32,
    /// Accuracy percentage (0–100).
    pub accuracy: u32,
    /// Secondary status effect type.
    pub effect: EffectType,
    /// Chance to apply the secondary effect (percentage).
    pub effect_chance: u32,
    /// Which stat is modified by this move (if any).
    pub stat_mod_stat: Option<Stat>,
    /// Stat modification stage change (positive = buff, negative = debuff).
    pub stat_mod_stage: i32,
    /// Target of the stat modification (SELF or TARGET).
    pub stat_mod_target: StatModTarget,
    /// Number of hits for multi-hit moves.
    pub hit_count: u32,
    /// Recoil damage percentage of damage dealt.
    pub recoil: u32,
    /// Healing percentage of max HP.
    pub healing: u32,
    /// Damage category (Physical or Arts).
    pub damage_category: DamageCategory,
    /// Flavor description text.
    pub description: String,
}

impl MoveData {
    /// Returns `true` if this move modifies a stat (buff or debuff).
    pub fn has_stat_mod(&self) -> bool {
        self.stat_mod_stat.is_some() && self.stat_mod_stage != 0
    }

    /// Returns `true` if this move has a stat modification target set.
    pub fn has_stat_mod_target(&self) -> bool {
        self.stat_mod_target != StatModTarget::Self_
    }

    /// Returns `true` if this move deals damage (`power > 0`).
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
            stat_mod_target: StatModTarget::Self_,
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
            stat_mod_target: StatModTarget::Self_,
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
            stat_mod_target: StatModTarget::Self_,
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
            stat_mod_target: StatModTarget::Self_,
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
            stat_mod_target: StatModTarget::Self_,
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

    #[test]
    fn test_move_max_power() {
        let mv = MoveData {
            id: "max_power".into(),
            name: "MAX".into(),
            element: TypeElement::Fire,
            power: 255,
            accuracy: 100,
            effect: EffectType::None,
            effect_chance: 0,
            stat_mod_stat: None,
            stat_mod_stage: 0,
            stat_mod_target: StatModTarget::Self_,
            hit_count: 1,
            recoil: 0,
            healing: 0,
            damage_category: DamageCategory::Physical,
            description: "Max power".into(),
        };
        assert!(mv.is_damaging());
        assert_eq!(mv.power, 255);
    }

    #[test]
    fn test_move_zero_accuracy() {
        let mv = MoveData {
            id: "no_aim".into(),
            name: "No Aim".into(),
            element: TypeElement::Water,
            power: 30,
            accuracy: 0,
            effect: EffectType::None,
            effect_chance: 0,
            stat_mod_stat: None,
            stat_mod_stage: 0,
            stat_mod_target: StatModTarget::Self_,
            hit_count: 1,
            recoil: 0,
            healing: 0,
            damage_category: DamageCategory::Arts,
            description: "Zero accuracy".into(),
        };
        assert_eq!(mv.accuracy, 0);
    }

    #[test]
    fn test_move_stat_mod_both_fields() {
        let mv = MoveData {
            id: "buff_all".into(),
            name: "Buff".into(),
            element: TypeElement::Yang,
            power: 0,
            accuracy: 100,
            effect: EffectType::Confusion,
            effect_chance: 30,
            stat_mod_stat: Some(Stat::Speed),
            stat_mod_stage: 1,
            stat_mod_target: StatModTarget::Self_,
            hit_count: 1,
            recoil: 0,
            healing: 0,
            damage_category: DamageCategory::Physical,
            description: "".into(),
        };
        assert!(mv.has_stat_mod());
        assert!(!mv.is_damaging());
        assert_eq!(mv.effect, EffectType::Confusion);
    }

    #[test]
    fn test_move_recoil_healing_combination() {
        let mv = MoveData {
            id: "life_drain".into(),
            name: "Drain".into(),
            element: TypeElement::Yin,
            power: 40,
            accuracy: 90,
            effect: EffectType::None,
            effect_chance: 0,
            stat_mod_stat: None,
            stat_mod_stage: 0,
            stat_mod_target: StatModTarget::Self_,
            hit_count: 1,
            recoil: 50,
            healing: 25,
            damage_category: DamageCategory::Physical,
            description: "Has both recoil and healing".into(),
        };
        assert!(mv.is_damaging());
        assert_eq!(mv.recoil, 50);
        assert_eq!(mv.healing, 25);
    }

    #[test]
    fn test_move_description_long() {
        let long_desc = "A".repeat(100);
        let mv = MoveData {
            id: "long_desc".into(),
            name: "Long".into(),
            element: TypeElement::Wood,
            power: 10,
            accuracy: 100,
            effect: EffectType::None,
            effect_chance: 0,
            stat_mod_stat: None,
            stat_mod_stage: 0,
            stat_mod_target: StatModTarget::Self_,
            hit_count: 1,
            recoil: 0,
            healing: 0,
            damage_category: DamageCategory::Physical,
            description: long_desc.clone(),
        };
        assert_eq!(mv.description.len(), 100);
        let json = serde_json::to_string(&mv).unwrap();
        let deserialized: MoveData = serde_json::from_str(&json).unwrap();
        assert_eq!(deserialized.description.len(), 100);
    }
}
