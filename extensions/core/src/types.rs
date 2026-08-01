use serde::{Deserialize, Serialize};
use strum::{Display, EnumString, FromRepr};

/// The five-phase element types plus Yang/Yin for the type effectiveness system.
///
/// Each character and move is associated with one (sometimes two) elements.
/// Type interactions follow a chart: Wood→Fire→Metal→Wood with Earth→Water→Fire→... cycles,
/// plus Yang↔Yin mutual super-effectiveness.
#[derive(
    Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Display, EnumString, FromRepr,
)]
#[repr(u8)]
pub enum TypeElement {
    /// Wood element (0).
    Wood = 0,
    /// Fire element (1).
    Fire = 1,
    /// Earth element (2).
    Earth = 2,
    /// Metal element (3).
    Metal = 3,
    /// Water element (4).
    Water = 4,
    /// Yang element (5) — super-effective against Yin.
    Yang = 5,
    /// Yin element (6) — super-effective against Yang.
    Yin = 6,
}

impl TypeElement {
    /// All valid `TypeElement` values in enum order.
    pub const ALL: [TypeElement; 7] = [
        TypeElement::Wood,
        TypeElement::Fire,
        TypeElement::Earth,
        TypeElement::Metal,
        TypeElement::Water,
        TypeElement::Yang,
        TypeElement::Yin,
    ];

    /// Number of defined element types.
    pub const COUNT: usize = 7;
}

/// Types of status effects that can be applied during battle.
#[derive(
    Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, Display, EnumString, FromRepr,
)]
#[repr(u8)]
pub enum EffectType {
    /// No effect.
    None = 0,
    /// Burn — deals damage over time each turn.
    Burn = 1,
    /// Poison — deals escalating damage over time.
    Poison = 2,
    /// Confusion — chance to self-hit each turn.
    Confusion = 3,
    /// Chain — additional constraint effect.
    Chain = 4,
    /// Charm — manipulation effect.
    Charm = 5,
}

impl EffectType {
    /// All valid `EffectType` values in enum order.
    pub const ALL: [EffectType; 6] = [
        EffectType::None,
        EffectType::Burn,
        EffectType::Poison,
        EffectType::Confusion,
        EffectType::Chain,
        EffectType::Charm,
    ];
}

/// Damage category determining which stats are used for attack/defense.
///
/// - `Physical`: uses Attack vs Defense.
/// - `Arts`: uses Intelligence vs Spirit.
#[derive(
    Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Display, EnumString, FromRepr,
)]
#[repr(u8)]
pub enum DamageCategory {
    /// Physical damage — uses Attack vs Defense.
    Physical = 0,
    /// Arts damage — uses Intelligence vs Spirit.
    Arts = 1,
}

/// Character stats used in battle calculations.
#[derive(
    Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Display, EnumString, FromRepr,
)]
#[repr(u8)]
pub enum Stat {
    /// Physical attack power.
    Attack = 0,
    /// Physical defense.
    Defense = 1,
    /// Turn speed (determines initiative order).
    Speed = 2,
    /// Arts attack power / magical prowess.
    Intelligence = 3,
    /// Arts defense / magical resistance.
    Spirit = 4,
}

impl Stat {
    /// Number of distinct stat types.
    pub const COUNT: usize = 5;
    /// All valid `Stat` values in enum order.
    pub const ALL: [Stat; 5] = [
        Stat::Attack,
        Stat::Defense,
        Stat::Speed,
        Stat::Intelligence,
        Stat::Spirit,
    ];

    /// Returns the zero-based index of this stat for array lookups.
    pub fn to_index(&self) -> usize {
        *self as usize
    }
}

/// The type effectiveness chart — a 7×7 matrix of multipliers.
///
/// Rows = defender element, Columns = attacker element.
/// Values range from 0.0 (immune) through 0.5, 1.0, 1.25, 2.0 (super-effective).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TypeChart([[f64; TypeElement::COUNT]; TypeElement::COUNT]);

