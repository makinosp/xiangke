//! xiangke-core: Shared data types for the Xianke turn-based battle game.
//!
//! This crate provides the fundamental types used across all Rust components:
//! - Type system (element types, type chart)
//! - Character and move data definitions
//! - Status effect definitions
//! - Shared utility functions

/// Type system module: element types, effectiveness chart, and shared enums.
pub mod types;

/// Character data definitions.
pub mod character;

/// Move data definitions.
pub mod moves;

/// Status effect definitions.
pub mod status;

/// Pure calculation helpers (stat stage multiplier, raw damage formula).
pub mod calc;

/// Data validation logic (migrated from GDScript DataValidator + DataValidationUtils).
pub mod validator;

#[cfg(test)]
mod proptests;
