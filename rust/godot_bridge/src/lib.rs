use std::collections::HashMap;

use godot::builtin::{VarArray, VarDictionary};
use godot::classes::Node;
use godot::obj::Base;
use godot::prelude::*;
use rand::SeedableRng;
use rand::rngs::StdRng;
use xiangke_battle::action;
use xiangke_battle::flow;
use xiangke_battle::manager;
use xiangke_battle::participant::{BattleParticipant, Team};
use xiangke_battle::state::{BattleState, Status};
use xiangke_core::character::{CharacterData, Stats};
use xiangke_core::moves::MoveData;
use xiangke_core::types::{DamageCategory, EffectType, TypeElement};

type Dict = VarDictionary;
type Arr = VarArray;

struct XiangkeExtension;

fn dict_char(d: &Dict) -> Option<CharacterData> {
    let id = d.get("id")?.to::<String>();
    let name = d.get("name")?.to::<String>();
    let type_val = d.get("type")?.to::<i64>();
    let secondary = d.get("secondary_type").map(|v| v.to::<i64>()).unwrap_or(-1);
    let hp = d.get("hp").map(|v| v.to::<i64>()).unwrap_or(1) as u32;
    let atk = d.get("attack").map(|v| v.to::<i64>()).unwrap_or(0) as u32;
    let def = d.get("defense").map(|v| v.to::<i64>()).unwrap_or(0) as u32;
    let spd = d.get("speed").map(|v| v.to::<i64>()).unwrap_or(0) as u32;
    let intel = d.get("intelligence").map(|v| v.to::<i64>()).unwrap_or(0) as u32;
    let spr = d.get("spirit").map(|v| v.to::<i64>()).unwrap_or(0) as u32;
    let moves_arr = d.get("moves")?.to::<Arr>();
    let desc = d
        .get("description")
        .map(|v| v.to::<String>())
        .unwrap_or_default();
    let element = TypeElement::from_repr(type_val as u8).unwrap_or(TypeElement::Wood);
    let secondary_element = if secondary >= 0 {
        TypeElement::from_repr(secondary as u8)
    } else {
        None
    };
    let mut moves = Vec::new();
    for i in 0..moves_arr.len() {
        if let Some(s) = moves_arr.get(i)?.try_to::<String>().ok() {
            moves.push(s);
        }
    }
    Some(CharacterData {
        id,
        name,
        element,
        secondary_element,
        base_stats: Stats {
            hp,
            attack: atk,
            defense: def,
            speed: spd,
            intelligence: intel,
            spirit: spr,
        },
        moves,
        description: desc,
    })
}

fn dict_move(d: &Dict) -> Option<MoveData> {
    let id = d.get("id")?.to::<String>();
    let name = d.get("name")?.to::<String>();
    let type_val = d.get("type")?.to::<i64>();
    let power = d.get("power").map(|v| v.to::<i64>()).unwrap_or(0) as u32;
    let acc = d.get("accuracy").map(|v| v.to::<i64>()).unwrap_or(100) as u32;
    let effect_val = d.get("effect").map(|v| v.to::<i64>()).unwrap_or(0);
    let eff_chance = d.get("effect_chance").map(|v| v.to::<i64>()).unwrap_or(0) as u32;
    let stat_mod_stat = d.get("stat_mod_stat").map(|v| v.to::<i64>()).unwrap_or(-1);
    let stat_mod_stage = d.get("stat_mod_stage").map(|v| v.to::<i64>()).unwrap_or(0) as i32;
    let hit_count = d.get("hit_count").map(|v| v.to::<i64>()).unwrap_or(1) as u32;
    let recoil = d.get("recoil").map(|v| v.to::<i64>()).unwrap_or(0) as u32;
    let healing = d.get("healing").map(|v| v.to::<i64>()).unwrap_or(0) as u32;
    let damage_cat = d.get("damage_category").map(|v| v.to::<i64>()).unwrap_or(0);
    let desc = d
        .get("description")
        .map(|v| v.to::<String>())
        .unwrap_or_default();
    let element = TypeElement::from_repr(type_val as u8).unwrap_or(TypeElement::Wood);
    let effect = EffectType::from_repr(effect_val as u8).unwrap_or(EffectType::None);
    let stat_mod = if stat_mod_stat >= 0 {
        Some(
            xiangke_core::types::Stat::from_repr(stat_mod_stat as u8)
                .unwrap_or(xiangke_core::types::Stat::Attack),
        )
    } else {
        None
    };
    let dmg_cat = if damage_cat == 1 {
        DamageCategory::Arts
    } else {
        DamageCategory::Physical
    };
    Some(MoveData {
        id,
        name,
        element,
        power,
        accuracy: acc,
        effect,
        effect_chance: eff_chance,
        stat_mod_stat: stat_mod,
        stat_mod_stage,
        hit_count,
        recoil,
        healing,
        damage_category: dmg_cat,
        description: desc,
    })
}

