class_name ExplorationPlayer
extends ExplorationActor

signal manual_navigation_cancelled
var blocked_time: float = 0

func _ready() -> void:
	super._ready()
	var bindings: Dictionary = {"explore_left": [KEY_A, KEY_LEFT], "explore_right": [KEY_D, KEY_RIGHT], "explore_up": [KEY_W, KEY_UP], "explore_down": [KEY_S, KEY_DOWN], "explore_run": [KEY_SHIFT]}
	for action: String in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for code: int in bindings[action]:
				var binding: InputEventKey = InputEventKey.new()
				binding.physical_keycode = code
				InputMap.action_add_event(action, binding)

func _physics_process(delta: float) -> void:
	var direction: Vector2 = Vector2.ZERO
	if not locked:
		direction = Input.get_vector("explore_left", "explore_right", "explore_up", "explore_down")
		if direction != Vector2.ZERO:
			if not route.is_empty():
				manual_navigation_cancelled.emit()
			route.clear()
		else:
			direction = follow_route(delta)
	move_direction(direction, delta, Input.is_action_pressed("explore_run"))
	if not route.is_empty() and direction.length() > 0 and velocity.length() < 1:
		blocked_time += delta
		if blocked_time > 1.5:
			route.clear()
			manual_navigation_cancelled.emit()
			blocked_time = 0
	else:
		blocked_time = 0
