## Context

Current state (see proposal.md for motivation):

- All scene UI text is hardcoded English (~36 strings across 5 scenes).
- Data resources are mixed: character/move names in Chinese, descriptions in
  English. Display code reads `name` / `description` fields directly.
- `SaveManager` persists settings (volume) via ConfigFile with checksum
  validation and a `SAVE_VERSION` (currently 1).
- `AudioManager` already exposes `set_master_volume` / `set_master_muted` /
  bus-based BGM/SFX volume and applies saved values in `_ready`.
- `GameManager` runs a strict linear state machine: TITLE → CORPS_CREATION →
  CHARACTER_SELECT → BATTLE → RESULT → TITLE.
- `UIFocusManager` provides keyboard focus groups; each screen registers its
  controls.
- No i18n infrastructure exists: no translation catalogs, no CJK font.

## Goals / Non-Goals

**Goals:**

- Establish a translation pipeline (catalogs, keys, `tr()` usage) that the whole
  game follows consistently.
- Add a settings screen (language + volume) reachable from the title screen,
  with immediate application and persistence.
- Keep existing saves and data resources backward compatible.

**Non-Goals:**

- Translating Rust-side battle log strings (battle logs are generated in
  `xiangke-battle`; localizing them is deferred — see Open Questions).
- Runtime language packs / downloadable content.
- Full Chinese reading notation (furigana) for character names.
- Settings beyond language and volume (resolution, keybinds, etc.).

## Decisions

### D1: Translation catalog format — CSV

Use Godot `.csv` translation catalogs (UTF-8 with BOM) placed in `translations/`
(e.g. `translations/ja.csv`, `translations/zh_CN.csv`,
`translations/zh_TW.csv`), registered in `project.godot` under
`[internationalization]` → `translations`.

- **Rationale**: ~150 entries is small; CSV is easy to edit in any spreadsheet
  and by Godot itself. `en` needs no catalog (source strings are English).
- **Alternative considered**: `.po` (gettext). Better for external translators
  and fuzzy matching, but heavier tooling for a small in-house catalog.
- **Alternative considered**: CSV as the _source of truth_ with `.po` exported
  for translators. Overkill at this scale.

### D2: Translation key scheme — data-driven keys, not display strings

Resources get explicit `name_key` / `desc_key` fields:

```
char.<id>.name   char.<id>.desc    (e.g. char.cao_cao.name)
move.<id>.name   move.<id>.desc
effect.<id>.name effect.<id>.desc
ui.*                               (generic UI strings)
```

- **Rationale**: Character names are currently Chinese literals ("曹操"). Using
  the display string as the key would force self-translation (曹操 → 曹操 in zh,
  曹操 → "Cao Cao" in en) and breaks when Simplified/Traditional spellings
  diverge (関羽 / 關羽). Stable IDs survive data renames.
- **Alternative considered**: display-string-as-key (`tr(character.name)`).
  Rejected: self-translation awkwardness and fragility.

### D3: Resource model — add keys, keep legacy fields

Add `name_key` and `desc_key` to `CharacterData`, `MoveData`, and
`StatusEffectData` (`.tres` resources and their GDScript classes). The legacy
`name` / `description` fields stay for this change so existing tooling
(`tools/data_export.gd`, `extensions/tools/xiangke_checker`, tests) keeps
working; display code switches to `tr(name_key)`.

- **Rationale**: Decouples the data-model migration from the display migration,
  reducing blast radius. A follow-up change can drop the legacy fields.
- **Alternative considered**: rename fields in place. Rejected: breaks
  validation tools and tests in the same change.

### D4: Settings manager — new autoload `SettingsManager`

Add a new autoload `SettingsManager` that is the single owner of active
settings:

- `current_locale: String` (e.g. `"ja"`)
- `set_language(locale)` → calls `TranslationServer.set_locale()`, persists via
  `SaveManager`
- `apply_settings()` → applies saved language + volumes at startup
- `get_supported_locales()` → `["en", "ja", "zh_CN", "zh_TW"]`

`SaveManager` stays a pure persistence layer (adds `settings.language`
read/write with backward-compatible defaults). `AudioManager` keeps its volume
logic; the settings screen calls `AudioManager.set_*` directly.

- **Rationale**: Language is a runtime concern (locale switching, immediate
  re-translation) that shouldn't live in save-file plumbing. One autoload avoids
  duplicating `TranslationServer` calls across screens.
