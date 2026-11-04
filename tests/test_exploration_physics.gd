extends SceneTree

var checks: int = 0
var failures: int = 0

func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func key(code: int, pressed: bool) -> void:
	var actions: Dictionary = {KEY_D: "explore_right", KEY_S: "explore_down", KEY_A: "explore_left", KEY_SHIFT: "explore_run"}
	if pressed:
		Input.action_press(actions[code])
	else:
		Input.action_release(actions[code])

func frames(count: int) -> void:
	for index: int in range(count):
		await physics_frame

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.start_exploration("res://data/narrative/settlement.json", false)
	await frames(2)
	var session: StorySession = main.screen.get_child(0)
	var world: ExplorationController = session.exploration
	var player: ExplorationPlayer = world.player
	key(KEY_D, true)
	await frames(3)
	expect(is_equal_approx(player.velocity.length(), 100), "walk speed")
	key(KEY_S, true)
	await frames(3)
	expect(is_equal_approx(player.velocity.length(), 100) and player.velocity.x > 0 and player.velocity.y > 0, "diagonal normalized")
	key(KEY_SHIFT, true)
	await frames(3)
	expect(is_equal_approx(player.velocity.length(), 160), "shift runs")
	key(KEY_D, false)
	key(KEY_S, false)
	key(KEY_SHIFT, false)
	player.position = Vector2(390, 230)
	key(KEY_A, true)
	await frames(45)
	key(KEY_A, false)
	expect(player.position.x >= 368, "house collision prevents crossing wall")
	player.position = Vector2(500, 480)
	world.interact("villager")
	expect(not player.route.is_empty(), "click request creates automatic route")
	key(KEY_D, true)
	await frames(3)
	key(KEY_D, false)
	expect(player.route.is_empty() and world.pending.is_empty(), "manual movement cancels route and pending interaction")
	world.interact("villager")
	var timeout: int = 0
	while not player.locked and timeout < 240:
		await physics_frame
		timeout += 1
	expect(player.locked and session.conversation == "villager", "automatic approach opens dialogue")
	expect(player.position.distance_to(Vector2(520, 610)) > 24, "approach stops outside NPC collider")
	var position: Vector2 = player.position
	key(KEY_D, true)
	await frames(10)
	key(KEY_D, false)
	expect(player.position.distance_to(position) < 0.1, "dialogue locks movement")
	session.choose(session.content.dialogues.villager.choices[1])
	session.choose(session.content.dialogues.villager.choices[0])
	expect(main.story_flow.world.data.flags.villager_warned, "duplicate choice ignored")
	await frames(2)
	session.confirm_continue()
	expect(player.locked and main.story_flow.phase == "exploration", "confirmation does not start battle")
	# Simulate the Back button's documented cancellation without advancing the flow.
	session.dialog.queue_free()
	player.locked = false
	expect(main.story_flow.phase == "exploration", "cancel preserves exploration")
	expect(world.camera.limit_right == world.content.bounds[0] and world.camera.limit_bottom == world.content.bounds[1], "configured camera bounds")
	main.show_menu()
	main.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("EXPLORATION PHYSICS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
