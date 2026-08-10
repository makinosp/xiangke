//! xiangke-checker: dev CLI that validates exported game data against the
//! authoritative core schema and rules.
//!
//! Usage:
//!   cargo run -p xiangke_checker -- validate <export.json>
//!
//! The input JSON is produced by the Godot export scene
//! (`tools/data_export.tscn`). Each entity is checked twice:
//!   1. Strict schema check: JSON keys must exactly match the core struct
//!      fields (serde alone silently ignores unknown fields, so drift in
//!      field names would otherwise go unnoticed).
//!   2. Rule validation: the same `validate_move` / `validate_character`
//!      functions the core itself uses.
//!
//! Exit codes: 0 = valid, 1 = validation errors, 2 = usage error.

use std::collections::HashSet;
use std::env;
use std::fs;
use std::process::ExitCode;

use serde_json::Value;
use xiangke_core::character::CharacterData;
use xiangke_core::moves::MoveData;
use xiangke_core::validator::{ValidationResult, validate_character, validate_move};

/// Expected JSON keys for the core `CharacterData` struct.
const CHARACTER_KEYS: [&str; 7] = [
    "id",
    "name",
    "element",
    "secondary_element",
    "base_stats",
    "moves",
    "description",
];

/// Expected JSON keys for the core `Stats` struct.
const STATS_KEYS: [&str; 6] = ["hp", "attack", "defense", "speed", "intelligence", "spirit"];

/// Expected JSON keys for the core `MoveData` struct.
const MOVE_KEYS: [&str; 15] = [
    "id",
    "name",
    "element",
    "power",
    "accuracy",
    "effect",
    "effect_chance",
    "stat_mod_stat",
    "stat_mod_stage",
    "stat_mod_target",
    "hit_count",
    "recoil",
    "healing",
    "damage_category",
    "description",
];

fn main() -> ExitCode {
    let args: Vec<String> = env::args().skip(1).collect();

    if args.len() != 2 || args[0] != "validate" {
        eprintln!("Usage: xiangke-checker validate <export.json>");
        return ExitCode::from(2);
    }

    let path = &args[1];
    let text = match fs::read_to_string(path) {
        Ok(t) => t,
        Err(e) => {
            eprintln!("xiangke-checker: cannot read '{path}': {e}");
            return ExitCode::from(1);
        }
    };

    let root: Value = match serde_json::from_str(&text) {
        Ok(v) => v,
        Err(e) => {
            eprintln!("xiangke-checker: '{path}' is not valid JSON: {e}");
            return ExitCode::from(1);
        }
    };

    let mut result = ValidationResult::new();

    let characters = match root.get("characters").and_then(Value::as_array) {
        Some(arr) => arr,
        None => {
            eprintln!("xiangke-checker: missing 'characters' array in '{path}'");
            return ExitCode::from(1);
        }
    };
    let moves = match root.get("moves").and_then(Value::as_array) {
        Some(arr) => arr,
        None => {
            eprintln!("xiangke-checker: missing 'moves' array in '{path}'");
            return ExitCode::from(1);
        }
    };

    result.total_files_scanned = (characters.len() + moves.len()) as u32;

    let mut parsed_moves: Vec<MoveData> = Vec::new();
    for (idx, mv) in moves.iter().enumerate() {
        let id = entity_id(mv, idx);
        if let Some(issue) = check_keys(mv, &MOVE_KEYS, "move", &id) {
            result.add_error("SCHEMA-1", &issue, &id);
            result.invalid_files += 1;
            continue;
        }
        match serde_json::from_value::<MoveData>(mv.clone()) {
            Ok(parsed) => {
                if let Err(errors) = validate_move(&parsed) {
                    for err in errors {
                        result.add_error(&err.code, &err.message, &err.context);
                    }
                    result.invalid_files += 1;
                } else {
                    result.valid_files += 1;
                }
                parsed_moves.push(parsed);
            }
            Err(e) => {
                result.add_error("SCHEMA-2", &format!("deserialization failed: {e}"), &id);
                result.invalid_files += 1;
            }
        }
    }

    for (idx, c) in characters.iter().enumerate() {
        let id = entity_id(c, idx);
        if let Some(issue) = check_keys(c, &CHARACTER_KEYS, "character", &id) {
            result.add_error("SCHEMA-1", &issue, &id);
            result.invalid_files += 1;
            continue;
        }
        // The base_stats object has its own key set.
        if let Some(stats) = c.get("base_stats")
            && let Some(issue) = check_keys(stats, &STATS_KEYS, "base_stats", &id)
        {
            result.add_error("SCHEMA-1", &issue, &id);
            result.invalid_files += 1;
            continue;
        }
        match serde_json::from_value::<CharacterData>(c.clone()) {
            Ok(parsed) => {
                if let Err(errors) = validate_character(&parsed, &parsed_moves) {
                    for err in errors {
                        result.add_error(&err.code, &err.message, &err.context);
                    }
                    result.invalid_files += 1;
                } else {
                    result.valid_files += 1;
                }
            }
            Err(e) => {
                result.add_error("SCHEMA-2", &format!("deserialization failed: {e}"), &id);
                result.invalid_files += 1;
            }
        }
    }

    if result.is_valid() {
        println!("{}", result.get_summary());
        ExitCode::SUCCESS
    } else {
        eprintln!("{}", result.get_summary());
        ExitCode::from(1)
    }
}

