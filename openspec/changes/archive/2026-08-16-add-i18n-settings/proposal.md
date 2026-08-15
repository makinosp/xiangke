# Proposal: Add i18n & Settings Screen

## Why

The game is a Three Kingdoms title but currently hardcodes English UI text while
character names are Chinese and descriptions are English — a mixed, untranslated
state that blocks wider audiences. There is also no settings UI at all, even
though volume persistence logic already exists in `SaveManager`. Adding
localization (ja / zh-Hans / zh-Hant / en) and a settings screen unlocks both
international reach and user-controllable audio.

## What Changes

- Add an i18n foundation: register translation catalogs (4 locales) with
  `TranslationServer`, apply the saved locale on startup, and enable automatic
  translation of scene `text` properties.
- Localize all hardcoded UI strings across scenes (~36 occurrences: title, corps
  creation, character select, battle, result).
- Localize data-driven display strings: character names & descriptions (38
  resources), move names & descriptions (8 resources), status effect names &
  descriptions (5 resources) via translation keys in `.tres` resources.
- Add a **Settings button** to the title screen that transitions to a new
  settings screen.
- Add a new **Settings screen** (new scene, `GameState.SETTINGS`) with:
  - Language selection (ja / zh-Hans / zh-Hant / en), applied immediately.
  - Master / BGM / SFX volume sliders, persisted via `SaveManager`.
- Extend `SaveManager` with a `settings.language` field (backward compatible:
  missing key defaults to system locale, then `en`).
- Add a CJK-capable font (e.g., Noto Sans CJK) and apply it project-wide so
  Japanese / Chinese glyphs render correctly.

## Capabilities

### New Capabilities

- `i18n`: Translation foundation, locale management, and localized display of UI
  strings and data-driven strings (character/move/status-effect names and
  descriptions) in ja / zh-Hans / zh-Hant / en.
- `settings-screen`: The settings UI reachable from the title screen, covering
  language selection with immediate application and volume controls persisted to
  save data.

### Modified Capabilities

- `domain`: The "display name" requirement for characters, moves, and status
  effects changes — display names become translation-keyed and locale-aware
  rather than fixed strings stored in the resource.

## Impact

- **Scenes**: `title_screen.tscn` (add button), new `settings_screen.tscn`, and
  localized `text` on all existing scenes.
- **Resources**: `resources/characters/*.tres` (38), `resources/moves/*.tres`
  (8), `resources/status_effects/*.tres` (5) — add translation key fields.
- **Autoloads**: `SaveManager` (language persistence, backward-compatible
  defaults), `GameManager` (`GameState.SETTINGS` + transition rules),
  `AudioManager` (already exposes volume setters; wiring only).
- **Foundation scripts**: display code paths for names/descriptions wrapped in
  `tr()`.
- **New assets**: 4 translation catalogs, CJK font files (added to the Web
  export payload — increases package size).
- **Save format**: new optional `settings.language` key; existing saves remain
  valid.
