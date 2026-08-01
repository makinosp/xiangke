//! xiangke-battle: Battle system logic for the Xianke turn-based battle game.
//!
//! This crate implements the core battle mechanics:
//! - Turn management and initiative ordering
//! - Damage calculation with type effectiveness
//! - Battle state tracking (participants, status effects)
//! - AI decision-making for enemy characters

/// Participant representation with runtime state.
pub mod participant;

/// Battle state management.
pub mod state;

/// Action execution and damage calculation.
pub mod action;

/// Turn management and initiative ordering.
pub mod manager;

/// Battle flow orchestration.
pub mod flow;

/// Shared test helpers (hidden from public docs).
#[doc(hidden)]
pub mod test_utils;

#[cfg(test)]
mod proptests;
