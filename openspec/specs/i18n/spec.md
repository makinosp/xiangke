# i18n Specification

## Purpose
Localization foundation for the game: translation catalogs, locale management,
and localized rendering of UI and data-driven strings across supported locales.
## Requirements
### Requirement: Translation Catalog Registration

The system SHALL register translation catalogs for the four supported locales:
English (`en`), Japanese (`ja`), Simplified Chinese (`zh_CN`), and Traditional
Chinese (`zh_TW`), covering all user-facing UI strings and data-driven display
strings (character names/descriptions, move names/descriptions, status effect
names/descriptions).

#### Scenario: All catalogs registered

- **WHEN** the game starts
- **THEN** translation catalogs for `en`, `ja`, `zh_CN`, and `zh_TW` are
  registered with `TranslationServer`
- **AND** every catalog contains entries for all defined translation keys

#### Scenario: Missing key fallback

- **WHEN** a translation key is not present in the active locale's catalog
- **THEN** the system falls back to the English catalog entry
- **AND** if the key is missing from English too, the raw key is displayed

### Requirement: Locale Persistence and Startup Application

The system SHALL apply the persisted locale on startup: the saved `language`
setting takes precedence, otherwise the system locale is used if supported,
otherwise English.

#### Scenario: Saved locale applied on startup

- **WHEN** the game starts and a `language` setting is saved
- **THEN** `TranslationServer.set_locale()` is called with the saved locale
- **AND** all UI text renders in that locale

#### Scenario: No saved locale

- **WHEN** the game starts and no `language` setting is saved
- **THEN** the system locale is used if it matches a supported locale
- **AND** otherwise English is used

### Requirement: UI Text Localization

The system SHALL display all user-facing scene text (title, buttons, labels,
battle announcements, result screen) in the active locale.

#### Scenario: Scene text translated

- **WHEN** a scene's UI text is rendered in a non-English locale
- **THEN** every user-facing string is shown translated into that locale
- **AND** no hardcoded English UI strings remain visible

### Requirement: Data-Driven String Localization

The system SHALL resolve character names, move names, status effect names, and
their descriptions through translation keys defined in the `.tres` resources, so
the displayed text follows the active locale.

#### Scenario: Localized character name

- **WHEN** a character's name is displayed while the locale is Japanese
- **THEN** the name resolves via the character's translation key
- **AND** matches the Japanese catalog entry

#### Scenario: Localized description

- **WHEN** a character or move description is displayed
- **THEN** it resolves via the resource's description translation key
- **AND** matches the active locale's catalog entry

### Requirement: CJK Glyph Rendering

The system SHALL render Japanese and Chinese glyphs correctly on all UI controls
across all supported locales.

#### Scenario: Japanese and Chinese text renders

- **WHEN** the locale is `ja`, `zh_CN`, or `zh_TW`
- **THEN** labels and buttons display CJK characters without missing-glyph boxes
- **AND** the active font covers the required glyph ranges

