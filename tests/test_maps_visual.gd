extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func snapshot(name: String) -> void:
	await create_timer(0.35).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/" + name + ".png")

func run() -> void:
	root.title = "UMBRAL · Validación de mapas"
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots")
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await snapshot("maps_menu")
	for mission: BattleMissionData in MissionCatalog.missions():
		main.start_battle(mission)
		await snapshot("maps_" + mission.mission_id)
		main.inspect_unit(main.battle.unit_by_id("soldier"))
		main.toggle_danger()
		await snapshot("maps_" + mission.mission_id + "_threat")
		main.start_battle()
		for unit: TacticalUnit in main.battle.units:
			if unit.team == "enemy":
				unit.hp = 0
		main.battle.check_end()
		await snapshot("maps_" + mission.mission_id + "_results")
	main.show_menu()
	await snapshot("maps_menu_test_selected")
	main.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("MAP VISUAL: 8 rendered screenshots, both missions and shared menu/HUD")
	quit()
