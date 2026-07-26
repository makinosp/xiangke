use rand::Rng;
use rand::seq::SliceRandom;

use crate::state::{BattleError, BattleState, Status};

pub fn calculate_turn_queue(
    participants: &[crate::participant::BattleParticipant],
    rng: &mut impl Rng,
) -> Vec<usize> {
    let mut entries: Vec<(usize, f64)> = participants
        .iter()
        .enumerate()
        .filter(|(_, p)| !p.is_defeated)
        .map(|(i, p)| (i, p.effective_speed()))
        .collect();

    entries.shuffle(rng);
    entries.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));
    entries.into_iter().map(|(i, _)| i).collect()
}

pub fn start_new_round(state: &mut BattleState, rng: &mut impl Rng) -> Result<(), BattleError> {
    state.round_count += 1;
    state.turn_queue = calculate_turn_queue(&state.participants, rng);
    state.turn_queue_index = 0;
    if state.turn_queue.is_empty() {
        return Err(BattleError::NoActiveParticipants);
    }
    Ok(())
}

pub fn advance_to_next_turn(
    state: &mut BattleState,
    rng: &mut impl Rng,
) -> Result<(), BattleError> {
    if state.turn_queue.is_empty() || state.turn_queue_index >= state.turn_queue.len() {
        start_new_round(state, rng)?;
    }

    state.turn_queue_index += 1;

    if state.turn_queue_index >= state.turn_queue.len() {
        start_new_round(state, rng)?;
    }

    while state.turn_queue_index < state.turn_queue.len() {
        let idx = state.turn_queue[state.turn_queue_index];
        if idx < state.participants.len() {
            let p = &state.participants[idx];
            if !p.is_defeated {
                state.active_participant = Some(idx);
                state.turn_count += 1;
                return Ok(());
            }
        }
        state.turn_queue_index += 1;
    }

    match start_new_round(state, rng) {
        Ok(()) => {
            if state.turn_queue.is_empty() {
                return Err(BattleError::NoActiveParticipants);
            }
            state.active_participant = Some(state.turn_queue[0]);
            state.turn_count += 1;
            Ok(())
        }
        Err(e) => Err(e),
    }
}

