class_name ExplorationActor
extends CharacterBody2D

signal arrived
var cinematic_running: bool = false
var cinematic_velocity: Vector2 = Vector2.ZERO
var locked: bool = false
var interacting: bool = false
var route: PackedVector2Array = []
var speed: float = 100.0
var facing: Vector2 = Vector2.DOWN
var visual: DirectionalVisual
@export var art_key: String = "hero"
var visual_row: int = 0
var visual_scale: float = 1.0

func _ready() -> void:
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 9
	collision.shape = shape
	add_child(collision)
	visual = DirectionalVisual.new()
	visual.row = visual_row
	visual.art_key = art_key
	visual.scale_factor = visual_scale
	add_child(visual)

func follow_route(delta: float) -> Vector2:
	while not route.is_empty() and position.distance_to(route[0]) < 2:
		route.remove_at(0)
		if route.is_empty():
			arrived.emit()
	return position.direction_to(route[0]) if not route.is_empty() else Vector2.ZERO

func move_direction(direction: Vector2, delta: float, running: bool = false) -> void:
	velocity = direction.normalized() * speed * (1.6 if running else 1.0)
	if not route.is_empty():
		velocity = direction.normalized() * minf(velocity.length(), position.distance_to(route[0]) / maxf(delta, 0.001))
	move_and_slide()
	if velocity.length() > 1:
		facing = velocity.normalized()
	visual.advance(cinematic_velocity if cinematic_velocity != Vector2.ZERO else velocity, running or cinematic_running, interacting, delta)
