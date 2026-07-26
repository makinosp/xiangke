# Components

## Overview

This document defines the high-level components for the turn-based command
battle game built with Godot Engine 4.x using GDScript.

---

## Component: GameManager (Autoload/Singleton)

**Purpose**: Central game state management and scene transition control.

**Responsibilities**:

- Manage game state (title, character select, battle, result)
- Handle scene transitions
- Store global game data (selected characters, player stats)
- Coordinate between systems

**Type**: Autoload (persistent across scenes)

---

## Component: BattleManager

**Purpose**: Core battle system logic and turn management.

**Responsibilities**:

- Manage turn flow (player turn → enemy turn → resolve)
- Handle action selection and execution
- Calculate damage and apply effects
- Determine win/loss conditions
- Coordinate with AI for enemy decisions

**Type**: Node (attached to BattleScene)

---

## Component: AIController

**Purpose**: Enemy NPC decision-making for battle actions.

**Responsibilities**:

- Evaluate current battle state
- Select actions based on state machine logic
- Consider type advantages and HP thresholds
- Provide moderate difficulty (not purely random, not optimal)

**Type**: Node (attached to enemy entities in BattleScene)

---

## Component: Character

**Purpose**: Represents a playable character or enemy in battle.

**Responsibilities**:

- Store character stats (HP, attack, defense, speed)
- Store move set with properties (power, type, effects)
- Handle damage application and status changes
- Emit signals for state changes

**Type**: Resource or Node2D

---

## Component: ActionSystem

**Purpose**: Handles move execution, damage calculation, and effect resolution.

**Responsibilities**:

- Calculate damage based on attacker/defender stats
- Apply type effectiveness multipliers
- Handle special effects (status changes, stat modifications)
- Queue and resolve actions in speed order

**Type**: Node or static function library

---

## Component: UIController

**Purpose**: Manages all user interface elements and HUD updates.

**Responsibilities**:

- Update HP bars, status indicators
- Display action menus during player turn
- Show battle log messages
- Handle menu navigation (start, pause, result screens)

**Type**: Node (attached to UI layers in each scene)

---

## Component: AudioController

**Purpose**: Manages background music and sound effects.

**Responsibilities**:

- Play/stop BGM per scene (title BGM, battle BGM, result BGM)
- Trigger SFX for actions (attack, hit, victory, defeat)
- Handle Web platform autoplay policy compliance
- Manage volume settings

**Type**: Autoload or Node with AudioStreamPlayer children

---

## Component: SaveManager

**Purpose**: Handles local data persistence using Godot's ConfigFile.

**Responsibilities**:

- Save/load player progress
- Store high scores and leaderboard data
- Persist game settings (volume, keybindings)
- Use Godot's `user://` directory for storage

**Type**: Autoload (singleton)

---

## Component: SceneDefinitions

**Purpose**: Defines all scenes in the project.

**Responsibilities**:

- TitleScreen: Game title, start button, settings access
- CorpsCreation: Corps roster creation, player selects 6 characters
- CharacterSelect: Battle party selection, player picks 3 from their corps
- BattleScene: Main battle view with characters, HP bars, action menu
- ResultScreen: Battle outcome, score display, replay option

**Type**: Scene files (.tscn)

---

## Component: CorpsCreation

**Purpose**: Manages the corps creation screen where players select 6 characters.

**Responsibilities**:

- Display all available characters in a grid
- Manage selection/deselection (max 6, no duplicates)
- Show stats preview with full 6 stats + move list on hover
- On confirm: save corps to CorpsRoster, generate opponent corps, persist,
  and transition to CharacterSelect

**Type**: Node (attached to CorpsCreation scene)
