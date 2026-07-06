use rand::Rng;

use xiangke_core::moves::MoveData;
use xiangke_core::types::{DamageCategory, EffectType};
use xiangke_core::types::TypeChart;

use crate::participant::BattleParticipant;
use crate::state::BattleError;

const STAB_MULTIPLIER: f64 = 1.2;
const MIN_VARIANCE: f64 = 0.85;
const MAX_VARIANCE: f64 = 1.0;
const CRITICAL_CHANCE: f64 = 6.0;
const CRITICAL_MULTIPLIER: f64 = 1.5;

#[derive(Debug, Clone)]
pub struct ActionResult {
    pub damage_dealt: u32,
    pub target_index: usize,
    pub hit: bool,
    pub is_critical: bool,
    pub type_effectiveness: f64,
    pub is_super_effective: bool,
    pub is_not_very_effective: bool,
    pub is_immune: bool,
    pub status_applied: Option<EffectType>,
    pub status_resisted: bool,
    pub recoil_damage: u32,
    pub heal_amount: u32,
    pub raw_damage: u32,
    pub log_message: String,
}

impl ActionResult {
    fn miss(target_index: usize, attacker_name: &str, move_name: &str) -> Self {
        Self {
            damage_dealt: 0,
            target_index,
            hit: false,
            is_critical: false,
            type_effectiveness: 1.0,
            is_super_effective: false,
            is_not_very_effective: false,
            is_immune: false,
            status_applied: None,
            status_resisted: false,
            recoil_damage: 0,
            heal_amount: 0,
            raw_damage: 0,
            log_message: format!("{attacker_name} used {move_name} but it missed!"),
        }
    }
}

pub fn check_accuracy(accuracy: u32, rng: &mut impl Rng) -> bool {
    rng.r#gen::<f64>() * 100.0 < accuracy as f64
}

pub fn check_effect_chance(chance: u32, rng: &mut impl Rng) -> bool {
    rng.r#gen::<f64>() * 100.0 < chance as f64
}

pub fn has_stab(attacker: &BattleParticipant, mv: &MoveData) -> bool {
    attacker.character_data.element == mv.element
}

fn build_damage_log(
    attacker_name: &str,
    defender_name: &str,
    move_name: &str,
    result: &ActionResult,
) -> String {
    let mut parts = vec![format!("{attacker_name} used {move_name}!")];
    if result.is_immune {
        parts.push(format!("It doesn't affect {defender_name}..."));
    } else if result.is_super_effective {
        parts.push("It's super effective!".into());
    } else if result.is_not_very_effective {
        parts.push("It's not very effective...".into());
    }
    if result.is_critical {
        parts.push("A critical hit!".into());
    }
    if result.recoil_damage > 0 {
        parts.push(format!("{attacker_name} took {} recoil damage!", result.recoil_damage));
    }
    parts.join(" ")
}

