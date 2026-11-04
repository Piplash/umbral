class_name GridManager
extends RefCounted

const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]
var map_data: BattleMapData
var size: Vector2i
var obstacles: Array[Vector2i]

func _init(data: BattleMapData) -> void:
	map_data = data
	size = data.dimensions
	obstacles = data.blocked_cells.duplicate()

func terrain_walkable(cell: Vector2i) -> bool:
	return inside(cell) and cell not in obstacles and (map_data.walkable_cells.is_empty() or cell in map_data.walkable_cells)

func inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y

func distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

func occupant(cell: Vector2i, units: Array) -> TacticalUnit:
	for unit: TacticalUnit in units:
		if unit.alive() and unit.cell == cell:
			return unit
	return null

func is_walkable(cell: Vector2i, units: Array) -> bool:
	return terrain_walkable(cell) and occupant(cell, units) == null

