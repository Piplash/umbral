extends SceneTree

var checks: int = 0
var failures: int = 0

func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main: Control = scene.instantiate()
	root.add_child(main)
	main.start_battle()
	await create_timer(1.1).timeout
	expect(main.board.get_node_or_null("Ground") != null, "ground layer")
	expect(main.board.get_node_or_null("Lower") != null, "lower decoration layer")
	expect(main.board.get_node_or_null("Obstacles") != null, "obstacle layer")
	expect(main.board.get_node_or_null("Units") != null, "unit layer")
	expect(main.board.get_node_or_null("UpperDecoration") != null, "upper decoration layer")
	expect(main.board.get_node_or_null("Effects") != null, "effect layer")
	expect(main.log_label == null, "no visible debug log")
	for id: String in ArtLibrary.IDS:
		expect(ArtLibrary.character(id) != null and ArtLibrary.character(id, true) != null, "sprite and portrait " + id)
	var environment: Image = ArtLibrary.environment.get_image()
	expect(environment.get_pixel(0, environment.get_height() / 2).a == 0, "real alpha outside props")
	expect(environment.get_pixel(20, 20).a > 0.99, "opaque ground tile")
	expect(main.board.cell_at(main.board.origin + Vector2(1, 1)) == Vector2i.ZERO, "first cell coordinates")
	expect(not main.battle.grid.inside(main.board.cell_at(main.board.origin - Vector2(1, 0))), "left boundary not rounded into board")
	expect(main.board.cell_at(main.board.origin + Vector2(367, 367)) == Vector2i(7, 7), "last cell coordinates")
	main.inspect_unit(main.battle.units[1])
	main.skill_menu = true
	main.refresh()
	await process_frame
	expect(main.action_box.get_child_count() == 3, "two skills plus back")
	expect(main.action_description.get_parent().position.y + main.action_description.get_parent().size.y <= 503, "description clear of footer")
	main.inspect_unit(main.battle.units[0])
	main.on_cell(Vector2i(2, 4))
	await process_frame
	await process_frame
	expect(main.board.busy, "movement animation active")
	main.choose("attack")
	expect(main.battle.mode == "move", "no commands during displacement")
	await create_timer(0.3).timeout
	main.choose("attack")
	expect(main.battle.mode == "attack", "commands resume after animation")
	main.show_help()
	expect(main.paused, "help pauses gameplay")
	main.toggle_pause()
	main.end_turn()
	main.end_turn()
	expect(main.enemy_running and main.battle.turns.phase == "enemy", "single enemy sequence")
	main.toggle_pause()
	var old_position: Vector2i = main.battle.units[2].cell
	await create_timer(0.8).timeout
	expect(main.battle.units[2].cell == old_position and main.battle.turns.number == 1, "pause holds enemy activation")
	main.toggle_pause()
	await create_timer(1.5).timeout
	expect(main.battle.turns.phase == "ally" and main.battle.turns.number == 2, "enemy sequence resumes once")
	main.end_turn()
	main.start_battle()
	await create_timer(0.8).timeout
	expect(main.battle.turns.number == 1 and main.battle.units[2].cell == Vector2i(6, 2), "restart cancels old enemy coroutine")
	main.show_menu()
	main.queue_free()
	await process_frame
	# Allow the audio mixer to release stopped playback objects before engine shutdown.
	await create_timer(0.1).timeout
	print("PRESENTATION: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

