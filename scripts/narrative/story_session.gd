class_name StorySession
extends CanvasLayer

var host: Control
var flow: MissionFlowController
var content: Dictionary
var exploration: ExplorationController
var dialog: Control
var ui: Control
var line: int = 0
var conversation: String = ""
signal dialogue_finished
var dialogue_data: Dictionary

func _ready() -> void:
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = host.theme
	add_child(ui)
	exploration = load("res://scenes/exploration.tscn").instantiate() as ExplorationController
	host.screen.add_child(exploration)
	exploration.setup(content)
	exploration.world = flow.world
	exploration.dialogue_requested.connect(open_dialogue)
	var header: Label = Label.new()
	header.text = content.get("title", "UMBRAL") + "\nWASD / flechas · Shift correr · Clic para conversar o examinar"
	header.position = Vector2(20, 16)
	header.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(header)
	var advance: Button = Button.new()
	advance.text = "Continuar historia"
	advance.position = Vector2(760, 20)
	advance.pressed.connect(confirm_continue)
	ui.add_child(advance)

func panel(title: String) -> VBoxContainer:
	if is_instance_valid(dialog):
		dialog.queue_free()
	dialog = Control.new()
	dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(dialog)
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0, 0, 0, 0.45)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialog.add_child(shade)
	var frame: OrnamentPanel = OrnamentPanel.new()
	frame.position = Vector2(120, 280)
	frame.size = Vector2(720, 230)
	dialog.add_child(frame)
	var box: VBoxContainer = VBoxContainer.new()
	frame.add_child(box)
	host.text(box, title, 20)
	return box

func open_dialogue(id: String) -> void:
	conversation = id
	dialogue_data = content.dialogues[id]
	line = 0
	exploration.player.locked = true
	exploration.player.route.clear()
	show_line()

func show_line() -> void:
	var box: VBoxContainer = panel(dialogue_data.speaker)
	if dialogue_data.has("art"):
		var portrait: TextureRect = TextureRect.new()
		portrait.texture = ArtLibrary.character(dialogue_data.art, true)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.position = Vector2(45, 285)
		portrait.size = Vector2(65, 80)
		dialog.add_child(portrait)
	var label: Label = host.text(box, dialogue_data.lines[line], 16)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var source_page: Control = dialog
	if line + 1 < dialogue_data.lines.size():
		host.button(box, "Continuar", func() -> void:
			if is_instance_valid(source_page) and not source_page.is_queued_for_deletion() and source_page == dialog:
				line += 1
				show_line())
	else:
		for choice: Dictionary in dialogue_data.get("choices", [{"text": "Continuar"}]):
			if ConditionEvaluator.matches(choice.get("conditions", []), flow.world):
				var button: Button = host.button(box, choice.text, func() -> void: choose(choice, source_page))
				button.text = ""
				button.custom_minimum_size.y = 46
				var caption: Label = Label.new()
				caption.text = choice.text
				caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				caption.offset_left = 10
				caption.offset_right = -10
				caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
				button.add_child(caption)

func choose(choice: Dictionary, source_page: Control = null) -> void:
	if source_page != null and source_page != dialog:
		return
	if not is_instance_valid(dialog) or dialog.is_queued_for_deletion():
		return
	EffectResolver.apply(choice.get("effects", []), flow.world)
	if dialogue_data.has("examined_id"):
		flow.world.data.examined[dialogue_data.examined_id] = true
	flow.world.data.conversations[conversation] = true
	dialog.queue_free()
	exploration.player.locked = flow.phase != "exploration"
	dialogue_finished.emit()

func confirm_continue() -> void:
	if exploration.player.locked or flow.phase != "exploration":
		return
	exploration.player.locked = true
	exploration.player.route.clear()
	var box: VBoxContainer = panel("¿Quieres continuar?")
	host.text(box, "Algunas conversaciones y oportunidades podrían dejar de estar disponibles.", 14)
	host.button(box, "Volver", func() -> void: dialog.queue_free(); exploration.player.locked = false)
	host.button(box, "Continuar", begin_sequence)

func begin_sequence() -> void:
	if not flow.consolidate(load(content.get("battle_mission", MissionCatalog.DEFAULT_MISSION)), content):
		return
	dialog.queue_free()
	for action: Dictionary in content.sequence:
		match action.type:
			"camera":
				var tween: Tween = create_tween()
				tween.tween_property(exploration.camera, "position", Vector2(action.position[0], action.position[1]), 0.7)
				await tween.finished
			"sound": host.audio.play(action.cue)
			"effects": EffectResolver.apply(action.get("effects", []), flow.world)
			"show", "hide":
				if action.has("actor"):
					exploration.actors[action.id] = action.actor.duplicate(true)
				exploration.actors[action.id].visible = action.type == "show"
			"move":
				var tween: Tween = create_tween()
				var start: Vector2 = Vector2(exploration.actors[action.id].position[0], exploration.actors[action.id].position[1])
				tween.tween_method(func(value: Vector2) -> void: exploration.actors[action.id].position = [value.x, value.y], start, Vector2(action.position[0], action.position[1]), 0.8)
				await tween.finished
			"dialogue":
				conversation = "attack_sequence"
				dialogue_data = {"speaker": action.speaker, "lines": [action.text]}
				line = 0
				show_line()
				await dialogue_finished
			"wait": await host.get_tree().create_timer(float(action.get("seconds", 0.5))).timeout
			"wait_event":
				while not flow.world.data.events.get(action.event, false):
					await host.get_tree().process_frame
			"scene":
				host.get_tree().change_scene_to_file(action.path)
				return
			"fade":
				var shade: ColorRect = ColorRect.new()
				shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				shade.color = Color(0, 0, 0, 0)
				ui.add_child(shade)
				var tween: Tween = create_tween()
				tween.tween_property(shade, "color:a", 1.0, 0.6)
				await tween.finished
			"battle":
				flow.before_battle = flow.world.snapshot()
				flow.phase = "battle"
				host.start_battle(flow.prepared)
				return
			_:
				push_error("Acción de secuencia desconocida: " + str(action.type))
				return
