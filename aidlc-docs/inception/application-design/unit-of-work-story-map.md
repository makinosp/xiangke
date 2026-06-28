# Unit of Work Story Map

## Overview

Mapping of functional requirements to units of work. Since User Stories were
skipped (internal tool, single user), this maps FRs from the requirements
document to units.

---

## Requirement-to-Unit Mapping

### FR-1: Game Core → Unit 2 (Game Foundation)

| Requirement                               | Unit   | Notes                                  |
| ----------------------------------------- | ------ | -------------------------------------- |
| FR-1.1: 2D game with Godot 4.x / GDScript | Unit 2 | Project setup and configuration        |
| FR-1.2: Web (HTML5) export                | Unit 2 | Export settings, project configuration |
| FR-1.3: Desktop support for development   | Unit 2 | Export templates                       |

### FR-2: AI / NPC Behavior → Unit 4 (AI System)

| Requirement                             | Unit   | Notes                       |
| --------------------------------------- | ------ | --------------------------- |
| FR-2.1: AI-controlled NPCs              | Unit 4 | AIController implementation |
| FR-2.2: NPCs interact with world/player | Unit 4 | State machine logic         |
| FR-2.3: AI in GDScript node system      | Unit 4 | Node-based implementation   |

### FR-3: UI / HUD → Unit 5 (UI System)

| Requirement                     | Unit   | Notes                           |
| ------------------------------- | ------ | ------------------------------- |
| FR-3.1: UI with HUD elements    | Unit 5 | HP bars, status indicators      |
| FR-3.2: Responsive Web viewport | Unit 5 | UI layout adaptation            |
| FR-3.3: Menu systems            | Unit 5 | Title, pause, game over screens |

### FR-4: Audio / Music → Unit 6 (Audio System)

| Requirement                     | Unit   | Notes                      |
| ------------------------------- | ------ | -------------------------- |
| FR-4.1: Background music        | Unit 6 | BGM playback per scene     |
| FR-4.2: Sound effects           | Unit 6 | SFX for actions and events |
| FR-4.3: Web autoplay compliance | Unit 6 | Browser policy handling    |

### FR-5: Local Storage → Unit 2 (Game Foundation)

| Requirement                       | Unit   | Notes                       |
| --------------------------------- | ------ | --------------------------- |
| FR-5.1: Local player data storage | Unit 2 | SaveManager with ConfigFile |
| FR-5.2: Local leaderboard         | Unit 2 | High score persistence      |
| FR-5.3: Persist between sessions  | Unit 2 | user:// directory storage   |
| FR-5.4: No external database      | Unit 2 | Client-side only            |

### Shared Data → Unit 1 (Resources)

| Data                  | Unit   | Notes                  |
| --------------------- | ------ | ---------------------- |
| Character definitions | Unit 1 | Resource files (.tres) |
| Move data             | Unit 1 | Resource files (.tres) |
| Type effectiveness    | Unit 1 | Lookup table           |
| Status effects        | Unit 1 | Effect definitions     |

### Battle Logic → Unit 3 (Battle System)

| Feature             | Unit   | Notes                        |
| ------------------- | ------ | ---------------------------- |
| Turn management     | Unit 3 | BattleManager                |
| Damage calculation  | Unit 3 | ActionSystem                 |
| Action execution    | Unit 3 | BattleManager + ActionSystem |
| Win/loss conditions | Unit 3 | BattleManager                |

---

## Coverage Matrix

| Unit                    | FRs Covered             | Coverage            |
| ----------------------- | ----------------------- | ------------------- |
| Unit 1: Resources       | Shared data for all FRs | Foundation          |
| Unit 2: Game Foundation | FR-1, FR-5              | Core infrastructure |
| Unit 3: Battle System   | Core gameplay logic     | Battle mechanics    |
| Unit 4: AI System       | FR-2                    | Enemy behavior      |
| Unit 5: UI System       | FR-3                    | User interface      |
| Unit 6: Audio System    | FR-4                    | Sound and music     |

---

## Validation

- [x] All functional requirements mapped to at least one unit
- [x] No orphaned requirements
- [x] Unit dependencies respect development order
- [x] Shared resources isolated in Unit 1
- [x] Critical path identified (Unit 1 → 2 → 3 → 4/5/6)
