# Functional Design Plan — Unit 3: Battle System

## Unit Context

- **Unit**: Unit 3: Battle System
- **Purpose**: Core battle logic and turn management.
- **Dependencies**: Resources (Unit 1), Game Foundation (Unit 2)
- **Artifacts**:
  - `systems/battle/battle_manager.gd`
  - `systems/battle/action_system.gd`
  - `systems/battle/battle_flow_service.gd`
  - `scenes/battle_scene.tscn`

---

## Design Questions

Please answer the following questions to clarify the functional design for the
Battle System unit.

### Question 1: Turn Flow Structure

How should the turn flow be structured in battle?

A) Simple alternating: Player Turn → Enemy Turn → Repeat

B) Speed-based: Entities act in order of Speed stat (fastest first),
recalculated each round

C) Phase-based: Player Phase (all player actions) → Enemy Phase (all enemy
actions) → End Phase (status effects, end-of-turn effects)

D) Other (please describe after [Answer]: tag below)

[Answer]: B — Speed-based turn order with initiative recalculation each round.
This fits the tactical depth of character speed/agility matters. Allows for
strategic planning around turn order manipulation (e.g., moves that boost speed,
status effects that reduce it).

### Question 2: Action Selection

How should the player select actions during their turn?

A) Simple menu: Attack, Skill, Item, Flee

B) Move selection: Choose from character's 4 moves (learned from Unit 1 data)

C) Command cards: Draw cards each turn, play from hand

D) Other (please describe after [Answer]: tag below)

[Answer]: B — Move selection from character's 4 moves (defined in Unit 1
resources). This aligns with the move system already defined in
resources/moves/. Each character has a move list in their .tres file. Simple,
familiar, and leverages existing data structure.

### Question 3: Damage Calculation

What factors should influence damage calculation?

A) Basic: Attacker's ATK vs Defender's DEF, move power, type effectiveness

B) Standard: A + critical hit chance, random variance (85-100%)

C) Advanced: B + stat stages (buffs/debuffs), weather/field effects, same-type
attack bonus (STAB)

D) Other (please describe after [Answer]: tag below)

[Answer]: C — Advanced formula with stat stages, field effects, and STAB. This
provides tactical depth. The 五行 type system (Wood/Fire/Earth/Metal/Water +
Yang/Yin) from Unit 1 naturally supports STAB (same-type attack bonus). Stat
stages allow for buff/debuff moves. Field effects could represent terrain
advantages (e.g., fire moves stronger on "burning field").

### Question 4: Win/Loss Conditions

What constitutes victory or defeat in battle?

A) Defeat all enemy units / All player units defeated

B) A + Turn limit (draw if exceeded), Escape mechanic

C) B + Specific objectives (protect NPC, survive N turns, defeat boss within
time)

D) Other (please describe after [Answer]: tag below)

[Answer]: B — Defeat all enemies / all allies defeated, with turn limit (e.g.,
50 turns = draw) and escape mechanic. Turn limit prevents infinite battles.
Escape allows strategic retreat (with penalty: no rewards, possible HP loss).
Keeps it focused on core combat without mission-specific objectives for now.

### Question 5: Battle Scene Structure

How should the battle scene be organized in Godot?

A) Single BattleScene with all UI as children (Control nodes)

B) BattleScene (root) + separate HUD scene + separate ActionMenu scene +
BattleLog scene

C) BattleScene with instanced sub-scenes for each UI component

D) Other (please describe after [Answer]: tag below)

[Answer]: C — BattleScene with instanced sub-scenes for each UI component (HUD,
ActionMenu, BattleLog, TargetSelector). This follows Godot best practices for
modularity and reusability. Each UI component can be developed/tested
independently. Matches the existing pattern in scenes/ (title_screen.tscn,
character_select.tscn are separate scenes).

### Question 6: Status Effect Processing

When and how should status effects be processed?

A) At end of each turn (after both player and enemy act)

B) At start of affected entity's turn

C) Both: Damage-over-time at start of turn, duration decrement at end of turn

D) Other (please describe after [Answer]: tag below)

[Answer]: D — Hybrid processing: Non-damage effects (e.g., action restriction,
stat debuffs) are processed at the start of the turn. However, damage-dealing
effects (DoT) are processed at the end of the turn to ensure that character
defeat and win/loss conditions are evaluated after the entity has had its chance
to act. Duration decrement for all effects occurs at the end of the turn.

### Question 7: Enemy AI Integration

How should the Battle System interact with the AI System (Unit 4)?

A) Battle System calls AI Controller to get action, then executes it

B) AI Controller subscribes to battle events and acts autonomously

C) Battle Flow Service coordinates both player and AI turns

D) Other (please describe after [Answer]: tag below)

[Answer]: C — Battle Flow Service coordinates both player and AI turns. The
BattleFlowService acts as the central coordinator: it manages the turn queue
(speed-sorted), requests actions from player (via UI callback) or AI (via
AIController.get_action(battle_state)), then executes them through ActionSystem.
Clean separation: BattleSystem doesn't know about AI internals, AI doesn't know
about execution details.

### Question 8: Battle Rewards

What rewards should be granted after battle victory?

A) None (placeholder for now)

B) Experience points, currency, item drops

C) B + Character progression (level up, learn new moves)

D) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Plan Steps

- [x] Collect and analyze user answers to design questions
- [x] Define domain entities (BattleState, TurnManager, Action,
      BattleParticipant)
- [x] Define turn flow state machine
- [x] Define action execution pipeline
- [x] Define damage calculation formula
- [x] Define win/loss condition evaluation
- [x] Define battle scene node structure
- [x] Define integration points with AI System (Unit 4) and UI System (Unit 5)
- [x] Generate `domain-entities.md`
- [x] Generate `business-logic-model.md`
- [x] Generate `business-rules.md`
- [x] Present completion message and await approval
