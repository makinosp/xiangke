use std::fmt;

use crate::types::EffectType;

#[derive(Debug, Clone)]
pub struct ValidationError {
    pub code: String,
    pub message: String,
    pub context: String,
}

impl fmt::Display for ValidationError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        if self.context.is_empty() {
            write!(f, "[{}] {}", self.code, self.message)
        } else {
            write!(f, "[{}] {}: {}", self.code, self.context, self.message)
        }
    }
}

#[derive(Debug, Clone)]
pub struct ValidationWarning {
    pub code: String,
    pub message: String,
    pub context: String,
}

impl fmt::Display for ValidationWarning {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        if self.context.is_empty() {
            write!(f, "[{}] {}", self.code, self.message)
        } else {
            write!(f, "[{}] {}: {}", self.code, self.context, self.message)
        }
    }
}

#[derive(Debug, Clone)]
pub struct ValidationResult {
    pub errors: Vec<ValidationError>,
    pub warnings: Vec<ValidationWarning>,
    pub total_files_scanned: u32,
    pub valid_files: u32,
    pub invalid_files: u32,
}

impl ValidationResult {
    pub fn new() -> Self {
        Self {
            errors: Vec::new(),
            warnings: Vec::new(),
            total_files_scanned: 0,
            valid_files: 0,
            invalid_files: 0,
        }
    }

    pub fn add_error(&mut self, code: &str, message: &str, context: &str) {
        self.errors.push(ValidationError {
            code: code.to_string(),
            message: message.to_string(),
            context: context.to_string(),
        });
    }

    pub fn add_warning(&mut self, code: &str, message: &str, context: &str) {
        self.warnings.push(ValidationWarning {
            code: code.to_string(),
            message: message.to_string(),
            context: context.to_string(),
        });
    }

    pub fn is_valid(&self) -> bool {
        self.errors.is_empty()
    }

    pub fn get_summary(&self) -> String {
        let mut result = String::from("=== Data Validation Summary ===\n");
        result.push_str(&format!("Files scanned: {}\n", self.total_files_scanned));
        result.push_str(&format!("Valid: {} | Invalid: {}\n", self.valid_files, self.invalid_files));
        if !self.errors.is_empty() {
            result.push_str(&format!("\n--- Errors ({}) ---\n", self.errors.len()));
            for err in &self.errors {
                result.push_str(&format!("{err}\n"));
            }
        }
        if !self.warnings.is_empty() {
            result.push_str(&format!("\n--- Warnings ({}) ---\n", self.warnings.len()));
            for warn in &self.warnings {
                result.push_str(&format!("{warn}\n"));
            }
        }
        result.push_str(&format!(
            "\nValidation complete. {} errors, {} warnings.",
            self.errors.len(),
            self.warnings.len()
        ));
        result
    }
}

impl Default for ValidationResult {
    fn default() -> Self {
        Self::new()
    }
}

fn is_valid_id_format(id: &str) -> bool {
    if id.is_empty() || id.len() > 50 {
        return false;
    }
    let mut chars = id.chars();
    match chars.next() {
        Some(c) if c.is_ascii_lowercase() => {}
        _ => return false,
    }
    for c in chars {
        if !c.is_ascii_lowercase() && !c.is_ascii_digit() && c != '_' {
            return false;
        }
    }
    true
}

fn is_in_range(value: u32, min_val: u32, max_val: u32) -> bool {
    value >= min_val && value <= max_val
}

fn is_valid_type(value: u32) -> bool {
    value <= 6
}

fn is_valid_effect_type(value: u32) -> bool {
    value <= 5
}

fn is_valid_stat(value: u32) -> bool {
    value <= 4
}