fn part_dict(p: &BattleParticipant) -> Dict {
    let mut d = Dict::new();
    d.set("id", p.character_data.id.clone());
    d.set("name", p.character_data.name.clone());
    d.set("current_hp", p.current_hp as i64);
    d.set("max_hp", p.max_hp as i64);
    d.set("team", p.team as i64);
    d.set("slot_index", p.slot_index);
    d.set("is_defeated", p.is_defeated);
    let mut stages = Arr::new();
    for s in &p.stat_stages {
        stages.push(*s as i64);
    }
    d.set("stat_stages", &stages);
    let mut effects = Arr::new();
    for e in EffectType::ALL {
        if e != EffectType::None && p.has_status(e) {
            effects.push(e as i64);
        }
    }
    d.set("active_status_effects", &effects);
    d
}

fn result_dict(r: &action::ActionResult) -> Dict {
    let mut d = Dict::new();
    d.set("damage_dealt", r.damage_dealt as i64);
    d.set("healing_done", r.heal_amount as i64);
    d.set("hit", r.hit);
    d.set("critical_hit", r.is_critical);
    d.set("type_effectiveness", r.type_effectiveness);
    d.set("is_super_effective", r.is_super_effective);
    d.set("is_not_very_effective", r.is_not_very_effective);
    d.set("is_immune", r.is_immune);
    d.set(
        "status_applied",
        r.status_applied.map(|e| e as i64).unwrap_or(0),
    );
    d.set("status_resisted", r.status_resisted);
    d.set("recoil_damage", r.recoil_damage as i64);
    d.set("log_message", r.log_message.clone());
    d.set("raw_damage", r.raw_damage as i64);
    d
}

#[derive(GodotClass)]
#[class(init, base=Node)]
struct RustBattleSystem {
    base: Base<Node>,
    battle_state: Option<BattleState>,
    rng: Option<StdRng>,
}

#[godot_api]
impl RustBattleSystem {
    /// Initializes a new battle with player and enemy character data.
    /// Builds participant list from Dictionaries, seeds RNG, and starts first round.
    /// Returns true on success, false if participants are empty or initialization fails.
    #[func]
    fn start_battle(&mut self, player_chars: Arr, enemy_chars: Arr, move_lookup: Dict) -> bool {
        let mut participants = Vec::new();
        let mut move_map: HashMap<String, Box<MoveData>> = HashMap::new();

        let move_keys = move_lookup.keys_array();
        for i in 0..move_keys.len() {
            if let Some(key) = move_keys.get(i).and_then(|v| v.try_to::<String>().ok()) {
                if let Some(val) = move_lookup.get(key.as_str()) {
                    let val: Dict = val.to::<Dict>();
                    if let Some(mv) = dict_move(&val) {
                        move_map.insert(key, Box::new(mv));
                    }
                }
            }
        }

        for i in 0..player_chars.len() {
            if let Some(v) = player_chars.get(i) {
                let d: Dict = v.to::<Dict>();
                if let Some(cd) = dict_char(&d) {
                    if let Ok(p) = BattleParticipant::new(cd, Team::Player, i as u32) {
                        participants.push(p);
                    }
                }
            }
        }

        for i in 0..enemy_chars.len() {
            if let Some(v) = enemy_chars.get(i) {
                let d: Dict = v.to::<Dict>();
                if let Some(cd) = dict_char(&d) {
                    if let Ok(p) = BattleParticipant::new(cd, Team::Enemy, i as u32) {
                        participants.push(p);
                    }
                }
            }
        }

        if participants.is_empty() {
            return false;
        }

        let mut state = match BattleState::new(participants, move_map) {
            Ok(s) => s,
            Err(_) => return false,
        };

        let mut rng = StdRng::from_entropy();
        if manager::start_battle(&mut state, &mut rng).is_ok() {
            self.battle_state = Some(state);
            self.rng = Some(rng);
            true
        } else {
            false
        }
    }

