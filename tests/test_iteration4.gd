extends SceneTree

var checks: int = 0
var failures: int = 0

func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for index: int in range(count):
		await physics_frame

func run() -> void:
	var visual: DirectionalVisual = DirectionalVisual.new()
	for vector: Vector2 in [Vector2.UP, Vector2.LEFT, Vector2.DOWN, Vector2.RIGHT]:
		visual.advance(vector * 100, false, false, 0.1)
		var orientation: String = visual.direction
		var phase: float = visual.phase
		visual.advance(Vector2.ZERO, false, false, 0.1)
		expect(visual.state == "idle" and visual.direction == orientation, "idle retains orientation")
		visual.advance(vector * 100, false, false, 0.1)
		expect(visual.state == "walk" and visual.phase > phase, "step phase continues")
	visual.advance(Vector2.UP * 160, true, false, 0.1)
	expect(visual.direction == "up" and visual.state == "run", "rear art and running")
	visual.advance(Vector2.ZERO, false, true, 0.1)
	expect(visual.state == "interact", "interact state")
	visual.face(Vector2(1.0, 1.01))
	expect(visual.last_axis == "vertical", "diagonal hysteresis")
	visual.free()
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.start_exploration()
	var session: StorySession = main.screen.get_child(0)
	await frames(2)
	expect(session.intro_active and session.exploration.player.locked and main.story_flow.phase == "intro", "intro precedes controls")
	var duration: float = 0
	for action: Dictionary in session.content.intro:
		duration += float(action.seconds)
	expect(duration >= 30 and duration <= 60, "configured intro duration")
	var generation: int = session.card_generation
	session.finish_card(generation)
	expect(session.card_generation == generation + 1, "advance opens next card")
	session.finish_card(generation)
	expect(session.card_generation == generation + 1, "stale double advance ignored")
	session.skip_intro()
	await create_timer(0.8).timeout
	expect(not session.intro_active and not session.exploration.player.locked and main.story_flow.phase == "exploration", "skip fades and enables exploration")
	var world: ExplorationController = session.exploration
	expect(world.world_bounds().size == Vector2(1080, 780), "compact existing map")
	expect(world.actor_nodes.size() == 8, "configured compact population uses shared actors")
	var lira: AmbientActor = world.actor_nodes.lira
	var start: Vector2 = lira.position
	var dog_start: Vector2 = world.actor_nodes.dog.position
	var child_start: Vector2 = world.actor_nodes.child.position
	await frames(180)
	expect(lira.position.distance_to(start) > 15, "Lira moves independently")
	expect(lira.visual.state in ["walk", "idle"], "Lira shares visual controller")
	world.player.position = lira.position + Vector2(0, 42)
	world.interact("lira")
	await frames(3)
	var paused: Vector2 = lira.position
	await frames(30)
	expect(world.player.locked and lira.position.distance_to(paused) < 0.1 and lira.visual.state == "idle", "dialogue pauses routine")
	session.choose(session.content.dialogues.lira.choices[0])
	world.player.position = Vector2(500, 480)
	await frames(300)
	expect(not lira.suspended and lira.position.distance_to(paused) > 5, "routine resumes")
	expect(world.actor_nodes.dog.position.distance_to(dog_start) > 1, "animal moves autonomously")
	expect(world.actor_nodes.child.position.distance_to(child_start) > 1 and Rect2(300, 440, 100, 100).has_point(world.actor_nodes.child.position), "child wanders in safe area")
	expect(session.card_generation == 2 and not session.intro_active, "dialogue does not replay intro")
	var path_count: int = world.routines.path_requests
	await frames(60)
	expect(world.routines.path_requests - path_count < 35, "routes only at decisions")
	for id: String in world.actor_nodes:
		var actor: AmbientActor = world.actor_nodes[id]
		expect(world.world_bounds().grow(-9).has_point(actor.position), "actor inside bounds: " + id)
		for blocker: Rect2 in world.blockers:
			expect(not blocker.grow(8).has_point(actor.position), "actor avoids obstacle: " + id)
	# Freeze a stable snapshot and prove every interaction has a reachable approach.
	world.player.locked = true
	await frames(2)
	for id: String in world.actors:
		var target: Vector2 = Vector2(world.actors[id].position[0], world.actors[id].position[1])
		var reachable: bool = false
		for offset: Vector2 in [Vector2(0, 42), Vector2(-42, 0), Vector2(42, 0), Vector2(0, -42)]:
			if not InteractionNavigation.route(Vector2(500, 480), target + offset, world.navigation_blockers(), world.world_bounds()).is_empty():
				reachable = true
				break
		expect(reachable, "reachable interaction: " + id)
	for warned: bool in [false, true]:
		for terminal: bool in [false, true]:
			var state: WorldState = WorldState.new()
			state.data.flags.villager_warned = warned
			state.data.prepared.terminal = terminal
			var mission: BattleMissionData = BattlePreparationResolver.prepare(MissionCatalog.default_mission(), state, session.content.modifiers)
			var battle: BattleManager = BattleManager.new(mission)
			expect(mission.validation_errors().is_empty() and battle.grid.size == Vector2i(8, 8), "valid same board")
			expect(battle.protected_unit().cell == (Vector2i(1, 3) if warned else Vector2i(4, 3)), "decision changes initial position")
			var scout: TacticalUnit = battle.unit_by_id("scout")
			expect(scout != null and scout.movement == 5 and scout.hp == 22 and scout.behavior == "flanker", "scout reusable definition")
			expect(not EnemyAI.plan(scout, battle.units, battle.grid).is_empty(), "scout uses common pathfinding")
	var worker: AmbientActor = world.actor_nodes.worker_a
	worker.routine = {"type": "patrol", "pause": 1.0, "points": [[200, 200]]}
	worker.wait_remaining = 0
	world.player.locked = false
	var worker_start: Vector2 = worker.position
	var requests: int = world.routines.path_requests
	await frames(130)
	expect(worker.route.is_empty() and worker.position.distance_to(worker_start) < 0.1, "unreachable destination rejected")
	expect(world.routines.path_requests - requests < 40, "unreachable destination has bounded retries")
	main.start_exploration("res://data/narrative/settlement.json", false)
	session = main.screen.get_child(0)
	session.confirm_continue()
	session.begin_sequence()
	var surprised: bool = false
	var limit: int = 0
	while main.story_flow.phase != "battle" and limit < 650:
		await process_frame
		limit += 1
		if is_instance_valid(session) and is_instance_valid(session.dialog) and not session.dialog.is_queued_for_deletion() and session.conversation == "attack_sequence":
			if session.dialogue_data.speaker == "Aldeano":
				surprised = session.dialogue_data.lines[0].contains("¿Qué")
			session.choose({})
	expect(main.story_flow.phase == "battle" and main.battle.unit_by_id("scout") != null, "unwarned cinematic loads three enemies")
	expect(surprised, "unwarned cinematic shows confusion")
	main.start_battle()
	expect(main.battle.protected_unit().cell == Vector2i(4, 3), "retry retains exposed civilian position")
	# Auto-completion uses the same action interpreter; shorten durations only in this test.
	main.show_menu()
	main.start_exploration()
	session = main.screen.get_child(0)
	expect(session.intro_active and session.card_generation == 1, "new game replays intro")
	for action: Dictionary in session.content.intro:
		action.seconds = 0.03
	session.finish_card(session.card_generation)
	await create_timer(1).timeout
	expect(not session.intro_active and session.card_generation == 4, "natural completion releases controls")
	main.show_menu()
	main.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("ITERATION 4: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

