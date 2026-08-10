use rand::Rng;

use xiangke_core::calc;
use xiangke_core::moves::MoveData;
use xiangke_core::types::TypeChart;
use xiangke_core::types::{DamageCategory, EffectType, Stat, StatModTarget};

use crate::participant::BattleParticipant;
use crate::state::BattleError;

const MIN_VARIANCE: f64 = 0.85;
const MAX_VARIANCE: f64 = 1.0;
const CRITICAL_CHANCE: f64 = 6.0;
const CRITICAL_MULTIPLIER: f64 = 1.5;

/// The result of a single action execution during battle.
#[derive(Debug, Clone)]
pub struct ActionResult {
    /// Damage dealt to the target.
    pub damage_dealt: u32,
    /// Index of the target participant.
    pub target_index: usize,
    /// Whether the move landed (false = miss).
    pub hit: bool,
    /// Whether the hit was critical.
    pub is_critical: bool,
    /// Type effectiveness multiplier (0.0–4.0).
    pub type_effectiveness: f64,
    /// True when type_effectiveness > 1.0.
    pub is_super_effective: bool,
    /// True when 0 < type_effectiveness < 1.0.
    pub is_not_very_effective: bool,
    /// True when type_effectiveness == 0.0.
    pub is_immune: bool,
    /// Status effect that was applied, if any.
    pub status_applied: Option<EffectType>,
    /// True if the target already had this status.
    pub status_resisted: bool,
    /// Recoil damage dealt back to the attacker.
    pub recoil_damage: u32,
    /// HP restored to the attacker (healing moves).
    pub heal_amount: u32,
    /// Raw damage before any variance/critical modifications.
    pub raw_damage: u32,
    /// Stat that was modified by this move (if any).
    pub stat_mod_applied: Option<Stat>,
    /// Stage change applied to the stat (positive = buff, negative = debuff).
    pub stat_mod_stage: i32,
    /// Formatted log message describing the action result.
    pub log_message: String,
}

/// Rolls a percentage check: returns `true` if a random value in [0, 100)
/// is less than the given percentage threshold.
fn roll_percent(percent: u32, rng: &mut impl Rng) -> bool {
    rng.r#gen::<f64>() * 100.0 < percent as f64
}

/// Checks whether a move hits based on its accuracy stat and a random roll.
/// Returns `true` if the generated value is less than the accuracy.
pub fn check_accuracy(accuracy: u32, rng: &mut impl Rng) -> bool {
    roll_percent(accuracy, rng)
}

/// Checks whether a secondary effect triggers based on its chance and a random roll.
/// Returns `true` if the generated value is less than the effect chance.
pub fn check_effect_chance(chance: u32, rng: &mut impl Rng) -> bool {
    roll_percent(chance, rng)
}

/// Returns `true` if the attacker's element matches the move's element (Same-Type Attack Bonus).
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
        parts.push(format!(
            "{attacker_name} took {} recoil damage!",
            result.recoil_damage
        ));
    }
    parts.join(" ")
}

/// Returns the display name for a stat, used in log messages.
fn stat_name(stat: Stat) -> &'static str {
    match stat {
        Stat::Attack => "Attack",
        Stat::Defense => "Defense",
        Stat::Speed => "Speed",
        Stat::Intelligence => "Intelligence",
        Stat::Spirit => "Spirit",
    }
}

#[derive(Debug, Clone)]
struct RawDamage {
    pub raw_damage: u32,
    pub type_effectiveness: f64,
    pub is_super_effective: bool,
    pub is_not_very_effective: bool,
    pub is_immune: bool,
}

fn calculate_raw_damage(
    attacker: &BattleParticipant,
    defender: &BattleParticipant,
    mv: &MoveData,
    type_chart: &TypeChart,
) -> RawDamage {
    let (effective_atk, effective_def) = match mv.damage_category {
        DamageCategory::Physical => (attacker.effective_attack(), defender.effective_defense()),
        DamageCategory::Arts => (
            attacker.effective_intelligence(),
            defender.effective_spirit(),
        ),
    };
    let raw_damage = calc::calculate_raw_damage(effective_atk, mv.power, effective_def);

    let def_secondary = defender
        .character_data
        .secondary_element
        .unwrap_or(defender.character_data.element);
    let type_effectiveness =
        type_chart.effectiveness_dual(mv.element, defender.character_data.element, def_secondary);
    let is_super_effective = type_effectiveness > 1.0;
    let is_not_very_effective = type_effectiveness > 0.0 && type_effectiveness < 1.0;
    let is_immune = type_effectiveness == 0.0;

    RawDamage {
        raw_damage,
        type_effectiveness,
        is_super_effective,
        is_not_very_effective,
        is_immune,
    }
}

