# ── Rust toolchain setup (run once) ──────────────────────────
#   rustup toolchain install nightly
#   rustup component add rust-src --toolchain nightly
#   rustup target add wasm32-unknown-emscripten --toolchain nightly
#   rustup target add wasm32-unknown-emscripten
#
# ── Emscripten SDK setup (run once) ──────────────────────────
#   git clone https://github.com/emscripten-core/emsdk.git
#   cd emsdk && ./emsdk install 3.1.74 && ./emsdk activate 3.1.74
#   source ./emsdk_env.sh

# Build Rust GDExtension for native (macOS/Linux/Windows)
# On macOS, copying the dylib invalidates its code signature (Godot SIGKILL
# on launch), so re-sign with ad-hoc identity after the copy.
build-rust:
    cd extensions && cargo build
    cp extensions/target/debug/libxiangke_godot_bridge.dylib addons/gdext/libxiangke-godot-bridge.macos.debug.dylib
    codesign --force --sign - addons/gdext/libxiangke-godot-bridge.macos.debug.dylib

# Build Rust GDExtension for Web (WASM/Emscripten)
# Requires: nightly toolchain, Emscripten SDK, rust-src component
build-rust-wasm:
    cd extensions && cargo +nightly build -Zbuild-std --target wasm32-unknown-emscripten

# Build WASM in release mode with size optimization
build-rust-wasm-release:
    cd extensions && cargo +nightly build -Zbuild-std --target wasm32-unknown-emscripten --release
    wasm-opt -Oz \
      --enable-bulk-memory \
      --enable-sign-ext \
      --enable-nontrapping-float-to-int \
      --enable-mutable-globals \
      target/wasm32-unknown-emscripten/release/xiangke_godot_bridge.wasm \
      -o target/wasm32-unknown-emscripten/release/xiangke_godot_bridge.wasm

# Quick-check WASM compilation without full build
check-rust-wasm:
    cd extensions && cargo +nightly check -Zbuild-std --target wasm32-unknown-emscripten

test-rust:
    cd extensions && cargo test

check-rust:
    cd extensions && cargo check

run-godot: build-rust
    godot

# Godot project validation
inspect: build-rust
    godot --headless --check-only --debug --verbose --quit

# Combined: build Rust + run Godot
run: build-rust
    godot

# ── Data verification ────────────────────────────────────────
# Export all .tres resources via Godot and validate against Rust core schema/rules.
# Requires: local Godot install (headless mode).
# Usage: just verify-data
#        UPDATE_FIXTURE=1 just verify-data   (regenerate integration fixture)
verify-data:
	set -eu; \
	export_path=$(mktemp -t xiangke_data.XXXXXX.json); \
	trap 'rm -f "$export_path"' EXIT; \
	echo "Exporting resources to $export_path..."; \
	godot --headless res://tools/data_export.tscn -- --export-path=$export_path; \
	echo "Validating with Rust checker..."; \
	cd extensions && cargo run -p xiangke-checker -- validate $export_path; \
	if [ -n "${UPDATE_FIXTURE:-}" ]; then \
		echo "Updating fixture..."; \
		cp $export_path core/tests/fixtures/resources.json; \
		echo "✓ Fixture updated at core/tests/fixtures/resources.json"; \
	else \
		echo "✓ All data valid"; \
	fi; \
	rm -f $export_path
