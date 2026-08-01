## Why

After every Rust build, copying the dylib into `addons/gdext/` invalidates the
macOS code signature, causing Godot to crash immediately on launch
(`SIGKILL - Code Signature Invalid`). The developer must manually re-sign with
`codesign --force --sign -` after each build or the game will not start. This
friction should be eliminated.

## What Changes

- Add an automatic re-sign step to the `just build-rust` recipe (and the
  combined `run`/`inspect` recipes that depend on it), so the dylib is always
  re-signed before Godot launches.
- macOS-specific build tooling only — no game behavior changes.

## Capabilities

### New Capabilities

<!-- None -->

### Modified Capabilities

<!-- None — pure tooling change, `skip_specs: true` set in .openspec.yaml -->

## Impact

- `justfile` — `build-rust` recipe gains a `codesign --force --sign -` step
  after the copy; `run` and `inspect` inherit it automatically.
- Memory note `godot-bridge-fixes.md` documents the manual workaround that this
  change makes obsolete.