pub fn validate_type_chart(chart: &[[f64; 7]; 7]) -> Result<(), Vec<ValidationError>> {
    let mut errors = Vec::new();

    // TR-1: chart must be 7x7 (guaranteed by type system, check remains for completeness)
    // TR-2: Diagonal must not be 2.0 or 0.0
    for i in 0..7 {
        if (chart[i][i] - 2.0).abs() < f64::EPSILON {
            errors.push(ValidationError {
                code: "TR-2".into(),
                message: format!("Type {i} must not be super effective against itself"),
                context: String::new(),
            });
        }
        if (chart[i][i] - 0.0).abs() < f64::EPSILON {
            errors.push(ValidationError {
                code: "TR-2".into(),
                message: format!("Type {i} must not be immune to itself"),
                context: String::new(),
            });
        }
    }

    // Yang (5) and Yin (6) must be super effective against each other
    if (chart[6][5] - 2.0).abs() > f64::EPSILON {
        errors.push(ValidationError {
            code: "TR-2".into(),
            message: "Yang must be super effective against Yin (2.0)".into(),
            context: String::new(),
        });
    }
    if (chart[5][6] - 2.0).abs() > f64::EPSILON {
        errors.push(ValidationError {
            code: "TR-2".into(),
            message: "Yin must be super effective against Yang (2.0)".into(),
            context: String::new(),
        });
    }

    // Yang and Yin must have neutral effectiveness against 五行 types (0-4)
    for i in 0..5 {
        if (chart[i][5] - 1.0).abs() > f64::EPSILON {
            errors.push(ValidationError {
                code: "TR-2".into(),
                message: format!("Yang must have neutral effectiveness against type {i}"),
                context: String::new(),
            });
        }
        if (chart[i][6] - 1.0).abs() > f64::EPSILON {
            errors.push(ValidationError {
                code: "TR-2".into(),
                message: format!("Yin must have neutral effectiveness against type {i}"),
                context: String::new(),
            });
        }
        if (chart[5][i] - 1.0).abs() > f64::EPSILON {
            errors.push(ValidationError {
                code: "TR-2".into(),
                message: format!("Type {i} must have neutral effectiveness against Yang"),
                context: String::new(),
            });
        }
        if (chart[6][i] - 1.0).abs() > f64::EPSILON {
            errors.push(ValidationError {
                code: "TR-2".into(),
                message: format!("Type {i} must have neutral effectiveness against Yin"),
                context: String::new(),
            });
        }
    }

    // TR-3: Five Elements Cycle Compliance
    for defender in 0..5 {
        let super_effective_count = (0..5)
            .filter(|&attacker| (chart[defender][attacker] - 2.0).abs() < f64::EPSILON)
            .count();
        if super_effective_count != 1 {
            errors.push(ValidationError {
                code: "TR-3".into(),
                message: format!(
                    "Type {defender} must be super effective against exactly 1 type, got {super_effective_count}"
                ),
                context: String::new(),
            });
        }
    }

    for defender in 0..5 {
        let generating_count = (0..5)
            .filter(|&attacker| (chart[defender][attacker] - 1.25).abs() < f64::EPSILON)
            .count();
        if generating_count != 1 {
            errors.push(ValidationError {
                code: "TR-3".into(),
                message: format!(
                    "Type {defender} must generate exactly 1 type (1.25x), got {generating_count}"
                ),
                context: String::new(),
            });
        }
    }

    for defender in 0..5 {
        let weak_count = (0..5)
            .filter(|&attacker| (chart[defender][attacker] - 0.5).abs() < f64::EPSILON)
            .count();
        if weak_count != 1 {
            errors.push(ValidationError {
                code: "TR-3".into(),
                message: format!(
                    "Type {defender} must be weak against exactly 1 type (0.5x), got {weak_count}"
                ),
                context: String::new(),
            });
        }
    }

    if errors.is_empty() {
        Ok(())
    } else {
        Err(errors)
    }
}