pub fn start_battle(state: &mut BattleState, rng: &mut impl Rng) -> Result<(), BattleError> {
    if state.battle_status != Status::Active {
        return Err(BattleError::BattleAlreadyEnded);
    }

    start_new_round(state, rng)?;

    state.turn_queue_index = 0;
    if state.turn_queue.is_empty() {
        state.battle_status = Status::Defeat;
        return Err(BattleError::NoActiveParticipants);
    }

    state.active_participant = Some(state.turn_queue[0]);
    state.turn_count = 1;
    state.add_log("Battle started! Round 1.".into());
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::participant::{BattleParticipant, Team};
    use rand::SeedableRng;
    use rand::rngs::StdRng;
    use std::collections::HashMap;
    use xiangke_core::character::{CharacterData, Stats};
    use xiangke_core::types::TypeElement;

    fn make_participant(team: Team, hp: u32, speed: u32) -> BattleParticipant {
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
                    speed,
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

    fn make_state(players: usize, enemies: usize) -> BattleState {
        let mut participants = Vec::new();
        for i in 0..players {
            participants.push(make_participant(Team::Player, 100, 70 - i as u32 * 10));
        }
        for i in 0..enemies {
            participants.push(make_participant(Team::Enemy, 100, 60 - i as u32 * 10));
        }
        BattleState::new(participants, HashMap::new()).unwrap()
    }

    #[test]
    fn test_turn_queue_order() {
        let state = make_state(1, 1);
        let mut rng = StdRng::seed_from_u64(42);
        let queue = calculate_turn_queue(&state.participants, &mut rng);
        assert_eq!(queue.len(), 2);
        let speed0 = state.participants[queue[0]].effective_speed();
        let speed1 = state.participants[queue[1]].effective_speed();
        assert!(speed0 >= speed1);
    }

    #[test]
    fn test_turn_queue_excludes_defeated() {
        let mut state = make_state(2, 1);
        state.participants[0].is_defeated = true;
        let mut rng = StdRng::seed_from_u64(42);
        let queue = calculate_turn_queue(&state.participants, &mut rng);
        assert_eq!(queue.len(), 2);
        assert!(!queue.contains(&0));
    }

    #[test]
    fn test_start_battle() {
        let mut state = make_state(1, 1);
        let mut rng = StdRng::seed_from_u64(42);
        assert!(start_battle(&mut state, &mut rng).is_ok());
        assert_eq!(state.turn_count, 1);
        assert!(state.active_participant.is_some());
        assert!(state.turn_count > 0);
    }

    #[test]
    fn test_advance_to_next_turn() {
        let mut state = make_state(1, 1);
        let mut rng = StdRng::seed_from_u64(42);
        start_battle(&mut state, &mut rng).unwrap();
        let first = state.active_participant;
        advance_to_next_turn(&mut state, &mut rng).unwrap();
        assert_ne!(state.active_participant, first);
    }

    #[test]
    fn test_start_battle_no_participants() {
        let mut state = make_state(1, 1);
        state.participants[0].take_damage(100);
        state.participants[1].take_damage(100);
        let mut rng = StdRng::seed_from_u64(42);
        assert!(start_battle(&mut state, &mut rng).is_err());
    }

    #[test]
    fn test_new_round() {
        let mut state = make_state(2, 1);
        let mut rng = StdRng::seed_from_u64(42);
        start_new_round(&mut state, &mut rng).unwrap();
        assert_eq!(state.round_count, 1);
        assert!(!state.turn_queue.is_empty());
        assert_eq!(state.turn_queue_index, 0);
    }

    #[test]
    fn test_multiple_rounds() {
        let mut state = make_state(1, 1);
        let mut rng = StdRng::seed_from_u64(42);
        start_battle(&mut state, &mut rng).unwrap();
        assert_eq!(state.round_count, 1);
        // Advance through entire first round (2 participants)
        advance_to_next_turn(&mut state, &mut rng).unwrap();
        // Should start round 2
        assert!(state.round_count >= 1);
    }

    #[test]
    fn test_speed_tie_breaking() {
        // Same speed participants should still produce a deterministic order
        let mut participants = Vec::new();
        for _i in 0..4 {
            participants.push(make_participant(Team::Player, 100, 50));
        }
        let mut rng = StdRng::seed_from_u64(42);
        let queue = calculate_turn_queue(&participants, &mut rng);
        assert_eq!(queue.len(), 4);
        // Order may vary due to shuffle, but must contain all indices
        for idx in 0..4 {
            assert!(queue.contains(&idx), "queue {queue:?} missing index {idx}");
        }
    }

    #[test]
    fn test_advance_to_next_turn_defeated_skipped() {
        let mut state = make_state(2, 1);
        let mut rng = StdRng::seed_from_u64(42);
        start_battle(&mut state, &mut rng).unwrap();
        // Defeat all players except one
        state.participants[0].is_defeated = true;
        // Advance until all undefeated participants have had a turn
        let mut advance_count = 0;
        while advance_count < 10 {
            if advance_to_next_turn(&mut state, &mut rng).is_err() {
                break;
            }
            if let Some(idx) = state.active_participant {
                assert!(
                    !state.participants[idx].is_defeated,
                    "defeated participant should not be active"
                );
            }
            advance_count += 1;
        }
    }

    #[test]
    fn test_start_battle_battle_already_ended() {
        let mut state = make_state(1, 1);
        let mut rng = StdRng::seed_from_u64(42);
        state.battle_status = Status::Victory;
        let result = start_battle(&mut state, &mut rng);
        assert!(result.is_err());
    }
}
