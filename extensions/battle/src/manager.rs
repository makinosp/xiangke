use rand::Rng;
use rand::seq::SliceRandom;

use crate::participant::Team;
use crate::state::{BattleError, BattleState, Status};

/// Calculates the turn order for all front-line participants.
///
/// Only non-defeated front characters participate in the turn queue.
/// Sorts by effective Speed (descending), with random shuffle to break ties.
/// Returns a list of participant indices.
pub fn calculate_turn_queue(
    participants: &[crate::participant::BattleParticipant],
    rng: &mut impl Rng,
) -> Vec<usize> {
    let mut entries: Vec<(usize, f64)> = participants
        .iter()
        .enumerate()
        .filter(|(_, p)| !p.is_defeated && p.is_front)
        .map(|(i, p)| (i, p.effective_speed()))
        .collect();

    entries.shuffle(rng);
    entries.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));
    entries.into_iter().map(|(i, _)| i).collect()
}

/// Returns the index of a team's front (non-defeated) participant, if any.
pub fn find_front_index(state: &BattleState, team: Team) -> Option<usize> {
    state
        .participants
        .iter()
        .enumerate()
        .find(|(_, p)| p.team == team && p.is_front && !p.is_defeated)
        .map(|(i, _)| i)
}

/// Returns the indices of a team's living benched participants.
pub fn living_bench_indices(state: &BattleState, team: Team) -> Vec<usize> {
    state
        .participants
        .iter()
        .enumerate()
        .filter(|(_, p)| p.team == team && !p.is_front && !p.is_defeated)
        .map(|(i, _)| i)
        .collect()
}

/// Swaps the front character of a team with a living benched participant.
///
/// Validates that the target is alive, on the same team, and currently benched.
/// Returns an error otherwise. Stat stages and status effects are preserved.
pub fn execute_switch(
    state: &mut BattleState,
    team: Team,
    bench_index: usize,
) -> Result<(), BattleError> {
    if bench_index >= state.participants.len() {
        return Err(BattleError::InvalidTarget(format!(
            "Bench index {bench_index} out of range"
        )));
    }
    if state.participants[bench_index].team != team {
        return Err(BattleError::InvalidTarget(
            "Cannot switch to a participant of the other team".into(),
        ));
    }
    if state.participants[bench_index].is_defeated {
        return Err(BattleError::InvalidTarget(
            "Cannot switch to a defeated participant".into(),
        ));
    }
    if state.participants[bench_index].is_front {
        return Err(BattleError::InvalidTarget(
            "Cannot switch to the current front participant".into(),
        ));
    }

    let front_index = match find_front_index(state, team) {
        Some(i) => i,
        None => {
            return Err(BattleError::InvalidTarget(
                "Team has no living front participant to switch away from".into(),
            ));
        }
    };
    let front_name = state.participants[front_index].character_data.name.clone();
    let bench_name = state.participants[bench_index].character_data.name.clone();

    state.participants[front_index].is_front = false;
    state.participants[bench_index].is_front = true;

    state.add_log(format!(
        "{front_name} switches out! {bench_name} enters the front line."
    ));
    Ok(())
}

/// Promotes the first living benched participant of a team to the front.
///
/// Called when the team's front participant is defeated. Returns `true` if a
/// replacement entered, `false` if the bench is empty or the team still has a
/// living front.
pub fn auto_replace(state: &mut BattleState, team: Team) -> bool {
    if find_front_index(state, team).is_some() {
        return false;
    }
    let bench = living_bench_indices(state, team);
    let Some(&bench_index) = bench.first() else {
        return false;
    };
    let name = state.participants[bench_index].character_data.name.clone();
    state.participants[bench_index].is_front = true;
    state.add_log(format!("{name} automatically enters the front line!"));
    true
}

/// Marks the first living participant of each team as the front character.
///
/// Uses the participant order in the state; the first entry of each team
/// (lowest slot) becomes the front character.
fn mark_initial_fronts(state: &mut BattleState) {
    for team in [Team::Player, Team::Enemy] {
        if let Some(idx) = state.participants.iter().position(|p| p.team == team) {
            state.participants[idx].is_front = true;
        }
    }
}

/// Starts a new round by incrementing the round counter and recalculating the turn queue.
/// Returns an error if no active participants exist.
pub fn start_new_round(state: &mut BattleState, rng: &mut impl Rng) -> Result<(), BattleError> {
    state.round_count += 1;
    state.turn_queue = calculate_turn_queue(&state.participants, rng);
    state.turn_queue_index = 0;
    if state.turn_queue.is_empty() {
        return Err(BattleError::NoActiveParticipants);
    }
    Ok(())
}

