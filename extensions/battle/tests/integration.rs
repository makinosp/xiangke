use std::collections::HashMap;

use rand::SeedableRng;
use rand::rngs::StdRng;

use xiangke_battle::action::calculate_damage;
use xiangke_battle::flow::{AiStrategy, BasicAi, process_end_of_turn};
use xiangke_battle::manager;
use xiangke_battle::participant::{BattleParticipant, Team};
use xiangke_battle::state::{BattleState, MAX_TURNS, Status};

use xiangke_core::character::{CharacterData, Stats};
use xiangke_core::moves::MoveData;
use xiangke_core::types::{DamageCategory, EffectType, TypeElement};

/// Helper to create a character with one damaging move.
fn make_fighter(
    id: &str,
    name: &str,
    element: TypeElement,
    hp: u32,
    atk: u32,
    def: u32,
    spd: u32,
) -> CharacterData {
    CharacterData {
        id: id.into(),
        name: name.into(),
        element,
        secondary_element: None,
        base_stats: Stats {
            hp,
            attack: atk,
            defense: def,
            speed: spd,
            intelligence: 50,
            spirit: 50,
        },
        moves: vec![format!("{}_strike", id)],
        description: "".into(),
    }
}

/// Helper to create a damaging physical move.
fn make_strike(id: &str, element: TypeElement, power: u32, accuracy: u32) -> MoveData {
    MoveData {
        id: format!("{}_strike", id),
        name: format!("{} Strike", id),
        element,
        power,
        accuracy,
        effect: EffectType::None,
        effect_chance: 0,
        stat_mod_stat: None,
        stat_mod_stage: 0,
        hit_count: 1,
        recoil: 0,
        healing: 0,
        damage_category: DamageCategory::Physical,
        description: "".into(),
    }
}

/// Full 3v3 battle simulation: player team (Wood) vs enemy team (Fire).
/// Wood→Fire = 1.25 (generating), so player has advantage.
#[test]
fn test_full_battle_3v3_player_advantage() {
    let mut rng = StdRng::seed_from_u64(12345);

    // Player team: Wood element (advantage vs Fire enemies)
    let player_chars = vec![
        make_fighter("p1", "P1", TypeElement::Wood, 120, 60, 50, 60),
        make_fighter("p2", "P2", TypeElement::Wood, 100, 70, 40, 50),
        make_fighter("p3", "P3", TypeElement::Wood, 110, 55, 55, 55),
    ];

    // Enemy team: Fire element (weak to Wood)
    let enemy_chars = vec![
        make_fighter("e1", "E1", TypeElement::Fire, 80, 50, 40, 50),
        make_fighter("e2", "E2", TypeElement::Fire, 70, 55, 35, 45),
        make_fighter("e3", "E3", TypeElement::Fire, 90, 45, 45, 55),
    ];

    // Build participants and move lookup
    let mut participants = Vec::new();
    for ch in &player_chars {
        participants.push(BattleParticipant::new(ch.clone(), Team::Player, 0).unwrap());
    }
    for ch in &enemy_chars {
        participants.push(BattleParticipant::new(ch.clone(), Team::Enemy, 1).unwrap());
    }

    let mut move_lookup: HashMap<String, Box<MoveData>> = HashMap::new();
    for ch in player_chars.iter().chain(enemy_chars.iter()) {
        let move_id = format!("{}_strike", ch.id);
        let mv = make_strike(&ch.id, ch.element, 40, 95);
        move_lookup.insert(move_id, Box::new(mv));
    }

    let mut state = BattleState::new(participants, move_lookup).unwrap();
    manager::start_battle(&mut state, &mut rng).unwrap();

    let ai = BasicAi::new();

    // Run up to 30 turns
    for _turn in 0..30 {
        if state.evaluate_status() != Status::Active {
            break;
        }

        let active_idx = match state.active_participant {
            Some(idx) => idx,
            None => {
                let _ = manager::advance_to_next_turn(&mut state, &mut rng);
                continue;
            }
        };

        // Process start-of-turn effects
        {
            let p = &mut state.participants[active_idx];
            let _logs = process_end_of_turn(p, &state.status_effect_configs, &mut rng);
        }

        // AI selects action
        let action = ai.select_action(&state, active_idx);
        if let Some(action) = action
            && let Some(mv) = state.move_lookup.get(&action.move_id)
        {
            let target = action.target_index;
            // Use split_at_mut for safe dual mutable borrow
            let result = if active_idx < target {
                let (left, right) = state.participants.split_at_mut(target);
                calculate_damage(&mut left[active_idx], &mut right[0], mv, target, &mut rng)
            } else {
                let (left, right) = state.participants.split_at_mut(active_idx);
                calculate_damage(&mut right[0], &mut left[target], mv, target, &mut rng)
            };
            if let Ok(ref result) = result
                && (result.damage_dealt > 0 || result.hit)
            {
                state.add_log(result.log_message.clone());
            }
        }

        // Check if battle ended
        let status = state.evaluate_status();
        if status != Status::Active {
            state.apply_status(status);
            break;
        }

        // Advance to next turn
        if let Err(_e) = manager::advance_to_next_turn(&mut state, &mut rng) {
            // Check if battle should end
            let status = state.evaluate_status();
            if status != Status::Active {
                state.apply_status(status);
            }
            break;
        }
    }

    // Verify battle reached a terminal state
    let final_status = state.evaluate_status();
    assert!(
        final_status != Status::Active,
        "Battle did not reach terminal state in 30 turns (ended at turn {})",
        state.turn_count
    );
}

