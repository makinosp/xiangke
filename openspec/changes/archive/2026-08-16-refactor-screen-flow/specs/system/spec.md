## MODIFIED Requirements

### Requirement: Scene Flow

The system SHALL support a hub-and-spoke scene flow centered on the title
screen: Title → CorpsSettings, Title → CharacterSelect → Battle → Result, and
Title → Settings. All sub-screens return to Title via a back button.

#### Scenario: Scene transition from title

- **WHEN** GameManager changes the game state from Title
- **THEN** the corresponding scene is loaded with a transition animation
- **AND** relevant data is passed between scenes

#### Scenario: Return to title from sub-screen

- **WHEN** GameManager transitions back to the Title state from any sub-screen
- **THEN** the title screen is loaded
- **AND** the title screen reflects current save state (e.g., Start button
  enabled/disabled)
