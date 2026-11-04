class_name AmbientRoutines
extends Node

var exploration: ExplorationController
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var path_requests: int = 0
var frozen: bool = false

func _ready() -> void:
	process_priority = -10
	rng.seed = 4021

func _physics_process(delta: float) -> void:
	for id: String in exploration.actor_nodes:
		var actor: AmbientActor = exploration.actor_nodes[id]
		actor.suspended = frozen or exploration.interaction_target == id
		if actor.suspended:
			actor.interacting = false
			if exploration.interaction_target == id:
				actor.visual.face(exploration.player.position - actor.position)
			continue
		if not actor.route.is_empty():
			continue
		actor.wait_remaining -= delta
		if actor.wait_remaining > 0:
			continue
		actor.wait_remaining = float(actor.routine.get("pause", 2.0))
		var kind: String = actor.routine.get("type", "idle")
		actor.interacting = kind in ["work", "socialize"]
		if kind == "socialize":
			var partner: String = actor.routine.get("partner", "")
			if exploration.actor_nodes.has(partner):
				actor.visual.face(exploration.actor_nodes[partner].position - actor.position)
		if kind not in ["patrol", "wander"]:
			continue
		for attempt: int in range(4):
			var target: Vector2 = actor.position
			if kind == "patrol":
				var points: Array = actor.routine.get("points", [])
				if points.is_empty():
					break
				var point: Array = points[actor.waypoint % points.size()]
				actor.waypoint += 1
				target = Vector2(point[0], point[1])
				if actor.position.distance_to(target) < 2:
					continue
			else:
				var box: Array = actor.routine.get("area", [actor.position.x - 40, actor.position.y - 40, 80, 80])
				target = Vector2(rng.randf_range(box[0], box[0] + box[2]), rng.randf_range(box[1], box[1] + box[3]))
			var reserved: bool = false
			for other_id: String in exploration.actor_nodes:
				var other: AmbientActor = exploration.actor_nodes[other_id]
				if other_id != id and (other.position.distance_to(target) < 28 or (not other.route.is_empty() and other.route[-1].distance_to(target) < 28)):
					reserved = true
			if reserved:
				continue
			path_requests += 1
			actor.route = InteractionNavigation.route(actor.position, target, exploration.navigation_blockers(id), exploration.world_bounds())
			if not actor.route.is_empty():
				break
