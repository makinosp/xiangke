## 1. Translation Foundation

- [x] 1.1 Create `translations/` directory with `ja.csv`, `zh_CN.csv`,
      `zh_TW.csv` catalogs (UTF-8 BOM; `key,source,translation` columns; source
      = English)
- [x] 1.2 Register the three catalogs in `project.godot` under
      `[internationalization]` → `translations`
- [x] 1.3 Add `ui.*` entries to the catalogs for all hardcoded scene strings
      (~36 across title, corps creation, character select, battle, result)
- [x] 1.4 Create `SettingsManager` autoload: `current_locale`,
      `get_supported_locales()` → `["en","ja","zh_CN","zh_TW"]`,
      `set_language(locale)` (calls `TranslationServer.set_locale()` +
      persists), `apply_settings()`
- [x] 1.5 Implement startup locale resolution in `SettingsManager`: saved value
      → system locale if supported → `"en"`

## 2. Data Model & Resources

- [x] 2.1 Add `name_key` and `desc_key` fields to `CharacterData`, `MoveData`,
      and `StatusEffectData` GDScript classes
- [x] 2.2 Add `name_key` / `desc_key` to all 38 character resources in
      `resources/characters/`
- [x] 2.3 Add `name_key` / `desc_key` to all 8 move resources in
      `resources/moves/`
- [x] 2.4 Add `name_key` / `desc_key` to all 5 status effect resources in
      `resources/status_effects/`
- [x] 2.5 Author `char.*` / `move.*` / `effect.*` name+description entries for
      ja / zh_CN / zh_TW (per-locale character name spellings included)
- [x] 2.6 Extend data validation tooling (`extensions/tools/xiangke_checker`,
      `tools/data_export.gd`) to assert `name_key` / `desc_key` presence

## 3. Display Code Migration

- [x] 3.1 Replace direct `name` / `description` reads with `tr(name_key)` /
      `tr(desc_key)` in foundation scripts (character panels, move buttons,
      battle unit panel, etc.)
- [x] 3.2 Audit remaining scripts for hardcoded display strings and route them
      through `tr()` or catalog entries

## 4. Settings Screen

- [x] 4.1 Add `GameState.SETTINGS` to `GameManager` with scene path and
      transition rules (`TITLE ⇄ SETTINGS` only)
- [x] 4.2 Create `scenes/settings_screen.tscn`: language selector,
      master/BGM/SFX volume sliders, Back button
- [x] 4.3 Create `settings_screen.gd`: language selection →
      `SettingsManager.set_language()`; sliders → `AudioManager` volume setters;
      Back → `GameManager.transition_to_state(TITLE)`; register focus group with
      `UIFocusManager`
- [x] 4.4 Add Settings button to `title_screen.tscn` and wire transition to
      SETTINGS

## 5. Save & Locale Persistence

- [x] 5.1 Add `settings.language` read/write to `SaveManager`
      (`_create_default_save`, `save_game`, `_parse_save_data`) with
      backward-compatible defaults
- [x] 5.2 Verify legacy save without `language` key loads and upgrades on next
      save

## 6. Font

- [x] 6.1 Add a CJK-capable font asset (Noto Sans CJK) to the project
- [x] 6.2 Create a default theme resource applying the CJK font and wire it
      project-wide

## 7. Tests & Verification

- [x] 7.1 Add unit test: every `name_key` / `desc_key` in resources resolves in
      all 4 locales
- [x] 7.2 Add unit test: `SettingsManager` locale resolution order (saved →
      system → en)
- [x] 7.3 Add unit test: `SaveManager` language persistence round-trip
- [x] 7.4 Add unit test: legacy save (no `language` key) loads without error
- [x] 7.5 Run the existing test suite and confirm no regressions
- [x] 7.6 Manual verification: change language in settings (UI re-translates
      immediately, CJK renders), adjust volumes, relaunch to confirm
      persistence, and confirm Web export builds
