class_name TurnManager
extends RefCounted

var number: int = 1
var phase: String = "ally"

func start_allies(units: Array) -> void:
	number += 1
	phase = "ally"
	for unit: TacticalUnit in units:
		if unit.team == "ally" and unit.alive():
			AbilitySystem.new_phase(unit)

func all_finished(units: Array) -> bool:
	for unit: TacticalUnit in units:
		if unit.team == "ally" and unit.alive() and not (unit.moved and unit.acted):
			return false
	return true