impl Default for TypeChart {
    fn default() -> Self {
        use TypeElement::*;
        let mut chart = [[1.0_f64; TypeElement::COUNT]; TypeElement::COUNT];
        // Row = defender, Column = attacker — matching GDScript layout
        // Wood
        chart[Wood as usize][Wood as usize] = 1.0;
        chart[Wood as usize][Fire as usize] = 0.5;
        chart[Wood as usize][Earth as usize] = 2.0;
        chart[Wood as usize][Metal as usize] = 1.0;
        chart[Wood as usize][Water as usize] = 1.25;
        chart[Wood as usize][Yang as usize] = 1.0;
        chart[Wood as usize][Yin as usize] = 1.0;
        // Fire
        chart[Fire as usize][Wood as usize] = 1.25;
        chart[Fire as usize][Fire as usize] = 1.0;
        chart[Fire as usize][Earth as usize] = 0.5;
        chart[Fire as usize][Metal as usize] = 2.0;
        chart[Fire as usize][Water as usize] = 1.0;
        chart[Fire as usize][Yang as usize] = 1.0;
        chart[Fire as usize][Yin as usize] = 1.0;
        // Earth
        chart[Earth as usize][Wood as usize] = 1.0;
        chart[Earth as usize][Fire as usize] = 1.25;
        chart[Earth as usize][Earth as usize] = 1.0;
        chart[Earth as usize][Metal as usize] = 0.5;
        chart[Earth as usize][Water as usize] = 2.0;
        chart[Earth as usize][Yang as usize] = 1.0;
        chart[Earth as usize][Yin as usize] = 1.0;
        // Metal
        chart[Metal as usize][Wood as usize] = 2.0;
        chart[Metal as usize][Fire as usize] = 1.0;
        chart[Metal as usize][Earth as usize] = 1.25;
        chart[Metal as usize][Metal as usize] = 1.0;
        chart[Metal as usize][Water as usize] = 0.5;
        chart[Metal as usize][Yang as usize] = 1.0;
        chart[Metal as usize][Yin as usize] = 1.0;
        // Water
        chart[Water as usize][Wood as usize] = 0.5;
        chart[Water as usize][Fire as usize] = 2.0;
        chart[Water as usize][Earth as usize] = 1.0;
        chart[Water as usize][Metal as usize] = 1.25;
        chart[Water as usize][Water as usize] = 1.0;
        chart[Water as usize][Yang as usize] = 1.0;
        chart[Water as usize][Yin as usize] = 1.0;
        // Yang
        chart[Yang as usize][Yang as usize] = 1.0;
        chart[Yang as usize][Yin as usize] = 2.0;
        // Yin
        chart[Yin as usize][Yang as usize] = 2.0;
        chart[Yin as usize][Yin as usize] = 1.0;
        Self(chart)
    }
}

impl TypeChart {
    /// Returns the type effectiveness multiplier for `attack` vs `defense`.
    pub fn effectiveness(&self, attack: TypeElement, defense: TypeElement) -> f64 {
        self.0[defense as usize][attack as usize]
    }

