## 1. Build tooling

- [ ] 1.1 Add `codesign --force --sign -` re-sign step to the `build-rust`
      recipe in `justfile`, after the dylib copy
- [ ] 1.2 Confirm `run` and `inspect` recipes inherit the re-sign step via their
      `build-rust` dependency

## 2. Verification

- [ ] 2.1 Run `just build-rust` — dylib is copied and re-signed without error
- [ ] 2.2 Launch Godot (or `godot --headless res://tests/test_runner.tscn`) — no
      `SIGKILL (Code Signature Invalid)` crash
- [ ] 2.3 Update memory note `godot-bridge-fixes.md` to reflect that the manual
      codesign step is now automated
