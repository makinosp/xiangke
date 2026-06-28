# Application Design Plan

## Design Checklist

- [ ] Generate `components.md` with component definitions and high-level
      responsibilities
- [ ] Generate `component-methods.md` with method signatures
- [ ] Generate `services.md` with service definitions and orchestration patterns
- [ ] Generate `component-dependency.md` with dependency relationships and
      communication patterns
- [ ] Validate design completeness and consistency

---

## Design Questions

Please answer the following questions to guide the application design.

## DQ-1: Game Genre / Style

What specific type of 2D game are you building?

A) Platformer (side-scrolling, jumping mechanics)

B) Top-down adventure / dungeon crawler

C) Puzzle game

D) Shooter (top-down or side-scrolling)

E) Other (please describe after [Answer]: tag below)

[Answer]: E ― Turn-based command battle game

## DQ-2: Scene / Node Organization

How would you like the Godot project scenes to be organized?

A) Single scene with all game logic (simple structure)

B) Multiple scenes per level/stage (level-based structure)

C) Persistent game manager + separate level scenes (modular structure)

D) Other (please describe after [Answer]: tag below)

[Answer]: C

## DQ-3: AI Behavior Complexity

What level of AI complexity do you need for NPCs?

A) Simple patrol / chase (basic state machine: idle, patrol, chase, attack)

B) Moderate (state machine + basic pathfinding using Godot Navigation2D)

C) Complex (behavior trees, multiple AI types, dynamic decision making)

D) Other (please describe after [Answer]: tag below)

[Answer]: B

## DQ-4: Database Backend

What database backend do you plan to use for player data and leaderboards?

A) Self-hosted PostgreSQL / MySQL server

B) Firebase Realtime Database / Firestore (Google)

C) Supabase (open-source Firebase alternative)

D) Custom REST API backend

E) Other (please describe after [Answer]: tag below)

[Answer]: (Skipped)

## DQ-5: Audio Approach

How will audio be handled in the project?

A) Use Godot's built-in AudioStreamPlayer nodes (simple approach)

B) Use Godot's Audio Bus system with mixer effects (advanced approach)

C) External audio middleware (e.g., FMOD, Wwise)

D) Other (please describe after [Answer]: tag below)

[Answer]: A

## DQ-6: Code Architecture Pattern

What code architecture pattern do you prefer for the game logic?

A) Godot's default node/component pattern (inherit from Node/Node2D)

B) ECS-like pattern (Entity-Component-System using Godot nodes)

C) Signal-heavy architecture (loosely coupled via Godot signals)

D) Mix of node inheritance + signals (recommended for most Godot projects)

E) Other (please describe after [Answer]: tag below)

[Answer]: A