/// Returns the entity's `id` field when present, else its array index.
fn entity_id(value: &Value, index: usize) -> String {
    value
        .get("id")
        .and_then(Value::as_str)
        .map(str::to_string)
        .unwrap_or_else(|| format!("<index {index}>"))
}

/// Checks that `obj` has exactly the expected keys.
///
/// Returns `Some(message)` describing unknown/missing fields, or `None` when
/// the key set matches exactly.
fn check_keys(obj: &Value, expected: &[&str], kind: &str, id: &str) -> Option<String> {
    let map = obj.as_object()?;
    let expected_set: HashSet<&str> = expected.iter().copied().collect();
    let actual_set: HashSet<&str> = map.keys().map(String::as_str).collect();

    let mut extra: Vec<&str> = actual_set.difference(&expected_set).copied().collect();
    let mut missing: Vec<&str> = expected_set.difference(&actual_set).copied().collect();
    extra.sort();
    missing.sort();

    let mut issues = Vec::new();
    if !extra.is_empty() {
        issues.push(format!("unknown field(s): {}", extra.join(", ")));
    }
    if !missing.is_empty() {
        issues.push(format!("missing field(s): {}", missing.join(", ")));
    }
    if issues.is_empty() {
        None
    } else {
        Some(format!("{kind} '{id}' {}", issues.join("; ")))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn check_keys_exact_match_is_ok() {
        let obj = json!({ "id": "a", "name": "b" });
        assert_eq!(check_keys(&obj, &["id", "name"], "move", "a"), None);
    }

    #[test]
    fn check_keys_reports_unknown_fields() {
        let obj = json!({ "id": "a", "name": "b", "extra_field": 1 });
        let issue = check_keys(&obj, &["id", "name"], "move", "a").expect("issue");
        assert!(issue.contains("unknown field(s): extra_field"), "{issue}");
        assert!(!issue.contains("missing"), "{issue}");
    }

    #[test]
    fn check_keys_reports_missing_fields() {
        let obj = json!({ "id": "a" });
        let issue = check_keys(&obj, &["id", "name"], "move", "a").expect("issue");
        assert!(issue.contains("missing field(s): name"), "{issue}");
        assert!(!issue.contains("unknown"), "{issue}");
    }

    #[test]
    fn check_keys_reports_extra_and_missing_sorted() {
        let obj = json!({ "id": "a", "zeta": 1 });
        let issue = check_keys(&obj, &["id", "alpha"], "move", "a").expect("issue");
        assert!(issue.contains("unknown field(s): zeta"), "{issue}");
        assert!(issue.contains("missing field(s): alpha"), "{issue}");
        assert!(issue.find("zeta") < issue.find("alpha"), "{issue}");
    }

    #[test]
    fn check_keys_non_object_returns_none() {
        assert_eq!(check_keys(&json!(42), &["id"], "move", "a"), None);
    }
}