    /// Executes a player's chosen move against a target participant.
    /// Takes `move_data` as a Dictionary matching MoveData fields and `target_index` as
    /// the global participant index. Returns an ActionResult Dictionary with damage,
    /// healing, hit/miss, type effectiveness, and log message fields.
    /// Returns empty Dictionary on error (invalid index, missing state, move parse failure).
    #[func]
    fn execute_player_action(&mut self, move_data: Dict, target_index: i64) -> Dict {
        let default = Dict::new();
        let attacker_idx = match self
            .battle_state
            .as_ref()
            .and_then(|s| s.active_participant)
        {
            Some(i) => i,
            None => return default,
        };
        let ti = target_index as usize;
        {
            let state = self.battle_state.as_ref().unwrap();
            if ti >= state.participants.len() {
                return default;
            }
        }
        let mv = match dict_move(&move_data) {
            Some(m) => m,
            None => return default,
        };
        let rng = match self.rng.as_mut() {
            Some(r) => r,
            None => return default,
        };
        let state = self.battle_state.as_mut().unwrap();

        let result = if attacker_idx <= ti {
            let (left, right) = state.participants.split_at_mut(ti);
            match action::calculate_damage(&mut left[attacker_idx], &mut right[0], &mv, ti, rng) {
                Ok(r) => r,
                Err(_) => return default,
            }
        } else {
            let (left, right) = state.participants.split_at_mut(attacker_idx);
            match action::calculate_damage(&mut right[0], &mut left[ti], &mv, ti, rng) {
                Ok(r) => r,
                Err(_) => return default,
            }
        };

        if !result.log_message.is_empty() {
            state.add_log(result.log_message.clone());
        }
        result_dict(&result)
    }

    /// Advances the turn queue to the next active participant.
    /// Returns true if a next participant exists, false if no valid participants remain.
    #[func]
    fn advance_turn(&mut self) -> bool {
        match (self.battle_state.as_mut(), self.rng.as_mut()) {
            (Some(state), Some(rng)) => manager::advance_to_next_turn(state, rng).is_ok(),
            _ => false,
        }
    }

    /// Returns a Dictionary of the current active participant's data.
    /// Keys: id, name, current_hp, max_hp, team, slot_index, is_defeated, stat_stages, active_status_effects.
    /// Returns empty Dictionary if no battle state or no active participant.
    #[func]
    fn get_active_participant(&self) -> Dict {
        match self
            .battle_state
            .as_ref()
            .and_then(|s| s.active_participant)
        {
            Some(idx) => part_dict(&self.battle_state.as_ref().unwrap().participants[idx]),
            None => Dict::new(),
        }
    }

    /// Returns an Array of participant Dictionaries for the player's team.
    #[func]
    fn get_player_participants(&self) -> Arr {
        let mut arr = Arr::new();
        let state = match self.battle_state.as_ref() {
            Some(s) => s,
            None => return arr,
        };
        for p in state.player_participants() {
            arr.push(&part_dict(p));
        }
        arr
    }

    /// Returns an Array of participant Dictionaries for the enemy's team.
    #[func]
    fn get_enemy_participants(&self) -> Arr {
        let mut arr = Arr::new();
        let state = match self.battle_state.as_ref() {
            Some(s) => s,
            None => return arr,
        };
        for p in state.enemy_participants() {
            arr.push(&part_dict(p));
        }
        arr
    }

    /// Returns the last `count` log entries as an Array of formatted strings.
    /// Each entry follows the format "[T{N}/R{M}] message".
    #[func]
    fn get_recent_log(&self, count: i64) -> Arr {
        let mut arr = Arr::new();
        let state = match self.battle_state.as_ref() {
            Some(s) => s,
            None => return arr,
        };
        for msg in state.recent_log(count as usize) {
            arr.push(msg.to_string());
        }
        arr
    }

    /// Returns the current battle status as an integer.
    /// Values: 0=Active, 1=Victory, 2=Defeat, 3=Draw, 4=Escaped. Returns 5 if no battle.
    #[func]
    fn get_battle_status(&self) -> i64 {
        match self.battle_state.as_ref() {
            Some(s) => s.battle_status as i64,
            None => 5,
        }
    }

