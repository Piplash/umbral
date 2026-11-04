class_name DirectionalVisual
extends Node2D

static var atlas: Texture2D
const BANDS: Array[Vector2] = [Vector2(8, 230), Vector2(239, 457), Vector2(463, 685), Vector2(693, 918), Vector2(921, 1164), Vector2(1180, 1380), Vector2(1424, 1560), Vector2(1624, 1764)]
var row: int = 0
var art_key: String = "hero"
var direction: String = "down"
var state: String = "idle"
var phase: float = 0
var last_axis: String = "vertical"
var scale_factor: float = 1.0
const COLUMNS: Dictionary = {"down": 0, "right": 1, "up": 2, "left": 3}

func face(vector: Vector2) -> void:
	if vector.length_squared() < 0.001:
		return
	if absf(vector.x) > absf(vector.y) * 1.15:
		last_axis = "horizontal"
	elif absf(vector.y) > absf(vector.x) * 1.15:
		last_axis = "vertical"
	direction = ("right" if vector.x > 0 else "left") if last_axis == "horizontal" else ("down" if vector.y > 0 else "up")

func advance(velocity: Vector2, running: bool, interacting: bool, delta: float) -> void:
	if velocity.length() > 1:
		face(velocity)
		state = "run" if running else "walk"
		phase += delta * (12 if running else 7)
	else:
		state = "interact" if interacting else "idle"
		if interacting:
			phase += delta * 3
	queue_redraw()

func _draw() -> void:
	if atlas == null and ResourceLoader.exists("res://assets/art/directional_villagers.png"):
		atlas = load("res://assets/art/directional_villagers.png")
	if atlas == null:
		draw_texture_rect(ArtLibrary.character(art_key), Rect2(-23, -55, 46, 64), false)
		return
	# Normalized row bands from the inspected generated atlas (887x1774).
	# Padding is deliberately excluded; smaller animals keep their natural scale.
	var factor: float = atlas.get_height() / 1774.0
	var band: Vector2 = BANDS[clampi(row, 0, 7)] * factor
	var cell: Vector2 = Vector2(atlas.get_width() / 4.0, band.y - band.x)
	var source: Vector2 = Vector2(COLUMNS[direction] * cell.x, band.x)
	var height: float = cell.y / cell.x * 60.0
	var walking: bool = state in ["walk", "run"]
	var swing: float = sin(phase * TAU * 0.5) * (2.5 if state == "run" else 1.8) if walking else 0.0
	var bob: float = absf(swing) * -0.35
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE * scale_factor)
	# The upper body and two lower pieces form a small procedural stepping rig.
	# Rear/front artwork comes from separate atlas regions, never vertical flipping.
	draw_texture_rect_region(atlas, Rect2(-30, -height + bob, 60, height * 0.72), Rect2(source, Vector2(cell.x, cell.y * 0.72)))
	for half: int in range(2):
		var offset: float = swing if half == 0 else -swing
		draw_texture_rect_region(atlas, Rect2(-30 + half * 30, -height * 0.28 + offset, 30, height * 0.28), Rect2(source + Vector2(half * cell.x * 0.5, cell.y * 0.72), Vector2(cell.x * 0.5, cell.y * 0.28)))
	if state == "interact":
		draw_line(Vector2(12, -26), Vector2(19, -31 + sin(phase) * 3), Color("d4bd86"), 2)
	draw_set_transform(Vector2.ZERO)
