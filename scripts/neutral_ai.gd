class_name NeutralAI
extends RefCounted

static func plan(unit: TacticalUnit, grid: GridManager, units: Array, shelters: Array[Vector2i], turn: int) -> Array:
	var paths: Dictionary = MovementSystem.reachable(grid, units, unit.cell, unit.movement)
	if unit.behavior == "wander":
		var cells: Array = paths.keys()
		return paths[cells[(turn * 7) % cells.size()]]
	if unit.behavior != "seek_shelter" or shelters.is_empty():
		return [unit.cell]
	var danger: Dictionary = ThreatSystem.global_danger(grid, units).attacks
	var full: Dictionary = MovementSystem.reachable(grid, units, unit.cell, grid.size.x * grid.size.y)
	var best: Vector2i = unit.cell
	var score: float = INF
	for cell: Vector2i in paths:
		var distance: float = INF
		var onward: Dictionary = MovementSystem.reachable(grid, units, cell, grid.size.x * grid.size.y)
		for shelter: Vector2i in shelters:
			if full.has(shelter) and onward.has(shelter):
				distance = minf(distance, onward[shelter].size() - 1)
		var candidate: float = (100.0 if danger.has(cell) else 0.0) + (distance if distance < INF else 0.0)
		if candidate < score:
			score = candidate
			best = cell
	return paths[best]
