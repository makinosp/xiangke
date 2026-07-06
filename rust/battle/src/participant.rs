use serde::{Deserialize, Serialize};

use xiangke_core::calc;
use xiangke_core::character::CharacterData;
use xiangke_core::types::{EffectType, Stat};

use crate::state::BattleError;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum Team {
    Player,
    Enemy,
}

fn effect_bit(effect: EffectType) -> u8 {
    1u8 << (effect as u8)
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BattleParticipant {
    pub character_data: CharacterData,
    pub current_hp: u32,
    pub max_hp: u32,
    pub team: Team,
    pub slot_index: u32,
    pub is_defeated: bool,
    pub stat_stages: [i32; 5],
    pub active_status_effects: u8,
}

impl BattleParticipant {
    pub fn new(data: CharacterData, team: Team, slot: u32) -> Result<Self, BattleError> {
        if data.base_stats.hp == 0 {
            return Err(BattleError::InvalidParticipant(
                "CharacterData must have hp > 0".into(),
            ));
        }
        Ok(Self {
            max_hp: data.base_stats.hp,
            current_hp: data.base_stats.hp,
            character_data: data,
            team,
            slot_index: slot,
            is_defeated: false,
            stat_stages: [0; 5],
            active_status_effects: 0,
        })
    }

    pub fn stat_stage(&self, stat: Stat) -> i32 {
        self.stat_stages[stat.to_index()]
    }

    pub fn apply_stat_stage(&mut self, stat: Stat, delta: i32) {
        let idx = stat.to_index();
        let current = self.stat_stages[idx];
        self.stat_stages[idx] = current.saturating_add(delta).clamp(-6, 6);
    }

    pub fn reset_stat_stages(&mut self) {
        self.stat_stages = [0; 5];
    }

    pub fn effective_stat(&self, stat: Stat) -> f64 {
        let base = match stat {
            Stat::Attack => self.character_data.base_stats.attack as f64,
            Stat::Defense => self.character_data.base_stats.defense as f64,
            Stat::Speed => self.character_data.base_stats.speed as f64,
            Stat::Intelligence => self.character_data.base_stats.intelligence as f64,
            Stat::Spirit => self.character_data.base_stats.spirit as f64,
        };
        let stage = self.stat_stage(stat);
        base * calc::stat_stage_multiplier(stage)
    }

    pub fn effective_attack(&self) -> f64 {
        self.effective_stat(Stat::Attack)
    }

    pub fn effective_defense(&self) -> f64 {
        self.effective_stat(Stat::Defense)
    }

    pub fn effective_speed(&self) -> f64 {
        self.effective_stat(Stat::Speed)
    }

    pub fn effective_intelligence(&self) -> f64 {
        self.effective_stat(Stat::Intelligence)
    }

    pub fn effective_spirit(&self) -> f64 {
        self.effective_stat(Stat::Spirit)
    }

    pub fn take_damage(&mut self, amount: u32) -> u32 {
        let actual = amount.min(self.current_hp);
        self.current_hp -= actual;
        if self.current_hp == 0 {
            self.is_defeated = true;
        }
        actual
    }

    pub fn heal(&mut self, amount: u32) -> u32 {
        let actual = amount.min(self.max_hp - self.current_hp);
        self.current_hp += actual;
        actual
    }

    pub fn apply_status(&mut self, effect: EffectType) {
        self.active_status_effects |= effect_bit(effect);
    }

    pub fn has_status(&self, effect: EffectType) -> bool {
        self.active_status_effects & effect_bit(effect) != 0
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use xiangke_core::character::Stats;
    use xiangke_core::types::TypeElement;

    fn dummy_character() -> CharacterData {
        CharacterData {
            id: "test_char".into(),
            name: "Test".into(),
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
            moves: vec![],
            description: "".into(),
        }
    }

    #[test]
    fn test_participant_create_valid() {
        let p = BattleParticipant::new(dummy_character(), Team::Player, 0).unwrap();
        assert_eq!(p.current_hp, 100);
        assert_eq!(p.max_hp, 100);
        assert!(!p.is_defeated);
        assert_eq!(p.team, Team::Player);
        assert_eq!(p.slot_index, 0);
    }

    #[test]
    fn test_participant_create_invalid_data() {
        let mut data = dummy_character();
        data.base_stats.hp = 0;
        let result = BattleParticipant::new(data, Team::Player, 0);
        assert!(result.is_err());
    }

    #[test]
    fn test_stat_stage_clamping() {
        let mut p = BattleParticipant::new(dummy_character(), Team::Player, 0).unwrap();
        p.apply_stat_stage(Stat::Attack, 10);
        assert_eq!(p.stat_stage(Stat::Attack), 6);
        p.apply_stat_stage(Stat::Attack, -20);
        assert_eq!(p.stat_stage(Stat::Attack), -6);
    }

    #[test]
    fn test_stat_stage_roundtrip() {
        let mut p = BattleParticipant::new(dummy_character(), Team::Player, 0).unwrap();
        p.apply_stat_stage(Stat::Defense, 2);
        assert_eq!(p.stat_stage(Stat::Defense), 2);
        p.reset_stat_stages();
        assert_eq!(p.stat_stage(Stat::Defense), 0);
    }

    #[test]
    fn test_effective_stat() {
        let p = BattleParticipant::new(dummy_character(), Team::Player, 0).unwrap();
        let eff = p.effective_stat(Stat::Attack);
        assert!((eff - 90.0).abs() < f64::EPSILON);
    }

    #[test]
    fn test_take_damage() {
        let mut p = BattleParticipant::new(dummy_character(), Team::Player, 0).unwrap();
        let dealt = p.take_damage(30);
        assert_eq!(dealt, 30);
        assert_eq!(p.current_hp, 70);
        assert!(!p.is_defeated);
    }

    #[test]
    fn test_take_damage_lethal() {
        let mut p = BattleParticipant::new(dummy_character(), Team::Player, 0).unwrap();
        let dealt = p.take_damage(200);
        assert_eq!(dealt, 100);
        assert_eq!(p.current_hp, 0);
        assert!(p.is_defeated);
    }

    #[test]
    fn test_heal() {
        let mut p = BattleParticipant::new(dummy_character(), Team::Player, 0).unwrap();
        p.take_damage(50);
        let healed = p.heal(20);
        assert_eq!(healed, 20);
        assert_eq!(p.current_hp, 70);
    }

    #[test]
    fn test_heal_cap() {
        let mut p = BattleParticipant::new(dummy_character(), Team::Player, 0).unwrap();
        p.take_damage(10);
        let healed = p.heal(100);
        assert_eq!(healed, 10);
        assert_eq!(p.current_hp, 100);
    }

    #[test]
    fn test_defeated_flag() {
        let mut p = BattleParticipant::new(dummy_character(), Team::Player, 0).unwrap();
        p.take_damage(100);
        assert!(p.is_defeated);
    }

    #[test]
    fn test_status_application() {
        let mut p = BattleParticipant::new(dummy_character(), Team::Player, 0).unwrap();
        p.apply_status(EffectType::Burn);
        assert!(p.has_status(EffectType::Burn));
        assert!(!p.has_status(EffectType::Poison));
        p.apply_status(EffectType::Burn);
    }
}
