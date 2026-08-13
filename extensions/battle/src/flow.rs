use std::collections::HashMap;
use std::sync::OnceLock;

use rand::Rng;

use xiangke_core::calc;
use xiangke_core::status::StatusEffectData;
use xiangke_core::types::DamageCategory;
use xiangke_core::types::EffectType;
use xiangke_core::types::TypeChart;
use xiangke_core::types::TypeElement;

use crate::action::{self, ActionResult};
use crate::manager::{auto_replace, execute_switch, find_front_index, living_bench_indices};
use crate::participant::BattleParticipant;
use crate::participant::Team;
use crate::state::{BattleError, BattleState};

/// Lazily-initialized shared type chart, built once per process.
static TYPE_CHART: OnceLock<TypeChart> = OnceLock::new();

/// Returns the shared `TypeChart` instance.
fn type_chart() -> &'static TypeChart {
    TYPE_CHART.get_or_init(TypeChart::default)
}

/// Minimum variance factor assumed when estimating whether an attack can KO.
const MIN_VARIANCE_FACTOR: f64 = 0.85;
/// Type-match bonus multiplier (matches the battle damage pipeline).
const TYPE_MATCH_MULTIPLIER: f64 = 1.5;

/// The action selected by an AI strategy.
#[derive(Debug, Clone)]
pub enum AIAction {
    /// Attack with the given move against a target participant.
    Attack {
        /// ID of the move to use.
        move_id: String,
        /// Target participant index.
        target_index: usize,
        /// Heuristic score for this action (higher = preferred).
        score: f64,
    },
    /// Switch the front character with a benched participant.
    Switch {
        /// Index of the benched participant to bring in.
        bench_index: usize,
        /// Heuristic score for this action (higher = preferred).
        score: f64,
    },
}

/// Trait for AI decision-making strategies.
pub trait AiStrategy {
    /// Selects an action for the given participant, or `None` if no valid action exists.
    fn select_action(&self, state: &BattleState, participant_index: usize) -> Option<AIAction>;
}

/// Threshold below which the AI considers switching due to low HP.
const SWITCH_HP_RATIO: f64 = 0.3;
/// Type-effectiveness threshold that counts as a disadvantage.
const SWITCH_TYPE_THRESHOLD: f64 = 0.5;

/// Computes the type effectiveness of a move element against a defender's element(s).
///
/// Uses the single-type lookup when the defender has no secondary element, and
/// the dual-type lookup (product, clamped) otherwise.
fn move_effectiveness_against(
    type_chart: &TypeChart,
    move_element: TypeElement,
    defender: &BattleParticipant,
) -> f64 {
    match defender.character_data.secondary_element {
        Some(secondary) => {
            type_chart.effectiveness_dual(move_element, defender.character_data.element, secondary)
        }
        None => type_chart.effectiveness(move_element, defender.character_data.element),
    }
}

/// A basic AI that targets the opponent's front character and switches when
/// the front is at a disadvantage.
pub struct BasicAi;

impl BasicAi {
    /// Creates a new `BasicAi` instance.
    pub fn new() -> Self {
        Self
    }

    /// Computes the type effectiveness of the attacker's best move against the defender.
    ///
    /// Returns `-1.0` when the attacker has no usable damaging move, so that
    /// "no move" is distinguishable from a 0.0 effectiveness matchup.
    fn best_effectiveness(
        &self,
        state: &BattleState,
        attacker_index: usize,
        defender_index: usize,
    ) -> f64 {
        let attacker = &state.participants[attacker_index];
        let defender = &state.participants[defender_index];
        let type_chart = type_chart();
        let mut best: f64 = -1.0;
        for move_id in &attacker.character_data.moves {
            let Some(mv) = state.move_lookup.get(move_id) else {
                continue;
            };
            if mv.power == 0 {
                continue;
            }
            let eff = move_effectiveness_against(type_chart, mv.element, defender);
            best = best.max(eff);
        }
        best
    }

