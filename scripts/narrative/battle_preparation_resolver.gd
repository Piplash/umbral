class_name BattlePreparationResolver
extends RefCounted

static func prepare(base: BattleMissionData, state: WorldState, modifiers: Array) -> BattleMissionData:
	var mission: BattleMissionData = base.duplicate()
	mission.map = base.map.duplicate(true)
	mission.participants = []
	mission.preparation_messages = []
	for source: UnitSpawnData in base.participants:
		var spawn: UnitSpawnData = source.duplicate()
		spawn.definition = source.definition.duplicate(true)
		mission.participants.append(spawn)
	for modifier: Dictionary in modifiers:
		if not ConditionEvaluator.matches(modifier.get("conditions", []), state):
			continue
		if modifier.has("message"):
			mission.preparation_messages.append(modifier.message)
		match modifier.type:
			"unit_behavior":
				for spawn: UnitSpawnData in mission.participants:
					if spawn.instance_id == modifier.unit:
						spawn.definition.behavior = modifier.behavior
						spawn.definition.movement = int(modifier.movement)
			"barrier":
				var cell: Vector2i = Vector2i(int(modifier.cell[0]), int(modifier.cell[1]))
				if cell not in mission.map.blocked_cells:
					mission.map.blocked_cells.append(cell)
	return mission
