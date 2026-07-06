use std::collections::HashMap;

use rand::Rng;

use xiangke_core::status::StatusEffectData;
use xiangke_core::types::EffectType;
use xiangke_core::types::TypeChart;

use crate::participant::BattleParticipant;
use crate::state::BattleState;

#[derive(Debug, Clone)]
pub struct AIAction {
    pub move_id: String,
    pub target_index: usize,
    pub score: f64,
}

pub trait AiStrategy {
    fn select_action(
        &self,
        state: &BattleState,
        participant_index: usize,
    ) -> Option<AIAction>;
}

pub struct BasicAi;

impl BasicAi {
    pub fn new() -> Self {
        Self
    }

    fn find_weakest_enemy(&self, state: &BattleState, self_index: usize) -> Option<usize> {
        let self_team = state.participants.get(self_index).map(|p| p.team);
        state
            .participants
            .iter()
            .enumerate()
            .filter(|(_, p)| {
                !p.is_defeated && self_team.map_or(true, |t| p.team != t)
            })
            .min_by(|(_, a), (_, b)| {
                let ratio_a = a.current_hp as f64 / a.max_hp as f64;
                let ratio_b = b.current_hp as f64 / b.max_hp as f64;
                ratio_a.partial_cmp(&ratio_b).unwrap_or(std::cmp::Ordering::Equal)
            })
            .map(|(i, _)| i)
    }

    fn score_move(
        &self,
        state: &BattleState,
        move_id: &str,
        _attacker_index: usize,
        target_index: usize,
    ) -> f64 {
        let Some(mv) = state.move_lookup.get(move_id) else {
            return -1.0;
        };
        if mv.power == 0 {
            return -1.0;
        }
        let defender = &state.participants[target_index];
        let type_chart = TypeChart::default();
        let def_secondary = defender.character_data.secondary_element
            .unwrap_or(defender.character_data.element);
        let effectiveness = type_chart.effectiveness_dual(
            mv.element,
            defender.character_data.element,
            def_secondary,
        );
        mv.power as f64 * effectiveness * mv.accuracy as f64 / 100.0
    }
}

impl AiStrategy for BasicAi {
    fn select_action(
        &self,
        state: &BattleState,
        participant_index: usize,
    ) -> Option<AIAction> {
        let attacker = &state.participants[participant_index];
        if attacker.is_defeated {
            return None;
        }

        let target = self.find_weakest_enemy(state, participant_index);
        let self_team = state.participants.get(participant_index).map(|p| p.team);
        let target_index = match target {
            Some(idx) => idx,
            None => {
                state
                    .participants
                    .iter()
                    .enumerate()
                    .find(|(_, p)| {
                        !p.is_defeated && self_team.map_or(true, |t| p.team != t)
                    })
                    .map(|(i, _)| i)?
            }
        };

        let mut best_move: Option<(String, f64)> = None;
        for move_id in &attacker.character_data.moves {
            let Some(mv) = state.move_lookup.get(move_id) else {
                continue;
            };
            if mv.healing > 0 {
                continue;
            }
            let score = self.score_move(state, move_id, participant_index, target_index);
            if score > 0.0 && (best_move.is_none() || score > best_move.as_ref().unwrap().1) {
                best_move = Some((move_id.clone(), score));
            }
        }

        match best_move {
            Some((move_id, score)) => Some(AIAction {
                move_id,
                target_index,
                score,
            }),
            None => {
                let fallback = attacker.character_data.moves.first()?;
                Some(AIAction {
                    move_id: fallback.clone(),
                    target_index,
                    score: 0.0,
                })
            }
        }
    }
}

pub fn process_start_of_turn(
    participant: &mut BattleParticipant,
    configs: &HashMap<EffectType, StatusEffectData>,
    rng: &mut impl Rng,
) -> Vec<String> {
    let mut logs = Vec::new();
    if participant.has_status(EffectType::Confusion) {
        let cfg = configs.get(&EffectType::Confusion).cloned().unwrap_or_default();
        let self_dmg_frac = cfg.damage_per_turn.max(0.01);
        if rng.r#gen::<f64>() < 0.5 {
            let dmg = participant.take_damage(
                (participant.max_hp as f64 * self_dmg_frac).ceil().max(1.0) as u32,
            );
            logs.push(format!(
                "{} is confused and hit itself for {} damage!",
                participant.character_data.name, dmg
            ));
        }
    }
    logs
}

const DOT_EFFECTS: [EffectType; 2] = [EffectType::Burn, EffectType::Poison];

