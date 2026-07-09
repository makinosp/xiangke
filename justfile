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
build-rust:
    cd rust && cargo build

# Build Rust GDExtension for Web (WASM/Emscripten)
# Requires: nightly toolchain, Emscripten SDK, rust-src component
build-rust-wasm:
    cd rust && cargo +nightly build -Zbuild-std --target wasm32-unknown-emscripten

# Build WASM in release mode with size optimization
build-rust-wasm-release:
    cd rust && cargo +nightly build -Zbuild-std --target wasm32-unknown-emscripten --release
    wasm-opt -Oz target/wasm32-unknown-emscripten/release/libxiangke_godot_bridge.wasm -o target/wasm32-unknown-emscripten/release/libxiangke_godot_bridge.wasm

# Quick-check WASM compilation without full build
check-rust-wasm:
    cd rust && cargo +nightly check -Zbuild-std --target wasm32-unknown-emscripten

test-rust:
    cd rust && cargo test

check-rust:
    cd rust && cargo check

run-godot: build-rust
    godot

# Godot project validation
inspect:
    godot --headless --check-only --quit

# Combined: build Rust + run Godot
run: build-rust
    godot
