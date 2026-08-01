use serde::{Deserialize, Serialize};

use crate::types::{EffectType, Stat};

/// Default damage per turn for Burn status (1/16 of max HP).
pub const BURN_DAMAGE_RATIO: f64 = 1.0 / 16.0;
/// Default damage per turn for Poison status (2× Burn, since it escalates).
pub const POISON_DAMAGE_RATIO: f64 = 2.0 * BURN_DAMAGE_RATIO;
/// Maximum damage cap for escalating status effects (25% of max HP).
pub const MAX_DOT_CAP: f64 = 0.25;

/// Configuration data for a status effect (DoT, stat modification, etc.).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StatusEffectData {
    /// The type of status effect.
    pub status_type: EffectType,
    /// Display name.
    pub name: String,
    /// Description of the effect.
    pub description: String,
    /// Damage per turn as a fraction of max HP.
    pub damage_per_turn: f64,
    /// Whether damage escalates over time.
    pub escalating: bool,
    /// Maximum fractional damage cap (e.g. 0.25 = 25% of max HP).
    pub max_damage_cap: f64,
    /// Which stat is modified by this effect (if any).
    pub stat_mod_stat: Option<Stat>,
    /// Multiplier applied to the affected stat.
    pub stat_mod_multiplier: f64,
}

impl Default for StatusEffectData {
    fn default() -> Self {
        Self {
            status_type: EffectType::None,
            name: String::new(),
            description: String::new(),
            damage_per_turn: BURN_DAMAGE_RATIO,
            escalating: false,
            max_damage_cap: MAX_DOT_CAP,
            stat_mod_stat: None,
            stat_mod_multiplier: 1.0,
        }
    }
}

impl StatusEffectData {
    /// Returns `true` if this effect deals damage over time.
    pub fn has_damage_over_time(&self) -> bool {
        self.damage_per_turn > 0.0
    }

    /// Returns `true` if this effect modifies a character's stats.
    pub fn has_stat_modification(&self) -> bool {
        self.stat_mod_stat.is_some() && (self.stat_mod_multiplier - 1.0).abs() > f64::EPSILON
    }
}

/// Builds the default status effect configuration map.
///
/// Used by battle initialization and the Godot bridge so that Burn, Poison,
/// and Confusion are configured consistently everywhere.
pub fn default_configs() -> std::collections::HashMap<EffectType, StatusEffectData> {
    let mut m = std::collections::HashMap::new();
    m.insert(
        EffectType::Burn,
        StatusEffectData {
            status_type: EffectType::Burn,
            damage_per_turn: BURN_DAMAGE_RATIO,
            ..Default::default()
        },
    );
    m.insert(
        EffectType::Poison,
        StatusEffectData {
            status_type: EffectType::Poison,
            damage_per_turn: POISON_DAMAGE_RATIO,
            ..Default::default()
        },
    );
    m.insert(
        EffectType::Confusion,
        StatusEffectData {
            status_type: EffectType::Confusion,
            damage_per_turn: 0.0,
            ..Default::default()
        },
    );
    m
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

    #[test]
    fn test_status_default_constructor() {
        let status = StatusEffectData::default();
        assert_eq!(status.status_type, EffectType::None);
        assert_eq!(status.damage_per_turn, BURN_DAMAGE_RATIO);
        assert_eq!(status.max_damage_cap, MAX_DOT_CAP);
        assert!(status.has_damage_over_time()); // default has BURN_DAMAGE_RATIO > 0
        assert!(!status.has_stat_modification());
    }

    #[test]
    fn test_status_constants() {
        assert!((BURN_DAMAGE_RATIO - 1.0 / 16.0).abs() < f64::EPSILON);
        assert!((POISON_DAMAGE_RATIO - 2.0 / 16.0).abs() < f64::EPSILON);
        assert!((MAX_DOT_CAP - 0.25).abs() < f64::EPSILON);
    }

    #[test]
    fn test_status_chain_and_confusion() {
        let chain = StatusEffectData {
            status_type: EffectType::Chain,
            name: "連鎖".into(),
            description: "Links damage".into(),
            damage_per_turn: 0.0,
            escalating: false,
            max_damage_cap: 0.0,
            stat_mod_stat: None,
            stat_mod_multiplier: 1.0,
        };
        assert_eq!(chain.status_type, EffectType::Chain);
        assert!(!chain.has_damage_over_time());
        assert!(!chain.has_stat_modification());

        let confusion = StatusEffectData {
            status_type: EffectType::Confusion,
            name: "混乱".into(),
            description: "May hit itself".into(),
            damage_per_turn: 0.0,
            escalating: false,
            max_damage_cap: 0.0,
            stat_mod_stat: Some(Stat::Speed),
            stat_mod_multiplier: 0.75,
        };
        assert!(confusion.has_stat_modification());
        assert!((confusion.stat_mod_multiplier - 0.75).abs() < f64::EPSILON);
    }

    #[test]
    fn test_status_poison_config() {
        let poison = StatusEffectData {
            status_type: EffectType::Poison,
            name: "毒".into(),
            description: "Escalating DoT".into(),
            damage_per_turn: POISON_DAMAGE_RATIO,
            escalating: true,
            max_damage_cap: MAX_DOT_CAP,
            stat_mod_stat: None,
            stat_mod_multiplier: 1.0,
        };
        assert!(poison.escalating);
        assert!((poison.damage_per_turn - POISON_DAMAGE_RATIO).abs() < f64::EPSILON);
        assert!(!poison.has_stat_modification());
    }
}
