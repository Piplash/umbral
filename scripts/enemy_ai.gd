class_name EnemyAI
extends RefCounted

static func plan(enemy: TacticalUnit, units: Array, grid: GridManager) -> Array:
	if enemy.jammed:
		return [enemy.cell]
	var best: Array = []
	var best_score: float = INF
	for target: TacticalUnit in units:
		if not target.alive():
			continue
		if (enemy.behavior == "capture" and target != enemy.capture_target) or (enemy.behavior != "capture" and target.team != "ally"):
			continue
		var route: Array = MovementSystem.path_to_adjacent(grid, units, enemy.cell, target.cell)
		var score: float = float(route.size()) + (target.defense * 3.0 + target.hp * 0.05 if enemy.behavior == "flanker" else 0.0)
		if not route.is_empty() and score < best_score:
			best = route
			best_score = score
	return best.slice(0, mini(best.size(), enemy.movement + 1))

static func attack_target(enemy: TacticalUnit, units: Array, grid: GridManager) -> TacticalUnit:
	for target: TacticalUnit in units:
		if target.alive() and target.team == "ally" and grid.distance(enemy.cell, target.cell) == 1:
			return target
	return null
