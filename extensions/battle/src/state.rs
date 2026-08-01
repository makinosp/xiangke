use std::collections::HashMap;

use serde::{Deserialize, Serialize};
use thiserror::Error;

use xiangke_core::moves::MoveData;
use xiangke_core::status::{StatusEffectData, default_configs};
use xiangke_core::types::EffectType;

use crate::participant::{BattleParticipant, Team};

/// The overall status of a battle.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum Status {
    /// Battle is ongoing.
    Active,
    /// Player team has won.
    Victory,
    /// Player team has lost.
    Defeat,
    /// Battle ended in a draw (turn limit reached).
    Draw,
}

/// Maximum number of turns before the battle ends in a draw.
pub const MAX_TURNS: u32 = 50;

/// Errors that can occur during battle operations.
#[derive(Debug, Clone, Error)]
pub enum BattleError {
    /// Invalid character data (e.g. HP == 0).
    #[error("Invalid participant: {0}")]
    InvalidParticipant(String),

    /// Invalid battle configuration (e.g. missing players/enemies).
    #[error("Invalid battle state: {0}")]
    InvalidBattleState(String),

    /// Operation attempted on a defeated participant.
    #[error("Defeated participant: {0}")]
    DefeatedParticipant(String),

    /// Move ID not found in the battle's move lookup.
    #[error("Move not found: {0}")]
    MoveNotFound(String),

    /// No active (non-defeated) participants remain.
    #[error("No active participants remaining")]
    NoActiveParticipants,

    /// Action attempted after battle has ended.
    #[error("Battle has already ended")]
    BattleAlreadyEnded,

    /// Invalid target specified for an action.
    #[error("Invalid target: {0}")]
    InvalidTarget(String),
}

/// The complete state of a battle, including participants, turn queue, and log.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BattleState {
    /// All participants in the battle.
    pub participants: Vec<BattleParticipant>,
    /// Total number of turns elapsed.
    pub turn_count: u32,
    /// Current round number.
    pub round_count: u32,
    /// Overall battle status.
    pub battle_status: Status,
    /// Ordered indices into `participants` for the current round.
    pub turn_queue: Vec<usize>,
    /// Index into `turn_queue` for the current position.
    pub turn_queue_index: usize,
    /// Index of the currently active participant.
    pub active_participant: Option<usize>,
    /// Lookup table mapping move ID strings to move data.
    pub move_lookup: HashMap<String, Box<MoveData>>,
    /// Configuration data for status effects (DoT rates, etc.).
    pub status_effect_configs: HashMap<EffectType, StatusEffectData>,
    /// Chronological battle log entries.
    pub battle_log: Vec<String>,
}

impl BattleState {
    /// Creates a new `BattleState` with the given participants and move lookup.
    ///
    /// Automatically configures default status effect data (Burn, Poison, Confusion).
    /// Returns an error if no player or no enemy participants exist.
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
        let status_effect_configs = default_configs();

