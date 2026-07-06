use std::collections::HashMap;

use serde::{Deserialize, Serialize};
use thiserror::Error;

use xiangke_core::moves::MoveData;
use xiangke_core::status::StatusEffectData;
use xiangke_core::types::EffectType;

use crate::participant::{BattleParticipant, Team};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum Status {
    Active,
    Victory,
    Defeat,
    Draw,
    Escaped,
}

pub const MAX_TURNS: u32 = 50;

#[derive(Debug, Clone, Error)]
pub enum BattleError {
    #[error("Invalid participant: {0}")]
    InvalidParticipant(String),

    #[error("Invalid battle state: {0}")]
    InvalidBattleState(String),

    #[error("Defeated participant: {0}")]
    DefeatedParticipant(String),

    #[error("Move not found: {0}")]
    MoveNotFound(String),

    #[error("No active participants remaining")]
    NoActiveParticipants,

    #[error("Battle has already ended")]
    BattleAlreadyEnded,

    #[error("Invalid target: {0}")]
    InvalidTarget(String),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BattleState {
    pub battle_id: String,
    pub participants: Vec<BattleParticipant>,
    pub turn_count: u32,
    pub round_count: u32,
    pub battle_status: Status,
    pub turn_queue: Vec<usize>,
    pub turn_queue_index: usize,
    pub active_participant: Option<usize>,
    pub move_lookup: HashMap<String, Box<MoveData>>,
    pub status_effect_configs: HashMap<EffectType, StatusEffectData>,
    pub battle_log: Vec<String>,
}

impl BattleState {
    pub fn new(
        participants: Vec<BattleParticipant>,
        move_lookup: HashMap<String, Box<MoveData>>,
    ) -> Result<Self, BattleError> {
        let has_player = participants.iter().any(|p| p.team == Team::Player);
        let has_enemy = participants.iter().any(|p| p.team == Team::Enemy);
        if !has_player {
            return Err(BattleError::InvalidBattleState(
                "Must have at least 1 player participant".into(),
            ));
        }
        if !has_enemy {
            return Err(BattleError::InvalidBattleState(
                "Must have at least 1 enemy participant".into(),
            ));
        }
        let mut status_effect_configs = HashMap::new();
        for &effect in &[EffectType::Burn, EffectType::Poison, EffectType::Confusion] {
            status_effect_configs.insert(
                effect,
                StatusEffectData {
                    status_type: effect,
                    damage_per_turn: match effect {
                        EffectType::Poison => 1.0 / 8.0,
                        EffectType::Burn => 1.0 / 16.0,
                        EffectType::Confusion => 0.0,
                        _ => 0.0,
                    },
                    ..Default::default()
                },
            );
        }

        Ok(Self {
            battle_id: String::new(),
            participants,
            turn_count: 0,
            round_count: 0,
            battle_status: Status::Active,
            turn_queue: Vec::new(),
            turn_queue_index: 0,
            active_participant: None,
            move_lookup,
            status_effect_configs,
            battle_log: Vec::new(),
        })
    }

    pub fn player_participants(&self) -> impl Iterator<Item = &BattleParticipant> {
        self.participants.iter().filter(|p| p.team == Team::Player)
    }

    pub fn enemy_participants(&self) -> impl Iterator<Item = &BattleParticipant> {
        self.participants.iter().filter(|p| p.team == Team::Enemy)
    }

    pub fn active_participants(&self) -> impl Iterator<Item = &BattleParticipant> {
        self.participants.iter().filter(|p| !p.is_defeated)
    }

    pub fn evaluate_status(&self) -> Status {
        if self.battle_status != Status::Active {
            return self.battle_status;
        }
        let all_enemies_defeated = self
            .participants
            .iter()
            .filter(|p| p.team == Team::Enemy)
            .all(|p| p.is_defeated);
        if all_enemies_defeated {
            return Status::Victory;
        }
        let all_players_defeated = self
            .participants
            .iter()
            .filter(|p| p.team == Team::Player)
            .all(|p| p.is_defeated);
        if all_players_defeated {
            return Status::Defeat;
        }
        if self.turn_count >= MAX_TURNS {
            return Status::Draw;
        }
        Status::Active
    }

    pub fn apply_status(&mut self, status: Status) {
        self.battle_status = status;
        match status {
            Status::Victory => self.add_log("All enemies defeated! Victory!".into()),
            Status::Defeat => self.add_log("All allies defeated! Defeat...".into()),
            Status::Draw => self.add_log("Turn limit reached! The battle ends in a draw.".into()),
            _ => {}
        }
    }

    pub fn add_log(&mut self, message: String) {
        self.battle_log.push(format!(
            "[T{}/R{}] {}",
            self.turn_count, self.round_count, message
        ));
    }

    pub fn recent_log(&self, n: usize) -> Vec<&str> {
        let start = self.battle_log.len().saturating_sub(n);
        self.battle_log[start..]
            .iter()
            .map(|s| s.as_str())
            .collect()
    }

