use proptest::prelude::*;
use proptest::sample::select;

use crate::calc;
use crate::types::{TypeChart, TypeElement};

#[test]
fn test_type_effectiveness_clamped() {
    proptest!(|(atk in select(TypeElement::ALL.to_vec()), def in select(TypeElement::ALL.to_vec()))| {
        let chart = TypeChart::default();
        let eff = chart.effectiveness(atk, def);
        prop_assert!(eff >= 0.0, "effectiveness {eff} below 0.0 for {atk:?}->{def:?}");
        prop_assert!(eff <= 2.0, "effectiveness {eff} above 2.0 for {atk:?}->{def:?}");
    });
}

#[test]
fn test_dual_effectiveness_clamped() {
    proptest!(|(atk in select(TypeElement::ALL.to_vec()), d1 in select(TypeElement::ALL.to_vec()), d2 in select(TypeElement::ALL.to_vec()))| {
        let chart = TypeChart::default();
        let eff = chart.effectiveness_dual(atk, d1, d2);
        prop_assert!(eff >= 0.25, "dual effectiveness {eff} below 0.25");
        prop_assert!(eff <= 4.0, "dual effectiveness {eff} above 4.0");
    });
}

#[test]
fn test_same_type_effectiveness_is_neutral() {
    proptest!(|(t in select(TypeElement::ALL.to_vec()))| {
        let chart = TypeChart::default();
        let eff = chart.effectiveness(t, t);
        prop_assert!((eff - 1.0).abs() < f64::EPSILON, "same type {t:?} effectiveness {eff}");
    });
}

#[test]
fn test_yang_yin_neutral_to_elements() {
    proptest!(|(element in select(TypeElement::ALL[..5].to_vec()), celestial in select(vec![TypeElement::Yang, TypeElement::Yin]))| {
        let chart = TypeChart::default();
        let eff1 = chart.effectiveness(celestial, element);
        let eff2 = chart.effectiveness(element, celestial);
        prop_assert!((eff1 - 1.0).abs() < f64::EPSILON,
            "celestial {celestial:?} vs element {element:?} = {eff1}");
        prop_assert!((eff2 - 1.0).abs() < f64::EPSILON,
            "element {element:?} vs celestial {celestial:?} = {eff2}");
    });
}

#[test]
fn test_yang_yin_mutual_strong() {
    proptest!(|(a in select(vec![TypeElement::Yang, TypeElement::Yin]), b in select(vec![TypeElement::Yang, TypeElement::Yin]))| {
        let chart = TypeChart::default();
        if a != b {
            let eff = chart.effectiveness(a, b);
            prop_assert!((eff - 2.0).abs() < f64::EPSILON,
                "{a:?} vs {b:?} = {eff}, expected 2.0");
        }
    });
}

#[test]
fn test_stat_stage_multiplier_range() {
    proptest!(|(stage in -6i32..=6i32)| {
        let mult = calc::stat_stage_multiplier(stage);
        prop_assert!(mult > 0.0, "stat_stage({stage}) = {mult} <= 0");
        prop_assert!(mult <= 4.0, "stat_stage({stage}) = {mult} > 4.0");
    });
}

#[test]
fn test_stat_stage_multiplier_monotonic() {
    proptest!(|(a in -6i32..=5i32)| {
        let b = a + 1;
        let ma = calc::stat_stage_multiplier(a);
        let mb = calc::stat_stage_multiplier(b);
        prop_assert!(mb > ma, "stat_stage({b})={mb} should be > stat_stage({a})={ma}");
    });
}

#[test]
fn test_stat_stage_zero_is_identity() {
    let mult = calc::stat_stage_multiplier(0);
    assert!((mult - 1.0).abs() < f64::EPSILON, "stat_stage(0) = {mult}");
}

#[test]
fn test_raw_damage_at_least_one() {
    proptest!(|(atk in 1.0f64..=1000.0f64, defense in 1.0f64..=1000.0f64, power in 1u32..=200u32)| {
        let dmg = calc::calculate_raw_damage(atk, power, defense);
        prop_assert!(dmg >= 1, "damage {dmg} < 1 for atk={atk}, power={power}, defense={defense}");
    });
}

#[test]
fn test_raw_damage_non_decreasing_with_atk() {
    proptest!(|(atk_low in 1.0f64..=500.0f64, atk_high in 501.0f64..=1000.0f64, defense in 1.0f64..=200.0f64, power in 1u32..=100u32)| {
        let dmg_low = calc::calculate_raw_damage(atk_low, power, defense);
        let dmg_high = calc::calculate_raw_damage(atk_high, power, defense);
        prop_assert!(dmg_high >= dmg_low,
            "damage decreased when atk increased: {dmg_high} < {dmg_low}");
    });
}

#[test]
fn test_all_type_elements_distinct() {
    let mut set = std::collections::HashSet::new();
    for t in TypeElement::ALL {
        let s = t.to_string();
        assert!(set.insert(s.clone()), "duplicate string {s}");
    }
}