- **Alternative considered**: extend `SaveManager`. Rejected: mixes persistence
  with runtime locale handling.
- **Alternative considered**: call `TranslationServer` directly from the
  settings screen. Rejected: duplicate logic, no single place for startup
  application.

### D5: Settings screen — new scene + `GameState.SETTINGS`

- New scene `scenes/settings_screen.tscn` with:
  - Language selector (4 buttons or OptionButton + labels, registered with
    `UIFocusManager`)
  - Master / BGM / SFX volume sliders (or `HSlider` + percent label)
  - Back button
- Add `GameState.SETTINGS` to `GameManager`; extend `get_scene_for_state` and
  `_is_valid_transition` with `TITLE ⇄ SETTINGS` (no transitions from SETTINGS
  into the game flow).
- Language changes apply immediately via `SettingsManager.set_language()`; scene
  text auto-re-translates (Godot's built-in `auto_translate` on `Control`).
  Data-driven strings re-render because display code calls `tr()`.

- **Rationale**: The exploration chose an independent scene over a title-screen
  modal so the settings screen can grow (more options) without entangling the
  title screen. The state machine is the established navigation mechanism.
- **Alternative considered**: modal overlay on the title screen. Rejected in
  exploration: keeps state machine clean but couples settings UI to title screen
  and complicates future expansion.

### D6: Font — project-wide CJK-capable default

Bundle a CJK-capable font (Noto Sans CJK JP covers ja/zh-Hans/zh-Hant glyphs) as
the project default font via a theme resource (e.g.
`assets/ui/default_theme.tres`) applied globally.

- **Rationale**: Godot's default font lacks CJK glyphs; without a font swap the
  localized UI renders tofu boxes. A single global theme avoids per-control font
  configuration.
- **Alternative considered**: per-control font overrides. Rejected: repetitive
  and error-prone.
- **Trade-off**: font file adds several MB to the Web export (WASM/PCK payload).
  Subsetting is a possible follow-up (see Open Questions).

### D7: Locale persistence — backward-compatible `language` key

`SaveManager` reads `settings.language` with fallback: saved value → system
locale if supported → `"en"`. `SAVE_VERSION` stays at 1 (new key is optional;
checksum calculation already iterates all keys dynamically).

- **Rationale**: legacy saves must keep working (spec: settings persistence). No
  version bump is needed because the key is additive and the checksum
  regenerates on next save.

## Risks / Trade-offs

- **Web export size grows (CJK font)** → Accept for now; consider font
  subsetting in a follow-up if the bundle exceeds budget.
- **Translation coverage gaps (missing keys show raw key names)** → English
  fallback via catalog fallback; add a verification test that every `name_key` /
  `desc_key` in resources resolves in all 4 catalogs.
- **Code paths that still display raw `name` / `description`** → Audit display
  sites (foundation scripts, battle unit panels) and route all through `tr()`;
  the coverage test above catches stragglers.
- **Rust battle log strings stay English** → Accepted non-goal; visible in
  battle announcements until a follow-up change localizes the log pipeline.
- **Legacy fields kept alongside keys may drift** → Data validation tools should
  assert key presence; legacy fields are display-frozen for this change.

## Migration Plan

1. Add catalogs + `[internationalization]` registration; UI text entries cover
   the 5 scenes.
2. Add `name_key` / `desc_key` to data classes and all 51 resources; populate
   catalogs for the 4 locales.
3. Switch display code to `tr(name_key)` / `tr(desc_key)`.
4. Add `SettingsManager`; wire startup locale application.
5. Extend `SaveManager` with `language`; add `GameState.SETTINGS` + scene.
6. Add CJK default theme.
7. Rollback: remove the new autoload and revert `project.godot` sections; saves
   written with a `language` key are still readable by the old build (ignored
   unknown key, checksum unaffected for existing files until next save).

## Open Questions

- **Character name rendering per locale**: for `ja`, should "曹操" display as
  the Chinese characters or with kana reading (そうそう)? This is content, not
  architecture — the key scheme supports either. Decided during translation
  authoring.
- **Font subsetting**: whether to subset the CJK font for Web export to reduce
  size. Deferrable to a performance follow-up.
- **Rust-side log localization**: how battle log strings (generated in
  `xiangke-battle`) should be localized, if at all. Deferred; see Non-Goals.
