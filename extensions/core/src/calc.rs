/// Maximum possible stat stage value.
pub const STAT_STAGE_MAX: i32 = 6;
/// Minimum possible stat stage value (symmetric negation of MAX).
pub const STAT_STAGE_MIN: i32 = -STAT_STAGE_MAX;
/// Base damage multiplier applied before effectiveness/type match/variance.
pub const DAMAGE_MULTIPLIER: f64 = 0.8;

/// Converts a stat stage change to a multiplier.
///
/// - Stage 0 → ×1.0 (neutral)
/// - Positive stages → (2 + stage) / 2  (e.g. +1 → ×1.5, +6 → ×4.0)
/// - Negative stages → 2 / (2 - stage) (e.g. −1 → ×2/3, −6 → ×0.25)
///
/// # Panics
/// Panics if `stage` is outside [`STAT_STAGE_MIN`, `STAT_STAGE_MAX`].
pub fn stat_stage_multiplier(stage: i32) -> f64 {
    assert!(
        (STAT_STAGE_MIN..=STAT_STAGE_MAX).contains(&stage),
        "stat stage must be in [{}, {}], got {stage}",
        STAT_STAGE_MIN,
        STAT_STAGE_MAX,
    );
    match stage.cmp(&0) {
        std::cmp::Ordering::Equal => 1.0,
        std::cmp::Ordering::Greater => (2.0 + stage as f64) / 2.0,
        std::cmp::Ordering::Less => 2.0 / (2.0 - stage as f64),
    }
}

/// Computes raw damage before type effectiveness, type match, critical, and variance.
///
/// Formula: `ceil((attack * power * 0.8) / defense)`, minimum 1.
pub fn calculate_raw_damage(attack: f64, power: u32, defense: f64) -> u32 {
    let def = defense.max(1.0);
    ((attack * power as f64 * DAMAGE_MULTIPLIER) / def)
        .ceil()
        .max(1.0) as u32
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
        assert!((stat_stage_multiplier(STAT_STAGE_MAX) - 4.0).abs() < f64::EPSILON);
    }

    #[test]
    fn test_stage_negative_one() {
        let expected = 2.0 / 3.0;
        assert!((stat_stage_multiplier(-1) - expected).abs() < 1e-10);
    }

    #[test]
    fn test_stage_negative_six() {
        let expected = 2.0 / 8.0;
        assert!((stat_stage_multiplier(STAT_STAGE_MIN) - expected).abs() < 1e-10);
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
        stat_stage_multiplier(STAT_STAGE_MAX + 1);
    }

    #[test]
    #[should_panic(expected = "stat stage must be in [-6, 6]")]
    fn test_stage_out_of_range_negative() {
        stat_stage_multiplier(STAT_STAGE_MIN - 1);
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

    #[test]
    fn test_raw_damage_high_attack() {
        let result = calculate_raw_damage(255.0, 255, 1.0);
        assert_eq!(result, 52020);
    }

    #[test]
    fn test_stat_stage_all_valid_values() {
        for stage in -6..=6 {
            let m = stat_stage_multiplier(stage);
            assert!(
                m.is_finite(),
                "stage {stage} produced non-finite multiplier"
            );
            assert!(m > 0.0, "stage {stage} produced non-positive multiplier");
        }
    }

    #[test]
    fn test_stat_stage_monotonic() {
        for lower in -6..6 {
            let upper = lower + 1;
            let ml = stat_stage_multiplier(lower);
            let mu = stat_stage_multiplier(upper);
            assert!(
                mu > ml,
                "stage {upper} multiplier {mu} should be > stage {lower} multiplier {ml}"
            );
        }
    }
}
