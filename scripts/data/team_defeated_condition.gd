class_name TeamDefeatedCondition
extends BattleCondition

@export var team: String = "enemy"

func evaluate(units: Array, _capture: CaptureSystem, _turns: TurnManager) -> bool:
	for unit: TacticalUnit in units:
		if unit.team == team and unit.alive():
			return false
	return true
