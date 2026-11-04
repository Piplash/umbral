class_name BattleResults
extends RefCounted

var damage_received: int = 0
var abilities_used: int = 0

func defeated(units: Array) -> int:
	var count: int = 0
	for unit: TacticalUnit in units:
		if unit.team == "enemy" and not unit.alive():
			count += 1
	return count
