## Tests for type enum values matching Rust definitions.
extends "res://tests/test_base.gd"

## Verify Type enum values match Rust TypeElement definitions.
func test_type_values() -> int:
	var err := OK
	err = assert_eq(TypeEnums.Type.WOOD, 0, "WOOD = 0"); if err: return err
	err = assert_eq(TypeEnums.Type.FIRE, 1, "FIRE = 1"); if err: return err
	err = assert_eq(TypeEnums.Type.EARTH, 2, "EARTH = 2"); if err: return err
	err = assert_eq(TypeEnums.Type.METAL, 3, "METAL = 3"); if err: return err
	err = assert_eq(TypeEnums.Type.WATER, 4, "WATER = 4"); if err: return err
	err = assert_eq(TypeEnums.Type.YANG, 5, "YANG = 5"); if err: return err
	err = assert_eq(TypeEnums.Type.YIN, 6, "YIN = 6"); if err: return err
	return OK


## Verify EffectType enum values match Rust definitions.
func test_effect_type_values() -> int:
	var err := OK
	err = assert_eq(TypeEnums.EffectType.NONE, 0, "NONE = 0"); if err: return err
	err = assert_eq(TypeEnums.EffectType.BURN, 1, "BURN = 1"); if err: return err
	err = assert_eq(TypeEnums.EffectType.POISON, 2, "POISON = 2"); if err: return err
	err = assert_eq(TypeEnums.EffectType.CONFUSION, 3, "CONFUSION = 3"); if err: return err
	return OK


## Verify DamageCategory enum values match Rust definitions.
func test_damage_category_values() -> int:
	var err := OK
	err = assert_eq(TypeEnums.DamageCategory.PHYSICAL, 0, "PHYSICAL = 0"); if err: return err
	err = assert_eq(TypeEnums.DamageCategory.ARTS, 1, "ARTS = 1"); if err: return err
	return OK


## Verify all Type elements have correct count.
func test_type_count() -> int:
	return assert_eq(TypeEnums.Type.size(), 7, "Type should have 7 variants")