        Ok(Self {
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

    /// Returns an iterator over all player-controlled participants.
    pub fn player_participants(&self) -> impl Iterator<Item = &BattleParticipant> {
        self.participants.iter().filter(|p| p.team == Team::Player)
    }

    /// Returns an iterator over all enemy participants.
    pub fn enemy_participants(&self) -> impl Iterator<Item = &BattleParticipant> {
        self.participants.iter().filter(|p| p.team == Team::Enemy)
    }

    /// Returns an iterator over all non-defeated participants.
    pub fn active_participants(&self) -> impl Iterator<Item = &BattleParticipant> {
        self.participants.iter().filter(|p| !p.is_defeated)
    }

    /// Returns `true` when every participant on the given team is defeated.
    fn team_all_defeated(&self, team: Team) -> bool {
        self.participants
            .iter()
            .filter(|p| p.team == team)
            .all(|p| p.is_defeated)
    }

    /// Evaluates the current battle outcome and returns the appropriate [`Status`].
    ///
    /// Checks enemy defeat → Victory, player defeat → Defeat, turn limit → Draw.
    pub fn evaluate_status(&self) -> Status {
        if self.battle_status != Status::Active {
            return self.battle_status;
        }
        if self.team_all_defeated(Team::Enemy) {
            return Status::Victory;
        }
        if self.team_all_defeated(Team::Player) {
            return Status::Defeat;
        }
        if self.turn_count >= MAX_TURNS {
            return Status::Draw;
        }
        Status::Active
    }

    /// Sets the battle status and logs the corresponding outcome message.
    pub fn apply_status(&mut self, status: Status) {
        self.battle_status = status;
        match status {
            Status::Victory => self.add_log("All enemies defeated! Victory!".into()),
            Status::Defeat => self.add_log("All allies defeated! Defeat...".into()),
            Status::Draw => self.add_log("Turn limit reached! The battle ends in a draw.".into()),
            _ => {}
        }
    }

    /// Appends a timestamped log entry (prefixed with turn/round numbers).
    pub fn add_log(&mut self, message: String) {
        self.battle_log.push(format!(
            "[T{}/R{}] {}",
            self.turn_count, self.round_count, message
        ));
    }

    /// Returns the `n` most recent log entries.
    pub fn recent_log(&self, n: usize) -> Vec<&str> {
        let start = self.battle_log.len().saturating_sub(n);
        self.battle_log[start..]
            .iter()
            .map(|s| s.as_str())
            .collect()
    }

    /// Resets the battle state to its initial conditions (HP restored, log cleared).
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
            p.is_front = false;
            p.active_status_effects = 0;
            p.reset_stat_stages();
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_utils::make_participant;
    use xiangke_core::moves::MoveData;

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

    #[test]
    fn test_battle_error_all_variants() {
        let variants: [(&str, BattleError); 7] = [
            (
                "Invalid participant",
                BattleError::InvalidParticipant("a".into()),
            ),
            (
                "Invalid battle state",
                BattleError::InvalidBattleState("b".into()),
            ),
            (
                "Defeated participant",
                BattleError::DefeatedParticipant("c".into()),
            ),
            ("Move not found", BattleError::MoveNotFound("d".into())),
            ("No active participants", BattleError::NoActiveParticipants),
            ("Battle has already ended", BattleError::BattleAlreadyEnded),
            ("Invalid target", BattleError::InvalidTarget("e".into())),
        ];
        for (expected, err) in &variants {
            let msg = format!("{err}");
            assert!(
                msg.contains(expected),
                "expected '{msg}' to contain '{expected}'"
            );
        }
    }

    #[test]
    fn test_evaluate_draw_at_exact_turn_limit() {
        let participants = vec![
            make_participant(Team::Player, 100),
            make_participant(Team::Enemy, 100),
        ];
        let mut state = BattleState::new(participants, empty_move_lookup()).unwrap();
        state.turn_count = MAX_TURNS;
        assert_eq!(state.evaluate_status(), Status::Draw);
        state.turn_count = MAX_TURNS + 1;
        assert_eq!(state.evaluate_status(), Status::Draw);
    }

    #[test]
    fn test_battle_state_apply_status() {
        let participants = vec![
            make_participant(Team::Player, 100),
            make_participant(Team::Enemy, 100),
        ];
        let mut state = BattleState::new(participants, empty_move_lookup()).unwrap();
        state.apply_status(Status::Victory);
        assert_eq!(state.battle_status, Status::Victory);
        assert!(state.battle_log.iter().any(|l| l.contains("Victory")));
    }

    #[test]
    fn test_battle_state_status_effect_configs() {
        let participants = vec![
            make_participant(Team::Player, 100),
            make_participant(Team::Enemy, 100),
        ];
        let state = BattleState::new(participants, empty_move_lookup()).unwrap();
        assert!(state.status_effect_configs.contains_key(&EffectType::Burn));
        assert!(
            state
                .status_effect_configs
                .contains_key(&EffectType::Poison)
        );
        assert!(
            state
                .status_effect_configs
                .contains_key(&EffectType::Confusion)
        );
    }

    #[test]
    fn test_battle_state_evaluate_ignores_non_active() {
        let participants = vec![
            make_participant(Team::Player, 100),
            make_participant(Team::Enemy, 100),
        ];
        let mut state = BattleState::new(participants, empty_move_lookup()).unwrap();
        state.apply_status(Status::Victory);
        assert_eq!(state.evaluate_status(), Status::Victory);
    }
}
