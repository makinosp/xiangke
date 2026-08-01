## 1. Build tooling

- [x] 1.1 Add `codesign --force --sign -` re-sign step to the `build-rust`
      recipe in `justfile`, after the dylib copy
- [x] 1.2 Confirm `run` and `inspect` recipes inherit the re-sign step via their
      `build-rust` dependency

## 2. Verification

- [x] 2.1 Run `just build-rust` — dylib is copied and re-signed without error
- [x] 2.2 Launch Godot (or `godot --headless res://tests/test_runner.tscn`) — no
      `SIGKILL (Code Signature Invalid)` crash
- [x] 2.3 Update memory note `godot-bridge-fixes.md` to reflect that the manual
      codesign step is now automated
