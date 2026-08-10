//! Shared test helpers used by unit and integration tests.
//!
//! Kept public (but hidden from docs) so that integration tests in `tests/`
//! can reuse the same fixtures as the in-crate unit tests.

use std::collections::HashMap;

use xiangke_core::character::{CharacterData, Stats};
use xiangke_core::moves::MoveData;
use xiangke_core::status::StatusEffectData;
use xiangke_core::status::default_configs;
use xiangke_core::types::{DamageCategory, EffectType, StatModTarget, TypeElement};

use crate::participant::{BattleParticipant, Team};

/// Creates a participant with default stats (speed 50) and no moves.
pub fn make_participant(team: Team, hp: u32) -> BattleParticipant {
    make_participant_with_speed(team, hp, 50)
}

/// Creates a participant with the given speed and no moves.
pub fn make_participant_with_speed(team: Team, hp: u32, speed: u32) -> BattleParticipant {
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

/// Creates a character with one damaging move named `{id}_strike`.
pub fn make_fighter(
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

/// Creates a damaging physical move named `{id}_strike`.
pub fn make_strike(id: &str, element: TypeElement, power: u32, accuracy: u32) -> MoveData {
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
        stat_mod_target: StatModTarget::Self_,
        hit_count: 1,
        recoil: 0,
        healing: 0,
        damage_category: DamageCategory::Physical,
        description: "".into(),
    }
}

/// Builds the default status effect config map (Burn, Poison, Confusion).
pub fn make_status_configs() -> HashMap<EffectType, StatusEffectData> {
    default_configs()
}
