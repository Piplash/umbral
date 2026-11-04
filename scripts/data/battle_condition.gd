class_name BattleCondition
extends Resource

@export var message: String = ""

func evaluate(_units: Array, _capture: CaptureSystem, _turns: TurnManager) -> bool:
	return false
