//! Type system for the Xianke battle game.
//!
//! Defines element types and the type effectiveness chart.

use serde::{Deserialize, Serialize};
use strum::{Display, EnumString, FromRepr};

/// The seven element types used in the Xianke battle system.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Display, EnumString, FromRepr)]
#[repr(u8)]
pub enum TypeElement {
    Wood = 0,
    Fire = 1,
    Earth = 2,
    Metal = 3,
    Water = 4,
    Yang = 5,
    Yin = 6,
}

impl TypeElement {
    /// All element types in order.
    pub const ALL: [TypeElement; 7] = [
        TypeElement::Wood,
        TypeElement::Fire,
        TypeElement::Earth,
        TypeElement::Metal,
        TypeElement::Water,
        TypeElement::Yang,
        TypeElement::Yin,
    ];

    /// The number of element types.
    pub const COUNT: usize = 7;

    /// Get the index of this type (0-6).
    pub fn index(self) -> usize {
        self as usize
    }
}

/// A 7×7 type effectiveness lookup table.
///
/// Row = attacking type, Column = defending type.
/// Values: 0.0 (immune), 0.5 (not very effective), 1.0 (neutral), 2.0 (super effective).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TypeChart([[f64; TypeElement::COUNT]; TypeElement::COUNT]);

impl Default for TypeChart {
    fn default() -> Self {
        use TypeElement::*;
        // Build the chart using the same 7×7 matrix as the GDScript version.
        let mut chart = [[1.0_f64; TypeElement::COUNT]; TypeElement::COUNT];
        // Wood
        chart[Wood.index()][Wood.index()] = 1.0;
        chart[Wood.index()][Fire.index()] = 0.5;
        chart[Wood.index()][Earth.index()] = 2.0;
        chart[Wood.index()][Metal.index()] = 0.5;
        chart[Wood.index()][Water.index()] = 1.0;
        chart[Wood.index()][Yang.index()] = 1.0;
        chart[Wood.index()][Yin.index()] = 1.0;
        // Fire
        chart[Fire.index()][Wood.index()] = 2.0;
        chart[Fire.index()][Fire.index()] = 0.5;
        chart[Fire.index()][Earth.index()] = 0.5;
        chart[Fire.index()][Metal.index()] = 2.0;
        chart[Fire.index()][Water.index()] = 0.5;
        chart[Fire.index()][Yang.index()] = 1.0;
        chart[Fire.index()][Yin.index()] = 1.0;
        // Earth
        chart[Earth.index()][Wood.index()] = 0.5;
        chart[Earth.index()][Fire.index()] = 2.0;
        chart[Earth.index()][Earth.index()] = 1.0;
        chart[Earth.index()][Metal.index()] = 2.0;
        chart[Earth.index()][Water.index()] = 1.0;
        chart[Earth.index()][Yang.index()] = 1.0;
        chart[Earth.index()][Yin.index()] = 1.0;
        // Metal
        chart[Metal.index()][Wood.index()] = 2.0;
        chart[Metal.index()][Fire.index()] = 0.5;
        chart[Metal.index()][Earth.index()] = 0.5;
        chart[Metal.index()][Metal.index()] = 0.5;
        chart[Metal.index()][Water.index()] = 2.0;
        chart[Metal.index()][Yang.index()] = 1.0;
        chart[Metal.index()][Yin.index()] = 1.0;
        // Water
        chart[Water.index()][Wood.index()] = 1.0;
        chart[Water.index()][Fire.index()] = 2.0;
        chart[Water.index()][Earth.index()] = 2.0;
        chart[Water.index()][Metal.index()] = 0.5;
        chart[Water.index()][Water.index()] = 0.5;
        chart[Water.index()][Yang.index()] = 1.0;
        chart[Water.index()][Yin.index()] = 1.0;
        // Yang
        chart[Yang.index()][Yang.index()] = 2.0;
        chart[Yang.index()][Yin.index()] = 2.0;
        // Yin
        chart[Yin.index()][Yang.index()] = 2.0;
        chart[Yin.index()][Yin.index()] = 2.0;
        Self(chart)
    }
}

impl TypeChart {
    /// Get the effectiveness multiplier for a single attacking type vs a single defending type.
    pub fn effectiveness(&self, attack: TypeElement, defense: TypeElement) -> f64 {
        self.0[attack.index()][defense.index()]
    }

    /// Get the combined effectiveness for dual-type defenders.
    /// Returns the product of both effectiveness values, clamped to [0.25, 4.0].
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
    fn test_fire_vs_wood() {
        let chart = TypeChart::default();
        assert!((chart.effectiveness(TypeElement::Fire, TypeElement::Wood) - 2.0).abs() < f64::EPSILON);
    }

    #[test]
    fn test_water_vs_fire() {
        let chart = TypeChart::default();
        assert!((chart.effectiveness(TypeElement::Water, TypeElement::Fire) - 2.0).abs() < f64::EPSILON);
    }

    #[test]
    fn test_fire_vs_water() {
        let chart = TypeChart::default();
        assert!((chart.effectiveness(TypeElement::Fire, TypeElement::Water) - 0.5).abs() < f64::EPSILON);
    }
}
