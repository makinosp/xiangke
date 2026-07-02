# NFR Requirements Plan — Unit 3: Battle System

## Unit Context

- **Unit**: Unit 3: Battle System
- **Purpose**: Core battle logic and turn management
- **Dependencies**: Resources (Unit 1), Game Foundation (Unit 2)
- **Target Platform**: Web (HTML5), Desktop for dev/testing
- **Engine**: Godot 4.x, GDScript

---

## NFR Questions

Please answer the following questions to clarify non-functional requirements for
the Battle System.

### Question 1: Maximum Participants

What is the maximum number of battle participants (player + enemies) expected
simultaneously?

A) Small: 2v2 or 3v3 (max 6 participants)

B) Medium: 4v4 (max 8 participants)

C) Large: 6v6 or more (max 12+ participants)

[Answer]:

### Question 2: Turn Timer / Action Time Limit

Should there be a time limit for the player to select an action each turn?

A) No time limit — player can take as long as they need

B) Soft limit — visual indicator or suggestion after N seconds, but no forced
action

C) Hard limit — player must act within N seconds or skip turn

[Answer]:

### Question 3: Battle Animation Speed

How should battle animations and action pacing be handled?

A) Instant — actions resolve immediately (no animation delay), results shown at
once

B) Fast-paced — quick animations (~0.5-1s per action), minimal delay

C) Standard — full animations (~1.5-2s per action), with natural pacing

[Answer]:

### Question 4: Battle State Persistence

Should the battle state be saveable / restorable?

A) No — battles must be completed in one session; no mid-battle saves

B) Yes — allow saving mid-battle and restoring later

[Answer]:

### Question 5: Error Handling for Invalid States

How should the battle system handle errors or invalid game states (e.g., missing
move data, invalid targeting)?

A) Crash with error — fail fast during development

B) Graceful fallback — log the error, skip the action, continue battle

C) Defensive — validate all data before action execution; show user-friendly
error message and recover

[Answer]:

### Question 6: Observability / Debug Tools

What level of battle logging or debugging support is needed?

A) None — no battle log, just results

B) Basic in-game battle log showing action summaries (who used what move, damage
dealt)

C) Full — in-game battle log + debug console with detailed calculation breakdown
(stat values, modifiers, random variance)

[Answer]:

---

## Plan Steps

- [ ] Collect and analyze user answers to NFR questions
- [ ] Define performance requirements for the battle system
- [ ] Define reliability and error handling requirements
- [ ] Define maintainability and code organization conventions
- [ ] Define usability requirements for battle pacing
- [ ] Generate `nfr-requirements.md`
- [ ] Generate `tech-stack-decisions.md`
- [ ] Present completion message and await approval