fn apply_variance(raw_damage: u32, rng: &mut impl Rng) -> u32 {
    let variance: f64 = rng.gen_range(MIN_VARIANCE..MAX_VARIANCE);
    (raw_damage as f64 * variance).max(1.0) as u32
}

fn apply_critical_hit(damage: u32, rng: &mut impl Rng) -> (u32, bool) {
    if rng.r#gen::<f64>() * 100.0 < CRITICAL_CHANCE {
        let critical_damage = (damage as f64 * CRITICAL_MULTIPLIER) as u32;
        (critical_damage, true)
    } else {
        (damage, false)
    }
}

fn apply_recoil_damage(attacker: &mut BattleParticipant, damage_dealt: u32, mv: &MoveData) -> u32 {
    if mv.recoil > 0 && damage_dealt > 0 {
        let recoil = (damage_dealt as f64 * mv.recoil as f64 / 100.0)
            .ceil()
            .max(1.0) as u32;
        attacker.take_damage(recoil)
    } else {
        0
    }
}

fn apply_healing(attacker: &mut BattleParticipant, mv: &MoveData) -> u32 {
    if mv.healing > 0 {
        let heal = (attacker.max_hp as f64 * mv.healing as f64 / 100.0)
            .ceil()
            .max(1.0) as u32;
        attacker.heal(heal)
    } else {
        0
    }
}

fn apply_status_effect(
    defender: &mut BattleParticipant,
    mv: &MoveData,
    rng: &mut impl Rng,
) -> (Option<EffectType>, bool) {
    if mv.effect != EffectType::None && mv.effect_chance > 0 {
        let resisted = defender.has_status(mv.effect);
        if !resisted && check_effect_chance(mv.effect_chance, rng) {
            defender.apply_status(mv.effect);
            (Some(mv.effect), false)
        } else {
            (None, resisted)
        }
    } else {
        (None, false)
    }
}

/// Calculates damage for an attack action and returns the full result.
///
/// The damage pipeline:
/// 1. Checks if attacker/defender are alive.
/// 2. Rolls accuracy — returns miss on failure.
/// 3. Calculates raw damage from base power, effective stats, STAB, and type chart.
/// 4. Applies variance (±15% uniform random).
/// 5. Rolls for critical hit (1.5× multiplier, ~6% base chance).
/// 6. Applies secondary effect (status, recoil, healing) if applicable.
/// 7. Builds a formatted log message.
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

    // Apply stat modification (buff/debuff) for non-damaging and damaging moves alike.
    if mv.has_stat_mod() {
        let stat = mv.stat_mod_stat.unwrap();
        let stage_delta = mv.stat_mod_stage;
        let (target_name, target_stat_name) = match mv.stat_mod_target {
            StatModTarget::Self_ => {
                let name = attacker.character_data.name.clone();
                attacker.apply_stat_stage(stat, stage_delta);
                (name, stat_name(stat))
            }
            StatModTarget::Target => {
                let name = defender.character_data.name.clone();
                defender.apply_stat_stage(stat, stage_delta);
                (name, stat_name(stat))
            }
        };
        result.stat_mod_applied = Some(stat);
        result.stat_mod_stage = stage_delta;

        let direction = if stage_delta > 0 { "rose" } else { "fell" };
        let intensity = if stage_delta.abs() >= 2 {
            " sharply"
        } else {
            ""
        };
        let log = format!("{target_name}'s {target_stat_name}{intensity} {direction}!");
        if result.log_message.is_empty() {
            result.log_message = log;
        } else {
            result.log_message = format!("{}\n{log}", result.log_message);
        }
    }

    if mv.power > 0 {
        let type_chart = TypeChart::default();
        let raw_damage = calculate_raw_damage(attacker, defender, mv, &type_chart);
        let variance_damage = apply_variance(raw_damage.raw_damage, rng);
        let (critical_damage, is_critical) = apply_critical_hit(variance_damage, rng);
        let mut final_damage = critical_damage;

        if raw_damage.is_immune {
            final_damage = 0;
        }

        result = ActionResult {
            target_index,
            is_critical,
            ..ActionResult::from(raw_damage)
        };

        result.damage_dealt = defender.take_damage(final_damage);

        result.recoil_damage = apply_recoil_damage(attacker, result.damage_dealt, mv);

        result.log_message = build_damage_log(
            &attacker.character_data.name,
            &defender.character_data.name,
            &mv.name,
            &result,
        );
    }

    if mv.healing > 0 {
        result.heal_amount = apply_healing(attacker, mv);
        if result.log_message.is_empty() {
            result.log_message = format!(
                "{} used {} and restored {} HP!",
                attacker.character_data.name, mv.name, result.heal_amount,
            );
        } else {
            result.log_message = format!(
                "{}\n{} restored {} HP!",
                result.log_message, attacker.character_data.name, result.heal_amount,
            );
        }
    }

    let (status_applied, status_resisted) = apply_status_effect(defender, mv, rng);
    result.status_applied = status_applied;
    result.status_resisted = status_resisted;

    // Fallback: ensure non-damaging moves always have a log message.
    if result.log_message.is_empty() {
        result.log_message = format!("{} used {}!", attacker.character_data.name, mv.name,);
    }

    Ok(result)
}

