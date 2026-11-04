class_name BoardView
extends Control

signal cell_clicked(cell: Vector2i)
signal cursor_changed(cell: Vector2i)
signal settled
signal route_step(unit_id: String, cell: Vector2i)
signal route_finished(unit_id: String)
var layout: BoardLayout
var tile_size: int:
	get: return layout.tile_size
var origin: Vector2:
	get: return layout.origin
var battle: BattleManager
var cursor: Vector2i = Vector2i.ZERO
var pulse: float = 0.0
var floating: Array[Dictionary] = []
var render_positions: Dictionary = {}
var render_hp: Dictionary = {}
var flashes: Dictionary = {}
var defeat_time: Dictionary = {}
var unit_layer: Node2D
var effect_layer: Node2D
var busy: bool = false
var presentation_paused: bool = false
var travel: Dictionary = {}
var inspected: TacticalUnit
var danger_enabled: bool = false
var potential_enabled: bool = true
var animation_states: Dictionary = {}
var attack_time: Dictionary = {}
const ANIMATIONS: Array[String] = ["idle", "move", "attack", "hurt", "defeat"]

func play_route(unit_id: String, route: Array) -> void:
	if route.size() < 2:
		return
	render_positions[unit_id] = origin + Vector2(route[0]) * tile_size
	travel[unit_id] = route.slice(1).duplicate()
	busy = true

func cancel_presentation() -> void:
	travel.clear()
	attack_time.clear()
	flashes.clear()
	busy = false
	settled.emit()

func set_cursor(cell: Vector2i) -> void:
	if cursor != cell:
		cursor = cell
		cursor_changed.emit(cell)

func preview_route() -> Array:
	var unit: TacticalUnit = battle.selected
	if unit == null or unit.moved or battle.mode != "move" or inspected != null or busy or battle.turns.phase != "ally":
		return []
	return MovementSystem.reachable(battle.grid, battle.units, unit.cell, unit.movement).get(cursor, [])

func play_animation(unit_id: String, animation: String) -> void:
	animation_states[unit_id] = animation
	if animation == "attack":
		attack_time[unit_id] = 0.25
		busy = true
	elif animation == "hurt":
		flashes[unit_id] = 0.28
		busy = true
	elif animation == "defeat":
		defeat_time[unit_id] = 0.0
		busy = true

func _ready() -> void:
	layout = BoardLayout.new(battle.mission.map)
	mouse_filter = Control.MOUSE_FILTER_PASS
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for layer: String in ["ground", "lower", "obstacles"]:
		var scenery: MapVisual = MapVisual.create(battle.mission.map, battle, layer)
		scenery.name = layer.capitalize()
		scenery.layer = layer
		scenery.battle = battle
		scenery.z_index = -4 if layer == "ground" else -3 if layer == "lower" else -2
		add_child(scenery)
	unit_layer = Node2D.new()
	unit_layer.name = "Units"
	unit_layer.draw.connect(draw_units)
	add_child(unit_layer)
	var foreground: MapVisual = MapVisual.create(battle.mission.map, battle, "upper")
	foreground.name = "UpperDecoration"
	foreground.layer = "upper"
	foreground.z_index = 1
	add_child(foreground)
	effect_layer = Node2D.new()
	effect_layer.name = "Effects"
	effect_layer.z_index = 2
	effect_layer.draw.connect(draw_effects)
	add_child(effect_layer)

func cell_at(point: Vector2) -> Vector2i:
	return layout.cell_at(point)

func _gui_input(event: InputEvent) -> void:
	var cell: Vector2i = cell_at(get_local_mouse_position())
	if not battle.grid.inside(cell):
		return
	if event is InputEventMouseMotion:
		set_cursor(cell)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		set_cursor(cell)
		cell_clicked.emit(cell)

func _get_tooltip(at_position: Vector2) -> String:
	var cell: Vector2i = cell_at(at_position)
	if battle == null or not battle.grid.inside(cell):
		return ""
	var coordinate: String = "%s%d" % [char(65 + cell.x), cell.y + 1]
	var unit: TacticalUnit = battle.grid.occupant(cell, battle.units)
	if unit != null:
		return "%s · %s\nPV %d/%d · ATQ %d · DEF %d · MOV %d%s%s" % [coordinate, unit.unit_name, unit.hp, unit.max_hp, unit.attack, unit.defense, unit.movement, "\nDefensa activa" if unit.defending else "", "\nInterferencia activa" if unit.jammed else ""]
	return coordinate + (" · Obstáculo" if cell in battle.grid.obstacles else "")

func effect(cell: Vector2i, value: String, color: Color) -> void:
	floating.append({"cell": cell, "text": value, "color": color, "life": 1.1})
	busy = true
	var unit: TacticalUnit = battle.grid.occupant(cell, battle.units)
	if unit != null:
		flashes[unit.id] = 0.28