    /// Returns the combined effectiveness multiplier against a dual-type defender.
    ///
    /// Multiplies the effectiveness against each of the defender's elements,
    /// clamped to the range [0.25, 4.0].
    pub fn effectiveness_dual(
        &self,
        attack: TypeElement,
        defense_a: TypeElement,
        defense_b: TypeElement,
    ) -> f64 {
        let eff_a = self.effectiveness(attack, defense_a);
        let eff_b = self.effectiveness(attack, defense_b);
        (eff_a * eff_b).clamp(0.25, 4.0)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_type_element_roundtrip() {
        let wood = TypeElement::Wood;
        assert_eq!(wood as u8, 0);
        assert_eq!(TypeElement::from_repr(0), Some(TypeElement::Wood));
    }

    #[test]
    fn test_effect_type_roundtrip() {
        assert_eq!(EffectType::None as u8, 0);
        assert_eq!(EffectType::from_repr(5), Some(EffectType::Charm));
        assert_eq!(EffectType::from_repr(99), None);
    }

    #[test]
    fn test_damage_category_roundtrip() {
        assert_eq!(DamageCategory::Physical as u8, 0);
        assert_eq!(DamageCategory::Arts as u8, 1);
    }

    #[test]
    fn test_stat_roundtrip() {
        assert_eq!(Stat::Intelligence as u8, 3);
        assert_eq!(Stat::from_repr(3), Some(Stat::Intelligence));
    }

    #[test]
    fn test_water_vs_fire() {
        let chart = TypeChart::default();
        assert!(
            (chart.effectiveness(TypeElement::Water, TypeElement::Fire) - 1.0).abs() < f64::EPSILON
        );
    }

    #[test]
    fn test_fire_vs_water() {
        let chart = TypeChart::default();
        assert!(
            (chart.effectiveness(TypeElement::Fire, TypeElement::Water) - 2.0).abs() < f64::EPSILON
        );
    }

    #[test]
    fn test_wood_vs_fire() {
        let chart = TypeChart::default();
        assert!(
            (chart.effectiveness(TypeElement::Wood, TypeElement::Fire) - 1.25).abs() < f64::EPSILON
        );
    }

    #[test]
    fn test_fire_vs_wood() {
        let chart = TypeChart::default();
        assert!(
            (chart.effectiveness(TypeElement::Fire, TypeElement::Wood) - 0.5).abs() < f64::EPSILON
        );
    }

    #[test]
    fn test_earth_vs_wood() {
        let chart = TypeChart::default();
        assert!(
            (chart.effectiveness(TypeElement::Earth, TypeElement::Wood) - 2.0).abs() < f64::EPSILON
        );
    }

    #[test]
    fn test_metal_vs_wood() {
        let chart = TypeChart::default();
        assert!(
            (chart.effectiveness(TypeElement::Metal, TypeElement::Wood) - 1.0).abs() < f64::EPSILON
        );
    }

    #[test]
    fn test_wood_vs_earth() {
        let chart = TypeChart::default();
        assert!(
            (chart.effectiveness(TypeElement::Wood, TypeElement::Earth) - 1.0).abs() < f64::EPSILON
        );
    }

    #[test]
    fn test_yang_vs_yin() {
        let chart = TypeChart::default();
        assert!(
            (chart.effectiveness(TypeElement::Yang, TypeElement::Yin) - 2.0).abs() < f64::EPSILON
        );
    }

    #[test]
    fn test_yin_vs_yang() {
        let chart = TypeChart::default();
        assert!(
            (chart.effectiveness(TypeElement::Yin, TypeElement::Yang) - 2.0).abs() < f64::EPSILON
        );
    }

    #[test]
    fn test_effectiveness_dual_clamping() {
        let chart = TypeChart::default();
        let result =
            chart.effectiveness_dual(TypeElement::Wood, TypeElement::Wood, TypeElement::Metal);
        assert!(result >= 0.25);
        assert!(result <= 4.0);
    }

    #[test]
    fn test_effectiveness_dual_compound() {
        let chart = TypeChart::default();
        let result =
            chart.effectiveness_dual(TypeElement::Water, TypeElement::Fire, TypeElement::Earth);
        assert!((result - 2.0).abs() < f64::EPSILON);
    }

    #[test]
    fn test_type_chart_default_identity() {
        let chart = TypeChart::default();
        for t in TypeElement::ALL {
            let eff = chart.effectiveness(t, t);
            assert!(
                (eff - 1.0).abs() < f64::EPSILON,
                "{:?} vs itself = {}",
                t,
                eff
            );
        }
    }

    #[test]
    fn test_type_chart_five_element_cycle() {
        let chart = TypeChart::default();
        // effectiveness(attack, defense): row=defender, col=attacker
        // 2.0 cycle: Fire→Water, Water→Earth, Earth→Wood, Wood→Metal, Metal→Fire
        assert!(
            (chart.effectiveness(TypeElement::Fire, TypeElement::Water) - 2.0).abs() < f64::EPSILON
        );
        assert!(
            (chart.effectiveness(TypeElement::Water, TypeElement::Earth) - 2.0).abs()
                < f64::EPSILON
        );
        assert!(
            (chart.effectiveness(TypeElement::Earth, TypeElement::Wood) - 2.0).abs() < f64::EPSILON
        );
        assert!(
            (chart.effectiveness(TypeElement::Wood, TypeElement::Metal) - 2.0).abs() < f64::EPSILON
        );
        assert!(
            (chart.effectiveness(TypeElement::Metal, TypeElement::Fire) - 2.0).abs() < f64::EPSILON
        );
    }

    #[test]
    fn test_type_chart_yang_yin_neutral_to_five() {
        let chart = TypeChart::default();
        for t in [
            TypeElement::Wood,
            TypeElement::Fire,
            TypeElement::Earth,
            TypeElement::Metal,
            TypeElement::Water,
        ] {
            assert!((chart.effectiveness(TypeElement::Yang, t) - 1.0).abs() < f64::EPSILON);
            assert!((chart.effectiveness(TypeElement::Yin, t) - 1.0).abs() < f64::EPSILON);
            assert!((chart.effectiveness(t, TypeElement::Yang) - 1.0).abs() < f64::EPSILON);
            assert!((chart.effectiveness(t, TypeElement::Yin) - 1.0).abs() < f64::EPSILON);
        }
    }

    #[test]
    fn test_type_chart_known_effectiveness() {
        let chart = TypeChart::default();
        // effectiveness(attack, defense) = chart[defense][attack]
        let cases: [(TypeElement, TypeElement, f64); 8] = [
            (TypeElement::Fire, TypeElement::Wood, 0.5), // Fire attacks Wood → weak
            (TypeElement::Water, TypeElement::Metal, 0.5), // Water attacks Metal → weak
            (TypeElement::Water, TypeElement::Wood, 1.25), // Water attacks Wood → generating
            (TypeElement::Fire, TypeElement::Water, 2.0), // Fire attacks Water → strong
            (TypeElement::Wood, TypeElement::Fire, 1.25), // Wood attacks Fire → generating
            (TypeElement::Water, TypeElement::Fire, 1.0), // Water attacks Fire → neutral
            (TypeElement::Metal, TypeElement::Water, 1.25), // Metal attacks Water → generating
            (TypeElement::Earth, TypeElement::Fire, 0.5), // Earth attacks Fire → weak
        ];
        for (atk, def, expected) in cases {
            let eff = chart.effectiveness(atk, def);
            assert!(
                (eff - expected).abs() < f64::EPSILON,
                "{atk:?} vs {def:?} expected {expected}, got {eff}"
            );
        }
    }

    #[test]
    fn test_effectiveness_dual_extreme_clamping() {
        let chart = TypeChart::default();
        // Fire→Water = 2.0, Fire→Water+Water = 2.0*2.0 = 4.0
        let result =
            chart.effectiveness_dual(TypeElement::Fire, TypeElement::Water, TypeElement::Water);
        assert!(
            (result - 4.0).abs() < f64::EPSILON,
            "Fire vs Water+Water expected 4.0, got {result}"
        );
        // Fire→Wood = 0.5, Fire→Wood+Wood = 0.5*0.5 = 0.25
        let result2 =
            chart.effectiveness_dual(TypeElement::Fire, TypeElement::Wood, TypeElement::Wood);
        assert!(
            (result2 - 0.25).abs() < f64::EPSILON,
            "Fire vs Wood+Wood expected 0.25, got {result2}"
        );
    }

    #[test]
    fn test_stat_to_index() {
        assert_eq!(Stat::Attack.to_index(), 0);
        assert_eq!(Stat::Defense.to_index(), 1);
        assert_eq!(Stat::Speed.to_index(), 2);
        assert_eq!(Stat::Intelligence.to_index(), 3);
        assert_eq!(Stat::Spirit.to_index(), 4);
    }

    #[test]
    fn test_type_element_all_from_repr() {
        for (i, t) in TypeElement::ALL.iter().enumerate() {
            assert_eq!(TypeElement::from_repr(i as u8), Some(*t));
        }
    }

    #[test]
    fn test_effect_type_all_variants() {
        for (i, e) in EffectType::ALL.iter().enumerate() {
            let repr = i as u8;
            assert_eq!(*e as u8, repr);
            assert_eq!(EffectType::from_repr(repr), Some(*e));
        }
        assert_eq!(EffectType::from_repr(99), None);
    }
}