impl ActionResult {
    /// Creates an `ActionResult` for a damaging move.
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
            stat_mod_applied: None,
            stat_mod_stage: 0,
            log_message: String::new(),
        }
    }

    /// Creates a miss result with a formatted log message.
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
            stat_mod_applied: None,
            stat_mod_stage: 0,
            log_message: format!("{attacker_name} used {move_name} but it missed!"),
        }
    }
}

impl From<RawDamage> for ActionResult {
    fn from(raw: RawDamage) -> Self {
        Self {
            damage_dealt: 0,
            target_index: 0,
            hit: true,
            is_critical: false,
            type_effectiveness: raw.type_effectiveness,
            is_super_effective: raw.is_super_effective,
            is_not_very_effective: raw.is_not_very_effective,
            is_immune: raw.is_immune,
            status_applied: None,
            status_resisted: false,
            recoil_damage: 0,
            heal_amount: 0,
            raw_damage: raw.raw_damage,
            stat_mod_applied: None,
            stat_mod_stage: 0,
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
        )
        .unwrap();
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
        )
        .unwrap();
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
            stat_mod_target: StatModTarget::Self_,
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

    #[test]
    fn test_super_effective_flag() {
        let (mut atk, mut def) = make_attacker();
        let mv = make_move();
        def.character_data.element = TypeElement::Water; // Fire beats Water (2.0)
        let mut rng = StdRng::seed_from_u64(42);
        let result = calculate_damage(&mut atk, &mut def, &mv, 1, &mut rng).unwrap();
        assert!(result.hit);
        assert!(
            result.is_super_effective,
            "Fire vs Water should be super effective (got eff={}, expected 2.0)",
            result.type_effectiveness
        );
    }

    #[test]
    fn test_not_very_effective_flag() {
        let (mut atk, mut def) = make_attacker();
        let mv = make_move();
        // Attacker is Fire, defender is Wood (default) → Fire vs Wood = 0.5
        let mut rng = StdRng::seed_from_u64(42);
        let result = calculate_damage(&mut atk, &mut def, &mv, 1, &mut rng).unwrap();
        assert!(result.hit);
        assert!(
            result.is_not_very_effective,
            "Fire vs Wood should be not very effective (got eff={}, expected 0.5)",
            result.type_effectiveness
        );
    }

    #[test]
    fn test_immune_flag() {
        let (mut atk, mut def) = make_attacker();
        let mut mv = make_move();
        mv.element = TypeElement::Wood;
        def.character_data.element = TypeElement::Metal; // Metal resists Wood
        def.character_data.secondary_element = Some(TypeElement::Yin);
        let mut rng = StdRng::seed_from_u64(42);
        let result = calculate_damage(&mut atk, &mut def, &mv, 1, &mut rng).unwrap();
        if result.is_immune {
            assert_eq!(result.damage_dealt, 0);
        }
    }

    #[test]
    fn test_critical_hit_flag() {
        // Use fixed seed that produces a crit
        for seed in 0..100 {
            let (mut atk, mut def) = make_attacker();
            let mv = make_move();
            let mut rng = StdRng::seed_from_u64(seed);
            let result = calculate_damage(&mut atk, &mut def, &mv, 1, &mut rng).unwrap();
            if result.is_critical {
                assert!(result.damage_dealt > 0);
                return;
            }
        }
        // CRITICAL_CHANCE=6%, seeds 0..100 should trigger ~6 crits
        panic!("No critical hit occurred in 100 seeds — possible RNG issue");
    }

