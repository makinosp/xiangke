# Component Methods

## Overview

Method signatures for each component. Detailed business logic will be defined in
Functional Design (per-unit, CONSTRUCTION phase).

---

## GameManager (Autoload)

```gdscript
# GameManager.gd
extends Node

# Signals
signal scene_change_requested(scene_name: String)
signal game_state_changed(new_state: GameState)

# Methods
func change_scene(scene_name: String) -> void
func get_game_state() -> GameState
func set_game_state(state: GameState) -> void
func get_player_character() -> Character
func set_player_character(character: Character) -> void
func get_enemy_character() -> Character
func set_enemy_character(character: Character) -> void
```

---

## BattleManager

```gdscript
# BattleManager.gd
extends Node

# Signals
signal turn_started(character: Character)
signal turn_ended(character: Character)
signal action_selected(action: BattleAction)
signal action_executed(action: BattleAction, result: ActionResult)
signal battle_ended(winner: Character)

# Methods
func start_battle(player: Character, enemy: Character) -> void
func start_turn(character: Character) -> void
func select_action(character: Character, action: BattleAction) -> void
func execute_action(action: BattleAction) -> void
func end_turn(character: Character) -> void
func check_battle_end() -> bool
func get_current_turn_character() -> Character
func get_battle_state() -> BattleState
```

---

## AIController

```gdscript
# AIController.gd
extends Node

# Methods
func decide_action(ai_character: Character, opponent: Character) -> BattleAction
func evaluate_state(ai_character: Character, opponent: Character) -> float
func select_move(ai_Character: Character, opponent: Character) -> Move
func should_use_recovery(ai_character: Character) -> bool
func calculate_type_effectiveness(move: Move, target: Character) -> float
```

---

## Character

```gdscript
# Character.gd
class_name Character
extends Resource

# Signals
signal hp_changed(new_hp: int, max_hp: int)
signal status_changed(status: StatusEffect)
signal fainted()

# Properties
var name: String
var max_hp: int
var current_hp: int
var attack: int
var defense: int
var speed: int
var moves: Array[Move]
var status_effects: Array[StatusEffect]
var character_type: Type

# Methods
func take_damage(amount: int) -> void
func heal(amount: int) -> void
func is_alive() -> bool
func get_move(index: int) -> Move
func apply_status_effect(effect: StatusEffect) -> void
func clear_status_effects() -> void
func get_stat(stage: StatType) -> int
```

---

## ActionSystem

```gdscript
# ActionSystem.gd
extends Node

# Methods
func calculate_damage(attacker: Character, defender: Character, move: Move) -> int
func apply_type_effectiveness(base_damage: int, move_type: Type, target: Character) -> int
func execute_move(user: Character, target: Character, move: Move) -> ActionResult
func resolve_action_queue(actions: Array[BattleAction]) -> void
func check_faint(character: Character) -> bool
```

---

## UIController

```gdscript
# UIController.gd
extends Node

# Methods
func update_hp_bar(character: Character, current_hp: int, max_hp: int) -> void
func show_action_menu(moves: Array[Move]) -> void
func hide_action_menu() -> void
func display_battle_log(message: String) -> void
func show_result_screen(winner: Character) -> void
func show_corps_creation(characters: Array[Character]) -> void

# Methods
func play_bgm(bgm_name: String) -> void
func stop_bgm() -> void
func play_sfx(sfx_name: String) -> void
func set_bgm_volume(volume: float) -> void
func set_sfx_volume(volume: float) -> void
func get_bgm_volume() -> float
func get_sfx_volume() -> float
```

---

## SaveManager (Autoload)

```gdscript
# SaveManager.gd
extends Node

# Constants
const SAVE_PATH: String = "user://save_data.cfg"
const LEADERBOARD_PATH: String = "user://leaderboard.cfg"

# Methods
func save_game(data: Dictionary) -> void
func load_game() -> Dictionary
func save_score(player_name: String, score: int) -> void
func load_leaderboard() -> Array[Dictionary]
func clear_save() -> void
func save_exists() -> bool
```