    /// Checks and updates win/loss/draw conditions based on current state.
    /// Returns the new status: 0=Active (ongoing), 1=Victory, 2=Defeat, 3=Draw.
    /// If status changed from Active, applies the end-of-battle status and logs.
    #[func]
    fn evaluate_battle_status(&mut self) -> i64 {
        let state = match self.battle_state.as_mut() {
            Some(s) => s,
            None => return 5,
        };
        let status = state.evaluate_status();
        if status != Status::Active {
            state.apply_status(status);
        }
        status as i64
    }

    /// Returns the total number of participants in the battle (both teams).
    #[func]
    fn get_participant_count(&self) -> i64 {
        match self.battle_state.as_ref() {
            Some(s) => s.participants.len() as i64,
            None => 0,
        }
    }

    /// Returns a participant Dictionary at the given global index.
    /// Returns empty Dictionary if index is out of range or no battle state.
    #[func]
    fn get_participant(&self, index: i64) -> Dict {
        let state = match self.battle_state.as_ref() {
            Some(s) => s,
            None => return Dict::new(),
        };
        let idx = index as usize;
        if idx < state.participants.len() {
            part_dict(&state.participants[idx])
        } else {
            Dict::new()
        }
    }

    /// Returns the global index of the current active participant, or -1 if none.
    #[func]
    fn get_active_participant_index(&self) -> i64 {
        match self.battle_state.as_ref() {
            Some(s) => s.active_participant.map(|i| i as i64).unwrap_or(-1),
            None => -1,
        }
    }

    /// Returns whether the participant at the given global index is defeated.
    /// Returns true if no battle state exists.
    #[func]
    fn is_participant_defeated(&self, index: i64) -> bool {
        match self.battle_state.as_ref() {
            Some(s) => {
                let idx = index as usize;
                idx < s.participants.len() && s.participants[idx].is_defeated
            }
            None => true,
        }
    }

    /// Processes start-of-turn effects for the participant at the given index.
    /// Handles confusion (self-damage with 50% chance). Delegates to flow.rs.
    /// Returns an Array of log message strings generated during processing.
    #[func]
    fn process_start_of_turn(&mut self, participant_index: i64) -> Arr {
        let mut logs = Arr::new();
        let state = match self.battle_state.as_mut() {
            Some(s) => s,
            None => return logs,
        };
        let idx = participant_index as usize;
        if idx >= state.participants.len() {
            return logs;
        };
        let rng = match self.rng.as_mut() {
            Some(r) => r,
            None => return logs,
        };
        for msg in flow::process_start_of_turn(
            &mut state.participants[idx],
            &state.status_effect_configs,
            rng,
        ) {
            logs.push(msg.clone());
            state.add_log(msg);
        }
        logs
    }

    /// Processes end-of-turn effects for the participant at the given index.
    /// Handles damage-over-time effects (Burn, Poison). Delegates to flow.rs.
    /// Damage values are configurable via StatusEffectData in BattleState.
    /// Returns an Array of log message strings generated during processing.
    #[func]
    fn process_end_of_turn(&mut self, participant_index: i64) -> Arr {
        let mut logs = Arr::new();
        let state = match self.battle_state.as_mut() {
            Some(s) => s,
            None => return logs,
        };
        let idx = participant_index as usize;
        if idx >= state.participants.len() {
            return logs;
        };
        let rng = match self.rng.as_mut() {
            Some(r) => r,
            None => return logs,
        };
        for msg in flow::process_end_of_turn(
            &mut state.participants[idx],
            &state.status_effect_configs,
            rng,
        ) {
            logs.push(msg.clone());
            state.add_log(msg);
        }
        logs
    }

    /// Adds a custom log message to the battle log with current turn/round prefix.
    #[func]
    fn add_log_message(&mut self, message: String) {
        if let Some(ref mut state) = self.battle_state {
            state.add_log(message);
        }
    }

    /// Returns the display name of the participant at the given global index.
    /// Returns empty string if index is out of range or no battle state.
    #[func]
    fn get_participant_name(&self, index: i64) -> String {
        match self.battle_state.as_ref() {
            Some(s) => {
                let idx = index as usize;
                if idx < s.participants.len() {
                    s.participants[idx].character_data.name.clone()
                } else {
                    String::new()
                }
            }
            None => String::new(),
        }
    }
}

#[gdextension]
unsafe impl ExtensionLibrary for XiangkeExtension {}