    pub fn reset(&mut self) {
        self.turn_count = 0;
        self.round_count = 0;
        self.battle_status = Status::Active;
        self.active_participant = None;
        self.turn_queue.clear();
        self.turn_queue_index = 0;
        self.battle_log.clear();
        for p in &mut self.participants {
            p.current_hp = p.max_hp;
            p.is_defeated = false;
            p.active_status_effects = 0;
            p.reset_stat_stages();
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::participant::Team;
    use xiangke_core::character::{CharacterData, Stats};
    use xiangke_core::moves::MoveData;
    use xiangke_core::types::{EffectType, TypeElement};

    fn make_participant(team: Team, hp: u32) -> BattleParticipant {
        BattleParticipant::new(
            CharacterData {
                id: "test".into(),
                name: "Test".into(),
                element: TypeElement::Wood,
                secondary_element: None,
                base_stats: Stats {
                    hp,
                    attack: 50,
                    defense: 50,
                    speed: 50,
                    intelligence: 50,
                    spirit: 50,
                },
                moves: vec![],
                description: "".into(),
            },
            team,
            0,
        )
        .unwrap()
    }

    fn empty_move_lookup() -> HashMap<String, Box<MoveData>> {
        HashMap::new()
    }

    #[test]
    fn test_battle_state_create_valid() {
        let participants = vec![
            make_participant(Team::Player, 100),
            make_participant(Team::Enemy, 100),
        ];
        let state = BattleState::new(participants, empty_move_lookup()).unwrap();
        assert_eq!(state.battle_status, Status::Active);
    }

    #[test]
    fn test_battle_state_create_no_players() {
        let participants = vec![make_participant(Team::Enemy, 100)];
        let result = BattleState::new(participants, empty_move_lookup());
        assert!(result.is_err());
    }

    #[test]
    fn test_battle_state_create_no_enemies() {
        let participants = vec![make_participant(Team::Player, 100)];
        let result = BattleState::new(participants, empty_move_lookup());
        assert!(result.is_err());
    }

    #[test]
    fn test_evaluate_victory() {
        let mut participants = vec![
            make_participant(Team::Player, 100),
            make_participant(Team::Enemy, 100),
        ];
        participants[1].take_damage(100);
        let state = BattleState::new(participants, empty_move_lookup()).unwrap();
        let status = state.evaluate_status();
        assert_eq!(status, Status::Victory);
    }

    #[test]
    fn test_evaluate_defeat() {
        let mut participants = vec![
            make_participant(Team::Player, 100),
            make_participant(Team::Enemy, 100),
        ];
        participants[0].take_damage(100);
        let state = BattleState::new(participants, empty_move_lookup()).unwrap();
        let status = state.evaluate_status();
        assert_eq!(status, Status::Defeat);
    }

    #[test]
    fn test_evaluate_draw() {
        let participants = vec![
            make_participant(Team::Player, 100),
            make_participant(Team::Enemy, 100),
        ];
        let mut state = BattleState::new(participants, empty_move_lookup()).unwrap();
        state.turn_count = MAX_TURNS;
        let status = state.evaluate_status();
        assert_eq!(status, Status::Draw);
    }

    #[test]
    fn test_evaluate_active() {
        let participants = vec![
            make_participant(Team::Player, 100),
            make_participant(Team::Enemy, 100),
        ];
        let state = BattleState::new(participants, empty_move_lookup()).unwrap();
        let status = state.evaluate_status();
        assert_eq!(status, Status::Active);
    }

    #[test]
    fn test_participant_filtering() {
        let mut participants = vec![
            make_participant(Team::Player, 100),
            make_participant(Team::Player, 100),
            make_participant(Team::Enemy, 100),
            make_participant(Team::Enemy, 100),
        ];
        participants[3].take_damage(100);
        let state = BattleState::new(participants, empty_move_lookup()).unwrap();
        assert_eq!(state.player_participants().count(), 2);
        assert_eq!(state.enemy_participants().count(), 2);
        assert_eq!(state.active_participants().count(), 3);
    }

    #[test]
    fn test_add_log() {
        let participants = vec![
            make_participant(Team::Player, 100),
            make_participant(Team::Enemy, 100),
        ];
        let mut state = BattleState::new(participants, empty_move_lookup()).unwrap();
        state.turn_count = 1;
        state.round_count = 1;
        state.add_log("Test message".into());
        assert!(state.battle_log[0].contains("Test message"));
        assert!(state.battle_log[0].contains("[T1/R1]"));
    }

    #[test]
    fn test_recent_log() {
        let participants = vec![
            make_participant(Team::Player, 100),
            make_participant(Team::Enemy, 100),
        ];
        let mut state = BattleState::new(participants, empty_move_lookup()).unwrap();
        state.add_log("Msg 1".into());
        state.add_log("Msg 2".into());
        state.add_log("Msg 3".into());
        let recent = state.recent_log(2);
        assert_eq!(recent.len(), 2);
        assert!(recent[0].contains("Msg 2"));
        assert!(recent[1].contains("Msg 3"));
    }

    #[test]
    fn test_reset() {
        let mut participants = vec![
            make_participant(Team::Player, 100),
            make_participant(Team::Enemy, 100),
        ];
        participants[0].apply_stat_stage(xiangke_core::types::Stat::Attack, 2);
        participants[0].apply_status(EffectType::Burn);
        participants[0].take_damage(30);
        let mut state = BattleState::new(participants, empty_move_lookup()).unwrap();
        state.turn_count = 3;
        state.battle_status = Status::Defeat;
        state.reset();
        assert_eq!(state.turn_count, 0);
        assert_eq!(state.battle_status, Status::Active);
        assert!(!state.participants[0].is_defeated);
        assert_eq!(
            state.participants[0].current_hp,
            state.participants[0].max_hp
        );
        assert_eq!(state.participants[0].active_status_effects, 0);
        assert_eq!(
            state.participants[0].stat_stage(xiangke_core::types::Stat::Attack),
            0
        );
    }

    #[test]
    fn test_battle_error_display() {
        let err = BattleError::InvalidParticipant("hp is 0".into());
        let msg = format!("{err}");
        assert!(msg.contains("Invalid participant"));
    }
}
