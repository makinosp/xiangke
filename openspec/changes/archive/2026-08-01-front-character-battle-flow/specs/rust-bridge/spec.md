## MODIFIED Requirements

### Requirement: Battle Mechanics

The `xiangke-battle` crate SHALL implement BattleParticipant with runtime state,
BattleState with turn management, ActionSystem with damage formula,
BattleManager with turn queue, and AiStrategy trait with BasicAi implementation.

#### Scenario: Battle participant creation

- **WHEN** a BattleParticipant is created from valid CharacterData
- **THEN** current_hp equals max_hp
- **AND** is_defeated is false
- **AND** stat_stages are all 0
- **AND** is_front is false

#### Scenario: Turn queue ordering

- **WHEN** turn queue is calculated
- **THEN** only front-line participants are ordered by speed descending
- **AND** benched and defeated participants are excluded

#### Scenario: Front-line assignment at battle start

- **WHEN** a battle starts
- **THEN** the first participant of each team is marked as the front character
- **AND** all other participants remain benched

#### Scenario: Battle end detection

- **WHEN** all enemy participants have current_hp = 0
- **THEN** battle_status is Victory
- **WHEN** all player participants have current_hp = 0
- **THEN** battle_status is Defeat

#### Scenario: Switch action

- **WHEN** a team executes a switch to a living benched participant
- **THEN** the benched participant becomes the front character
- **AND** the former front character becomes benched
- **AND** stat stages and status effects are preserved

#### Scenario: Switch validation

- **WHEN** a switch targets a defeated participant or the current front
  participant
- **THEN** the switch is rejected with an invalid-target error

#### Scenario: Automatic bench replacement

- **WHEN** the front participant becomes defeated
- **THEN** the first living benched participant becomes the front character
- **AND** the replacement is excluded from acting until the next round

### Requirement: GDExtension Bridge

The `xiangke-godot-bridge` crate SHALL expose a RustBattleSystem Node with
`#[func]` methods for battle initialization, action execution, state
serialization, and battle log access.

#### Scenario: Bridge method registration

- **WHEN** the GDExtension library is loaded by Godot
- **THEN** RustBattleSystem appears as a valid Node type
- **AND** all `#[func]` methods are callable from GDScript

#### Scenario: Data conversion

- **WHEN** GDScript Dictionaries are passed to RustBattleSystem
- **THEN** they are converted to Rust types via dict_to_character/dict_to_move
- **AND** Rust types are serialized back via participant_to_dict/result_to_dict
- **AND** participant dictionaries include the is_front flag

#### Scenario: Target-less player action

- **WHEN** GDScript calls execute_player_action with move data only
- **THEN** the action resolves the opponent's front participant as the target
- **AND** the target index is not required as an argument

#### Scenario: Automatic replacement on defeat

- **WHEN** an action defeats the opponent's front participant
- **THEN** the bridge automatically brings the first living benched enemy to the
  front

#### Scenario: Switch bridge method

- **WHEN** GDScript calls execute_switch with a bench index
- **THEN** the switch is applied and a result dictionary is returned

#### Scenario: Front and bench queries

- **WHEN** GDScript calls get_front_participant/get_bench_participants
- **THEN** the front participant and living benched participants are returned
