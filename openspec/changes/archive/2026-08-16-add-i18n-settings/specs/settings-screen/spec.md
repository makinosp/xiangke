## Purpose

Settings screen reachable from the title screen that lets players change the
game language and audio volume, with changes persisted across sessions.

## ADDED Requirements

### Requirement: Settings Access from Title Screen

The system SHALL provide a Settings button on the title screen that transitions
to the settings screen.

#### Scenario: Open settings from title

- **WHEN** the player activates the Settings button on the title screen
- **THEN** the game transitions to the settings screen
- **AND** the settings screen receives keyboard focus on entry

#### Scenario: Return to title

- **WHEN** the player activates the Back button on the settings screen
- **THEN** the game returns to the title screen
- **AND** no unsaved setting changes are lost (they are already persisted on
  change)

### Requirement: Language Selection

The system SHALL offer a language selector on the settings screen listing the
four supported locales, apply the selection immediately, and persist it.

#### Scenario: Change language

- **WHEN** the player selects a language other than the current one
- **THEN** the active locale changes immediately
- **AND** all visible UI text updates to the new locale without a scene reload

#### Scenario: Language persisted

- **WHEN** the player changes the language
- **THEN** the new `language` value is written to save data
- **AND** it is applied on the next startup

### Requirement: Volume Controls

The system SHALL offer master, BGM, and SFX volume sliders on the settings
screen, applying changes in real time and persisting them.

#### Scenario: Adjust volume

- **WHEN** the player moves a volume slider
- **THEN** the corresponding audio bus volume updates immediately
- **AND** the new value is written to save data

#### Scenario: Muted state

- **WHEN** the master volume slider is set to zero
- **THEN** the master bus is muted
- **AND** the muted state is persisted

### Requirement: Settings Persistence

The system SHALL persist all settings screen values (language and volumes) in
the existing save file without invalidating saves created before this change.

#### Scenario: Legacy save compatibility

- **WHEN** a save file without a `language` key is loaded
- **THEN** the game uses the default locale resolution
- **AND** the save is upgraded with the current values on next save