func _process(delta: float) -> void:
	if presentation_paused:
		return
	pulse += delta
	var was_busy: bool = busy
	busy = false
	if battle != null:
		for unit: TacticalUnit in battle.units:
			var destination: Vector2 = origin + Vector2(unit.cell) * tile_size
			var current: Vector2 = render_positions.get(unit.id, destination)
			var remaining: float = delta * 340.0
			while travel.has(unit.id) and remaining > 0:
				var next_cell: Vector2i = travel[unit.id][0]
				var waypoint: Vector2 = origin + Vector2(next_cell) * tile_size
				var distance: float = current.distance_to(waypoint)
				if distance <= remaining:
					current = waypoint
					remaining -= distance
					travel[unit.id].pop_front()
					route_step.emit(unit.id, next_cell)
					if travel[unit.id].is_empty():
						travel.erase(unit.id)
						route_finished.emit(unit.id)
				else:
					current = current.move_toward(waypoint, remaining)
					remaining = 0
			# No interpolation toward unit.cell: only the validated route drives motion.
			render_positions[unit.id] = current
			busy = busy or travel.has(unit.id)
			attack_time[unit.id] = maxf(0, float(attack_time.get(unit.id, 0)) - delta)
			busy = busy or float(attack_time[unit.id]) > 0
			render_hp[unit.id] = move_toward(float(render_hp.get(unit.id, unit.hp)), float(unit.hp), delta * 55)
			flashes[unit.id] = maxf(0, float(flashes.get(unit.id, 0)) - delta)
			busy = busy or float(flashes[unit.id]) > 0
			animation_states[unit.id] = "defeat" if not unit.alive() else "move" if travel.has(unit.id) else "attack" if float(attack_time[unit.id]) > 0 else "hurt" if float(flashes[unit.id]) > 0 else "idle"
			if not unit.alive():
				defeat_time[unit.id] = float(defeat_time.get(unit.id, 0)) + delta
				busy = busy or float(defeat_time[unit.id]) < 0.55
	for item: Dictionary in floating:
		item.life -= delta
	floating = floating.filter(func(item: Dictionary) -> bool: return item.life > 0)
	for item: Dictionary in floating:
		busy = busy or float(item.life) > 0.7
	queue_redraw()
	if unit_layer != null:
		unit_layer.queue_redraw()
		effect_layer.queue_redraw()
	if was_busy and not busy:
		settled.emit()

func _draw() -> void:
	if battle == null:
		return
	var selected: TacticalUnit = battle.selected
	var reachable: Dictionary = {}
	var focused: TacticalUnit = inspected if inspected != null and inspected.alive() else selected
	var current_attack: Array[Vector2i] = []
	var potential: Dictionary = {}
	var captures: Dictionary = {}
	if focused != null and focused.alive() and not battle.ended:
		var area: Dictionary = ThreatSystem.ranges(focused, battle.grid, battle.units)
		reachable = area.paths
		current_attack = area.current if focused.team != "neutral" else []
		if focused.team == "enemy" and potential_enabled:
			potential = area.potential
			captures = area.capture
	var danger: Dictionary = ThreatSystem.global_danger(battle.grid, battle.units) if danger_enabled else {"attacks": {}, "capture": {}}
	var targets: Array[Vector2i] = battle.targets()
	for x: int in range(battle.grid.size.x):
		for y: int in range(battle.grid.size.y):
			var cell: Vector2i = Vector2i(x, y)
			var rect: Rect2 = Rect2(origin + Vector2(cell) * tile_size, Vector2(tile_size, tile_size))
			draw_rect(rect, Color(0.7, 0.75, 0.68, 0.12), false)
			if not battle.grid.terrain_walkable(cell):
				draw_rect(rect.grow(-2), Color(0.15, 0.11, 0.08, 0.15))
			if danger.attacks.has(cell) or potential.has(cell):
				draw_rect(rect.grow(-1), Color(0.8, 0.18, 0.16, 0.19))
			if focused != null and reachable.has(cell) and cell != focused.cell:
				var move_tint: Color = Color(0.25, 0.64, 0.77, 0.29) if focused.team == "ally" else Color(0.8, 0.49, 0.24, 0.23)
				draw_rect(rect.grow(-1), move_tint)
				draw_rect(rect.grow(-1), Color(move_tint.lightened(0.2), 0.6), false)
			if cell in current_attack:
				draw_rect(rect.grow(-2), Color(0.9, 0.21, 0.18, 0.25))
				draw_rect(rect.grow(-2), Color(1, 0.48, 0.36, 0.85), false, 2)
			if captures.has(cell) or danger.capture.has(cell):
				draw_rect(rect.grow(-5), Color("e4b65b"), false, 1)
			if cell in targets:
				var tint: Color = Color(0.77, 0.24, 0.24, 0.35) if battle.mode != "heal" else Color(0.3, 0.8, 0.48, 0.32)
				draw_rect(rect.grow(-1), tint)
				draw_rect(rect.grow(-1), Color(tint, 0.8), false)
	if selected != null and selected.alive():
		var rect: Rect2 = Rect2(origin + Vector2(selected.cell) * tile_size + Vector2(2, 2), Vector2(tile_size - 4, tile_size - 4))
		draw_rect(rect, Color(0.52, 0.83, 0.87, 0.65 + sin(pulse * 4) * 0.15), false, 2)
	if inspected != null and inspected.alive():
		draw_rect(Rect2(origin + Vector2(inspected.cell) * tile_size + Vector2(2, 2), Vector2(tile_size - 4, tile_size - 4)), Color("e4b65b"), false, 2)
	if battle.grid.inside(cursor):
		var p: Vector2 = origin + Vector2(cursor) * tile_size
		for offset: Vector2 in [Vector2(1, 1), Vector2(tile_size - 1, 1), Vector2(1, tile_size - 1), Vector2(tile_size - 1, tile_size - 1)]:
			var sx: float = 1 if offset.x < tile_size * 0.5 else -1
			var sy: float = 1 if offset.y < tile_size * 0.5 else -1
			draw_line(p + offset, p + offset + Vector2(sx * 9, 0), Color("f4eed0"), 2)
			draw_line(p + offset, p + offset + Vector2(0, sy * 9), Color("f4eed0"), 2)
		var route: Array = preview_route()
		if route.size() > 1:
			for index: int in range(route.size() - 1):
				draw_line(origin + Vector2(route[index]) * tile_size + Vector2.ONE * tile_size * 0.5, origin + Vector2(route[index + 1]) * tile_size + Vector2.ONE * tile_size * 0.5, Color(0.9, 0.83, 0.58, 0.55), 1)

