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

func finish_dialogue(session: StorySession) -> void:
	if is_instance_valid(session.dialog) and not session.dialog.is_queued_for_deletion() and session.conversation == "attack_sequence":
		session.choose({})

func run() -> void:
	var content: Dictionary = NarrativeContent.read("res://data/narrative/settlement.json")
	var fall: Dictionary = NarrativeContent.read("res://data/narrative/fall.json")
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for cue: String in ["wind", "embers", "alarm", "blast"]:
		expect(main.audio.stream(cue).get_length() > 0, "new synthesized audio: " + cue)
	for variant: Array in [[true, true, false], [true, false, true], [false, true, true], [false, false, false]]:
		var survived: bool = variant[0]
		var warned: bool = variant[1]
		var terminal: bool = variant[2]
		main.start_exploration("res://data/narrative/settlement.json", false)
		var flow: MissionFlowController = main.story_flow
		flow.world.data.flags.villager_warned = warned
		flow.world.data.prepared.terminal = terminal
		expect(not flow.can_continue(), "no continuation before victory")
		expect(flow.consolidate(MissionCatalog.default_mission(), content), "prepare normal narrative battle")
		main.start_battle(flow.prepared)
		var battle: BattleManager = main.battle
		flow.record_result(battle)
		expect(flow.world.data.results.is_empty(), "ongoing battle cannot record a result")
		# Outcome fixture: exercise the real objective evaluator and finished/result UI signal.
		if not survived:
			battle.protected_unit().hp = 0
		if survived and not warned:
			battle.unit_by_id("support").hp = 0
		for unit: TacticalUnit in battle.units:
			if unit.team == "enemy":
				unit.hp = 0
		battle.check_end()
		expect(battle.ended and battle.outcome.status == "victory" and flow.phase == "results", "real victory evaluator records result")
		expect(flow.world.data.results.settlement.villager_survived == survived, "survival comes from outcome, not warning")
		expect(flow.can_continue(), "victory result enables continuation")
		main.continue_story_after_battle()
		var session: StorySession = main.screen.get_child(0)
		session.playback_speed = 250
		expect(main.battle == null and flow.phase == "aftermath", "tactical state ends before cinematic")
		expect(session.exploration.actors.has("villager") == survived, "civilian absent at relief when dead")
		var lines: Array[String] = []
		var moves: Array[String] = []
		session.action_started.connect(func(action: Dictionary) -> void:
			if action.type == "dialogue":
				lines.append(action.text)
			if action.type == "move":
				moves.append(action.id))
		var limit: int = 0
		while flow.phase != "exploration" and limit < 1500:
			await process_frame
			limit += 1
			finish_dialogue(session)
		expect(flow.phase == "exploration", "aftermath returns playable control")
		expect(flow.world.data.flags.get("settlement_destroyed", false) and flow.world.data.flags.get("lira_captured", false) and flow.world.data.flags.get("chapter_1_started", false), "destruction, capture and chapter recorded")
		expect("player" in moves and "lira" in moves and "carrier" in moves, "capture visually stages rescue, separation and departure")
		expect(session.card_generation == 2, "capture illustration and chapter title shown, no prologue replay")
		expect(flow.world.data.flags.escape_group_saved == terminal, "terminal changes visible escape consequence")
		expect(not session.exploration.actors.has("lira") and session.exploration.actor_nodes.size() == (1 if survived else 0), "ruins have no captured or everyday NPCs")
		expect(session.exploration.actors.has("villager") == survived, "conditional witness only when survived")
		expect(("Me dijiste que buscara refugio. Si no te hubiera escuchado, no estaría aquí para contártelo." in lines) == (survived and warned), "warning recognition is conditional on both facts")
		expect(("Me alcancé a esconder cuando empezó el ataque. Otros no tuvieron esa suerte." in lines) == (survived and not warned), "unwarned survivor has valid dialogue")
		expect(flow.world.data.flags.convoy_route_known == survived and flow.world.data.flags.industrial_bridge_known == survived, "information differs at awakening")
		if survived:
			expect(flow.world.data.flags.convoy_route_source == "witness" and flow.world.data.prepared.basic_supplies, "witness grants route and idempotent supplies")
		else:
			session.confirm_continue()
			expect(flow.phase == "exploration" and not flow.world.data.flags.convoy_route_known, "unknown route gates departure")
			session.dialog.queue_free()
			session.exploration.player.locked = false
			var before_clues: Dictionary = flow.world.snapshot()
			for order: Array in [["convoy_tracks", "authority_equipment", "transport_record"], ["convoy_tracks", "transport_record", "authority_equipment"], ["authority_equipment", "convoy_tracks", "transport_record"], ["authority_equipment", "transport_record", "convoy_tracks"], ["transport_record", "convoy_tracks", "authority_equipment"], ["transport_record", "authority_equipment", "convoy_tracks"]]:
				flow.world.restore(before_clues)
				for index: int in range(3):
					session.open_dialogue(order[index])
					session.choose({})
					expect(flow.world.data.flags.convoy_route_known == (index >= 1), "any two distinct clues reveal route")
					if index == 0:
						session.open_dialogue(order[index])
						session.choose({})
						expect(not flow.world.data.flags.convoy_route_known, "repeated clue does not count twice")
					expect(not flow.world.data.flags.industrial_bridge_known, "investigation preserves less detailed information")
				expect(flow.world.data.flags.convoy_route_source == "investigation", "investigation source persists")
		# All clues have reachable approaches in the changed obstacle layout.
		var world: ExplorationController = session.exploration
		for id: String in ["convoy_tracks", "authority_equipment", "transport_record"]:
			var point: Vector2 = world.actor_position(id)
			var reached: bool = false
			for offset: Vector2 in [Vector2(0, 42), Vector2(42, 0), Vector2(-42, 0), Vector2(0, -42)]:
				if not InteractionNavigation.route(world.player.position, point + offset, world.navigation_blockers(), world.world_bounds()).is_empty():
					reached = true
					break
			expect(reached, "ruins clue remains reachable: " + id)
		world.player.position = Vector2(780, 700)
		world.interact("transport_record")
		var approach: int = 0
		while not world.player.locked and approach < 180:
			await physics_frame
			approach += 1
		expect(world.player.locked and session.conversation == "transport_record", "real click approach opens ruins clue")
		session.choose({})
		world.player.position = Vector2(620, 480)
		Input.action_press("explore_up")
		for frame: int in range(36):
			await physics_frame
		Input.action_release("explore_up")
		expect(world.player.position.y >= 458, "new solid rubble stops physical movement")
		var completed: Dictionary = flow.world.snapshot()
		flow.record_result(battle)
		main.continue_story_after_battle()
		expect(flow.world.snapshot() == completed and main.screen.get_child(0) == session, "duplicate result/continuation cannot wipe progress or replay capture")
		# Restoring the state into a new presentation resumes ruins without Lira or title.
		main.clear_screen()
		flow.world.restore(completed)
		session = StorySession.new()
		session.host = main
		session.flow = flow
		session.play_intro = false
		session.content = fall
		main.screen.add_child(session)
		expect(session.environment_id == "ruins" and not session.exploration.actors.has("lira") and session.card_generation == 0, "restored state resumes ruins without replay")
		expect(session.exploration.actors.has("villager") == survived, "restored witness respects survival")
		session.confirm_continue()
		session.begin_sequence()
		expect(flow.phase == "chapter_boundary" and flow.world.data.flags.north_departure_ready and main.battle == null, "known route ends at boundary without another map or combat")
		await process_frame
	# Defeat and retry still use the existing flow and never destroy the settlement.
	main.start_exploration("res://data/narrative/settlement.json", false)
	var flow: MissionFlowController = main.story_flow
	flow.consolidate(MissionCatalog.default_mission(), content)
	main.start_battle(flow.prepared)
	main.battle.capture.progress = main.battle.capture.limit
	main.battle.check_end()
	expect(main.battle.outcome.status == "defeat" and not flow.can_continue(), "defeat never enables continuation")
	main.continue_story_after_battle()
	expect(main.battle != null and not flow.world.data.flags.get("settlement_destroyed", false), "defeat cannot trigger destruction")
	main.start_battle()
	expect(not main.battle.ended and flow.phase == "battle" and flow.world.data.results.is_empty(), "retry resets battle result as before")
	main.show_menu()
	main.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("ITERATION 6: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
