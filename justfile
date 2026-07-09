# Rust build commands
# Build Rust GDExtension for native (macOS/Linux/Windows)
build-rust:
    cd rust && cargo build

# Build Rust GDExtension for Web (WASM/Emscripten)
# Requires: nightly toolchain, Emscripten SDK, rust-src component
build-rust-wasm:
    cd rust && cargo +nightly build -Zbuild-std --target wasm32-unknown-emscripten

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