pub fn calculate_damage(
    attacker: &mut BattleParticipant,
    defender: &mut BattleParticipant,
    mv: &MoveData,
    target_index: usize,
    rng: &mut impl Rng,
) -> Result<ActionResult, BattleError> {
    if attacker.is_defeated {
        return Err(BattleError::DefeatedParticipant(
            "Attacker is defeated".into(),
        ));
    }
    if defender.is_defeated {
        return Err(BattleError::DefeatedParticipant(
            "Defender is defeated".into(),
        ));
    }

    if !check_accuracy(mv.accuracy, rng) {
        return Ok(ActionResult::miss(
            target_index,
            &attacker.character_data.name,
            &mv.name,
        ));
    }

    let mut result = ActionResult::new(target_index);

    if mv.power > 0 {
        let (effective_atk, effective_def) = match mv.damage_category {
            DamageCategory::Physical => {
                (attacker.effective_attack(), defender.effective_defense())
            }
            DamageCategory::Arts => {
                (attacker.effective_intelligence(), defender.effective_spirit())
            }
        };
        let effective_def = effective_def.max(1.0);
        result.raw_damage = ((effective_atk * mv.power as f64 * 0.8) / effective_def)
            .ceil()
            .max(1.0) as u32;

        let type_chart = TypeChart::default();
        let def_secondary = defender.character_data.secondary_element
            .unwrap_or(defender.character_data.element);
        result.type_effectiveness = type_chart.effectiveness_dual(
            mv.element,
            defender.character_data.element,
            def_secondary,
        );
        result.is_super_effective = result.type_effectiveness > 1.0;
        result.is_not_very_effective = result.type_effectiveness > 0.0
            && result.type_effectiveness < 1.0;
        result.is_immune = result.type_effectiveness == 0.0;

        let stab_multiplier = if has_stab(attacker, mv) {
            STAB_MULTIPLIER
        } else {
            1.0
        };

        let variance: f64 = rng.gen_range(MIN_VARIANCE..MAX_VARIANCE);

        let mut final_damage = (result.raw_damage as f64
            * result.type_effectiveness
            * stab_multiplier
            * variance)
            .max(1.0) as u32;

        if result.is_immune {
            final_damage = 0;
        }

        if rng.r#gen::<f64>() * 100.0 < CRITICAL_CHANCE {
            result.is_critical = true;
            final_damage = (final_damage as f64 * CRITICAL_MULTIPLIER) as u32;
        }

        result.damage_dealt = defender.take_damage(final_damage);

        if mv.recoil > 0 && result.damage_dealt > 0 {
            let recoil = (result.damage_dealt as f64 * mv.recoil as f64 / 100.0)
                .ceil()
                .max(1.0) as u32;
            result.recoil_damage = attacker.take_damage(recoil);
        }

        result.log_message = build_damage_log(
            &attacker.character_data.name,
            &defender.character_data.name,
            &mv.name,
            &result,
        );
    }

    if mv.healing > 0 {
        let heal = (attacker.max_hp as f64 * mv.healing as f64 / 100.0)
            .ceil()
            .max(1.0) as u32;
        result.heal_amount = attacker.heal(heal);
        if result.log_message.is_empty() {
            result.log_message = format!(
                "{} used {} and restored {} HP!",
                attacker.character_data.name,
                mv.name,
                result.heal_amount,
            );
        } else {
            result.log_message = format!(
                "{}\n{} restored {} HP!",
                result.log_message,
                attacker.character_data.name,
                result.heal_amount,
            );
        }
    }

    if mv.effect != EffectType::None && mv.effect_chance > 0 {
        let resisted = defender.has_status(mv.effect);
        if !resisted && check_effect_chance(mv.effect_chance, rng) {
            defender.apply_status(mv.effect);
            result.status_applied = Some(mv.effect);
        } else {
            result.status_resisted = resisted;
        }
    }

    Ok(result)
}

