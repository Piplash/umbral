class_name InteractionNavigation
extends RefCounted

static func route(start: Vector2, target: Vector2, blockers: Array[Rect2], bounds: Rect2) -> PackedVector2Array:
	var graph: AStar2D = AStar2D.new()
	var points: Array[Vector2] = [start, target]
	for rect: Rect2 in blockers:
		var grown: Rect2 = rect.grow(14)
		points.append_array([grown.position, Vector2(grown.end.x, grown.position.y), grown.end, Vector2(grown.position.x, grown.end.y)])
	for index: int in range(points.size()):
		graph.add_point(index, points[index])
	for a: int in range(points.size()):
		for b: int in range(a + 1, points.size()):
			if not bounds.grow(-12).has_point(points[a]) or not bounds.grow(-12).has_point(points[b]):
				continue
			var clear: bool = true
			for rect: Rect2 in blockers:
				var expanded: Rect2 = rect.grow(11)
				if Geometry2D.segment_intersects_segment(points[a], points[b], expanded.position, Vector2(expanded.end.x, expanded.position.y)) != null or Geometry2D.segment_intersects_segment(points[a], points[b], expanded.end, Vector2(expanded.position.x, expanded.end.y)) != null or Geometry2D.segment_intersects_segment(points[a], points[b], expanded.position, Vector2(expanded.position.x, expanded.end.y)) != null or Geometry2D.segment_intersects_segment(points[a], points[b], expanded.end, Vector2(expanded.end.x, expanded.position.y)) != null or expanded.has_point(points[a]) or expanded.has_point(points[b]):
					clear = false
			if clear:
				graph.connect_points(a, b)
	return graph.get_point_path(0, 1)
