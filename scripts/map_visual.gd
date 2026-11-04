class_name MapVisual
extends Node2D

var layer: String = "ground"
var battle: BattleManager
var map_data: BattleMapData
var board_layout: BoardLayout

static func create(data: BattleMapData, active_battle: BattleManager, visual_layer: String) -> MapVisual:
	var visual: MapVisual = data.visual_scene.instantiate() as MapVisual if data.visual_scene != null else MapVisual.new()
	visual.map_data = data
	visual.board_layout = BoardLayout.new(data)
	visual.battle = active_battle
	visual.layer = visual_layer
	return visual

func sprite(index: int, rect: Rect2, tint: Color = Color.WHITE) -> void:
	var texture: Texture2D = ArtLibrary.prop(index)
	if texture != null:
		draw_texture_rect(texture, rect, false, tint)

func _draw() -> void:
	if map_data == null:
		return
	if layer == "ground":
		draw_rect(Rect2(0, 0, 960, 540), Color("1b2421"))
		var tile: int = board_layout.tile_size
		for x: int in range(ceili(960.0 / tile)):
			for y: int in range(ceili(540.0 / tile)):
				sprite(map_data.default_terrain, Rect2(x * tile, y * tile, tile, tile), Color("969e91"))
		for x: int in range(map_data.dimensions.x):
			for y: int in range(map_data.dimensions.y):
				var cell: Vector2i = Vector2i(x, y)
				sprite(int(map_data.terrain.get(cell, map_data.default_terrain)), Rect2(board_layout.pixel(cell), Vector2.ONE * tile))
	elif layer == "obstacles" and battle != null:
		var scale_factor: float = board_layout.tile_size / ArtLibrary.BASE_SPRITE_FOOTPRINT
		for index: int in range(battle.grid.obstacles.size()):
			var p: Vector2 = board_layout.pixel(battle.grid.obstacles[index])
			draw_ellipse_shadow(p + Vector2(23, 37) * scale_factor, Vector2(18, 5) * scale_factor)
			sprite(8 if index % 3 != 1 else 9, Rect2(p + Vector2(1, -6) * scale_factor, Vector2(44, 49) * scale_factor))

func draw_terrain_overrides() -> void:
	for cell: Vector2i in map_data.terrain:
		sprite(int(map_data.terrain[cell]), Rect2(board_layout.pixel(cell), Vector2.ONE * board_layout.tile_size))

func draw_ellipse_shadow(center: Vector2, radius: Vector2) -> void:
	draw_set_transform(center, 0, radius)
	draw_circle(Vector2.ZERO, 1, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
