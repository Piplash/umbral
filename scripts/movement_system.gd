class_name MovementSystem
extends RefCounted

static func reachable(grid: GridManager, units: Array, origin: Vector2i, budget: int) -> Dictionary:
	var visited: Dictionary = {origin: [origin]}
	var frontier: Array[Vector2i] = [origin]
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		var route: Array = visited[current]
		if route.size() - 1 >= budget:
			continue
		for direction: Vector2i in GridManager.DIRECTIONS:
			var next: Vector2i = current + direction
			if not visited.has(next) and grid.is_walkable(next, units):
				visited[next] = route + [next]
				frontier.append(next)
	return visited

static func path_to_adjacent(grid: GridManager, units: Array, origin: Vector2i, target: Vector2i) -> Array:
	var paths: Dictionary = reachable(grid, units, origin, grid.size.x * grid.size.y)
	var best: Array = []
	for cell: Vector2i in paths:
		var path: Array = paths[cell]
		if grid.distance(cell, target) == 1 and (best.is_empty() or path.size() < best.size()):
			best = path
	return best

