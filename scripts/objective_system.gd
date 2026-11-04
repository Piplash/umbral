class_name ObjectiveSystem
extends RefCounted

var mission: BattleMissionData

func _init(data: BattleMissionData) -> void:
	mission = data

func evaluate(units: Array, capture: CaptureSystem, turns: TurnManager) -> Dictionary:
	var all_won: bool = not mission.victory_conditions.is_empty()
	for condition: BattleCondition in mission.victory_conditions:
		all_won = all_won and condition.evaluate(units, capture, turns)
	if all_won:
		return {"status": "victory", "reason": mission.victory_conditions[0].message}
	for condition: BattleCondition in mission.defeat_conditions:
		if condition.evaluate(units, capture, turns):
			return {"status": "defeat", "reason": condition.message}
	return {"status": "ongoing", "reason": ""}