    fn score_move(&self, state: &BattleState, move_id: &str, target_index: usize) -> f64 {
        let Some(mv) = state.move_lookup.get(move_id) else {
            return -1.0;
        };
        if mv.power == 0 {
            return -1.0;
        }
        let defender = &state.participants[target_index];
        let effectiveness = move_effectiveness_against(type_chart(), mv.element, defender);
        mv.power as f64 * effectiveness * mv.accuracy as f64 / 100.0
    }

    /// Estimates the minimum damage `move_id` would deal to the defender,
    /// assuming worst-case variance and no critical hit.
    fn estimate_min_damage(
        &self,
        state: &BattleState,
        attacker_index: usize,
        defender_index: usize,
        move_id: &str,
    ) -> u32 {
        let attacker = &state.participants[attacker_index];
        let defender = &state.participants[defender_index];
        let Some(mv) = state.move_lookup.get(move_id) else {
            return 0;
        };
        if mv.power == 0 {
            return 0;
        }
        let (atk, def) = match mv.damage_category {
            DamageCategory::Physical => (attacker.effective_attack(), defender.effective_defense()),
            DamageCategory::Arts => (
                attacker.effective_intelligence(),
                defender.effective_spirit(),
            ),
        };
        let base = calc::calculate_raw_damage(atk, mv.power, def) as f64;
        let effectiveness = move_effectiveness_against(type_chart(), mv.element, defender);
        if effectiveness == 0.0 {
            return 0;
        }
        let type_match = if attacker.character_data.element == mv.element {
            TYPE_MATCH_MULTIPLIER
        } else {
            1.0
        };
        ((base * type_match * effectiveness) * MIN_VARIANCE_FACTOR).max(1.0) as u32
    }
}

impl Default for BasicAi {
    fn default() -> Self {
        Self::new()
    }
}

impl AiStrategy for BasicAi {
    fn select_action(&self, state: &BattleState, participant_index: usize) -> Option<AIAction> {
        let attacker = &state.participants[participant_index];
        if attacker.is_defeated {
            return None;
        }

        let self_team = attacker.team;
        let enemy_team = match self_team {
            Team::Player => Team::Enemy,
            Team::Enemy => Team::Player,
        };

        // The only valid target is the opponent's front character.
        let target_index = find_front_index(state, enemy_team)?;

        // Find the best damaging move first; it is needed both for the attack
        // decision and for the attack-vs-switch comparison.
        let mut best_move: Option<(String, f64)> = None;
        for move_id in &attacker.character_data.moves {
            let Some(mv) = state.move_lookup.get(move_id) else {
                continue;
            };
            if mv.power == 0 || mv.healing > 0 {
                continue;
            }
            let score = self.score_move(state, move_id, target_index);
            if score > 0.0 && (best_move.is_none() || score > best_move.as_ref().unwrap().1) {
                best_move = Some((move_id.clone(), score));
            }
        }

        // Decide whether to switch: low front HP or type disadvantage
        // (including no usable move, where best effectiveness is -1.0).
        let hp_ratio = attacker.current_hp as f64 / attacker.max_hp as f64;
        let our_eff = self.best_effectiveness(state, participant_index, target_index);
        let should_switch = hp_ratio < SWITCH_HP_RATIO || our_eff <= SWITCH_TYPE_THRESHOLD;

        if should_switch {
            // Prefer attacking when the best move is guaranteed to defeat the
            // opponent's front, even at low HP.
            if let Some((move_id, score)) = &best_move {
                let est = self.estimate_min_damage(state, participant_index, target_index, move_id);
                let target_hp = state.participants[target_index].current_hp;
                if est >= target_hp {
                    return Some(AIAction::Attack {
                        move_id: move_id.clone(),
                        target_index,
                        score: *score,
                    });
                }
            }

            // Otherwise pick the living benched participant with the best type
            // effectiveness against the opponent's front.
            let mut best_bench: Option<(usize, f64)> = None;
            for bench_index in living_bench_indices(state, self_team) {
                let bench_eff = self.best_effectiveness(state, bench_index, target_index);
                if best_bench.is_none_or(|(_, eff)| bench_eff > eff) {
                    best_bench = Some((bench_index, bench_eff));
                }
            }
            if let Some((bench_index, bench_eff)) = best_bench {
                // Only switch if the bench character is not worse off.
                if bench_eff >= our_eff {
                    let score = (1.0 - hp_ratio) * 10.0 + bench_eff;
                    return Some(AIAction::Switch { bench_index, score });
                }
            }
        }

        match best_move {
            Some((move_id, score)) => Some(AIAction::Attack {
                move_id,
                target_index,
                score,
            }),
            None => {
                // Fallback: first usable damaging move — never a healing move.
                let fallback = attacker
                    .character_data
                    .moves
                    .iter()
                    .find(|move_id| {
                        state
                            .move_lookup
                            .get(move_id.as_str())
                            .is_some_and(|mv| mv.power > 0 && mv.healing == 0)
                    })?
                    .clone();
                Some(AIAction::Attack {
                    move_id: fallback,
                    target_index,
                    score: 0.0,
                })
            }
        }
    }
}

