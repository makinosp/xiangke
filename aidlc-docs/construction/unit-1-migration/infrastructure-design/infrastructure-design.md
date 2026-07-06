# Infrastructure Design — Phase 1: Toolchain Setup

## 1. Infrastructure Mapping

This document maps the logical infrastructure components for the Rust toolchain
setup to actual services and configurations.

### 1.1 Development Toolchain

| Component                 | Technology    | Version    | Configuration                                              |
| ------------------------- | ------------- | ---------- | ---------------------------------------------------------- |
| **Rust Compiler**         | `rustc`       | 1.94.0     | Installed via `rustup`, target `wasm32-unknown-unknown` |
| **Cargo Package Manager** | `cargo`       | 1.94.0     | Default configuration, uses `Cargo.toml`                   |
| **Godot Engine**          | Godot         | 4.7.stable | Installed locally, uses `project.godot`                    |
| **Godot-Rust Bindings**   | `godot` crate | 0.5.4      | `edition = "2024"`, `features = ["gdextension"]`           |
| **Build System**          | `just`        | 1.24.0     | Uses `justfile` for task automation                        |

### 1.2 Development Environment

| Component              | Description                             |
| ---------------------- | --------------------------------------- |
| **IDE**                | VS Code with Rust Analyzer extension    |
| **Editor Integration** | rust-analyzer, rustfmt, clippy          |
| **Debugging**          | `cargo run`, `cargo test`, Godot editor |
| **Testing**            | `cargo test`, `#[cfg(test)]` unit tests |

### 1.3 Build Infrastructure

| Component          | Description                                                               |
| ------------------ | ------------------------------------------------------------------------- |
| **Local Build**    | `just build` → `cargo build --target wasm32-unknown-emscripten` → `godot` |
| **CI/CD Pipeline** | GitHub Actions: `on: push` → `cargo build` + `cargo test`                 |
| **Export Target**  | Web (HTML5/WASM) via Godot export                                         |

## 2. Deployment Environment

| Component   | Description                                 |
| ----------- | ------------------------------------------- |
| **Hosting** | GitHub Pages (via `gh-pages` branch)        |
| **CDN**     | GitHub Pages CDN                            |
| **Runtime** | Web browser (Chrome, Firefox, Safari, Edge) |

## 3. Deployment Considerations

- **GDExtension Binary**: The compiled `.gdextension` file will be built for
  `wasm32-unknown-unknown` target.
- **WASM Size**: Optimize for <5MB additional size using `wasm-opt`.
- **Web Autoplay**: The Rust GDExtension must respect Web browser autoplay
  policies.
- **Error Handling**: Comprehensive error reporting via `thiserror`/`anyhow`.

---

## 4. Summary

The infrastructure design has mapped the following:

- **Development Toolchain**: Rust 1.94.0 (2024 edition), Cargo, Godot 4.7,
  godot-rust v0.5.4
- **Development Environment**: VS Code, rust-analyzer, cargo test
- **Build Infrastructure**: `just` + `justfile`, GitHub Actions CI/CD
- **Deployment Environment**: GitHub Pages, Web browser

All components are compatible and ready for implementation.
