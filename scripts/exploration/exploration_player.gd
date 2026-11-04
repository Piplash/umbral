class_name ExplorationPlayer
extends CharacterBody2D

signal arrived
signal manual_navigation_cancelled
var locked: bool = false
var route: PackedVector2Array = []
var speed: float = 100.0
var facing: Vector2 = Vector2.RIGHT
var clock: float = 0
@export var art_key: String = "hero"

func _ready() -> void:
	var bindings: Dictionary = {"explore_left": [KEY_A, KEY_LEFT], "explore_right": [KEY_D, KEY_RIGHT], "explore_up": [KEY_W, KEY_UP], "explore_down": [KEY_S, KEY_DOWN], "explore_run": [KEY_SHIFT]}
	for action: String in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for code: int in bindings[action]:
				var binding: InputEventKey = InputEventKey.new()
				binding.physical_keycode = code
				InputMap.action_add_event(action, binding)
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 9
	collision.shape = shape
	add_child(collision)

func _physics_process(delta: float) -> void:
	clock += delta
	var direction: Vector2 = Vector2.ZERO
	if not locked:
		direction = Input.get_vector("explore_left", "explore_right", "explore_up", "explore_down")
		if direction != Vector2.ZERO:
			if not route.is_empty():
				manual_navigation_cancelled.emit()
			route.clear()
		elif not route.is_empty():
			if position.distance_to(route[0]) < 3:
				route.remove_at(0)
				if route.is_empty():
					arrived.emit()
			if not route.is_empty():
				direction = position.direction_to(route[0])
	velocity = direction * speed * (1.6 if Input.is_action_pressed("explore_run") else 1.0)
	if not route.is_empty():
		velocity = direction * minf(velocity.length(), position.distance_to(route[0]) / maxf(delta, 0.001))
	if direction != Vector2.ZERO:
		facing = direction
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	var texture: Texture2D = ArtLibrary.character(art_key)
	var bob: float = sin(clock * 12) if velocity.length() > 1 else sin(clock * 2) * 0.5
	draw_set_transform(Vector2.ZERO, 0, Vector2(-1 if facing.x < 0 else 1, 1))
	draw_texture_rect(texture, Rect2(-22, -55 + bob, 44, 65), false)
	draw_set_transform(Vector2.ZERO)