pub fn validate_move(data: &crate::moves::MoveData) -> Result<(), Vec<ValidationError>> {
    let mut errors = Vec::new();

    // MR-1: Move Identity
    if !is_valid_id_format(&data.id) {
        errors.push(ValidationError {
            code: "MR-1".into(),
            message: "Invalid ID format (must be lowercase snake_case)".into(),
            context: data.id.clone(),
        });
    }
    if data.name.is_empty() || data.name.len() > 20 {
        errors.push(ValidationError {
            code: "MR-1".into(),
            message: "Name must be 1-20 characters".into(),
            context: data.id.clone(),
        });
    }

    // MR-2: Move Power and Accuracy
    if !is_in_range(data.power, 0, 255) {
        errors.push(ValidationError {
            code: "MR-2".into(),
            message: format!("Power must be in range [0, 255], got {}", data.power),
            context: data.id.clone(),
        });
    }
    if !is_in_range(data.accuracy, 1, 100) {
        errors.push(ValidationError {
            code: "MR-2".into(),
            message: format!("Accuracy must be in range [1, 100], got {}", data.accuracy),
            context: data.id.clone(),
        });
    }

    // MR-3: Move Effect
    if !is_valid_effect_type(data.effect as u32) {
        errors.push(ValidationError {
            code: "MR-3".into(),
            message: format!("Invalid effect type: {:?}", data.effect),
            context: data.id.clone(),
        });
    }
    if !is_in_range(data.effect_chance, 0, 100) {
        errors.push(ValidationError {
            code: "MR-3".into(),
            message: format!("Effect chance must be in range [0, 100], got {}", data.effect_chance),
            context: data.id.clone(),
        });
    }
    if data.effect == EffectType::None && data.effect_chance != 0 {
        errors.push(ValidationError {
            code: "MR-3".into(),
            message: "Effect chance must be 0 when effect is None".into(),
            context: data.id.clone(),
        });
    }
    if data.effect != EffectType::None && data.effect_chance == 0 {
        errors.push(ValidationError {
            code: "MR-3".into(),
            message: "Effect chance must be > 0 when effect is not None".into(),
            context: data.id.clone(),
        });
    }

    // MR-4: Move Stat Modification
    if data.has_stat_mod() {
        if let Some(stat) = data.stat_mod_stat {
            if !is_valid_stat(stat as u32) {
                errors.push(ValidationError {
                    code: "MR-4".into(),
                    message: format!("Invalid stat for modification: {:?}", stat),
                    context: data.id.clone(),
                });
            }
        }
        if data.stat_mod_stage < -3 || data.stat_mod_stage > 3 {
            errors.push(ValidationError {
                code: "MR-4".into(),
                message: format!(
                    "Stat mod stage must be in range [-3, 3], got {}",
                    data.stat_mod_stage
                ),
                context: data.id.clone(),
            });
        }
    }

    // MR-5: Move Multi-Hit
    if !is_in_range(data.hit_count, 1, 5) {
        errors.push(ValidationError {
            code: "MR-5".into(),
            message: format!("Hit count must be in range [1, 5], got {}", data.hit_count),
            context: data.id.clone(),
        });
    }

    // MR-6: Move Recoil
    if !is_in_range(data.recoil, 0, 100) {
        errors.push(ValidationError {
            code: "MR-6".into(),
            message: format!("Recoil must be in range [0, 100], got {}", data.recoil),
            context: data.id.clone(),
        });
    }
    if data.recoil > 0 && data.power == 0 {
        errors.push(ValidationError {
            code: "MR-6".into(),
            message: "Recoil requires power > 0".into(),
            context: data.id.clone(),
        });
    }

    // MR-7: Move Healing
    if !is_in_range(data.healing, 0, 100) {
        errors.push(ValidationError {
            code: "MR-7".into(),
            message: format!("Healing must be in range [0, 100], got {}", data.healing),
            context: data.id.clone(),
        });
    }

    if errors.is_empty() {
        Ok(())
    } else {
        Err(errors)
    }
}

