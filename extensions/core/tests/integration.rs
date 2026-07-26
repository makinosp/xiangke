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
        moves: vec![
            "water_surge".into(),
            "wood_heal".into(),
        ],
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

/// Validate two characters from the resource files by their JSON data.
#[test]
fn test_resource_characters_parsable() {
    // These are structured like the .tres JSON content
    let json = r#"{
        "id": "guan_yu",
        "name": "关羽",
        "element": "Wood",
        "secondary_element": null,
        "base_stats": {
            "hp": 120,
            "attack": 95,
            "defense": 80,
            "speed": 65,
            "intelligence": 55,
            "spirit": 60
        },
        "moves": ["iron_cleave", "war_cry"],
        "description": "A powerful warrior of Shu"
    }"#;

    let chara: CharacterData = serde_json::from_str(json).expect("parse guan_yu");
    assert_eq!(chara.id, "guan_yu");
    assert_eq!(chara.element, TypeElement::Wood);
    assert_eq!(chara.base_stats.attack, 95);
    assert!(!chara.has_secondary_type());
    assert_eq!(chara.moves.len(), 2);
}