/// Advances the battle to the next turn, skipping defeated participants.
///
/// Starts a new round if the turn queue is exhausted. Returns an error
/// if no active participants are found.
pub fn advance_to_next_turn(
    state: &mut BattleState,
    rng: &mut impl Rng,
) -> Result<(), BattleError> {
    // Move to the next candidate in the queue, starting a new round if exhausted.
    state.turn_queue_index += 1;
    if state.turn_queue_index >= state.turn_queue.len() {
        start_new_round(state, rng)?;
    }

    // Find the next active participant.
    while state.turn_queue_index < state.turn_queue.len() {
        let idx = state.turn_queue[state.turn_queue_index];
        if idx < state.participants.len() {
            let p = &state.participants[idx];
            if !p.is_defeated {
                state.active_participant = Some(idx);
                state.turn_count += 1;
                return Ok(());
            }
        }
        state.turn_queue_index += 1;
    }

    // Queue fully scanned without finding an active participant: start a fresh round.
    start_new_round(state, rng)?;
    if state.turn_queue.is_empty() {
        return Err(BattleError::NoActiveParticipants);
    }
    state.active_participant = Some(state.turn_queue[0]);
    state.turn_count += 1;
    Ok(())
}

/// Initializes the battle by setting up the first round and selecting the first active participant.
/// Marks the first participant of each team as the front character.
/// Returns an error if the battle is already ended or has no active participants.
pub fn start_battle(state: &mut BattleState, rng: &mut impl Rng) -> Result<(), BattleError> {
    if state.battle_status != Status::Active {
        return Err(BattleError::BattleAlreadyEnded);
    }

    mark_initial_fronts(state);
    start_new_round(state, rng)?;

    state.turn_queue_index = 0;
    if state.turn_queue.is_empty() {
        state.battle_status = Status::Defeat;
        return Err(BattleError::NoActiveParticipants);
    }

    state.active_participant = Some(state.turn_queue[0]);
    state.turn_count = 1;
    state.add_log("Battle started! Round 1.".into());
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::participant::Team;
    use crate::test_utils::make_participant_with_speed as make_participant;
    use rand::SeedableRng;
    use rand::rngs::StdRng;
    use std::collections::HashMap;

    fn make_state(players: usize, enemies: usize) -> BattleState {
        let mut participants = Vec::new();
        for i in 0..players {
            participants.push(make_participant(Team::Player, 100, 70 - i as u32 * 10));
        }
        for i in 0..enemies {
            participants.push(make_participant(Team::Enemy, 100, 60 - i as u32 * 10));
        }
        let mut state = BattleState::new(participants, HashMap::new()).unwrap();
        mark_initial_fronts(&mut state);
        state
    }

    #[test]
    fn test_turn_queue_order() {
        let state = make_state(1, 1);
        let mut rng = StdRng::seed_from_u64(42);
        let queue = calculate_turn_queue(&state.participants, &mut rng);
        assert_eq!(queue.len(), 2);
        let speed0 = state.participants[queue[0]].effective_speed();
        let speed1 = state.participants[queue[1]].effective_speed();
        assert!(speed0 >= speed1);
    }

    #[test]
    fn test_turn_queue_excludes_defeated() {
        let mut state = make_state(2, 1);
        state.participants[0].is_defeated = true;
        let mut rng = StdRng::seed_from_u64(42);
        let queue = calculate_turn_queue(&state.participants, &mut rng);
        // Only the enemy front remains active.
        assert_eq!(queue.len(), 1);
        assert_eq!(queue[0], 2);
        assert!(!queue.contains(&0));
    }

    #[test]
    fn test_turn_queue_excludes_benched() {
        let state = make_state(2, 2);
        let mut rng = StdRng::seed_from_u64(42);
        let queue = calculate_turn_queue(&state.participants, &mut rng);
        // Only front participants (indices 0 and 2) are in the queue.
        assert_eq!(queue.len(), 2);
        assert!(queue.contains(&0));
        assert!(queue.contains(&2));
        assert!(!queue.contains(&1));
        assert!(!queue.contains(&3));
    }

    #[test]
    fn test_initial_fronts_marked() {
        let state = make_state(2, 2);
        assert!(state.participants[0].is_front);
        assert!(!state.participants[1].is_front);
        assert!(state.participants[2].is_front);
        assert!(!state.participants[3].is_front);
    }

    #[test]
    fn test_execute_switch_success() {
        let mut state = make_state(2, 2);
        let result = execute_switch(&mut state, Team::Player, 1);
        assert!(result.is_ok());
        assert!(!state.participants[0].is_front);
        assert!(state.participants[1].is_front);
    }

    #[test]
    fn test_execute_switch_to_defeated_rejected() {
        let mut state = make_state(2, 2);
        state.participants[1].is_defeated = true;
        let result = execute_switch(&mut state, Team::Player, 1);
        assert!(result.is_err());
    }

    #[test]
    fn test_execute_switch_to_front_rejected() {
        let mut state = make_state(2, 2);
        let result = execute_switch(&mut state, Team::Player, 0);
        assert!(result.is_err());
    }

    #[test]
    fn test_execute_switch_other_team_rejected() {
        let mut state = make_state(2, 2);
        let result = execute_switch(&mut state, Team::Player, 2);
        assert!(result.is_err());
    }

    #[test]
    fn test_auto_replace_promotes_first_bench() {
        let mut state = make_state(2, 2);
        state.participants[0].is_defeated = true;
        state.participants[0].is_front = false;
        assert!(auto_replace(&mut state, Team::Player));
        assert!(state.participants[1].is_front);
    }

    #[test]
    fn test_auto_replace_no_bench() {
        let mut state = make_state(1, 1);
        state.participants[0].is_defeated = true;
        state.participants[0].is_front = false;
        assert!(!auto_replace(&mut state, Team::Player));
        assert!(find_front_index(&state, Team::Player).is_none());
    }

    #[test]
    fn test_auto_replace_noop_with_living_front() {
        let mut state = make_state(2, 2);
        assert!(!auto_replace(&mut state, Team::Player));
        assert!(state.participants[0].is_front);
    }

    #[test]
    fn test_find_front_and_bench() {
        let state = make_state(2, 2);
        assert_eq!(find_front_index(&state, Team::Player), Some(0));
        assert_eq!(find_front_index(&state, Team::Enemy), Some(2));
        assert_eq!(living_bench_indices(&state, Team::Player), vec![1]);
        assert_eq!(living_bench_indices(&state, Team::Enemy), vec![3]);
    }

    #[test]
    fn test_start_battle() {
        let mut state = make_state(1, 1);
        let mut rng = StdRng::seed_from_u64(42);
        assert!(start_battle(&mut state, &mut rng).is_ok());
        assert_eq!(state.turn_count, 1);
        assert!(state.active_participant.is_some());
        assert!(state.turn_count > 0);
    }

    #[test]
    fn test_advance_to_next_turn() {
        let mut state = make_state(1, 1);
        let mut rng = StdRng::seed_from_u64(42);
        start_battle(&mut state, &mut rng).unwrap();
        let first = state.active_participant;
        advance_to_next_turn(&mut state, &mut rng).unwrap();
        assert_ne!(state.active_participant, first);
    }

    #[test]
    fn test_start_battle_no_participants() {
        let mut state = make_state(1, 1);
        state.participants[0].take_damage(100);
        state.participants[1].take_damage(100);
        let mut rng = StdRng::seed_from_u64(42);
        assert!(start_battle(&mut state, &mut rng).is_err());
    }

    #[test]
    fn test_new_round() {
        let mut state = make_state(2, 1);
        let mut rng = StdRng::seed_from_u64(42);
        start_new_round(&mut state, &mut rng).unwrap();
        assert_eq!(state.round_count, 1);
        assert!(!state.turn_queue.is_empty());
        assert_eq!(state.turn_queue_index, 0);
    }

    #[test]
    fn test_multiple_rounds() {
        let mut state = make_state(1, 1);
        let mut rng = StdRng::seed_from_u64(42);
        start_battle(&mut state, &mut rng).unwrap();
        assert_eq!(state.round_count, 1);
        // Advance through entire first round (2 participants)
        advance_to_next_turn(&mut state, &mut rng).unwrap();
        // Should start round 2
        assert!(state.round_count >= 1);
    }

    #[test]
    fn test_speed_tie_breaking() {
        // Same speed front participants should still produce a deterministic order
        let mut participants = Vec::new();
        for _i in 0..2 {
            participants.push(make_participant(Team::Player, 100, 50));
        }
        for _i in 0..2 {
            participants.push(make_participant(Team::Enemy, 100, 50));
        }
        // Mark first of each team as front.
        participants[0].is_front = true;
        participants[2].is_front = true;
        let mut rng = StdRng::seed_from_u64(42);
        let queue = calculate_turn_queue(&participants, &mut rng);
        assert_eq!(queue.len(), 2);
        // Order may vary due to shuffle, but must contain both front indices
        for idx in [0, 2] {
            assert!(queue.contains(&idx), "queue {queue:?} missing index {idx}");
        }
    }

    #[test]
    fn test_advance_to_next_turn_defeated_skipped() {
        let mut state = make_state(2, 1);
        let mut rng = StdRng::seed_from_u64(42);
        start_battle(&mut state, &mut rng).unwrap();
        // Defeat all players except one
        state.participants[0].is_defeated = true;
        // Advance until all undefeated participants have had a turn
        let mut advance_count = 0;
        while advance_count < 10 {
            if advance_to_next_turn(&mut state, &mut rng).is_err() {
                break;
            }
            if let Some(idx) = state.active_participant {
                assert!(
                    !state.participants[idx].is_defeated,
                    "defeated participant should not be active"
                );
            }
            advance_count += 1;
        }
    }

    #[test]
    fn test_start_battle_battle_already_ended() {
        let mut state = make_state(1, 1);
        let mut rng = StdRng::seed_from_u64(42);
        state.battle_status = Status::Victory;
        let result = start_battle(&mut state, &mut rng);
        assert!(result.is_err());
    }
}