func draw_units() -> void:
	var sorted: Array = battle.units.duplicate()
	sorted.sort_custom(func(a: TacticalUnit, b: TacticalUnit) -> bool: return a.cell.y < b.cell.y)
	for unit: TacticalUnit in sorted:
		var death: float = float(defeat_time.get(unit.id, 0))
		if not unit.alive() and death > 0.55:
			continue
		var body_origin: Vector2 = Vector2(render_positions.get(unit.id, origin + Vector2(unit.cell) * tile_size)).round()
		var visual_scale: float = tile_size / ArtLibrary.BASE_SPRITE_FOOTPRINT
		var p: Vector2 = Vector2.ZERO
		if float(attack_time.get(unit.id, 0)) > 0:
			body_origin.x += sin(float(attack_time[unit.id]) / 0.25 * PI) * 5 * visual_scale
		var color: Color = Color("8d9699") if unit.team == "ally" and unit.moved and unit.acted else Color.WHITE
		if float(flashes.get(unit.id, 0)) > 0:
			color = Color("ffc3b0")
		if not unit.alive():
			color.a = maxf(0, 1.0 - death / 0.55)
		var sprite: Texture2D = ArtLibrary.unit_texture(unit)
		unit_layer.draw_set_transform(body_origin + Vector2(23, 38) * visual_scale, 0, Vector2(17, 4) * visual_scale)
		unit_layer.draw_circle(Vector2.ZERO, 1, Color(0, 0, 0, 0.4 * color.a))
		unit_layer.draw_set_transform(body_origin, 0, Vector2.ONE * visual_scale)
		if sprite != null:
			var bob: float = floorf(sin(pulse * 2.5 + unit.cell.x) * 0.7)
			unit_layer.draw_texture_rect(sprite, Rect2(p + Vector2(-1, -19 + bob), Vector2(48, 66)), false, color)
		if unit.alive():
			unit_layer.draw_rect(Rect2(p + Vector2(4, 40), Vector2(38, 5)), Color("0a1015"))
			unit_layer.draw_rect(Rect2(p + Vector2(6, 41), Vector2(34 * float(render_hp.get(unit.id, unit.hp)) / unit.max_hp, 2)), unit.definition.tactical_color)
			if unit.defending:
				unit_layer.draw_arc(p + Vector2(23, 22), 20, -PI * 0.8, -PI * 0.2, 12, Color("98bec9"), 2)
			if unit.jammed:
				unit_layer.draw_arc(p + Vector2(23, 22), 22, pulse * 3, pulse * 3 + 4.2, 14, Color("b4a3e1"), 1)

	unit_layer.draw_set_transform(Vector2.ZERO)

func draw_effects() -> void:
	for item: Dictionary in floating:
		var point: Vector2 = origin + Vector2(item.cell) * tile_size + Vector2(4, 7) * (tile_size / ArtLibrary.BASE_SPRITE_FOOTPRINT) - Vector2(0, (1.1 - float(item.life)) * 23)
		var color: Color = item.color
		color.a = minf(1, float(item.life) * 3)
		effect_layer.draw_string(ThemeDB.fallback_font, point + Vector2.ONE, item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0, 0, 0, color.a))
		effect_layer.draw_string(ThemeDB.fallback_font, point, item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
		var age: float = 1.1 - float(item.life)
		if age < 0.25:
			effect_layer.draw_arc(origin + Vector2(item.cell) * tile_size + Vector2.ONE * tile_size * 0.5, 10 + age * 80, 0, TAU, 20, Color(color, 1 - age * 4), 2)
