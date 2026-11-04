class_name ExplorationController
extends Node2D

signal dialogue_requested(id: String)
var content: Dictionary
var player: ExplorationPlayer
var camera: Camera2D
var blockers: Array[Rect2] = []
var pending: Dictionary = {}
var actors: Dictionary = {}
var hover_id: String = ""
var world: WorldState

func setup(data: Dictionary) -> void:
	content = data
	for box: Array in data.blockers:
		var rect: Rect2 = Rect2(box[0], box[1], box[2], box[3])
		blockers.append(rect)
		add_collision(rect)
	for actor: Dictionary in data.actors:
		actors[actor.id] = actor.duplicate(true)
		var point: Vector2 = Vector2(actor.position[0], actor.position[1])
		var rect: Rect2 = Rect2(point - Vector2(12, 12), Vector2(24, 24))
		blockers.append(rect)
		add_collision(rect)
	var bounds: Vector2 = Vector2(data.bounds[0], data.bounds[1])
	for rect: Rect2 in [Rect2(-30, -30, bounds.x + 60, 30), Rect2(-30, bounds.y, bounds.x + 60, 30), Rect2(-30, 0, 30, bounds.y), Rect2(bounds.x, 0, 30, bounds.y)]:
		add_collision(rect)
	player = ExplorationPlayer.new()
	player.art_key = data.get("player_art", "hero")
	player.speed = float(data.get("walk_speed", 100))
	player.position = Vector2(data.start[0], data.start[1])
	add_child(player)
	player.arrived.connect(on_arrived)
	player.manual_navigation_cancelled.connect(func() -> void: pending = {})
	camera = Camera2D.new()
	camera.position = player.position
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(bounds.x)
	camera.limit_bottom = int(bounds.y)
	add_child(camera)
	queue_redraw()

func add_collision(rect: Rect2) -> void:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = rect.get_center()
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func interact(id: String) -> void:
	if player.locked or not actors.has(id):
		return
	pending = actors[id]
	if world != null and not ConditionEvaluator.matches(pending.get("conditions", []), world):
		pending = {}
		return
	var target: Vector2 = Vector2(pending.position[0], pending.position[1])
	if player.position.distance_to(target) <= 48:
		on_arrived()
		return
	var best: PackedVector2Array = []
	for offset: Vector2 in [Vector2(0, 42), Vector2(-42, 0), Vector2(42, 0), Vector2(0, -42)]:
		var path: PackedVector2Array = InteractionNavigation.route(player.position, target + offset, blockers, Rect2(0, 0, content.bounds[0], content.bounds[1]))
		if not path.is_empty() and (best.is_empty() or path.size() < best.size()):
			best = path
	player.route = best
	if best.is_empty():
		pending = {}

func on_arrived() -> void:
	if pending.is_empty() or player.locked:
		return
	var target: Vector2 = Vector2(pending.position[0], pending.position[1])
	if player.position.distance_to(target) <= 50:
		player.locked = true
		player.route.clear()
		dialogue_requested.emit(pending.dialogue)
	pending = {}

func _process(_delta: float) -> void:
	if player == null:
		return
	if not player.locked:
		camera.position = player.position
		if player.velocity.length() > 0 and player.route.is_empty():
			pending = {}
	hover_id = interactable_at(get_global_mouse_position())
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if not hover_id.is_empty() else Input.CURSOR_ARROW)
	queue_redraw()

func interactable_at(point: Vector2) -> String:
	for id: String in actors:
		if not actors[id].get("visible", true):
			continue
		if world != null and not ConditionEvaluator.matches(actors[id].get("conditions", []), world):
			continue
		var position: Vector2 = Vector2(actors[id].position[0], actors[id].position[1])
		if point.distance_to(position) < 30:
			return id
	return ""

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var id: String = interactable_at(get_global_mouse_position())
		if not id.is_empty():
			interact(id)
			get_viewport().set_input_as_handled()

func _draw() -> void:
	if content.is_empty():
		return
	var tile: int = int(content.get("ground_tile_size", 64))
	for x: int in range(ceili(float(content.bounds[0]) / tile)):
		for y: int in range(ceili(float(content.bounds[1]) / tile)):
			var index: int = int(content.get("ground_terrain", 0))
			for path: Dictionary in content.get("ground_paths", []):
				var box: Array = path.rect
				if Rect2(box[0], box[1], box[2], box[3]).has_point(Vector2(x + 0.5, y + 0.5) * tile):
					index = int(path.tile)
			draw_texture_rect(ArtLibrary.prop(index), Rect2(x * tile, y * tile, tile, tile), false)
	for prop: Array in content.props:
		draw_texture_rect(ArtLibrary.prop(int(prop[0])), Rect2(prop[1], prop[2], prop[3], prop[4]), false)
	for id: String in actors:
		var actor: Dictionary = actors[id]
		if not actor.get("visible", true):
			continue
		var point: Vector2 = Vector2(actor.position[0], actor.position[1])
		var texture: Texture2D = ArtLibrary.character(actor.art) if actor.has("art") else ArtLibrary.prop(int(actor.prop))
		draw_texture_rect(texture, Rect2(point - Vector2(23, 54), Vector2(46, 64)), false)
		if id == hover_id:
			draw_arc(point, 23, 0, TAU, 24, Color("d8bd7e"), 1)
			draw_string(ThemeDB.fallback_font, point + Vector2(-50, -63), actor.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("eee1be"))
