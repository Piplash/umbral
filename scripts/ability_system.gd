class_name AbilitySystem
extends RefCounted

const LABELS: Dictionary = {"heavy": "Golpe contundente", "jam": "Interferencia", "heal": "Primeros auxilios"}
const RANGES: Dictionary = {"attack": 1, "heavy": 1, "jam": 3, "heal": 2}

static func available(unit: TacticalUnit, ability: String) -> bool:
	return ability in unit.abilities and int(unit.cooldowns.get(ability, 0)) == 0

static func consume(unit: TacticalUnit, ability: String) -> void:
	# The first decrement occurs at the next allied phase. Thus N+1 blocks N full phases.
	unit.cooldowns[ability] = 3 if ability == "heavy" else 2

static func new_phase(unit: TacticalUnit) -> void:
	unit.moved = false
	unit.acted = false
	unit.defending = false
	for ability: String in unit.cooldowns:
		unit.cooldowns[ability] = maxi(0, int(unit.cooldowns[ability]) - 1)

static func heal(target: TacticalUnit) -> int:
	var amount: int = mini(12, target.max_hp - target.hp)
	target.hp += amount
	return amount
