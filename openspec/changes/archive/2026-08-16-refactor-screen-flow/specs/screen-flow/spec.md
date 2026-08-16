## Purpose

Define the screen navigation model for the game: which screens exist, how they
connect, what buttons are available on each, and how the player moves between
them.

## ADDED Requirements

### Requirement: Title Screen as Navigation Hub

The title screen SHALL serve as the central hub with buttons to reach Corps
Settings, Battle Preparation (Character Select), and Settings screens.

#### Scenario: Title screen buttons displayed

- **WHEN** the title screen loads
- **THEN** three buttons are visible: "Corps Settings", "Start" (Battle
  Preparation), and "Settings"

#### Scenario: Start button disabled when no corps saved

- **WHEN** the title screen loads and no corps roster has been saved
- **THEN** the "Start" button is disabled and visually indicates it is
  unavailable

#### Scenario: Start button enabled when corps saved

- **WHEN** the title screen loads and a valid 6-character corps roster exists in
  save data
- **THEN** the "Start" button is enabled

### Requirement: Corps Settings Screen

The system SHALL provide a Corps Settings screen where the player selects 6
characters to form their corps roster, with the selection persisted to save
data.

#### Scenario: Open corps settings

- **WHEN** the player activates the "Corps Settings" button on the title screen
- **THEN** the game transitions to the corps settings screen

#### Scenario: Pre-select saved characters

- **WHEN** the corps settings screen loads and a saved corps roster exists
- **THEN** the previously saved 6 characters are shown as pre-selected

#### Scenario: Save corps and return

- **WHEN** the player selects 6 characters and activates "Save & Back"
- **THEN** the corps roster is persisted to save data
- **AND** the game returns to the title screen

#### Scenario: Return without saving

- **WHEN** the player activates the "Back" button on the corps settings screen
- **THEN** the game returns to the title screen
- **AND** no changes are saved

### Requirement: Battle Preparation Uses Saved Corps

The character select screen (Battle Preparation) SHALL load the player's corps
from saved data and let the player pick 3 characters for deployment.

#### Scenario: Open battle preparation

- **WHEN** the player activates the "Start" button on the title screen
- **THEN** the game transitions to the character select screen
- **AND** the 6 saved corps characters are displayed for selection

#### Scenario: Back to title from battle preparation

- **WHEN** the player activates the "Back" button on the character select screen
- **THEN** the game returns to the title screen

### Requirement: Back Buttons on Sub-Screens

All sub-screens (Corps Settings, Character Select, Settings) SHALL provide a
"Back" button that returns to the title screen.

#### Scenario: Back button present

- **WHEN** any sub-screen loads
- **THEN** a "Back" button is visible and functional

#### Scenario: Back button returns to title

- **WHEN** the player activates the "Back" button on any sub-screen
- **THEN** the game transitions to the title screen
