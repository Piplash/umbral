extends SceneTree

var checks: int = 0
var failures: int = 0

func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/narrative/settlement.json"))
	var omitted: BattleManager = BattleManager.new(BattlePreparationResolver.prepare(MissionCatalog.default_mission(), WorldState.new(), content.modifiers))
	expect(omitted.protected_unit().behavior == "wander" and Vector2i(5, 3) not in omitted.grid.obstacles, "omitted conversations use unprepared default")
	for warned: bool in [false, true]:
		for terminal: bool in [false, true]:
			var state: WorldState = WorldState.new()
			EffectResolver.apply([{"bucket": "flags", "key": "villager_warned", "value": warned}, {"bucket": "prepared", "key": "terminal", "value": terminal}], state)
			var prepared: BattleMissionData = BattlePreparationResolver.prepare(MissionCatalog.default_mission(), state, content.modifiers)
			expect(prepared.validation_errors().is_empty(), "prepared mission invalid")
			var b: BattleManager = BattleManager.new(prepared)
			expect(b.protected_unit().movement == 2, "neutral movement")
			expect(b.protected_unit().behavior == ("seek_shelter" if warned else "wander"), "decision behavior")
			expect((Vector2i(5, 3) in b.grid.obstacles) == terminal, "barrier modifier")
			expect(MissionCatalog.default_mission().participants[4].definition.movement == 0 and Vector2i(5, 3) not in MissionCatalog.default_mission().map.blocked_cells, "base mutated")
			var civil: TacticalUnit = b.protected_unit()
			var route: Array = NeutralAI.plan(civil, b.grid, b.units, [Vector2i(0, 3)], 1)
			expect(not route.is_empty() and route.size() <= 3, "neutral valid budget")
			expect(not EnemyAI.plan(b.unit_by_id("captor"), b.units, b.grid).is_empty(), "barrier preserves captor path")
	var blocked: Array[Rect2] = [Rect2(40, 0, 30, 90)]
	var nav: PackedVector2Array = InteractionNavigation.route(Vector2(20, 30), Vector2(100, 30), blocked, Rect2(0, 0, 150, 150))
	expect(nav.size() > 2, "continuous navigation detours around obstacles")
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.start_exploration()
	await process_frame
	var session: StorySession = main.screen.get_child(0)
	expect(session.exploration.player is CharacterBody2D, "exploration actor")
	session.open_dialogue("lira")
	var next_button: Button = session.dialog.get_child(1).get_child(0).get_child(2)
	next_button.pressed.emit()
	next_button.pressed.emit()
	expect(session.line == 1, "duplicate continuation cannot skip dialogue pages")
	session.choose(content.dialogues.lira.choices[0])
	session.open_dialogue("neighbor")
	var neighbor_next: Button = session.dialog.get_child(1).get_child(0).get_child(2)
	neighbor_next.pressed.emit()
	session.choose(content.dialogues.neighbor.choices[0])
	expect(main.story_flow.world.data.conversations.has("lira") and main.story_flow.world.data.conversations.has("neighbor"), "support and worldbuilding conversations complete")
	session.open_dialogue("villager")
	session.choose(content.dialogues.villager.choices[1])
	expect(main.story_flow.world.data.flags.villager_warned, "choice stored")
	session.open_dialogue("terminal")
	session.choose(content.dialogues.terminal.choices[0])
	session.confirm_continue()
	session.begin_sequence()
	var frames: int = 0
	while main.story_flow.phase != "battle" and frames < 600:
		await process_frame
		frames += 1
		if is_instance_valid(session) and is_instance_valid(session.dialog) and not session.dialog.is_queued_for_deletion() and session.conversation == "attack_sequence":
			session.choose({})
	expect(main.battle != null and main.story_flow.phase == "battle", "exploration cinematic battle transition")
	if main.battle != null:
		expect(main.battle.grid.size == Vector2i(8, 8) and main.battle.protected_unit().behavior == "seek_shelter", "prepared battle loaded")
		for unit: TacticalUnit in main.battle.units:
			if unit.team == "enemy":
				unit.hp = 0
		main.battle.check_end()
		expect(main.story_flow.world.data.results.has("settlement"), "narrative result registered")
		main.start_battle()
		expect(main.story_flow.world.data.results.is_empty() and main.story_flow.world.data.flags.villager_warned, "retry restores prebattle state and choices")
	main.show_menu()
	main.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("STORY: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