/// Processes start-of-turn effects for a participant (e.g. confusion self-damage).
/// Returns a list of log messages describing what occurred.
pub fn process_start_of_turn(
    participant: &mut BattleParticipant,
    configs: &HashMap<EffectType, StatusEffectData>,
    rng: &mut impl Rng,
) -> Vec<String> {
    let mut logs = Vec::new();
    if participant.has_status(EffectType::Confusion) {
        let cfg = configs
            .get(&EffectType::Confusion)
            .cloned()
            .unwrap_or_default();
        let self_dmg_frac = cfg.damage_per_turn.max(0.01);
        if rng.r#gen::<f64>() < 0.5 {
            let dmg = participant
                .take_damage((participant.max_hp as f64 * self_dmg_frac).ceil().max(1.0) as u32);
            logs.push(format!(
                "{} is confused and hit itself for {} damage!",
                participant.character_data.name, dmg
            ));
        }
    }
    logs
}

const DOT_EFFECTS: [EffectType; 2] = [EffectType::Burn, EffectType::Poison];

/// Processes end-of-turn effects for a participant (e.g. Burn/Poison damage-over-time).
/// Returns a list of log messages describing what occurred.
pub fn process_end_of_turn(
    participant: &mut BattleParticipant,
    configs: &HashMap<EffectType, StatusEffectData>,
) -> Vec<String> {
    let mut logs = Vec::new();
    for &effect in &DOT_EFFECTS {
        if participant.has_status(effect) {
            let cfg = configs.get(&effect).cloned().unwrap_or_default();
            let dmg = (participant.max_hp as f64 * cfg.damage_per_turn)
                .ceil()
                .max(1.0) as u32;
            let actual = participant.take_damage(dmg);
            logs.push(format!(
                "{} takes {} damage from {:?}!",
                participant.character_data.name, actual, effect
            ));
        }
    }
    logs
}

/// Executes a damaging action from one participant against another.
///
/// Performs the `split_at_mut` borrow split needed to mutate both the attacker
/// and the defender simultaneously, then delegates to
/// [`action::calculate_damage`]. The attacker and target indices are global
/// participant indices and may appear in any order.
///
/// Returns an error if either index is out of range, the attacker and target
/// are the same participant, or the move is not present in the battle state.
pub fn execute_damage_action(
    state: &mut BattleState,
    attacker_index: usize,
    target_index: usize,
    move_id: &str,
    rng: &mut impl Rng,
) -> Result<ActionResult, BattleError> {
    if attacker_index >= state.participants.len() || target_index >= state.participants.len() {
        return Err(BattleError::InvalidTarget(format!(
            "Index out of range: attacker={attacker_index}, target={target_index}"
        )));
    }
    if attacker_index == target_index {
        return Err(BattleError::InvalidTarget(
            "Attacker and target cannot be the same participant".into(),
        ));
    }

    let mv = state
        .move_lookup
        .get(move_id)
        .map(|m| m.as_ref().clone())
        .ok_or_else(|| BattleError::MoveNotFound(move_id.into()))?;

    if attacker_index < target_index {
        let (left, right) = state.participants.split_at_mut(target_index);
        action::calculate_damage(
            &mut left[attacker_index],
            &mut right[0],
            &mv,
            target_index,
            rng,
        )
    } else {
        let (left, right) = state.participants.split_at_mut(attacker_index);
        action::calculate_damage(
            &mut right[0],
            &mut left[target_index],
            &mv,
            target_index,
            rng,
        )
    }
}

