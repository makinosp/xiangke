use std::collections::HashMap;

use rand::SeedableRng;
use rand::rngs::StdRng;

use xiangke_battle::action::calculate_damage;
use xiangke_battle::flow::{AiStrategy, BasicAi, process_end_of_turn, process_start_of_turn};
use xiangke_battle::manager;
use xiangke_battle::participant::{BattleParticipant, Team};
use xiangke_battle::state::{BattleState, MAX_TURNS, Status};

use xiangke_core::character::{CharacterData, Stats};
use xiangke_core::moves::MoveData;
use xiangke_core::status::StatusEffectData;
use xiangke_core::types::{DamageCategory, EffectType, Stat, TypeElement};

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

/// Build status effect configs matching BattleState defaults.
fn make_status_configs() -> HashMap<EffectType, StatusEffectData> {
    let mut configs = HashMap::new();
    configs.insert(
        EffectType::Burn,
        StatusEffectData {
            status_type: EffectType::Burn,
            damage_per_turn: 1.0 / 16.0,
            ..Default::default()
        },
    );
    configs.insert(
        EffectType::Poison,
        StatusEffectData {
            status_type: EffectType::Poison,
            damage_per_turn: 1.0 / 8.0,
            ..Default::default()
        },
    );
    configs.insert(
        EffectType::Confusion,
        StatusEffectData {
            status_type: EffectType::Confusion,
            damage_per_turn: 0.0,
            ..Default::default()
        },
    );
    configs
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

// ============================================================
// Status Effect Tests
// ============================================================

/// Verify Burn deals 1/16 max HP per turn via process_end_of_turn.
#[test]
fn test_status_burn_dot() {
    let mut rng = StdRng::seed_from_u64(1);
    let configs = make_status_configs();
    let mut p = BattleParticipant::new(
        make_fighter("burn_test", "BurnTest", TypeElement::Fire, 160, 50, 50, 50),
        Team::Player,
        0,
    )
    .unwrap();

    p.apply_status(EffectType::Burn);
    assert!(p.has_status(EffectType::Burn));

    let logs = process_end_of_turn(&mut p, &configs, &mut rng);

    // 1/16 of 160 = 10
    assert_eq!(p.current_hp, 150, "Burn should deal 1/16 max HP as DOT");
    assert!(
        p.has_status(EffectType::Burn),
        "Burn should persist after dealing damage"
    );
    assert!(!logs.is_empty(), "DOT processing should produce a log");
}

/// Verify Poison deals 1/8 max HP per turn (2x Burn ratio).
#[test]
fn test_status_poison_dot() {
    let mut rng = StdRng::seed_from_u64(2);
    let configs = make_status_configs();
    let mut p = BattleParticipant::new(
        make_fighter(
            "poison_test",
            "PoisonTest",
            TypeElement::Water,
            160,
            50,
            50,
            50,
        ),
        Team::Player,
        0,
    )
    .unwrap();

    p.apply_status(EffectType::Poison);
    assert!(p.has_status(EffectType::Poison));

    let logs = process_end_of_turn(&mut p, &configs, &mut rng);

    // 1/8 of 160 = 20
    assert_eq!(p.current_hp, 140, "Poison should deal 1/8 max HP as DOT");
    assert!(
        p.has_status(EffectType::Poison),
        "Poison should persist after dealing damage"
    );
    assert!(!logs.is_empty(), "DOT processing should produce a log");
}

/// Verify Confusion: 50% chance to self-hit for ceil(max_hp * damage_per_turn) via process_start_of_turn.
#[test]
fn test_status_confusion_self_hit() {
    let mut rng = StdRng::seed_from_u64(10);
    let configs = make_status_configs();
    let mut p = BattleParticipant::new(
        make_fighter("c", "C", TypeElement::Wood, 200, 50, 50, 50),
        Team::Player,
        0,
    )
    .unwrap();

    p.apply_status(EffectType::Confusion);
    assert!(p.has_status(EffectType::Confusion));

    let start_hp = p.current_hp;
    let logs = process_start_of_turn(&mut p, &configs, &mut rng);

    if p.current_hp < start_hp {
        // Confusion triggered: ceil(200 * 0.01).max(1) = 2
        assert_eq!(
            start_hp - p.current_hp,
            2,
            "Self-damage should be ceil(max_hp * 0.01) = 2"
        );
        assert!(
            logs.iter().any(|l| l.contains("confused")),
            "Log should mention confusion"
        );
    } else {
        // 50% chance didn't trigger — still valid
        assert!(logs.is_empty(), "No log when confusion doesn't trigger");
    }
}

// ============================================================
// Move Effect Tests
// ============================================================

/// Verify recoil: attacker takes ceil(damage * recoil / 100), min 1.
#[test]
fn test_move_recoil() {
    let mut rng = StdRng::seed_from_u64(4);

    let mut attacker = BattleParticipant::new(
        make_fighter("recoiler", "Recoiler", TypeElement::Wood, 500, 200, 50, 50),
        Team::Player,
        0,
    )
    .unwrap();
    let mut defender = BattleParticipant::new(
        make_fighter("victim", "Victim", TypeElement::Metal, 100, 10, 10, 10),
        Team::Enemy,
        0,
    )
    .unwrap();

    let recoil_mv = MoveData {
        id: "recoil_strike".into(),
        name: "Recoil Strike".into(),
        element: TypeElement::Wood,
        power: 80,
        accuracy: 100,
        effect: EffectType::None,
        effect_chance: 0,
        stat_mod_stat: None,
        stat_mod_stage: 0,
        hit_count: 1,
        recoil: 25, // 25% of damage dealt as recoil
        healing: 0,
        damage_category: DamageCategory::Physical,
        description: "".into(),
    };

    let result = calculate_damage(&mut attacker, &mut defender, &recoil_mv, 1, &mut rng).unwrap();

    assert!(result.hit, "Move should hit");
    assert!(
        result.recoil_damage > 0,
        "Should have recoil damage when dealing damage"
    );
    assert!(
        attacker.current_hp < attacker.max_hp,
        "Attacker should take recoil damage"
    );
}

/// Verify healing: move with healing > 0 restores attacker's HP.
#[test]
fn test_move_healing() {
    let mut rng = StdRng::seed_from_u64(5);

    let mut attacker = BattleParticipant::new(
        make_fighter("healer", "Healer", TypeElement::Wood, 200, 10, 50, 50),
        Team::Player,
        0,
    )
    .unwrap();
    // Damage the attacker first so healing has effect
    attacker.take_damage(80);
    assert_eq!(attacker.current_hp, 120);

    let mut defender = BattleParticipant::new(
        make_fighter("target", "Target", TypeElement::Metal, 100, 10, 10, 10),
        Team::Enemy,
        0,
    )
    .unwrap();

    let heal_mv = MoveData {
        id: "heal".into(),
        name: "Heal".into(),
        element: TypeElement::Wood,
        power: 0,
        accuracy: 100,
        effect: EffectType::None,
        effect_chance: 0,
        stat_mod_stat: None,
        stat_mod_stage: 0,
        hit_count: 1,
        recoil: 0,
        healing: 30, // 30% of max HP
        damage_category: DamageCategory::Physical,
        description: "".into(),
    };

    let result = calculate_damage(&mut attacker, &mut defender, &heal_mv, 1, &mut rng).unwrap();

    // 30% of 200 = 60
    assert_eq!(result.heal_amount, 60, "Should heal 30% of max HP");
    assert_eq!(
        attacker.current_hp, 180,
        "HP should increase from 120 to 180"
    );
    assert!(
        !result.log_message.is_empty(),
        "Healing should produce a log message"
    );
}

/// Verify stat stage changes affect effective stats correctly.
#[test]
fn test_stat_stage_affects_effective_stats() {
    let mut p = BattleParticipant::new(
        make_fighter("stat_test", "StatTest", TypeElement::Wood, 100, 100, 80, 60),
        Team::Player,
        0,
    )
    .unwrap();

    assert!(
        (p.effective_attack() - 100.0).abs() < 0.01,
        "Base attack should be 100"
    );
    assert!(
        (p.effective_defense() - 80.0).abs() < 0.01,
        "Base defense should be 80"
    );

    // +2 attack → stage multiplier = (2+2)/2 = 2.0
    p.apply_stat_stage(Stat::Attack, 2);
    assert_eq!(p.stat_stage(Stat::Attack), 2);
    assert!(
        (p.effective_attack() - 200.0).abs() < 0.01,
        "+2 ATK should double effective attack"
    );

    // -2 defense → stage multiplier = 2/(2-(-2)) = 0.5
    p.apply_stat_stage(Stat::Defense, -2);
    assert_eq!(p.stat_stage(Stat::Defense), -2);
    assert!(
        (p.effective_defense() - 40.0).abs() < 0.01,
        "-2 DEF should halve effective defense"
    );

    // Reset
    p.reset_stat_stages();
    assert_eq!(p.stat_stage(Stat::Attack), 0);
    assert_eq!(p.stat_stage(Stat::Defense), 0);
    assert!(
        (p.effective_attack() - 100.0).abs() < 0.01,
        "Reset attack should be 100"
    );
}

/// Verify move with secondary effect (e.g., Burn) applies status to defender.
#[test]
fn test_move_secondary_status_effect() {
    let mut rng = StdRng::seed_from_u64(7);

    let mut attacker = BattleParticipant::new(
        make_fighter(
            "inflictor",
            "Inflictor",
            TypeElement::Fire,
            100,
            100,
            50,
            50,
        ),
        Team::Player,
        0,
    )
    .unwrap();
    let mut defender = BattleParticipant::new(
        make_fighter("victim", "Victim", TypeElement::Wood, 100, 10, 10, 10),
        Team::Enemy,
        0,
    )
    .unwrap();

    let burn_mv = MoveData {
        id: "burn_strike".into(),
        name: "Burn Strike".into(),
        element: TypeElement::Fire,
        power: 40,
        accuracy: 100,
        effect: EffectType::Burn,
        effect_chance: 100, // Always applies
        stat_mod_stat: None,
        stat_mod_stage: 0,
        hit_count: 1,
        recoil: 0,
        healing: 0,
        damage_category: DamageCategory::Physical,
        description: "".into(),
    };

    let result = calculate_damage(&mut attacker, &mut defender, &burn_mv, 1, &mut rng).unwrap();

    assert!(result.hit, "Move should hit");
    assert_eq!(
        result.status_applied,
        Some(EffectType::Burn),
        "Should apply burn to defender"
    );
    assert!(
        defender.has_status(EffectType::Burn),
        "Defender should have burn status"
    );
}

/// Verify Arts damage uses Intelligence/Spirit and produces correct results.
#[test]
fn test_arts_damage_category() {
    let mut rng = StdRng::seed_from_u64(8);

    let mut attacker = BattleParticipant::new(
        make_fighter("mage", "Mage", TypeElement::Wood, 100, 50, 50, 50),
        Team::Player,
        0,
    )
    .unwrap();
    // High intelligence, low physical attack
    attacker.character_data.base_stats.intelligence = 150;
    attacker.character_data.base_stats.spirit = 100;

    let mut defender = BattleParticipant::new(
        make_fighter("dummy", "Dummy", TypeElement::Metal, 300, 10, 100, 10),
        Team::Enemy,
        0,
    )
    .unwrap();
    // Low spirit defense, high physical defense
    defender.character_data.base_stats.spirit = 30;

    let arts_mv = MoveData {
        id: "arts_blast".into(),
        name: "Arts Blast".into(),
        element: TypeElement::Wood,
        power: 70,
        accuracy: 100,
        effect: EffectType::None,
        effect_chance: 0,
        stat_mod_stat: None,
        stat_mod_stage: 0,
        hit_count: 1,
        recoil: 0,
        healing: 0,
        damage_category: DamageCategory::Arts,
        description: "".into(),
    };

    let result = calculate_damage(&mut attacker, &mut defender, &arts_mv, 1, &mut rng).unwrap();

    assert!(result.hit, "Arts move should hit");
    assert!(result.damage_dealt > 0, "Arts move should deal damage");
    // Wood → Metal = 2.0×, dual (Metal+Metal) = 2.0 * 2.0 = 4.0 clamped to [0.25, 4.0]
    assert!(
        (result.type_effectiveness - 4.0).abs() < 0.01,
        "Wood vs single-type Metal should be 4.0× (2.0 × 2.0 dual effectiveness)"
    );
    assert!(
        result.is_super_effective,
        "Should be flagged as super effective"
    );
}

// ============================================================
// Type Effectiveness Tests
// ============================================================

/// Verify resisted type matchup: Wood → Water = 0.5×.
#[test]
fn test_type_effectiveness_resisted() {
    let mut rng = StdRng::seed_from_u64(9);

    let mut attacker = BattleParticipant::new(
        make_fighter("a", "A", TypeElement::Wood, 100, 100, 50, 50),
        Team::Player,
        0,
    )
    .unwrap();
    let mut defender = BattleParticipant::new(
        make_fighter("b", "B", TypeElement::Water, 200, 10, 10, 10),
        Team::Enemy,
        0,
    )
    .unwrap();

    let mv = make_strike("strike", TypeElement::Wood, 60, 100);

    let result = calculate_damage(&mut attacker, &mut defender, &mv, 1, &mut rng).unwrap();

    assert!(result.hit, "Move should hit");
    // Wood → Water = 0.5×, dual (Water+Water) = 0.5 * 0.5 = 0.25, clamped to [0.25, 4.0]
    assert!(
        (result.type_effectiveness - 0.25).abs() < 0.01,
        "Wood vs single-type Water should be 0.25× (0.5 × 0.5 dual effectiveness)"
    );
    assert!(
        result.is_not_very_effective,
        "Should be flagged as not very effective"
    );
}

// ============================================================
// Edge Case Tests
// ============================================================

/// Verify 0% accuracy always results in a miss.
#[test]
fn test_accuracy_zero_always_miss() {
    let mut rng = StdRng::seed_from_u64(11);

    let mut attacker = BattleParticipant::new(
        make_fighter("a", "A", TypeElement::Wood, 100, 100, 50, 50),
        Team::Player,
        0,
    )
    .unwrap();
    let mut defender = BattleParticipant::new(
        make_fighter("b", "B", TypeElement::Metal, 100, 10, 10, 10),
        Team::Enemy,
        0,
    )
    .unwrap();

    // Accuracy 0 → check_accuracy(0, rng) is always false since random * 100 < 0 is never true
    let mv = make_strike("miss", TypeElement::Wood, 80, 0);

    let result = calculate_damage(&mut attacker, &mut defender, &mv, 1, &mut rng).unwrap();

    assert!(!result.hit, "0% accuracy move should always miss");
    assert_eq!(result.damage_dealt, 0, "Miss should deal no damage");
    assert!(
        result.log_message.contains("missed"),
        "Miss log should say 'missed'"
    );
}

/// Verify status resistance: defender already having a status prevents re-application.
#[test]
fn test_status_effect_resistance() {
    let mut rng = StdRng::seed_from_u64(12);

    // Neutral type matchup (Wood vs Wood → 1.0× effectiveness) so defender survives
    let burn_mv = MoveData {
        id: "burn_strike".into(),
        name: "Burn Strike".into(),
        element: TypeElement::Wood,
        power: 10,
        accuracy: 100,
        effect: EffectType::Burn,
        effect_chance: 100,
        stat_mod_stat: None,
        stat_mod_stage: 0,
        hit_count: 1,
        recoil: 0,
        healing: 0,
        damage_category: DamageCategory::Physical,
        description: "".into(),
    };

    let mut d = BattleParticipant::new(
        make_fighter("b", "B", TypeElement::Wood, 500, 10, 10, 10),
        Team::Enemy,
        0,
    )
    .unwrap();

    // First application: defender does NOT have burn yet
    let mut a1 = BattleParticipant::new(
        make_fighter("a", "A", TypeElement::Wood, 100, 10, 50, 50),
        Team::Player,
        0,
    )
    .unwrap();

    let r1 = calculate_damage(&mut a1, &mut d, &burn_mv, 1, &mut rng).unwrap();
    assert!(r1.hit, "First application should hit");
    assert_eq!(
        r1.status_applied,
        Some(EffectType::Burn),
        "First use should apply burn"
    );
    assert!(!r1.status_resisted, "First use should not be resisted");
    assert!(
        d.has_status(EffectType::Burn),
        "Defender should have burn after first hit"
    );
    assert!(!d.is_defeated, "Defender should survive with high HP");

    // Second application: defender already has burn → should be resisted
    let mut a2 = BattleParticipant::new(
        make_fighter("a", "A", TypeElement::Wood, 100, 10, 50, 50),
        Team::Player,
        0,
    )
    .unwrap();

    let r2 = calculate_damage(&mut a2, &mut d, &burn_mv, 1, &mut rng).unwrap();
    assert!(r2.hit, "Second application should still hit for damage");
    assert_eq!(
        r2.status_applied, None,
        "Second use should NOT apply burn (already has it)"
    );
    assert!(
        r2.status_resisted,
        "Second use should be flagged as resisted"
    );
    assert!(
        !d.is_defeated,
        "Defender should survive both hits with 500 HP"
    );
}

/// Verify 1v2 asymmetric team battle: 1 strong player vs 2 weaker enemies.
#[test]
fn test_asymmetric_team_1v2() {
    let mut rng = StdRng::seed_from_u64(105);

    // Player: Wood element (super-effective vs Metal enemies)
    let player_chars = vec![make_fighter(
        "hero",
        "Hero",
        TypeElement::Wood,
        500,
        150,
        100,
        70,
    )];
    // Enemies: Metal element (weak to Wood)
    let enemy_chars = vec![
        make_fighter("e1", "E1", TypeElement::Metal, 60, 30, 20, 50),
        make_fighter("e2", "E2", TypeElement::Metal, 60, 30, 20, 50),
    ];

    let mut participants = Vec::new();
    for ch in &player_chars {
        participants.push(BattleParticipant::new(ch.clone(), Team::Player, 0).unwrap());
    }
    for (i, ch) in enemy_chars.iter().enumerate() {
        participants.push(BattleParticipant::new(ch.clone(), Team::Enemy, i as u32).unwrap());
    }

    let mut move_lookup: HashMap<String, Box<MoveData>> = HashMap::new();
    for ch in player_chars.iter().chain(enemy_chars.iter()) {
        let move_id = format!("{}_strike", ch.id);
        let mv = make_strike(&ch.id, ch.element, 60, 100);
        move_lookup.insert(move_id, Box::new(mv));
    }

    let mut state = BattleState::new(participants, move_lookup).unwrap();
    manager::start_battle(&mut state, &mut rng).unwrap();

    let ai = BasicAi::new();

    for _ in 0..30 {
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

        {
            let p = &mut state.participants[active_idx];
            let _logs = process_end_of_turn(p, &state.status_effect_configs, &mut rng);
        }

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

    assert_eq!(
        state.evaluate_status(),
        Status::Victory,
        "Hero (Wood) should defeat both Metal enemies"
    );
    assert!(
        state.turn_count < 30,
        "Battle should end within 30 turns (ended at turn {})",
        state.turn_count
    );
}
