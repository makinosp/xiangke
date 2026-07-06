pub fn stat_stage_multiplier(stage: i32) -> f64 {
    assert!(
        stage >= -6 && stage <= 6,
        "stat stage must be in [-6, 6], got {stage}"
    );
    match stage.cmp(&0) {
        std::cmp::Ordering::Equal => 1.0,
        std::cmp::Ordering::Greater => (2.0 + stage as f64) / 2.0,
        std::cmp::Ordering::Less => 2.0 / (2.0 - stage as f64),
    }
}

pub fn calculate_raw_damage(attack: f64, power: u32, defense: f64) -> u32 {
    let def = defense.max(1.0);
    ((attack * power as f64 * 0.8) / def).ceil().max(1.0) as u32
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_stage_zero() {
        assert!((stat_stage_multiplier(0) - 1.0).abs() < f64::EPSILON);
    }

    #[test]
    fn test_stage_positive_one() {
        assert!((stat_stage_multiplier(1) - 1.5).abs() < f64::EPSILON);
    }

    #[test]
    fn test_stage_positive_six() {
        assert!((stat_stage_multiplier(6) - 4.0).abs() < f64::EPSILON);
    }

    #[test]
    fn test_stage_negative_one() {
        let expected = 2.0 / 3.0;
        assert!((stat_stage_multiplier(-1) - expected).abs() < 1e-10);
    }

    #[test]
    fn test_stage_negative_six() {
        let expected = 2.0 / 8.0;
        assert!((stat_stage_multiplier(-6) - expected).abs() < 1e-10);
    }

    #[test]
    fn test_stage_positive_two() {
        assert!((stat_stage_multiplier(2) - 2.0).abs() < f64::EPSILON);
    }

    #[test]
    fn test_stage_negative_two() {
        let expected = 2.0 / 4.0;
        assert!((stat_stage_multiplier(-2) - expected).abs() < 1e-10);
    }

    #[test]
    #[should_panic(expected = "stat stage must be in [-6, 6]")]
    fn test_stage_out_of_range_positive() {
        stat_stage_multiplier(7);
    }

    #[test]
    #[should_panic(expected = "stat stage must be in [-6, 6]")]
    fn test_stage_out_of_range_negative() {
        stat_stage_multiplier(-7);
    }

    #[test]
    fn test_raw_damage_basic() {
        let result = calculate_raw_damage(100.0, 60, 50.0);
        assert_eq!(result, 96);
    }

    #[test]
    fn test_raw_damage_minimum() {
        let result = calculate_raw_damage(1.0, 1, 9999.0);
        assert_eq!(result, 1);
    }

    #[test]
    fn test_raw_damage_zero_defense() {
        let result = calculate_raw_damage(100.0, 60, 0.0);
        assert_eq!(result, 4800);
    }

    #[test]
    fn test_raw_damage_floor_defense() {
        let result = calculate_raw_damage(100.0, 60, 0.5);
        assert_eq!(result, 4800);
    }
}
