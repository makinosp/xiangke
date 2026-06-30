## Shared type definitions and enums for the game data layer.
## Used across CharacterData, MoveData, TypeChart, and validation systems.
@tool
class_name TypeEnums
extends Node

## The seven elemental types based on 五行 (Five Elements) + 陰陽 (Yin-Yang).
enum Type {
	WOOD, ## Wood / Plant
	FIRE, ## Fire
	EARTH, ## Earth
	METAL, ## Metal
	WATER, ## Water
	YANG, ## Light / Active
	YIN ## Dark / Passive
}

## Status effect types that can be inflicted by moves.
enum EffectType {
	NONE, ## No special effect
	BURN, ## Deals damage over time each turn
	POISON, ## Deals increasing damage each turn
	CONFUSION, ## May cause the target to hit itself
	CHAIN, ## Links damage across multiple targets
	CHARM ## Reduces target's attack stat
}

## Damage calculation categories determining which stats are used.
enum DamageCategory {
	PHYSICAL, ## Uses attacker's Attack and defender's Defense
	ARTS ## Uses attacker's Intelligence and defender's Spirit
}

## Modifiable stat identifiers for stat stage modifications.
enum Stat {
	ATTACK,
	DEFENSE,
	SPEED,
	INTELLIGENCE,
	SPIRIT
}
