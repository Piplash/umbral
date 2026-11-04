class_name AmbientActor
extends ExplorationActor

var actor_id: String
var routine: Dictionary
var suspended: bool = false
var wait_remaining: float = 0
var waypoint: int = 0
var blocked_time: float = 0
var cinematic_velocity: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if suspended:
		move_direction(Vector2.ZERO, delta)
		if cinematic_velocity != Vector2.ZERO:
			visual.advance(cinematic_velocity, false, false, delta)
		return
	var direction: Vector2 = follow_route(delta)
	move_direction(direction, delta)
	if direction != Vector2.ZERO and velocity.length() < 1:
		blocked_time += delta
		if blocked_time > 1.5:
			route.clear()
			wait_remaining = 1.0
			blocked_time = 0
	else:
		blocked_time = 0
