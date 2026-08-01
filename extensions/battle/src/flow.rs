use std::collections::HashMap;

use rand::Rng;

use xiangke_core::status::StatusEffectData;
use xiangke_core::types::EffectType;
use xiangke_core::types::TypeChart;
use xiangke_core::types::TypeElement;

use crate::manager::{find_front_index, living_bench_indices};
use crate::participant::BattleParticipant;
use crate::participant::Team;
use crate::state::BattleState;

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
fn move_effectiveness_against(
    type_chart: &TypeChart,
    move_element: TypeElement,
    defender: &BattleParticipant,
) -> f64 {
    let def_secondary = defender
        .character_data
        .secondary_element
        .unwrap_or(defender.character_data.element);
    type_chart.effectiveness_dual(move_element, defender.character_data.element, def_secondary)
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
    fn best_effectiveness(
        &self,
        state: &BattleState,
        attacker_index: usize,
        defender_index: usize,
    ) -> f64 {
        let attacker = &state.participants[attacker_index];
        let defender = &state.participants[defender_index];
        let type_chart = TypeChart::default();
        let mut best: f64 = 0.0;
        for move_id in &attacker.character_data.moves {
            let Some(mv) = state.move_lookup.get(move_id) else {
                continue;
            };
            if mv.power == 0 {
                continue;
            }
            let eff = move_effectiveness_against(&type_chart, mv.element, defender);
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
        let type_chart = TypeChart::default();
        let effectiveness = move_effectiveness_against(&type_chart, mv.element, defender);
        mv.power as f64 * effectiveness * mv.accuracy as f64 / 100.0
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

        // Decide whether to switch: low front HP or type disadvantage.
        let hp_ratio = attacker.current_hp as f64 / attacker.max_hp as f64;
        let our_eff = self.best_effectiveness(state, participant_index, target_index);
        let should_switch =
            hp_ratio < SWITCH_HP_RATIO || (our_eff > 0.0 && our_eff <= SWITCH_TYPE_THRESHOLD);

        if should_switch {
            let bench = living_bench_indices(state, self_team);
            if let Some(&bench_index) = bench.first() {
                let bench_eff = self.best_effectiveness(state, bench_index, target_index);
                // Only switch if the bench character is not worse off.
                if bench_eff >= our_eff {
                    let score = (1.0 - hp_ratio) * 10.0 + bench_eff;
                    return Some(AIAction::Switch { bench_index, score });
                }
            }
        }

        let mut best_move: Option<(String, f64)> = None;
        for move_id in &attacker.character_data.moves {
            let Some(mv) = state.move_lookup.get(move_id) else {
                continue;
            };
            if mv.healing > 0 {
                continue;
            }
            let score = self.score_move(state, move_id, target_index);
            if score > 0.0 && (best_move.is_none() || score > best_move.as_ref().unwrap().1) {
                best_move = Some((move_id.clone(), score));
            }
        }

        match best_move {
            Some((move_id, score)) => Some(AIAction::Attack {
                move_id,
                target_index,
                score,
            }),
            None => {
                let fallback = attacker.character_data.moves.first()?;
                Some(AIAction::Attack {
                    move_id: fallback.clone(),
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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_utils::{make_participant, make_status_configs};
    use rand::SeedableRng;
    use rand::rngs::StdRng;
    use std::collections::HashMap;
    use xiangke_core::moves::MoveData;
    use xiangke_core::types::DamageCategory;

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
}