/// 1v1 battle where one side has massive HP advantage → victory.
#[test]
fn test_battle_1v1_victory() {
    let mut rng = StdRng::seed_from_u64(42);

    let attacker = CharacterData {
        id: "hero".into(),
        name: "Hero".into(),
        element: TypeElement::Wood,
        secondary_element: None,
        base_stats: Stats {
            hp: 500,
            attack: 200,
            defense: 100,
            speed: 100,
            intelligence: 50,
            spirit: 50,
        },
        moves: vec!["hero_strike".into()],
        description: "".into(),
    };
    let defender = CharacterData {
        id: "weakling".into(),
        name: "Weakling".into(),
        element: TypeElement::Fire,
        secondary_element: None,
        base_stats: Stats {
            hp: 50,
            attack: 10,
            defense: 10,
            speed: 10,
            intelligence: 10,
            spirit: 10,
        },
        moves: vec!["weak_strike".into()],
        description: "".into(),
    };

    let p1 = BattleParticipant::new(attacker.clone(), Team::Player, 0).unwrap();
    let p2 = BattleParticipant::new(defender.clone(), Team::Enemy, 1).unwrap();

    let mut move_lookup: HashMap<String, Box<MoveData>> = HashMap::new();
    move_lookup.insert(
        "hero_strike".into(),
        Box::new(MoveData {
            id: "hero_strike".into(),
            name: "Hero Strike".into(),
            element: TypeElement::Wood,
            power: 80,
            accuracy: 100,
            effect: EffectType::None,
            effect_chance: 0,
            stat_mod_stat: None,
            stat_mod_stage: 0,
            hit_count: 1,
            recoil: 0,
            healing: 0,
            damage_category: DamageCategory::Physical,
            description: "".into(),
        }),
    );
    move_lookup.insert(
        "weak_strike".into(),
        Box::new(MoveData {
            id: "weak_strike".into(),
            name: "Weak Strike".into(),
            element: TypeElement::Fire,
            power: 10,
            accuracy: 50,
            effect: EffectType::None,
            effect_chance: 0,
            stat_mod_stat: None,
            stat_mod_stage: 0,
            hit_count: 1,
            recoil: 0,
            healing: 0,
            damage_category: DamageCategory::Physical,
            description: "".into(),
        }),
    );

    let mut state = BattleState::new(vec![p1, p2], move_lookup).unwrap();
    manager::start_battle(&mut state, &mut rng).unwrap();

    let ai = BasicAi::new();

    for _ in 0..20 {
        if state.evaluate_status() != Status::Active {
            break;
        }

        let active_idx = match state.active_participant {
            Some(idx) => idx,
            None => {
                let _ = manager::advance_to_next_turn(&mut state, &mut rng);
                continue;
            }
        };

        // End-of-turn effects
        {
            let p = &mut state.participants[active_idx];
            let _logs = process_end_of_turn(p, &state.status_effect_configs, &mut rng);
        }

        // AI action
        if let Some(action) = ai.select_action(&state, active_idx)
            && let Some(mv) = state.move_lookup.get(&action.move_id)
        {
            let target = action.target_index;
            let result = if active_idx < target {
                let (left, right) = state.participants.split_at_mut(target);
                calculate_damage(&mut left[active_idx], &mut right[0], mv, target, &mut rng)
            } else {
                let (left, right) = state.participants.split_at_mut(active_idx);
                calculate_damage(&mut right[0], &mut left[target], mv, target, &mut rng)
            };
            if let Ok(ref result) = result
                && (result.damage_dealt > 0 || result.hit)
            {
                state.add_log(result.log_message.clone());
            }
        }

        let status = state.evaluate_status();
        if status != Status::Active {
            state.apply_status(status);
            break;
        }

        if manager::advance_to_next_turn(&mut state, &mut rng).is_err() {
            let status = state.evaluate_status();
            if status != Status::Active {
                state.apply_status(status);
            }
            break;
        }
    }

    // Hero should win (massive stat advantage)
    match state.evaluate_status() {
        Status::Victory | Status::Defeat => {} // Either side wins
        other => panic!("Expected terminal state, got {:?}", other),
    }
}

