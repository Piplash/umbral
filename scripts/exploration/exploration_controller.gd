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
var actor_nodes: Dictionary = {}
var prop_actors: Dictionary = {}
var routines: AmbientRoutines
var interaction_target: String = ""

func world_bounds() -> Rect2:
	return Rect2(0, 0, content.bounds[0], content.bounds[1])

func navigation_blockers(ignore_id: String = "") -> Array[Rect2]:
	var result: Array[Rect2] = blockers.duplicate()
	for id: String in actor_nodes:
		if id != ignore_id:
			result.append(Rect2(actor_nodes[id].position - Vector2(12, 12), Vector2(24, 24)))
	if not ignore_id.is_empty() and player != null:
		result.append(Rect2(player.position - Vector2(10, 10), Vector2(20, 20)))
	return result

func release_interaction() -> void:
	interaction_target = ""
	pending = {}

func setup(data: Dictionary) -> void:
	content = data
	y_sort_enabled = true
	var scenery: ExplorationScenery = ExplorationScenery.new()
	scenery.content = content
	scenery.z_index = -2
	add_child(scenery)
	for prop: Array in data.props:
		var node: ExplorationProp = ExplorationProp.new()
		node.configure(ArtLibrary.prop(int(prop[0])), Rect2(prop[1], prop[2], prop[3], prop[4]))
		add_child(node)
	for prop: Dictionary in data.get("visual_props", []):
		var rect: Array = prop.rect
		var node: ExplorationProp = ExplorationProp.new()
		node.configure(ExplorationProp.texture_for(prop), Rect2(rect[0], rect[1], rect[2], rect[3]), float(prop.get("sort_y", -1)))
		add_child(node)
	var atmosphere: ExplorationAtmosphere = ExplorationAtmosphere.new()
	atmosphere.content = data.get("atmosphere", {})
	atmosphere.z_index = 20
	add_child(atmosphere)
	for box: Array in data.blockers:
		var rect: Rect2 = Rect2(box[0], box[1], box[2], box[3])
		blockers.append(rect)
		add_collision(rect)
	for actor: Dictionary in data.actors:
		add_actor(actor)
	var bounds: Vector2 = Vector2(data.bounds[0], data.bounds[1])
	for rect: Rect2 in [Rect2(-30, -30, bounds.x + 60, 30), Rect2(-30, bounds.y, bounds.x + 60, 30), Rect2(-30, 0, 30, bounds.y), Rect2(bounds.x, 0, 30, bounds.y)]:
		add_collision(rect)
	player = ExplorationPlayer.new()
	player.art_key = data.get("player_art", "hero")
	player.visual_row = int(data.get("player_visual_row", 0))
	player.speed = float(data.get("walk_speed", 100))
	player.position = Vector2(data.start[0], data.start[1])
	add_child(player)
	player.arrived.connect(on_arrived)
	player.manual_navigation_cancelled.connect(release_interaction)
	camera = Camera2D.new()
	camera.zoom = Vector2.ONE * float(data.get("camera_zoom", 1.0))
	camera.position = camera_focus()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(bounds.x)
	camera.limit_bottom = int(bounds.y)
	add_child(camera)
	routines = AmbientRoutines.new()
	routines.exploration = self
	add_child(routines)
	queue_redraw()

func add_actor(actor: Dictionary) -> void:
	if world != null and not ConditionEvaluator.matches(actor.get("conditions", []), world):
		return
	actors[actor.id] = actor.duplicate(true)
	var point: Vector2 = Vector2(actor.position[0], actor.position[1])
	var body_size: Array = actor.get("collision_size", [24, 24])
	var size: Vector2 = Vector2(body_size[0], body_size[1])
	var rect: Rect2 = Rect2(point - size * 0.5, size)
	if (actor.has("art") or actor.has("visual_row")) and not actor.get("static_sprite", false):
		var npc: AmbientActor = AmbientActor.new()
		npc.actor_id = actor.id
		npc.art_key = actor.get("art", "civil")
		npc.visual_row = int(actor.get("visual_row", {"support": 1, "civil": 2}.get(npc.art_key, 0)))
		npc.visual_scale = float(actor.get("visual_scale", 1.0))
		npc.modulate = Color(actor.get("tint", "ffffff"))
		npc.speed = float(actor.get("speed", 42))
		npc.position = point
		npc.routine = actor.get("routine", {"type": "idle"})
		npc.wait_remaining = float(actor.get("initial_pause", 1))
		actor_nodes[actor.id] = npc
		add_child(npc)
		if actor.get("cinematic", false):
			npc.collision_layer = 0
			npc.collision_mask = 0
	elif actor.get("cinematic", false):
		var texture: Texture2D = ExplorationProp.texture_for(actor.visual) if actor.has("visual") else (ArtLibrary.character(actor.art) if actor.has("art") else ArtLibrary.prop(int(actor.prop)))
		var image_size: Array = actor.get("visual_size", [46, 64])
		var image_rect: Rect2 = Rect2(point - Vector2(image_size[0] * 0.5, image_size[1] - 10), Vector2(image_size[0], image_size[1]))
		var sprite: ExplorationProp = ExplorationProp.new()
		sprite.configure(texture, image_rect, point.y)
		sprite.modulate = Color(actor.get("tint", "ffffff"))
		prop_actors[actor.id] = sprite
		add_child(sprite)
	else:
		blockers.append(rect)
		add_collision(rect)

