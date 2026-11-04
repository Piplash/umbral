extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func capture(name: String) -> void:
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/" + name + ".png")

func run() -> void:
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.start_exploration()
	await capture("story_exploration")
	var session: StorySession = main.screen.get_child(0)
	session.open_dialogue("villager")
	await capture("story_choice")
	main.show_menu()
	main.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit()