impl ActionResult {
    fn new(target_index: usize) -> Self {
        Self {
            damage_dealt: 0,
            target_index,
            hit: true,
            is_critical: false,
            type_effectiveness: 1.0,
            is_super_effective: false,
            is_not_very_effective: false,
            is_immune: false,
            status_applied: None,
            status_resisted: false,
            recoil_damage: 0,
            heal_amount: 0,
            raw_damage: 0,
            log_message: String::new(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::participant::Team;
    use rand::SeedableRng;
    use rand::rngs::StdRng;
    use xiangke_core::character::{CharacterData, Stats};
    use xiangke_core::types::TypeElement;

    fn make_attacker() -> (BattleParticipant, BattleParticipant) {
        let attacker = BattleParticipant::new(
            CharacterData {
                id: "attacker".into(),
                name: "Attacker".into(),
                element: TypeElement::Fire,
                secondary_element: None,
                base_stats: Stats {
                    hp: 200,
                    attack: 100,
                    defense: 50,
                    speed: 60,
                    intelligence: 80,
                    spirit: 40,
                },
                moves: vec![],
                description: "".into(),
            },
            Team::Player,
            0,
        ).unwrap();
        let defender = BattleParticipant::new(
            CharacterData {
                id: "defender".into(),
                name: "Defender".into(),
                element: TypeElement::Wood,
                secondary_element: None,
                base_stats: Stats {
                    hp: 150,
                    attack: 60,
                    defense: 50,
                    speed: 40,
                    intelligence: 50,
                    spirit: 50,
                },
                moves: vec![],
                description: "".into(),
            },
            Team::Enemy,
            1,
        ).unwrap();
        (attacker, defender)
    }

    fn make_move() -> MoveData {
        MoveData {
            id: "fire_strike".into(),
            name: "Fire Strike".into(),
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
            description: "".into(),
        }
    }

    #[test]
    fn test_damage_calculation_basic() {
        let (mut atk, mut def) = make_attacker();
        let mv = make_move();
        let mut rng = StdRng::seed_from_u64(42);
        let result = calculate_damage(&mut atk, &mut def, &mv, 1, &mut rng).unwrap();
        assert!(result.hit);
        assert!(result.damage_dealt > 0);
    }

    #[test]
    fn test_damage_arts() {
        let (mut atk, mut def) = make_attacker();
        let mut mv = make_move();
        mv.damage_category = DamageCategory::Arts;
        let mut rng = StdRng::seed_from_u64(42);
        let result = calculate_damage(&mut atk, &mut def, &mv, 1, &mut rng).unwrap();
        assert!(result.hit);
    }

    #[test]
    fn test_miss() {
        let (mut atk, mut def) = make_attacker();
        let mut mv = make_move();
        mv.accuracy = 0;
        let mut rng = StdRng::seed_from_u64(42);
        let result = calculate_damage(&mut atk, &mut def, &mv, 1, &mut rng).unwrap();
        assert!(!result.hit);
        assert_eq!(result.damage_dealt, 0);
    }

    #[test]
    fn test_stab() {
        let (mut atk, mut def) = make_attacker();
        let mv = make_move();
        assert!(has_stab(&atk, &mv));
        let mut rng = StdRng::seed_from_u64(42);
        let result = calculate_damage(&mut atk, &mut def, &mv, 1, &mut rng).unwrap();
        assert!(result.hit);
    }

    #[test]
    fn test_defeated_attacker_error() {
        let (mut atk, mut def) = make_attacker();
        atk.is_defeated = true;
        let mv = make_move();
        let mut rng = StdRng::seed_from_u64(42);
        let result = calculate_damage(&mut atk, &mut def, &mv, 1, &mut rng);
        assert!(result.is_err());
    }

    #[test]
    fn test_defeated_defender_error() {
        let (mut atk, mut def) = make_attacker();
        def.is_defeated = true;
        let mv = make_move();
        let mut rng = StdRng::seed_from_u64(42);
        let result = calculate_damage(&mut atk, &mut def, &mv, 1, &mut rng);
        assert!(result.is_err());
    }

    #[test]
    fn test_recoil() {
        let (mut atk, mut def) = make_attacker();
        let mut mv = make_move();
        mv.recoil = 25;
        let mut rng = StdRng::seed_from_u64(42);
        let start_hp = atk.current_hp;
        let result = calculate_damage(&mut atk, &mut def, &mv, 1, &mut rng).unwrap();
        if result.damage_dealt > 0 {
            assert!(result.recoil_damage > 0);
            assert!(atk.current_hp < start_hp);
        }
    }

    #[test]
    fn test_healing() {
        let (mut atk, mut def) = make_attacker();
        let mut mv = make_move();
        mv.power = 0;
        mv.healing = 30;
        let mut rng = StdRng::seed_from_u64(42);
        let start_hp = atk.current_hp;
        atk.take_damage(50);
        let result = calculate_damage(&mut atk, &mut def, &mv, 1, &mut rng).unwrap();
        assert!(result.heal_amount > 0);
        assert!(atk.current_hp > start_hp - 50);
    }

    #[test]
    fn test_status_application() {
        let (mut atk, mut def) = make_attacker();
        let mut mv = make_move();
        mv.effect = EffectType::Burn;
        mv.effect_chance = 100;
        let mut rng = StdRng::seed_from_u64(42);
        let result = calculate_damage(&mut atk, &mut def, &mv, 1, &mut rng).unwrap();
        assert!(result.status_applied.is_some());
        assert!(def.has_status(EffectType::Burn));
    }

    #[test]
    fn test_status_resisted() {
        let (mut atk, mut def) = make_attacker();
        def.apply_status(EffectType::Burn);
        let mut mv = make_move();
        mv.effect = EffectType::Burn;
        mv.effect_chance = 100;
        let mut rng = StdRng::seed_from_u64(42);
        let result = calculate_damage(&mut atk, &mut def, &mv, 1, &mut rng).unwrap();
        assert!(result.status_resisted);
        assert!(result.status_applied.is_none());
    }
}
