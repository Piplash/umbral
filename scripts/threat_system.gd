class_name ThreatSystem
extends RefCounted

static func attack_cells(grid: GridManager, origin: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for direction: Vector2i in GridManager.DIRECTIONS:
		var cell: Vector2i = origin + direction
		if grid.terrain_walkable(cell):
			cells.append(cell)
	return cells

static func ranges(unit: TacticalUnit, grid: GridManager, units: Array) -> Dictionary:
	var budget: int = 0 if unit.jammed or unit.team == "neutral" else unit.movement
	if unit.team == "ally" and unit.moved:
		budget = 0
	var paths: Dictionary = MovementSystem.reachable(grid, units, unit.cell, budget)
	var potential: Dictionary = {}
	var captures: Dictionary = {}
	var civil: TacticalUnit = unit.capture_target
	for origin: Vector2i in paths:
		for cell: Vector2i in attack_cells(grid, origin):
			if legal_target_cell(cell, unit, grid, units):
				potential[cell] = true
		if unit.behavior == "capture" and not unit.jammed and civil != null and civil.alive() and grid.distance(origin, civil.cell) == 1:
			captures[origin] = true
	var current: Array[Vector2i] = []
	for cell: Vector2i in attack_cells(grid, unit.cell):
		if legal_target_cell(cell, unit, grid, units):
			current.append(cell)
	return {"paths": paths, "current": current, "potential": potential, "capture": captures}

static func legal_target_cell(cell: Vector2i, unit: TacticalUnit, grid: GridManager, units: Array) -> bool:
	var occupant: TacticalUnit = grid.occupant(cell, units)
	return occupant == null or occupant == unit or (occupant.team != unit.team and occupant.team != "neutral")

static func global_danger(grid: GridManager, units: Array) -> Dictionary:
	var attacks: Dictionary = {}
	var captures: Dictionary = {}
	for unit: TacticalUnit in units:
		if unit.team == "enemy" and unit.alive():
			var area: Dictionary = ranges(unit, grid, units)
			attacks.merge(area.potential)
			captures.merge(area.capture)
	return {"attacks": attacks, "capture": captures}
