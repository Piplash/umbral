extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/iteration5_" + name + ".png")

func run() -> void:
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.start_exploration()
	var session: StorySession = main.screen.get_child(0)
	for shot: String in ["city", "refuge", "twins", "title"]:
		await create_timer(4.3 if shot != "title" else 1.4).timeout
		await capture(shot)
		if shot != "title":
			session.finish_card(session.card_generation)
	session.skip_intro()
	await create_timer(3.5).timeout
	await capture("settlement")
	session.exploration_help()
	await create_timer(0.2).timeout
	await capture("help")
	session.dialog.queue_free()
	session.exploration.player.locked = false
	session.exploration.player.position = Vector2(780, 700)
	session.exploration.interact("terminal")
	await create_timer(1.5).timeout
	await capture("terminal")
	main.show_menu()
	main.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit()
