class_name ExplorationScenery
extends Node2D

var content: Dictionary

func _draw() -> void:
	var tile: int = int(content.get("ground_tile_size", 64))
	for x: int in range(ceili(float(content.bounds[0]) / tile)):
		for y: int in range(ceili(float(content.bounds[1]) / tile)):
			var index: int = int(content.get("ground_terrain", 0))
			for path: Dictionary in content.get("ground_paths", []):
				var box: Array = path.rect
				if Rect2(box[0], box[1], box[2], box[3]).has_point(Vector2(x + 0.5, y + 0.5) * tile):
					index = int(path.tile)
			draw_texture_rect(ArtLibrary.prop(index), Rect2(x * tile, y * tile, tile, tile), false)
	for surface: Dictionary in content.get("ground_polygons", []):
		var polygon: PackedVector2Array = []
		for point: Array in surface.points:
			polygon.append(Vector2(point[0], point[1]))
		var index: int = int(surface.get("tile", 3))
		for x: int in range(ceili(float(content.bounds[0]) / tile)):
			for y: int in range(ceili(float(content.bounds[1]) / tile)):
				var origin: Vector2 = Vector2(x * tile, y * tile)
				var square: PackedVector2Array = [origin, origin + Vector2(tile, 0), origin + Vector2(tile, tile), origin + Vector2(0, tile)]
				for clipped: PackedVector2Array in Geometry2D.intersect_polygons(square, polygon):
					var uv: PackedVector2Array = []
					for vertex: Vector2 in clipped:
						uv.append((Vector2(index % 4, floori(index / 4.0)) + (vertex - origin) / tile) / 4.0)
					draw_polygon(clipped, PackedColorArray([Color.WHITE]), uv, ArtLibrary.environment)
	for decoration: Dictionary in content.get("decorations", []):
		if decoration.type == "cable":
			var points: PackedVector2Array = []
			for point: Array in decoration.points:
				points.append(Vector2(point[0], point[1]))
			draw_polyline(points, Color("302c2b"), 3)
			continue
		var box: Array = decoration.rect
		var p: Vector2 = Vector2(box[0], box[1])
		match decoration.type:
			"garden":
				for row: int in range(3):
					for patch: int in range(5):
						draw_texture_rect(ArtLibrary.prop(1), Rect2(p + Vector2(patch * 32, row * 26), Vector2(32, 18)), false)
					for plant: int in range(8):
						var sprout: Vector2 = p + Vector2(plant * 19 + 7, row * 26 + 6)
						draw_rect(Rect2(sprout, Vector2(2, 8)), Color("344331"))
						draw_line(sprout + Vector2(0, 4), sprout + Vector2(-4, 1), Color("607b45"), 2)
						draw_line(sprout + Vector2(1, 6), sprout + Vector2(5, 2), Color("879353"), 2)
			"laundry":
				for post: int in [0, int(box[2])]:
					draw_rect(Rect2(p + Vector2(post, -8), Vector2(3, 48)), Color("4b3c30"))
				draw_line(p, p + Vector2(box[2], 0), Color("86715a"), 1)
				for item: int in range(4):
					var cloth: Vector2 = p + Vector2(10 + item * 32, 1)
					var tint: Color = Color("665348") if item % 2 == 0 else Color("596b6b")
					draw_rect(Rect2(cloth + Vector2(-3, 4), Vector2(27, 9)), tint.darkened(0.15))
					draw_rect(Rect2(cloth, Vector2(21, 28)), tint)
					for fold: int in [4, 13, 18]:
						draw_line(cloth + Vector2(fold, 3), cloth + Vector2(fold - 2, 26), tint.darkened(0.22), 1)
					draw_line(cloth, cloth + Vector2(21, 0), tint.lightened(0.18), 1)
					draw_rect(Rect2(cloth + Vector2(3, -3), Vector2(2, 4)), Color("b49d6c"))
			"bench":
				draw_rect(Rect2(p, Vector2(box[2], 9)), Color("65513e"))
				draw_line(p + Vector2(0, 4), p + Vector2(box[2], 4), Color("322b27"), 1)
				draw_line(p, p + Vector2(box[2], 0), Color("907150"), 1)
				draw_rect(Rect2(p + Vector2(8, 8), Vector2(6, 15)), Color("382e26"))
				draw_rect(Rect2(p + Vector2(box[2] - 14, 8), Vector2(6, 15)), Color("382e26"))