    #[test]
    fn test_damage_log_immune_message() {
        let msg = build_damage_log(
            "Attacker",
            "Defender",
            "Test",
            &ActionResult {
                damage_dealt: 0,
                target_index: 1,
                hit: true,
                is_critical: false,
                type_effectiveness: 0.0,
                is_super_effective: false,
                is_not_very_effective: false,
                is_immune: true,
                status_applied: None,
                status_resisted: false,
                recoil_damage: 0,
                heal_amount: 0,
                raw_damage: 0,
                stat_mod_applied: None,
                stat_mod_stage: 0,
                log_message: String::new(),
            },
        );
        assert!(msg.contains("doesn't affect"));
    }

    #[test]
    fn test_damage_log_super_effective() {
        let msg = build_damage_log(
            "A",
            "B",
            "Fire",
            &ActionResult {
                is_super_effective: true,
                is_not_very_effective: false,
                is_immune: false,
                is_critical: true,
                recoil_damage: 0,
                ..ActionResult::new(1)
            },
        );
        assert!(msg.contains("super effective"));
        assert!(msg.contains("critical"));
    }

    #[test]
    fn test_damage_log_recoil() {
        let msg = build_damage_log(
            "A",
            "B",
            "Strike",
            &ActionResult {
                is_super_effective: false,
                is_not_very_effective: false,
                is_immune: false,
                is_critical: false,
                recoil_damage: 10,
                ..ActionResult::new(1)
            },
        );
        assert!(msg.contains("recoil"));
    }

    #[test]
    fn test_accuracy_check_edge() {
        let mut rng = StdRng::seed_from_u64(42);
        assert!(check_accuracy(100, &mut rng));
        assert!(!check_accuracy(0, &mut rng));
    }

    #[test]
    fn test_no_stab_for_different_type() {
        let (atk, _) = make_attacker();
        let mut mv = make_move();
        mv.element = TypeElement::Water; // Attacker is Fire
        assert!(!has_stab(&atk, &mv));
    }

    #[test]
    fn test_stat_mod_self_buff() {
        let (mut atk, mut def) = make_attacker();
        let mut mv = make_move();
        mv.power = 0;
        mv.stat_mod_stat = Some(Stat::Defense);
        mv.stat_mod_stage = 2;
        mv.stat_mod_target = StatModTarget::Self_;
        let mut rng = StdRng::seed_from_u64(42);
        let result = calculate_damage(&mut atk, &mut def, &mv, 1, &mut rng).unwrap();
        assert_eq!(atk.stat_stage(Stat::Defense), 2);
        assert_eq!(result.stat_mod_applied, Some(Stat::Defense));
        assert_eq!(result.stat_mod_stage, 2);
        assert!(result.log_message.contains("rose"));
        assert!(result.log_message.contains("sharply"));
    }

    #[test]
    fn test_stat_mod_target_debuff() {
        let (mut atk, mut def) = make_attacker();
        let mut mv = make_move();
        mv.power = 0;
        mv.stat_mod_stat = Some(Stat::Attack);
        mv.stat_mod_stage = -1;
        mv.stat_mod_target = StatModTarget::Target;
        let mut rng = StdRng::seed_from_u64(42);
        let result = calculate_damage(&mut atk, &mut def, &mv, 1, &mut rng).unwrap();
        assert_eq!(def.stat_stage(Stat::Attack), -1);
        assert_eq!(result.stat_mod_applied, Some(Stat::Attack));
        assert_eq!(result.stat_mod_stage, -1);
        assert!(result.log_message.contains("fell"));
    }

    #[test]
    fn test_non_damaging_move_log_message() {
        let (mut atk, mut def) = make_attacker();
        let mut mv = make_move();
        mv.power = 0;
        mv.stat_mod_stat = None;
        mv.stat_mod_stage = 0;
        mv.healing = 0;
        mv.effect = EffectType::None;
        let mut rng = StdRng::seed_from_u64(42);
        let result = calculate_damage(&mut atk, &mut def, &mv, 1, &mut rng).unwrap();
        assert!(!result.log_message.is_empty());
        assert!(result.log_message.contains("used"));
    }
}