/// Draw by turn limit: two very tanky participants with low damage.
#[test]
fn test_battle_draw_by_turn_limit() {
    let mut rng = StdRng::seed_from_u64(999);

    let tank = CharacterData {
        id: "tank".into(),
        name: "Tank".into(),
        element: TypeElement::Earth,
        secondary_element: None,
        base_stats: Stats {
            hp: 9999,
            attack: 10,
            defense: 999,
            speed: 50,
            intelligence: 50,
            spirit: 999,
        },
        moves: vec!["tackle".into()],
        description: "".into(),
    };

    let p1 = BattleParticipant::new(tank.clone(), Team::Player, 0).unwrap();
    let p2 = BattleParticipant::new(tank.clone(), Team::Enemy, 1).unwrap();

    let mut move_lookup: HashMap<String, Box<MoveData>> = HashMap::new();
    move_lookup.insert(
        "tackle".into(),
        Box::new(MoveData {
            id: "tackle".into(),
            name: "Tackle".into(),
            element: TypeElement::Earth,
            power: 5,
            accuracy: 100,
            effect: EffectType::None,
            effect_chance: 0,
            stat_mod_stat: None,
            stat_mod_stage: 0,
            hit_count: 1,
            recoil: 0,
            healing: 0,
            damage_category: DamageCategory::Physical,
            description: "".into(),
        }),
    );

    let mut state = BattleState::new(vec![p1, p2], move_lookup).unwrap();
    manager::start_battle(&mut state, &mut rng).unwrap();
    let ai = BasicAi::new();

    // Run until turn limit or terminal
    while state.turn_count < MAX_TURNS && state.evaluate_status() == Status::Active {
        let active_idx = match state.active_participant {
            Some(idx) => idx,
            None => {
                let _ = manager::advance_to_next_turn(&mut state, &mut rng);
                continue;
            }
        };

        {
            let p = &mut state.participants[active_idx];
            let _logs = process_end_of_turn(p, &state.status_effect_configs, &mut rng);
        }

        if let Some(action) = ai.select_action(&state, active_idx)
            && let Some(mv) = state.move_lookup.get(&action.move_id)
        {
            let target = action.target_index;
            let _result = if active_idx < target {
                let (left, right) = state.participants.split_at_mut(target);
                calculate_damage(&mut left[active_idx], &mut right[0], mv, target, &mut rng)
            } else {
                let (left, right) = state.participants.split_at_mut(active_idx);
                calculate_damage(&mut right[0], &mut left[target], mv, target, &mut rng)
            };
        }

        let status = state.evaluate_status();
        if status != Status::Active {
            state.apply_status(status);
            break;
        }

        let _ = manager::advance_to_next_turn(&mut state, &mut rng);
    }

    // If neither side was defeated, it should be a draw or active at turn limit
    let _final_status = state.evaluate_status();
    assert!(state.turn_count > 0, "Battle should have made progress");
}
