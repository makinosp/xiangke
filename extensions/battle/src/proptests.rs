use proptest::prelude::*;
use rand::SeedableRng;

use std::collections::HashMap;

use crate::manager;
use crate::participant::Team;
use crate::state::BattleState;
use crate::test_utils::make_participant_with_speed as make_participant;

#[test]
fn test_participant_initialization_hp() {
    proptest!(|(hp in 1u32..=9999u32)| {
        let p = make_participant(Team::Player, hp, 50);
        prop_assert_eq!(p.current_hp, hp);
        prop_assert_eq!(p.max_hp, hp);
        prop_assert!(!p.is_defeated);
    });
}

#[test]
fn test_take_damage_non_negative() {
    proptest!(|(initial_hp in 1u32..=5000u32, damage in 0u32..=10000u32)| {
        let mut p = make_participant(Team::Player, initial_hp, 50);
        let dealt = p.take_damage(damage);
        if damage >= initial_hp {
            prop_assert!(p.current_hp == 0);
            prop_assert!(p.is_defeated);
            prop_assert_eq!(dealt, initial_hp);
        } else {
            prop_assert_eq!(p.current_hp, initial_hp - damage);
            prop_assert!(!p.is_defeated);
            prop_assert_eq!(dealt, damage);
        }
    });
}

#[test]
fn test_battle_initialization_team_sizes() {
    proptest!(|(size_a in 1usize..=4usize, size_b in 1usize..=4usize)| {
        let mut participants = Vec::new();
        for _ in 0..size_a {
            participants.push(make_participant(Team::Player, 100, 50));
        }
        for _ in 0..size_b {
            participants.push(make_participant(Team::Enemy, 100, 50));
        }
        let state = BattleState::new(participants, HashMap::new());
        prop_assert!(state.is_ok(), "BattleState::new failed: {:?}", state.err());
        let state = state.unwrap();
        prop_assert_eq!(state.turn_count, 0);
        prop_assert_eq!(state.battle_status, crate::state::Status::Active);
    });
}

#[test]
fn test_battle_runs_turns() {
    proptest!(|(size_a in 1usize..=3usize, size_b in 1usize..=3usize)| {
        let mut participants = Vec::new();
        for _ in 0..size_a {
            participants.push(make_participant(Team::Player, 100, 50));
        }
        for _ in 0..size_b {
            participants.push(make_participant(Team::Enemy, 100, 50));
        }
        let mut state = BattleState::new(participants, HashMap::new()).unwrap();
        let mut rng = rand::rngs::StdRng::seed_from_u64(42);
        manager::start_battle(&mut state, &mut rng).unwrap();
        for _ in 0..20 {
            if state.evaluate_status() != crate::state::Status::Active {
                break;
            }
            let _ = manager::advance_to_next_turn(&mut state, &mut rng);
        }
        prop_assert!(state.turn_count > 0 || state.evaluate_status() != crate::state::Status::Active,
            "Battle made no progress");
    });
}
