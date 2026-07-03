# NFR Requirements — Unit 3: Battle System

## 1. Performance Requirements

| ID      | Requirement                 | Target             | Rationale                                         |
| ------- | --------------------------- | ------------------ | ------------------------------------------------- |
| NFR-1.1 | Battle turn processing time | < 100ms per action | Ensures responsive gameplay on Web platform       |
| NFR-1.2 | Animation frame rate        | ≥ 30 FPS           | Smooth visual experience during battle animations |
| NFR-1.3 | Damage calculation time     | < 10ms             | Fast combat calculations for 1v1 battles          |

## 2. Scalability Requirements

| ID      | Requirement             | Target  | Rationale                       |
| ------- | ----------------------- | ------- | ------------------------------- |
| NFR-2.1 | Maximum participants    | 2 (1v1) | MVP scope; 1 player + 1 enemy   |
| NFR-2.2 | Memory usage per battle | < 10MB  | Web platform memory constraints |

## 3. Reliability Requirements

| ID      | Requirement            | Target                              | Rationale                              |
| ------- | ---------------------- | ----------------------------------- | -------------------------------------- |
| NFR-3.1 | Error handling         | Fail-fast with clear error messages | Development phase; easier debugging    |
| NFR-3.2 | Battle state integrity | Validated before each action        | Prevents corrupted game state          |
| NFR-3.3 | Turn queue consistency | Recalculated each round             | Ensures correct speed-based turn order |

## 4. Availability Requirements

| ID      | Requirement       | Target       | Rationale                                  |
| ------- | ----------------- | ------------ | ------------------------------------------ |
| NFR-4.1 | Battle completion | 100%         | No mid-battle saves; battles must complete |
| NFR-4.2 | Turn limit        | 50 turns max | Prevents infinite battles                  |

## 5. Security Requirements

| ID      | Requirement                   | Target               | Rationale                           |
| ------- | ----------------------------- | -------------------- | ----------------------------------- |
| NFR-5.1 | Data validation               | All inputs validated | Prevents crashes from invalid data  |
| NFR-5.2 | No external data transmission | Local-only           | Battle data never leaves the client |

## 6. Maintainability Requirements

| ID      | Requirement     | Target                                                              | Rationale                                 |
| ------- | --------------- | ------------------------------------------------------------------- | ----------------------------------------- |
| NFR-6.1 | Code modularity | Separate classes for BattleManager, ActionSystem, BattleFlowService | Easier testing and modification           |
| NFR-6.2 | Documentation   | Inline comments + this document                                     | Team collaboration and future maintenance |

## 7. Usability Requirements

| ID      | Requirement        | Target                         | Rationale                             |
| ------- | ------------------ | ------------------------------ | ------------------------------------- |
| NFR-7.1 | Animation speed    | Fast-paced (0.5-1s per action) | MVP balance between feedback and pace |
| NFR-7.2 | Player action time | No limit                       | MVP simplicity; can add timer later   |

## 8. Compatibility Requirements

| ID      | Requirement      | Target              | Rationale               |
| ------- | ---------------- | ------------------- | ----------------------- |
| NFR-8.1 | Web platform     | HTML5 export        | Primary target platform |
| NFR-8.2 | Desktop platform | Windows/macOS/Linux | Development and testing |

## 9. Observability Requirements

| ID      | Requirement   | Target                                        | Rationale                              |
| ------- | ------------- | --------------------------------------------- | -------------------------------------- |
| NFR-9.1 | Battle log    | Full debug console with calculation breakdown | Development debugging and verification |
| NFR-9.2 | Error logging | Console output                                | Development phase debugging            |

## 10. Tech Stack Decisions

| ID       | Decision         | Chosen                       | Rationale                  |
| -------- | ---------------- | ---------------------------- | -------------------------- |
| NFR-10.1 | Language         | GDScript                     | Godot 4.x standard         |
| NFR-10.2 | Architecture     | Node-based with Services     | Godot best practices       |
| NFR-10.3 | Data format      | .tres resources              | Godot native format        |
| NFR-10.4 | State management | In-memory BattleState object | Simple for 1v1 battles     |
| NFR-10.5 | Event system     | Godot signals                | Native Godot communication |
| NFR-10.6 | Debug tools      | In-game console              | Development support        |
