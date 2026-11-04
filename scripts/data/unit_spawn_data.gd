class_name UnitSpawnData
extends Resource

@export var instance_id: String = ""
@export var definition: UnitDefinition
@export var position: Vector2i = Vector2i.ZERO
@export var spawn_point: String = ""

func cell(map: BattleMapData) -> Vector2i:
	return map.spawn_points.get(spawn_point, position) if not spawn_point.is_empty() else position
