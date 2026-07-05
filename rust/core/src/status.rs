use serde::{Deserialize, Serialize};

use crate::types::{EffectType, Stat};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StatusEffectData {
    pub status_type: EffectType,
    pub name: String,
    pub description: String,
    pub damage_per_turn: f64,
    pub escalating: bool,
    pub max_damage_cap: f64,
    pub stat_mod_stat: Option<Stat>,
    pub stat_mod_multiplier: f64,
}

impl StatusEffectData {
    pub fn has_damage_over_time(&self) -> bool {
        self.damage_per_turn > 0.0
    }

    pub fn has_stat_modification(&self) -> bool {
        self.stat_mod_stat.is_some() && (self.stat_mod_multiplier - 1.0).abs() > f64::EPSILON
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_status_creation() {
        let status = StatusEffectData {
            status_type: EffectType::Burn,
            name: "炎上".into(),
            description: "Deals damage over time".into(),
            damage_per_turn: 0.125,
            escalating: false,
            max_damage_cap: 0.25,
            stat_mod_stat: Some(Stat::Attack),
            stat_mod_multiplier: 0.5,
        };
        assert_eq!(status.status_type, EffectType::Burn);
        assert!(status.has_damage_over_time());
        assert!(status.has_stat_modification());
    }

    #[test]
    fn test_status_no_damage() {
        let status = StatusEffectData {
            status_type: EffectType::Charm,
            name: "魅了".into(),
            description: "Reduces attack".into(),
            damage_per_turn: 0.0,
            escalating: false,
            max_damage_cap: 0.0,
            stat_mod_stat: Some(Stat::Attack),
            stat_mod_multiplier: 0.5,
        };
        assert!(!status.has_damage_over_time());
        assert!(status.has_stat_modification());
    }

    #[test]
    fn test_status_none_effect() {
        let status = StatusEffectData {
            status_type: EffectType::None,
            name: "None".into(),
            description: "No effect".into(),
            damage_per_turn: 0.0,
            escalating: false,
            max_damage_cap: 0.0,
            stat_mod_stat: None,
            stat_mod_multiplier: 1.0,
        };
        assert!(!status.has_damage_over_time());
        assert!(!status.has_stat_modification());
    }

    #[test]
    fn test_poison_escalating() {
        let status = StatusEffectData {
            status_type: EffectType::Poison,
            name: "毒".into(),
            description: "Increases damage over time".into(),
            damage_per_turn: 0.0625,
            escalating: true,
            max_damage_cap: 0.25,
            stat_mod_stat: None,
            stat_mod_multiplier: 1.0,
        };
        assert!(status.escalating);
        assert!(status.has_damage_over_time());
        assert!(!status.has_stat_modification());
    }

    #[test]
    fn test_serialization_roundtrip() {
        let status = StatusEffectData {
            status_type: EffectType::Confusion,
            name: "混乱".into(),
            description: "May hit itself".into(),
            damage_per_turn: 0.0,
            escalating: false,
            max_damage_cap: 0.0,
            stat_mod_stat: Some(Stat::Speed),
            stat_mod_multiplier: 0.75,
        };
        let json = serde_json::to_string(&status).unwrap();
        let deserialized: StatusEffectData = serde_json::from_str(&json).unwrap();
        assert_eq!(deserialized.status_type, EffectType::Confusion);
        assert_eq!(deserialized.stat_mod_stat, Some(Stat::Speed));
    }
}