func actor_node(id: String) -> ExplorationActor:
	return player if id == "player" else actor_nodes.get(id)

func actor_position(id: String) -> Vector2:
	var node: ExplorationActor = actor_node(id)
	if node != null:
		return node.position
	var point: Array = actors[id].position
	return Vector2(point[0], point[1])

func position_actor(id: String, value: Vector2) -> void:
	var node: ExplorationActor = actor_node(id)
	if node != null:
		node.position = value
	if prop_actors.has(id):
		prop_actors[id].position = value
	if actors.has(id):
		actors[id].position = [value.x, value.y]

func camera_focus() -> Vector2:
	var offset: Array = content.get("camera_offset", [0, 0])
	return player.position + Vector2(offset[0], offset[1])

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
	interaction_target = id
	if world != null and not ConditionEvaluator.matches(pending.get("conditions", []), world):
		release_interaction()
		return
	if actor_nodes.has(id):
		actor_nodes[id].suspended = true
		actor_nodes[id].visual.face(player.position - actor_nodes[id].position)
	var target: Vector2 = Vector2(pending.position[0], pending.position[1])
	if player.position.distance_to(target) <= 48:
		on_arrived()
		return
	var best: PackedVector2Array = []
	for offset: Vector2 in [Vector2(0, 42), Vector2(-42, 0), Vector2(42, 0), Vector2(0, -42)]:
		var path: PackedVector2Array = InteractionNavigation.route(player.position, target + offset, navigation_blockers(), world_bounds())
		if not path.is_empty() and (best.is_empty() or path.size() < best.size()):
			best = path
	player.route = best
	if best.is_empty():
		release_interaction()

func on_arrived() -> void:
	if pending.is_empty() or player.locked:
		return
	var target: Vector2 = Vector2(pending.position[0], pending.position[1])
	if player.position.distance_to(target) <= 50:
		player.visual.face(target - player.position)
		player.locked = true
		player.route.clear()
		dialogue_requested.emit(pending.get("dialogue", ""))
	pending = {}

func _process(_delta: float) -> void:
	if player == null:
		return
	routines.frozen = player.locked
	for id: String in actor_nodes:
		actors[id].position = [actor_nodes[id].position.x, actor_nodes[id].position.y]
	if not player.locked:
		camera.position = camera_focus()
		if player.velocity.length() > 0 and player.route.is_empty():
			release_interaction()
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
		if point.distance_to(position) < float(actors[id].get("interaction_radius", 30)):
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
	for id: String in actors:
		var actor: Dictionary = actors[id]
		if not actor.get("visible", true):
			continue
		var point: Vector2 = Vector2(actor.position[0], actor.position[1])
		if not actor_nodes.has(id) and not prop_actors.has(id):
			var texture: Texture2D = ExplorationProp.texture_for(actor.visual) if actor.has("visual") else (ArtLibrary.character(actor.art) if actor.has("art") else ArtLibrary.prop(int(actor.prop)))
			var size: Array = actor.get("visual_size", [46, 64])
			draw_texture_rect(texture, Rect2(point - Vector2(size[0] * 0.5, size[1] - 10), Vector2(size[0], size[1])), false, Color(actor.get("tint", "ffffff")))
		if id == hover_id:
			draw_arc(point, 23, 0, TAU, 24, Color("d8bd7e"), 1)
			draw_string(ThemeDB.fallback_font, point + Vector2(-50, -63), actor.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("eee1be"))

		if actor.has("marker") and (world == null or not world.data.examined.get(id, false)):
			draw_string(ThemeDB.fallback_font, point + Vector2(-5, -65), actor.marker, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("e2c688"))
