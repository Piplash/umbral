class_name SettlementView
extends MapVisual

func _draw() -> void:
	if map_data == null:
		return
	if layer == "ground":
		draw_rect(Rect2(0, 0, 960, 540), Color("1b2421"))
		for x: int in range(22):
			for y: int in range(13):
				var index: int = 0
				if (x >= 7 and x <= 11 and y >= 2) or (y == 8 and x > 3 and x < 14):
					index = 1 if (x + y) % 3 == 0 else 2
				sprite(index, Rect2(Vector2(x, y) * map_data.cell_size, Vector2.ONE * map_data.cell_size), Color("b7bbab"))
		draw_terrain_overrides()
		return
	if layer == "lower":
		# Independent scenery placed outside the playable grid.
		sprite(4, Rect2(67, 93, 157, 170))
		sprite(4, Rect2(-28, 340, 155, 166), Color("8c969d"))
		sprite(5, Rect2(530, 39, 176, 136))
		sprite(6, Rect2(622, 241, 105, 161))
		sprite(14, Rect2(133, 421, 87, 95))
		sprite(12, Rect2(158, 326, 49, 65))
		sprite(13, Rect2(178, 270, 34, 39))
		for x: int in range(3):
			sprite(10, Rect2(273 + x * 76, 68, 86, 52))
		sprite(10, Rect2(265, 487, 86, 52))
		sprite(15, Rect2(204, 56, 40, 100))
		sprite(15, Rect2(349, 475, 42, 100))
		for point: Vector2 in [Vector2(109, 288), Vector2(601, 166), Vector2(622, 431), Vector2(234, 79), Vector2(432, 37)]:
			sprite(9, Rect2(point, Vector2(62, 52)))
		return
	if layer == "obstacles" and battle != null:
		super._draw()
		return
	if layer == "upper":
		for point: Vector2 in [Vector2(-32, -60), Vector2(117, -95), Vector2(335, -113), Vector2(643, -35), Vector2(663, 373), Vector2(-48, 235)]:
			sprite(7, Rect2(point, Vector2(160, 164)), Color("7d9192"))
		for point: Vector2 in [Vector2(69, 298), Vector2(115, 377), Vector2(597, 377), Vector2(598, 478), Vector2(419, 498), Vector2(70, 25)]:
			sprite(11, Rect2(point, Vector2(70, 55)))
		# Local warm illumination is confined to scenery, away from tactical markers.
		for point: Vector2 in [Vector2(181, 360), Vector2(155, 203)]:
			for radius: int in range(5, 42, 5):
				draw_circle(point, radius, Color(0.9, 0.48, 0.13, 0.012))

