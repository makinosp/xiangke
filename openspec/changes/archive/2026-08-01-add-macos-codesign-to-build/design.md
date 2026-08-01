## Context

See `proposal.md` - Why. The `justfile` currently has a `build-rust` recipe that
runs `cargo build` and copies the dylib, but does not re-sign it. On macOS, the
copied dylib has an invalid code signature and Godot dies with `SIGKILL` at
launch. `run` and `inspect` both depend on `build-rust`, so fixing the one
recipe fixes all entry points.

## Goals / Non-Goals

**Goals:**

- Re-sign the copied dylib automatically on every macOS build via `just`.
- Keep the fix local to `build-rust` so `run`/`inspect` inherit it.

**Non-Goals:**

- No CI changes — CI builds are not used for local `just` runs.
- No Windows/Linux handling — codesign is macOS-only by nature.

## Decisions

- **Re-sign inside `build-rust` after the copy**, not as a separate recipe —
  `run` and `inspect` depend on `build-rust`, so a single edit covers all local
  entry points. Alternatives considered: a standalone `sign-rust` recipe would
  require developers to remember an extra step, which is exactly the friction
  this change removes.
- **Use ad-hoc signing** (`codesign --force --sign -`) — matches the verified
  workaround in `godot-bridge-fixes.md`; no Apple developer identity is needed
  for local development.

## Risks / Trade-offs

- [Risk: codesign binary unavailable / non-macOS environment] → Mitigation:
  `just` runs locally on the developer's macOS machine; codesign ships with
  Xcode Command Line Tools, already required for Rust builds on macOS.
- [Risk: re-signing adds a small step to every build] → Mitigation: it is a fast
  local operation, negligible next to `cargo build`.
