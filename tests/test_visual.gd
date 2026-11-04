extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func snapshot(file: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/" + file + ".png")

func run() -> void:
	root.title = "UMBRAL · Validación visual"
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots")
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main: Control = scene.instantiate()
	root.add_child(main)
	await create_timer(0.3).timeout
	await snapshot("menu")
	main.start_battle()
	await create_timer(1.2).timeout
	await snapshot("battle")
	main.inspect_unit(main.battle.units[1])
	main.skill_menu = true
	main.refresh()
	await create_timer(0.3).timeout
	await snapshot("lira_abilities")
	main.show_help()
	await snapshot("help")
	main.toggle_pause()
	main.start_battle()
	main.inspect_unit(main.battle.units[2])
	main.toggle_danger()
	await snapshot("enemy_threat")
	main.start_battle()
	main.on_cell(Vector2i(2, 4))
	if main.board.busy:
		await main.board.settled
	await snapshot("undo_available")
	main.start_battle()
	main.on_cell(Vector2i(4, 4))
	if main.board.busy:
		await main.board.settled
	main.end_turn()
	while main.enemy_running:
		await process_frame
	main.inspect_unit(main.battle.units[0])
	main.choose("heavy")
	main.board.set_cursor(main.battle.units[2].cell)
	main.on_cell(main.battle.units[2].cell)
	await snapshot("damage_forecast")
	main.toggle_pause()
	main.show_audio_settings()
	await snapshot("audio_settings")
	main.start_battle()
	main.battle.units[2].hp = 0
	main.battle.units[3].hp = 0
	main.battle.check_end()
	await create_timer(0.3).timeout
	await snapshot("victory")
	main.start_battle()
	main.battle.capture.progress = 3
	main.battle.check_end()
	await snapshot("defeat")
	# Also verify the composition at the exact internal resolution.
	main.start_battle()
	root.size = Vector2i(960, 540)
	await create_timer(1.2).timeout
	await snapshot("battle_960")
	main.show_menu()
	await snapshot("menu_960")
	main.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("VISUAL: 12 screenshots captured; menus, battle, threat, undo, forecast, audio, results, 960x540 layout")
	quit()