/// The outcome of an executed AI turn.
#[derive(Debug)]
pub enum AiTurnOutcome {
    /// An attack was executed against a target participant.
    Attack(ActionResult),
    /// The team's front was switched with a benched participant.
    Switch {
        /// Index of the benched participant that entered the front.
        bench_index: usize,
        /// Log message describing the switch.
        log: String,
    },
    /// No action was available or possible.
    None,
}

/// Executes the AI turn for the battle's active participant.
///
/// Resolves the active participant, asks the [`BasicAi`] strategy for an
/// action, and executes it (an attack against the opponent's front or a bench
/// switch). If the attack defeats the target's front, the first living benched
/// participant of that team automatically replaces it.
pub fn execute_ai_turn(state: &mut BattleState, rng: &mut impl Rng) -> AiTurnOutcome {
    let attacker_index = match state.active_participant {
        Some(i) => i,
        None => return AiTurnOutcome::None,
    };

    let ai = BasicAi::new();
    let Some(action) = ai.select_action(state, attacker_index) else {
        return AiTurnOutcome::None;
    };

    match action {
        AIAction::Attack {
            move_id,
            target_index,
            ..
        } => match execute_damage_action(state, attacker_index, target_index, &move_id, rng) {
            Ok(result) => {
                if !result.log_message.is_empty() {
                    state.add_log(result.log_message.clone());
                }
                // If the target's front was defeated, bring in a replacement.
                if target_index < state.participants.len()
                    && state.participants[target_index].is_defeated
                {
                    let target_team = state.participants[target_index].team;
                    auto_replace(state, target_team);
                }
                AiTurnOutcome::Attack(result)
            }
            Err(_) => AiTurnOutcome::None,
        },
        AIAction::Switch { bench_index, .. } => {
            let self_team = state.participants[attacker_index].team;
            match execute_switch(state, self_team, bench_index) {
                Ok(log) => AiTurnOutcome::Switch { bench_index, log },
                Err(_) => AiTurnOutcome::None,
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_utils::{make_participant, make_status_configs};
    use rand::SeedableRng;
    use rand::rngs::StdRng;
    use std::collections::HashMap;
    use xiangke_core::moves::MoveData;
    use xiangke_core::types::DamageCategory;
    use xiangke_core::types::StatModTarget;

    fn make_state() -> BattleState {
        let mut participants = vec![
            make_participant(Team::Player, 100),
            make_participant(Team::Enemy, 100),
        ];
        for p in &mut participants {
            p.character_data.moves = vec!["fire_strike".into()];
        }
        let mut move_lookup: HashMap<String, Box<MoveData>> = HashMap::new();
        move_lookup.insert(
            "fire_strike".into(),
            Box::new(MoveData {
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
            }),
        );
        let mut state = BattleState::new(participants, move_lookup).unwrap();
        // Mark both teams' first participant as front.
        state.participants[0].is_front = true;
        state.participants[1].is_front = true;
        state
    }

    #[test]
    fn test_confusion_damage() {
        let mut p = make_participant(Team::Player, 100);
        p.apply_status(EffectType::Confusion);
        let configs = make_status_configs();
        let mut rng = StdRng::seed_from_u64(42);
        let logs = process_start_of_turn(&mut p, &configs, &mut rng);
        if !logs.is_empty() {
            assert!(logs[0].contains("confused"));
            assert!(p.current_hp < 100);
        }
    }

    #[test]
    fn test_dot_damage() {
        let mut p = make_participant(Team::Player, 100);
        p.apply_status(EffectType::Burn);
        let configs = make_status_configs();
        let logs = process_end_of_turn(&mut p, &configs);
        assert!(!logs.is_empty());
        assert!(p.current_hp < 100);
    }

    #[test]
    fn test_ai_targets_front() {
        let state = make_state();
        let ai = BasicAi::new();
        // Enemy (index 1) should always target the player's front (index 0).
        let action = ai.select_action(&state, 1);
        let action = action.unwrap();
        match action {
            AIAction::Attack { target_index, .. } => assert_eq!(target_index, 0),
            AIAction::Switch { .. } => panic!("expected attack"),
        }
    }

    #[test]
    fn test_ai_selects_best_move() {
        let mut state = make_state();
        state.participants[0].character_data.moves = vec!["fire_strike".into()];
        let ai = BasicAi::new();
        let action = ai.select_action(&state, 1);
        assert!(action.is_some());
        let action = action.unwrap();
        match action {
            AIAction::Attack { move_id, score, .. } => {
                assert_eq!(move_id, "fire_strike");
                assert!(score > 0.0);
            }
            AIAction::Switch { .. } => panic!("expected attack"),
        }
    }

    #[test]
    fn test_ai_trait_object() {
        let state = make_state();
        let ai: Box<dyn AiStrategy> = Box::new(BasicAi::new());
        let action = ai.select_action(&state, 1);
        assert!(action.is_some());
    }

    #[test]
    fn test_ai_switches_on_low_hp() {
        let mut state = make_state();
        state.participants.push(make_participant(Team::Enemy, 100));
        // Enemy front (index 1) is at low HP.
        state.participants[1].take_damage(90);
        state.participants[1].character_data.moves = vec!["fire_strike".into()];
        state.participants[2].character_data.moves = vec!["fire_strike".into()];
        let ai = BasicAi::new();
        let action = ai.select_action(&state, 1);
        match action {
            Some(AIAction::Switch { bench_index, .. }) => assert_eq!(bench_index, 2),
            other => panic!("expected switch, got {other:?}"),
        }
    }

    #[test]
    fn test_ai_fallback() {
        let state = make_state();
        let ai = BasicAi::new();
        let action = ai.select_action(&state, 1);
        assert!(action.is_some());
    }

    #[test]
    fn test_ai_skips_healing() {
        let mut state = make_state();
        let mv = state.move_lookup.get("fire_strike").unwrap();
        let mut healing_move = mv.as_ref().clone();
        healing_move.healing = 50;
        state
            .move_lookup
            .insert("heal".into(), Box::new(healing_move));
        state.participants[1].character_data.moves = vec!["heal".into(), "fire_strike".into()];
        let ai = BasicAi::new();
        let action = ai.select_action(&state, 1).unwrap();
        match action {
            AIAction::Attack { move_id, score, .. } => {
                assert_ne!(move_id, "heal");
                assert!(score > 0.0);
            }
            AIAction::Switch { .. } => panic!("expected attack"),
        }
    }

    #[test]
    fn test_ai_selects_no_move_if_no_attacks() {
        let state = make_state();
        // Enemy has only fire_strike which is a damaging move
        // So this should still pick something
        let ai = BasicAi::new();
        let action = ai.select_action(&state, 1);
        assert!(action.is_some());
    }

    #[test]
    fn test_process_start_of_turn_no_confusion() {
        let mut p = make_participant(Team::Player, 100);
        let configs = make_status_configs();
        let mut rng = StdRng::seed_from_u64(42);
        let logs = process_start_of_turn(&mut p, &configs, &mut rng);
        assert!(logs.is_empty());
        assert_eq!(p.current_hp, 100);
    }

    #[test]
    fn test_process_end_of_turn_no_dot() {
        let mut p = make_participant(Team::Player, 100);
        let configs = make_status_configs();
        let logs = process_end_of_turn(&mut p, &configs);
        assert!(logs.is_empty());
    }

    #[test]
    fn test_ai_find_weakest_multiple() {
        let mut state = make_state();
        state.participants.push(make_participant(Team::Enemy, 100));
        state.participants[0].take_damage(30);
        state.participants[2].take_damage(60);
        // Give the enemy front a Metal move (2.0x vs Wood front) so it attacks.
        let mv = state.move_lookup.get("fire_strike").unwrap();
        let mut metal_strike = mv.as_ref().clone();
        metal_strike.element = TypeElement::Metal;
        state
            .move_lookup
            .insert("metal_strike".into(), Box::new(metal_strike));
        state.participants[1].character_data.moves = vec!["metal_strike".into()];
        let ai = BasicAi::new();
        // The enemy front (index 1) still only targets the player's front (index 0),
        // never the benched enemy at index 2.
        let action = ai.select_action(&state, 1);
        match action {
            Some(AIAction::Attack { target_index, .. }) => assert_eq!(target_index, 0),
            other => panic!("expected attack, got {other:?}"),
        }
    }

    #[test]
    fn test_ai_attacks_when_not_at_disadvantage() {
        let mut state = make_state();
        // Give the enemy front a Metal-type move so it has an advantage over the
        // Wood player front, preventing a switch and forcing an attack.
        let mv = state.move_lookup.get("fire_strike").unwrap();
        let mut metal_strike = mv.as_ref().clone();
        metal_strike.element = TypeElement::Metal;
        state
            .move_lookup
            .insert("metal_strike".into(), Box::new(metal_strike));
        state.participants[1].character_data.moves = vec!["metal_strike".into()];
        let ai = BasicAi::new();
        let action = ai.select_action(&state, 1);
        match action {
            Some(AIAction::Attack { .. }) => {}
            other => panic!("expected attack, got {other:?}"),
        }
    }

    #[test]
    fn test_ai_no_target_when_fronts_defeated() {
        let mut state = make_state();
        state.participants[0].take_damage(100);
        state.participants[1].take_damage(100);
        let ai = BasicAi::new();
        let action = ai.select_action(&state, 1);
        assert!(action.is_none());
    }

    #[test]
    fn test_execute_damage_action_attacker_before_target() {
        let mut state = make_state();
        // Player (index 0) attacks enemy front (index 1): attacker before target.
        let mut rng = StdRng::seed_from_u64(7);
        let result = execute_damage_action(&mut state, 0, 1, "fire_strike", &mut rng).unwrap();
        assert!(result.damage_dealt > 0);
        assert!(state.participants[1].current_hp < 100);
        // The attacker (player) is unharmed.
        assert_eq!(state.participants[0].current_hp, 100);
    }

    #[test]
    fn test_execute_damage_action_attacker_after_target() {
        let mut state = make_state();
        // Enemy (index 1) attacks player front (index 0): attacker after target.
        let mut rng = StdRng::seed_from_u64(42);
        let result = execute_damage_action(&mut state, 1, 0, "fire_strike", &mut rng).unwrap();
        assert!(result.damage_dealt > 0);
        assert!(state.participants[0].current_hp < 100);
        // The attacker (enemy) is unharmed.
        assert_eq!(state.participants[1].current_hp, 100);
    }

    #[test]
    fn test_execute_damage_action_miss() {
        let mut state = make_state();
        let mut miss_move = state
            .move_lookup
            .get("fire_strike")
            .unwrap()
            .as_ref()
            .clone();
        miss_move.accuracy = 0;
        state
            .move_lookup
            .insert("miss_strike".into(), Box::new(miss_move));
        let mut rng = StdRng::seed_from_u64(1);
        let result = execute_damage_action(&mut state, 1, 0, "miss_strike", &mut rng).unwrap();
        assert!(!result.hit);
        assert_eq!(result.damage_dealt, 0);
        assert_eq!(state.participants[0].current_hp, 100);
    }

    #[test]
    fn test_execute_ai_turn_attacks_player_front() {
        let mut state = make_state();
        // Enemy (index 1) is the active participant.
        state.active_participant = Some(1);
        let mut rng = StdRng::seed_from_u64(42);
        match execute_ai_turn(&mut state, &mut rng) {
            AiTurnOutcome::Attack(result) => {
                // The AI attacks the player's front (index 0), never itself.
                assert_eq!(result.target_index, 0);
                assert!(state.participants[0].current_hp < 100);
                assert_eq!(state.participants[1].current_hp, 100);
            }
            other => panic!("expected attack, got {other:?}"),
        }
    }

    #[test]
    fn test_execute_ai_turn_switches_on_low_hp() {
        let mut state = make_state();
        state.participants.push(make_participant(Team::Enemy, 100));
        state.participants[1].take_damage(90);
        state.participants[1].character_data.moves = vec!["fire_strike".into()];
        state.participants[2].character_data.moves = vec!["fire_strike".into()];
        state.active_participant = Some(1);
        let mut rng = StdRng::seed_from_u64(42);
        match execute_ai_turn(&mut state, &mut rng) {
            AiTurnOutcome::Switch { bench_index, .. } => {
                assert_eq!(bench_index, 2);
                assert!(!state.participants[1].is_front);
                assert!(state.participants[2].is_front);
            }
            other => panic!("expected switch, got {other:?}"),
        }
    }

    #[test]
    fn test_execute_ai_turn_switches_on_type_disadvantage() {
        let mut state = make_state();
        // Enemy front (index 1) holds a Fire move that is weak against the
        // single-type Wood player front (0.5x), so the AI switches on type
        // disadvantage even at full HP.
        state.participants[1].character_data.moves = vec!["fire_strike".into()];
        // Enemy bench (index 2) holds an Earth move (2.0x vs Wood), so it is
        // not worse off than the current front.
        let mv = state
            .move_lookup
            .get("fire_strike")
            .unwrap()
            .as_ref()
            .clone();
        let mut earth_move = mv.clone();
        earth_move.element = TypeElement::Earth;
        state
            .move_lookup
            .insert("earth_move".into(), Box::new(earth_move));
        state.participants.push(make_participant(Team::Enemy, 100));
        state.participants[2].character_data.moves = vec!["earth_move".into()];
        state.active_participant = Some(1);
        let mut rng = StdRng::seed_from_u64(42);
        match execute_ai_turn(&mut state, &mut rng) {
            AiTurnOutcome::Switch { bench_index, .. } => {
                assert_eq!(bench_index, 2);
                assert!(!state.participants[1].is_front);
                assert!(state.participants[2].is_front);
            }
            other => panic!("expected switch on type disadvantage, got {other:?}"),
        }
    }

    #[test]
    fn test_execute_ai_turn_none_when_no_active() {
        let mut state = make_state();
        state.active_participant = None;
        let mut rng = StdRng::seed_from_u64(42);
        match execute_ai_turn(&mut state, &mut rng) {
            AiTurnOutcome::None => {}
            other => panic!("expected none, got {other:?}"),
        }
    }

    #[test]
    fn test_effectiveness_single_type_not_squared() {
        let state = make_state();
        // Player front (index 0) is single-type Wood.
        // Fire vs Wood is 0.5 — not 0.25 (the squared dual-type result).
        let eff =
            move_effectiveness_against(type_chart(), TypeElement::Fire, &state.participants[0]);
        assert!((eff - 0.5).abs() < f64::EPSILON, "got {eff}");
    }

    #[test]
    fn test_effectiveness_dual_type_uses_both_elements() {
        let mut state = make_state();
        // Give the player front a secondary Fire element: Wood/Fire defender.
        state.participants[0].character_data.secondary_element = Some(TypeElement::Fire);
        // Metal vs Wood/Fire = chart[Wood][Metal] * chart[Fire][Metal] = 1.0 * 2.0.
        let eff =
            move_effectiveness_against(type_chart(), TypeElement::Metal, &state.participants[0]);
        assert!((eff - 2.0).abs() < f64::EPSILON, "got {eff}");
    }

    #[test]
    fn test_ai_fallback_skips_healing_only() {
        let mut state = make_state();
        state.participants.push(make_participant(Team::Enemy, 100));
        let mv = state.move_lookup.get("fire_strike").unwrap();
        let mut healing_move = mv.as_ref().clone();
        healing_move.healing = 50;
        state
            .move_lookup
            .insert("heal".into(), Box::new(healing_move));
        // Enemy front has only a healing move; the bench has a real attack.
        state.participants[1].character_data.moves = vec!["heal".into()];
        state.participants[2].character_data.moves = vec!["fire_strike".into()];
        let ai = BasicAi::new();
        // The AI must never select the healing move as an attack; it switches
        // to the bench instead.
        match ai.select_action(&state, 1) {
            Some(AIAction::Switch { bench_index, .. }) => assert_eq!(bench_index, 2),
            Some(AIAction::Attack { move_id, .. }) => {
                panic!("expected switch, got attack with {move_id}")
            }
            None => panic!("expected switch"),
        }
    }

    #[test]
    fn test_ai_switches_when_no_attack_move() {
        let mut state = make_state();
        state.participants.push(make_participant(Team::Enemy, 100));
        // Enemy front has no moves at all: best effectiveness is -1.0, which
        // is at most the switch threshold, so the AI switches to the bench.
        state.participants[1].character_data.moves = vec![];
        state.participants[2].character_data.moves = vec!["fire_strike".into()];
        let ai = BasicAi::new();
        let action = ai.select_action(&state, 1);
        match action {
            Some(AIAction::Switch { bench_index, .. }) => assert_eq!(bench_index, 2),
            other => panic!("expected switch, got {other:?}"),
        }
    }

    #[test]
    fn test_ai_switches_to_best_bench() {
        let mut state = make_state();
        state.participants.push(make_participant(Team::Enemy, 100));
        state.participants.push(make_participant(Team::Enemy, 100));
        // Player front is single-type Wood.
        // Enemy front holds a Fire move (0.5x vs Wood) → type disadvantage.
        state.participants[1].character_data.moves = vec!["fire_strike".into()];
        // Bench 2: Fire move (0.5x vs Wood) — same matchup as the front.
        state.participants[2].character_data.moves = vec!["fire_strike".into()];
        // Bench 3: Metal move (1.0x vs Wood) — strictly better matchup.
        let mv = state
            .move_lookup
            .get("fire_strike")
            .unwrap()
            .as_ref()
            .clone();
        let mut metal_strike = mv.clone();
        metal_strike.element = TypeElement::Metal;
        state
            .move_lookup
            .insert("metal_strike".into(), Box::new(metal_strike));
        state.participants[3].character_data.moves = vec!["metal_strike".into()];
        let ai = BasicAi::new();
        let action = ai.select_action(&state, 1);
        match action {
            Some(AIAction::Switch { bench_index, .. }) => assert_eq!(bench_index, 3),
            other => panic!("expected switch to best bench (3), got {other:?}"),
        }
    }

    #[test]
    fn test_ai_attacks_when_can_defeat_front() {
        let mut state = make_state();
        state.participants.push(make_participant(Team::Enemy, 100));
        // Enemy front at low HP (10/100) — switch condition is met.
        state.participants[1].take_damage(90);
        // Player front at 15/100: the enemy's minimum Fire Strike damage (~20)
        // defeats it, so the AI must attack instead of switching.
        state.participants[0].take_damage(85);
        state.participants[1].character_data.moves = vec!["fire_strike".into()];
        state.participants[2].character_data.moves = vec!["fire_strike".into()];
        let ai = BasicAi::new();
        let action = ai.select_action(&state, 1);
        match action {
            Some(AIAction::Attack { target_index, .. }) => assert_eq!(target_index, 0),
            other => panic!("expected attack, got {other:?}"),
        }
    }
}