pub fn validate_character(
    data: &crate::character::CharacterData,
    moves: &[crate::moves::MoveData],
) -> Result<(), Vec<ValidationError>> {
    let mut errors = Vec::new();

    // CR-1: Character Identity
    if !is_valid_id_format(&data.id) {
        errors.push(ValidationError {
            code: "CR-1".into(),
            message: "Invalid ID format (must be lowercase snake_case)".into(),
            context: data.id.clone(),
        });
    }
    if data.name.is_empty() || data.name.len() > 20 {
        errors.push(ValidationError {
            code: "CR-1".into(),
            message: "Name must be 1-20 characters".into(),
            context: data.id.clone(),
        });
    }

    // CR-2: Character Stats
    let stat_names = ["hp", "attack", "defense", "speed", "intelligence", "spirit"];
    let stat_values = [
        data.base_stats.hp,
        data.base_stats.attack,
        data.base_stats.defense,
        data.base_stats.speed,
        data.base_stats.intelligence,
        data.base_stats.spirit,
    ];
    for i in 0..stat_names.len() {
        if !is_in_range(stat_values[i], 1, 999) {
            errors.push(ValidationError {
                code: "CR-2".into(),
                message: format!("{} must be in range [1, 999], got {}", stat_names[i], stat_values[i]),
                context: data.id.clone(),
            });
        }
        if stat_values[i] > 500 {
            errors.push(ValidationError {
                code: "CR-2".into(),
                message: format!("{} exceeds maximum of 500, got {}", stat_names[i], stat_values[i]),
                context: data.id.clone(),
            });
        }
    }
    if data.get_stat_sum() > 3000 {
        errors.push(ValidationError {
            code: "CR-2".into(),
            message: format!("Stat sum {} exceeds maximum 3000", data.get_stat_sum()),
            context: data.id.clone(),
        });
    }

    // CR-3: Character Type Assignment
    if !is_valid_type(data.element as u32) {
        errors.push(ValidationError {
            code: "CR-3".into(),
            message: format!("Invalid primary type: {:?}", data.element),
            context: data.id.clone(),
        });
    }
    if let Some(secondary) = data.secondary_element {
        if !is_valid_type(secondary as u32) {
            errors.push(ValidationError {
                code: "CR-3".into(),
                message: format!("Invalid secondary type: {:?}", secondary),
                context: data.id.clone(),
            });
        }
        if secondary == data.element {
            errors.push(ValidationError {
                code: "CR-3".into(),
                message: format!("Secondary type same as primary ({:?})", data.element),
                context: data.id.clone(),
            });
        }
    }

    // CR-4: Character Move Assignment
    if data.moves.len() != 4 {
        errors.push(ValidationError {
            code: "CR-4".into(),
            message: format!("Must have exactly 4 moves, got {}", data.moves.len()),
            context: data.id.clone(),
        });
    }
    let has_damaging_move = data.moves.iter().any(|move_id| {
        moves.iter().any(|m| m.id == *move_id && m.is_damaging())
    });
    if !has_damaging_move && data.moves.len() == 4 {
        errors.push(ValidationError {
            code: "CR-4".into(),
            message: "Must have at least one move with power > 0".into(),
            context: data.id.clone(),
        });
    }

    if errors.is_empty() {
        Ok(())
    } else {
        Err(errors)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::character::CharacterData;
    use crate::moves::MoveData;
    use crate::types::*;

    fn valid_moves() -> Vec<MoveData> {
        vec![
            MoveData {
                id: "fire_strike".into(),
                name: "火炎斬".into(),
                element: TypeElement::Fire,
                power: 60,
                accuracy: 95,
                effect: EffectType::None,
                effect_chance: 0,
                stat_mod_stat: None,
                stat_mod_stage: 0,
                hit_count: 1,
                recoil: 0,
                healing: 0,
                damage_category: DamageCategory::Physical,
                description: "A fiery strike".into(),
            },
            MoveData {
                id: "water_blast".into(),
                name: "水撃".into(),
                element: TypeElement::Water,
                power: 55,
                accuracy: 100,
                effect: EffectType::None,
                effect_chance: 0,
                stat_mod_stat: None,
                stat_mod_stage: 0,
                hit_count: 1,
                recoil: 0,
                healing: 0,
                damage_category: DamageCategory::Arts,
                description: "A water blast".into(),
            },
            MoveData {
                id: "healing_wind".into(),
                name: "癒風".into(),
                element: TypeElement::Wood,
                power: 0,
                accuracy: 100,
                effect: EffectType::None,
                effect_chance: 0,
                stat_mod_stat: None,
                stat_mod_stage: 0,
                hit_count: 1,
                recoil: 0,
                healing: 30,
                damage_category: DamageCategory::Physical,
                description: "Heals the user".into(),
            },
            MoveData {
                id: "iron_wall".into(),
                name: "鉄壁".into(),
                element: TypeElement::Metal,
                power: 0,
                accuracy: 100,
                effect: EffectType::None,
                effect_chance: 0,
                stat_mod_stat: Some(Stat::Defense),
                stat_mod_stage: 2,
                hit_count: 1,
                recoil: 0,
                healing: 0,
                damage_category: DamageCategory::Physical,
                description: "Raises defense".into(),
            },
        ]
    }

    fn valid_character() -> CharacterData {
        let all_moves = valid_moves();
        CharacterData {
            id: "guan_yu".into(),
            name: "関羽".into(),
            element: TypeElement::Wood,
            secondary_element: None,
            base_stats: crate::character::Stats {
                hp: 100,
                attack: 90,
                defense: 80,
                speed: 70,
                intelligence: 60,
                spirit: 50,
            },
            moves: all_moves.iter().map(|m| m.id.clone()).collect(),
            description: "A warrior".into(),
        }
    }

    #[test]
    fn test_validate_type_chart_valid() {
        use TypeElement::*;
        let mut chart = [[1.0_f64; 7]; 7];
        // Row = defender, Col = attacker
        chart[Wood as usize] = [1.0, 0.5, 2.0, 1.0, 1.25, 1.0, 1.0];
        chart[Fire as usize] = [1.25, 1.0, 0.5, 2.0, 1.0, 1.0, 1.0];
        chart[Earth as usize] = [1.0, 1.25, 1.0, 0.5, 2.0, 1.0, 1.0];
        chart[Metal as usize] = [2.0, 1.0, 1.25, 1.0, 0.5, 1.0, 1.0];
        chart[Water as usize] = [0.5, 2.0, 1.0, 1.25, 1.0, 1.0, 1.0];
        chart[Yang as usize] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0];
        chart[Yin as usize] = [1.0, 1.0, 1.0, 1.0, 1.0, 2.0, 1.0];
        assert!(validate_type_chart(&chart).is_ok());
    }

    #[test]
    fn test_validate_move_valid() {
        let all_moves = valid_moves();
        assert!(validate_move(&all_moves[0]).is_ok());
    }

    #[test]
    fn test_validate_move_invalid_id() {
        let all_moves = valid_moves();
        let m = MoveData {
            id: "InvalidID".into(),
            ..all_moves[0].clone()
        };
        assert!(validate_move(&m).is_err());
    }

    #[test]
    fn test_validate_move_power_out_of_range() {
        let all_moves = valid_moves();
        let m = MoveData {
            power: 300,
            ..all_moves[0].clone()
        };
        assert!(validate_move(&m).is_err());
    }

    #[test]
    fn test_validate_move_effect_mismatch() {
        let all_moves = valid_moves();
        let m = MoveData {
            effect: EffectType::None,
            effect_chance: 50,
            ..all_moves[0].clone()
        };
        assert!(validate_move(&m).is_err());
    }

    #[test]
    fn test_validate_move_recoil_no_power() {
        let all_moves = valid_moves();
        let m = MoveData {
            power: 0,
            recoil: 50,
            ..all_moves[0].clone()
        };
        assert!(validate_move(&m).is_err());
    }

    #[test]
    fn test_validate_character_valid() {
        let all_moves = valid_moves();
        let c = valid_character();
        assert!(validate_character(&c, &all_moves).is_ok());
    }

    #[test]
    fn test_validate_character_invalid_id() {
        let all_moves = valid_moves();
        let c = CharacterData {
            id: "UPPERCASE".into(),
            ..valid_character()
        };
        assert!(validate_character(&c, &all_moves).is_err());
    }

    #[test]
    fn test_validate_character_stat_overflow() {
        let all_moves = valid_moves();
        let c = CharacterData {
            base_stats: crate::character::Stats {
                hp: 999,
                attack: 999,
                defense: 999,
                speed: 999,
                intelligence: 999,
                spirit: 999,
            },
            ..valid_character()
        };
        let result = validate_character(&c, &all_moves);
        assert!(result.is_err());
        let errors = result.unwrap_err();
        assert!(errors.iter().any(|e| e.code == "CR-2"));
    }

    #[test]
    fn test_validate_character_duplicate_type() {
        let all_moves = valid_moves();
        let c = CharacterData {
            element: TypeElement::Wood,
            secondary_element: Some(TypeElement::Wood),
            ..valid_character()
        };
        assert!(validate_character(&c, &all_moves).is_err());
    }

    #[test]
    fn test_validate_character_wrong_move_count() {
        let all_moves = valid_moves();
        let c = CharacterData {
            moves: vec![],
            ..valid_character()
        };
        assert!(validate_character(&c, &all_moves).is_err());
    }

    #[test]
    fn test_is_valid_id_format() {
        assert!(is_valid_id_format("valid_id_123"));
        assert!(is_valid_id_format("a"));
        assert!(!is_valid_id_format(""));
        assert!(!is_valid_id_format("Uppercase"));
        assert!(!is_valid_id_format("with spaces"));
    }

    #[test]
    fn test_validation_result_summary() {
        let mut result = ValidationResult::new();
        result.add_error("TEST", "Something went wrong", "ctx");
        result.add_warning("WARN", "Something to note", "ctx");
        result.total_files_scanned = 5;
        result.valid_files = 3;
        result.invalid_files = 2;
        let summary = result.get_summary();
        assert!(summary.contains("5"));
        assert!(summary.contains("TEST"));
        assert!(summary.contains("WARN"));
        assert!(!result.is_valid());
    }
}
