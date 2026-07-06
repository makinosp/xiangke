# Rust build commands
build-rust:
    cd rust && cargo build --target wasm32-unknown-unknown

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
