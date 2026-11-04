extends SceneTree

var pending: String = ""
var captured: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/iteration6_" + name + ".png")

func victory(main: Control, survived: bool) -> void:
	main.start_exploration("res://data/narrative/settlement.json", false)
	var content: Dictionary = NarrativeContent.read("res://data/narrative/settlement.json")
	main.story_flow.world.data.flags.villager_warned = true
	main.story_flow.world.data.prepared.terminal = survived
	main.story_flow.consolidate(MissionCatalog.default_mission(), content)
	main.start_battle(main.story_flow.prepared)
	if not survived:
		main.battle.protected_unit().hp = 0
	for unit: TacticalUnit in main.battle.units:
		if unit.team == "enemy":
			unit.hp = 0
	main.battle.check_end()
	main.continue_story_after_battle()

func run() -> void:
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	victory(main, true)
	var session: StorySession = main.screen.get_child(0)
	session.playback_speed = 20
	session.action_started.connect(func(action: Dictionary) -> void:
		if action.has("beat"):
			pending = action.beat)
	var limit: int = 0
	while main.story_flow.phase != "exploration" and limit < 3000:
		await process_frame
		limit += 1
		if not pending.is_empty():
			var tag: String = pending
			pending = ""
			await create_timer(0.11 if tag != "capture" else 0.22).timeout
			if tag == "capture":
				session.card_tween.pause()
				await create_timer(4).timeout
			await capture(tag)
			if tag == "capture":
				session.finish_card(session.card_generation)
			captured[tag] = true
		if is_instance_valid(session.dialog) and not session.dialog.is_queued_for_deletion() and session.conversation == "attack_sequence":
			session.choose({})
	await create_timer(0.3).timeout
	await capture("ruins_witness")
	victory(main, false)
	session = main.screen.get_child(0)
	session.playback_speed = 250
	limit = 0
	while main.story_flow.phase != "exploration" and limit < 2000:
		await process_frame
		limit += 1
		if is_instance_valid(session.dialog) and not session.dialog.is_queued_for_deletion() and session.conversation == "attack_sequence":
			session.choose({})
	await create_timer(0.2).timeout
	await capture("ruins_alone")
	session.open_dialogue("transport_record")
	await process_frame
	await capture("clue")
	session.choose({})
	session.open_dialogue("convoy_tracks")
	session.choose({})
	await process_frame
	session.confirm_continue()
	session.begin_sequence()
	await process_frame
	await capture("north_boundary")
	expect_captures()
	main.show_menu()
	main.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit(0 if captured.size() == 5 else 1)

func expect_captures() -> void:
	print("ITERATION 6 VISUAL: %d cinematic beats plus 4 playable captures" % captured.size())
