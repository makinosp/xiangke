use std::fs;
use xiangke_core::character::{CharacterData, Stats};
use xiangke_core::moves::MoveData;
use xiangke_core::status::StatusEffectData;
use xiangke_core::types::{DamageCategory, EffectType, Stat, TypeElement};

/// JSON serialization roundtrip for CharacterData.
#[test]
fn test_character_serde_roundtrip() {
    let original = CharacterData {
        id: "guan_yu".into(),
        name: "関羽".into(),
        element: TypeElement::Wood,
        secondary_element: None,
        base_stats: Stats {
            hp: 100,
            attack: 80,
            defense: 70,
            speed: 60,
            intelligence: 50,
            spirit: 50,
        },
        moves: vec!["metal_slash".into(), "war_cry".into()],
        description: "Wu general".into(),
    };

    let json = serde_json::to_string_pretty(&original).expect("serialize");
    let deserialized: CharacterData = serde_json::from_str(&json).expect("deserialize");

    assert_eq!(deserialized.id, original.id);
    assert_eq!(deserialized.name, original.name);
    assert_eq!(deserialized.element, original.element);
    assert_eq!(deserialized.secondary_element, original.secondary_element);
    assert_eq!(deserialized.base_stats.hp, original.base_stats.hp);
    assert_eq!(deserialized.moves, original.moves);
    assert_eq!(deserialized.get_stat_sum(), 100 + 80 + 70 + 60 + 50 + 50);
}

/// JSON serialization roundtrip for MoveData.
#[test]
fn test_move_serde_roundtrip() {
    let original = MoveData {
        id: "fire_strike".into(),
        name: "火炎斬".into(),
        element: TypeElement::Fire,
        power: 60,
        accuracy: 95,
        effect: EffectType::Burn,
        effect_chance: 30,
        stat_mod_stat: Some(Stat::Defense),
        stat_mod_stage: -1,
        hit_count: 1,
        recoil: 0,
        healing: 0,
        damage_category: DamageCategory::Physical,
        description: "A fiery slash".into(),
    };

    let json = serde_json::to_string_pretty(&original).expect("serialize");
    let deserialized: MoveData = serde_json::from_str(&json).expect("deserialize");

    assert_eq!(deserialized.id, original.id);
    assert_eq!(deserialized.element, original.element);
    assert_eq!(deserialized.power, 60);
    assert!(deserialized.is_damaging());
    assert!(deserialized.has_stat_mod());
}

/// JSON serialization roundtrip for StatusEffectData.
#[test]
fn test_status_serde_roundtrip() {
    let original = StatusEffectData {
        status_type: EffectType::Poison,
        name: "Poison".into(),
        description: "Deals damage over time".into(),
        damage_per_turn: 0.125,
        escalating: true,
        max_damage_cap: 0.25,
        stat_mod_stat: Some(Stat::Speed),
        stat_mod_multiplier: 0.5,
    };

    let json = serde_json::to_string_pretty(&original).expect("serialize");
    let deserialized: StatusEffectData = serde_json::from_str(&json).expect("deserialize");

    assert_eq!(deserialized.status_type, EffectType::Poison);
    assert!(deserialized.has_damage_over_time());
    assert!(deserialized.has_stat_modification());
}

/// Character with secondary type serializes correctly.
#[test]
fn test_character_secondary_type_serde() {
    let chara = CharacterData {
        id: "zhuge_liang".into(),
        name: "諸葛亮".into(),
        element: TypeElement::Water,
        secondary_element: Some(TypeElement::Wood),
        base_stats: Stats {
            hp: 80,
            attack: 30,
            defense: 40,
            speed: 70,
            intelligence: 100,
            spirit: 90,
        },
        moves: vec!["water_surge".into(), "wood_heal".into()],
        description: "Shu strategist".into(),
    };

    let json = serde_json::to_string(&chara).expect("serialize");
    let deserialized: CharacterData = serde_json::from_str(&json).expect("deserialize");

    assert!(deserialized.has_secondary_type());
    assert_eq!(deserialized.secondary_element, Some(TypeElement::Wood));
}

/// Type chart produces expected effectiveness for real character pairings.
#[test]
fn test_type_chart_character_scenario() {
    let chart = xiangke_core::types::TypeChart::default();

    // Guan Yu (Wood) attacks Zhou Yu (Fire) → generating = 1.25
    let eff = chart.effectiveness(TypeElement::Wood, TypeElement::Fire);
    assert!((eff - 1.25).abs() < f64::EPSILON, "Wood→Fire = {eff}");

    // Zhou Yu (Fire) attacks Zhuge Liang (Water) → strong = 2.0
    let eff = chart.effectiveness(TypeElement::Fire, TypeElement::Water);
    assert!((eff - 2.0).abs() < f64::EPSILON, "Fire→Water = {eff}");

    // Zhuge Liang (Water) attacks Guan Yu (Wood) → generating = 1.25
    let eff = chart.effectiveness(TypeElement::Water, TypeElement::Wood);
    assert!((eff - 1.25).abs() < f64::EPSILON, "Water→Wood = {eff}");
}

/// Load and validate all real resource data from the exported fixture.
///
/// This test ensures the actual .tres resource files (exported via the
/// Godot export scene) deserialize correctly into the core structs and
/// pass the core validation rules. The fixture is generated by
/// `just verify-data --update-fixture`.
#[test]
fn test_resource_fixture_parsable_and_valid() {
    let fixture_path = concat!(env!("CARGO_MANIFEST_DIR"), "/tests/fixtures/resources.json");
    let json = fs::read_to_string(fixture_path).expect("read fixture");
    let root: serde_json::Value = serde_json::from_str(&json).expect("parse fixture");

    let characters = root
        .get("characters")
        .and_then(|v| v.as_array())
        .expect("characters array");
    let moves = root
        .get("moves")
        .and_then(|v| v.as_array())
        .expect("moves array");

    // Deserialize all moves first (characters reference them)
    let mut parsed_moves: Vec<MoveData> = Vec::new();
    for mv in moves {
        let parsed: MoveData = serde_json::from_value(mv.clone()).expect("deserialize move");
        parsed_moves.push(parsed);
    }

    // Deserialize and validate all characters
    for c in characters {
        let chara: CharacterData =
            serde_json::from_value(c.clone()).expect("deserialize character");
        // Validate against core rules
        let result = xiangke_core::validator::validate_character(&chara, &parsed_moves);
        assert!(
            result.is_ok(),
            "character '{}' validation failed: {:?}",
            chara.id,
            result
        );
    }

    // Validate all moves
    for mv in &parsed_moves {
        let result = xiangke_core::validator::validate_move(mv);
        assert!(
            result.is_ok(),
            "move '{}' validation failed: {:?}",
            mv.id,
            result
        );
    }

    // Sanity: we expect at least the current character/move counts
    assert!(
        characters.len() >= 38,
        "expected at least 38 characters, got {}",
        characters.len()
    );
    assert!(
        moves.len() >= 8,
        "expected at least 8 moves, got {}",
        moves.len()
    );
}