pub fn process_end_of_turn(
    participant: &mut BattleParticipant,
    configs: &HashMap<EffectType, StatusEffectData>,
    _rng: &mut impl Rng,
) -> Vec<String> {
    let mut logs = Vec::new();
    for &effect in &DOT_EFFECTS {
        if participant.has_status(effect) {
            let cfg = configs.get(&effect).cloned().unwrap_or_default();
            let dmg = (participant.max_hp as f64 * cfg.damage_per_turn).ceil().max(1.0) as u32;
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
    use crate::participant::Team;
    use rand::SeedableRng;
    use rand::rngs::StdRng;
    use std::collections::HashMap;
    use xiangke_core::character::{CharacterData, Stats};
    use xiangke_core::moves::MoveData;
    use xiangke_core::status::StatusEffectData;
    use xiangke_core::types::{DamageCategory, TypeElement};

    fn default_configs() -> HashMap<EffectType, StatusEffectData> {
        let mut m = HashMap::new();
        m.insert(EffectType::Burn, StatusEffectData { status_type: EffectType::Burn, damage_per_turn: 1.0 / 16.0, ..Default::default() });
        m.insert(EffectType::Poison, StatusEffectData { status_type: EffectType::Poison, damage_per_turn: 1.0 / 8.0, ..Default::default() });
        m.insert(EffectType::Confusion, StatusEffectData { status_type: EffectType::Confusion, damage_per_turn: 1.0 / 16.0, ..Default::default() });
        m
    }

    fn make_participant(team: Team, hp: u32) -> BattleParticipant {
        BattleParticipant::new(
            CharacterData {
                id: "test".into(),
                name: "Test".into(),
                element: TypeElement::Wood,
                secondary_element: None,
                base_stats: Stats {
                    hp,
                    attack: 50,
                    defense: 50,
                    speed: 50,
                    intelligence: 50,
                    spirit: 50,
                },
                moves: vec!["fire_strike".into()],
                description: "".into(),
            },
            team,
            0,
        ).unwrap()
    }

    fn make_state() -> BattleState {
        let participants = vec![
            make_participant(Team::Player, 100),
            make_participant(Team::Enemy, 100),
        ];
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
        BattleState::new(participants, move_lookup).unwrap()
    }

    #[test]
    fn test_confusion_damage() {
        let mut p = make_participant(Team::Player, 100);
        p.apply_status(EffectType::Confusion);
        let configs = default_configs();
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
        let configs = default_configs();
        let mut rng = StdRng::seed_from_u64(42);
        let logs = process_end_of_turn(&mut p, &configs, &mut rng);
        assert!(!logs.is_empty());
        assert!(p.current_hp < 100);
    }

    #[test]
    fn test_ai_selects_weakest() {
        let mut state = make_state();
        state.participants[0].take_damage(50);
        let ai = BasicAi::new();
        let weakest = ai.find_weakest_enemy(&state, 1);
        assert_eq!(weakest, Some(0));
    }

    #[test]
    fn test_ai_selects_best_move() {
        let mut state = make_state();
        state.participants[0].character_data.moves = vec!["fire_strike".into()];
        let ai = BasicAi::new();
        let action = ai.select_action(&state, 1);
        assert!(action.is_some());
        let action = action.unwrap();
        assert_eq!(action.move_id, "fire_strike");
        assert!(action.score > 0.0);
    }

    #[test]
    fn test_ai_trait_object() {
        let state = make_state();
        let ai: Box<dyn AiStrategy> = Box::new(BasicAi::new());
        let action = ai.select_action(&state, 1);
        assert!(action.is_some());
    }

    #[test]
    fn test_find_weakest_enemy() {
        let mut state = make_state();
        state.participants[0].take_damage(70);
        state.participants.push(make_participant(Team::Enemy, 100));
        let ai = BasicAi::new();
        let weakest = ai.find_weakest_enemy(&state, 1);
        assert_eq!(weakest, Some(0));
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
        state.move_lookup.insert("heal".into(), Box::new(healing_move));
        state.participants[1].character_data.moves = vec!["heal".into(), "fire_strike".into()];
        let ai = BasicAi::new();
        let action = ai.select_action(&state, 1).unwrap();
        assert_ne!(action.move_id, "heal");
        assert!(action.score > 0.0);
    }

    #[test]
    fn test_ai_dynamic_team() {
        let mut state = make_state();
        state.participants[0].take_damage(100);
        let ai = BasicAi::new();
        let action = ai.select_action(&state, 1);
        assert!(action.is_none());
    }
}
