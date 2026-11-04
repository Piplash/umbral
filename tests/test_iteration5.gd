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

func run() -> void:
	var slow: DirectionalVisual = DirectionalVisual.new()
	var fast: DirectionalVisual = DirectionalVisual.new()
	slow.advance(Vector2.RIGHT * 32, false, false, 0.5)
	fast.advance(Vector2.RIGHT * 100, false, false, 0.5)
	expect(fast.phase > slow.phase, "step frequency follows actual speed")
	slow.free()
	fast.free()
	var content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/narrative/settlement.json"))
	var reference: String = "res://assets/references/486a0401-c42c-47e2-8b21-55ad25ebc5e0.png"
	expect(FileAccess.file_exists(reference), "approved reference retained")
	expect(content.bounds[0] <= 1080 and content.bounds[1] <= 780, "no world expansion")
	expect(content.reserve_actors.size() == 4, "population reduction preserves dormant content")
	for actor: Dictionary in content.reserve_actors:
		if actor.has("dialogue"):
			expect(content.dialogues.has(actor.dialogue), "reserved dialogue preserved")
	expect(content.ground_polygons.size() > 0, "configured nonrectangular paths")
	for prop: Dictionary in content.visual_props:
		expect(prop.sheet != reference and not prop.sheet.contains("cinematics"), "playable props never reference a composition")
		var texture: Texture2D = ExplorationProp.texture_for(prop)
		var sheet: Texture2D = load(prop.sheet)
		var r: Array = prop.region
		expect(r[0] >= 0 and r[1] >= 0 and r[0] + r[2] <= sheet.get_width() and r[1] + r[3] <= sheet.get_height(), "atlas region within source")
		expect(texture != null and prop.rect[2] > 0 and prop.rect[3] > 0, "individual prop geometry")
	for index: int in range(3):
		var action: Dictionary = content.intro[index]
		expect(action.image.contains("cinematics") and action.image != reference and ResourceLoader.exists(action.image), "dedicated original cinematic illustration")
		expect(action.zoom_to > action.zoom_from and action.pan.size() == 2, "configured camera motion")
	expect(content.intro[3].title and content.intro[3].text.contains("ANTES DEL SILENCIO"), "prologue title preserved")
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.start_exploration("res://data/narrative/settlement.json", false)
	var session: StorySession = main.screen.get_child(0)
	await process_frame
	var world: ExplorationController = session.exploration
	var props: int = 0
	var atmosphere: ExplorationAtmosphere
	for node: Node in world.get_children():
		if node is ExplorationProp:
			props += 1
		if node is ExplorationAtmosphere:
			atmosphere = node
	expect(props == content.props.size() + content.visual_props.size(), "individual sortable Godot props")
	expect(world.y_sort_enabled, "characters and buildings share depth sorting")
	expect(atmosphere != null and atmosphere.lights.size() == content.atmosphere.lights.size(), "local Godot lights instantiated")
	var cold: bool = false
	var warm: bool = false
	for light: PointLight2D in atmosphere.lights:
		warm = warm or light.color.r > light.color.b
		cold = cold or light.color.b > light.color.r
	expect(warm and cold, "warm homes and cold energy terminal")
	expect(is_equal_approx(world.camera.zoom.x, float(content.camera_zoom)), "configured framing")
	session.exploration_help()
	await process_frame
	expect(world.player.locked and is_instance_valid(session.dialog), "help locks movement and routines")
	var help_box: VBoxContainer = session.dialog.get_child(1).get_child(0)
	var back: Button = help_box.get_child(help_box.get_child_count() - 1)
	back.pressed.emit()
	await process_frame
	expect(not world.player.locked, "closing help releases controls")
	# A real approach to the redesigned console must preserve the existing decision.
	world.player.position = Vector2(780, 700)
	world.interact("terminal")
	var limit: int = 0
	while not world.player.locked and limit < 180:
		await physics_frame
		limit += 1
	expect(session.conversation == "terminal" and world.player.locked, "redesigned terminal remains reachable and interactive")
	session.choose(content.dialogues.terminal.choices[0])
	expect(main.story_flow.world.data.prepared.terminal, "terminal decision preserved")
	main.show_menu()
	main.start_exploration()
	session = main.screen.get_child(0)
	var image: TextureRect = session.card.get_node("Illustration")
	var scale_before: float = image.scale.x
	await create_timer(0.3).timeout
	expect(image.scale.x > scale_before and session.exploration.player.locked, "cinematic zoom runs while controls locked")
	session.skip_intro()
	await create_timer(0.8).timeout
	expect(not session.intro_active and not session.exploration.player.locked, "illustrated intro skips safely")
	main.show_menu()
	main.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("ITERATION 5: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
