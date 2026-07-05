//! xiangke-godot-bridge: Godot Engine GDExtension bindings for Xianke.
//!
//! This crate connects the Rust battle system to Godot Engine via gdext.
//! It registers Rust classes as Godot classes that can be called from GDScript.

use godot::prelude::*;

/// Register all Rust classes with Godot's GDExtension system.
struct XiankeExtension;

#[gdextension]
unsafe impl ExtensionLibrary for XiankeExtension {}
