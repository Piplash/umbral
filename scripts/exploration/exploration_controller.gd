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
	for box: Array in data.blockers:
		var rect: Rect2 = Rect2(box[0], box[1], box[2], box[3])
		blockers.append(rect)
		add_collision(rect)
	for actor: Dictionary in data.actors:
		actors[actor.id] = actor.duplicate(true)
		var point: Vector2 = Vector2(actor.position[0], actor.position[1])
		var rect: Rect2 = Rect2(point - Vector2(12, 12), Vector2(24, 24))
		if actor.has("art") or actor.has("visual_row"):
			var npc: AmbientActor = AmbientActor.new()
			npc.actor_id = actor.id
			npc.art_key = actor.get("art", "civil")
			npc.visual_row = int(actor.get("visual_row", {"support": 1, "civil": 2}.get(npc.art_key, 0)))
			npc.visual_scale = float(actor.get("visual_scale", 1.0))
			npc.speed = float(actor.get("speed", 42))
			npc.position = point
			npc.routine = actor.get("routine", {"type": "idle"})
			npc.wait_remaining = float(actor.get("initial_pause", 1))
			actor_nodes[actor.id] = npc
			add_child(npc)
		else:
			blockers.append(rect)
			add_collision(rect)
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
	camera.position = player.position
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(bounds.x)
	camera.limit_bottom = int(bounds.y)
	add_child(camera)
	routines = AmbientRoutines.new()
	routines.exploration = self
	add_child(routines)
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
		camera.position = player.position
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
	for id: String in actors:
		var actor: Dictionary = actors[id]
		if not actor.get("visible", true):
			continue
		var point: Vector2 = Vector2(actor.position[0], actor.position[1])
		if not actor_nodes.has(id):
			var texture: Texture2D = ArtLibrary.character(actor.art) if actor.has("art") else ArtLibrary.prop(int(actor.prop))
			draw_texture_rect(texture, Rect2(point - Vector2(23, 54), Vector2(46, 64)), false)
		if id == hover_id:
			draw_arc(point, 23, 0, TAU, 24, Color("d8bd7e"), 1)
			draw_string(ThemeDB.fallback_font, point + Vector2(-50, -63), actor.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("eee1be"))
