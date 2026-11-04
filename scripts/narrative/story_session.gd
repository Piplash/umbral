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
var play_intro: bool = true
var intro_active: bool = false
var intro_skipped: bool = false
var card: Control
var card_tween: Tween
var card_generation: int = 0
signal card_finished
var entry_sequence: String = ""
var playback_speed: float = 1.0
var current_action: Dictionary = {}
var sequence_running: bool = false
var environment_id: String = ""
var place: Label
var header: OrnamentPanel
var advance: Button
var help: Button
var fade_layer: ColorRect
var ambience: AudioStreamPlayer
signal action_started(action: Dictionary)
var dialogue_data: Dictionary

func _ready() -> void:
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = host.theme
	add_child(ui)
	var initial: String = content.get("initial_environment", "")
	if entry_sequence.is_empty():
		for candidate: Dictionary in content.get("resume_environments", []):
			if ConditionEvaluator.matches(candidate.get("conditions", []), flow.world):
				initial = candidate.id
	load_environment(initial)
	header = OrnamentPanel.new()
	header.position = Vector2(18, 16)
	header.size = Vector2(230, 38)
	ui.add_child(header)
	place = host.text(header, content.get("hud_title", content.get("title", "UMBRAL")), 12)
	place.add_theme_font_override("font", host.serif)
	place.modulate = Color("dbc38e")
	advance = host.button(ui, "Continuar historia  ›", confirm_continue)
	advance.position = Vector2(748, 16)
	advance.add_theme_font_size_override("font_size", 13)
	advance.custom_minimum_size = Vector2(155, 34)
	help = host.button(ui, "?", exploration_help)
	help.position = Vector2(912, 16)
	help.custom_minimum_size = Vector2(30, 34)
	help.tooltip_text = "Controles de exploración"
	if not entry_sequence.is_empty():
		set_hud_visible(false)
		exploration.player.locked = true
		sequence_running = true
		await play_actions(content.sequences[entry_sequence])
		sequence_running = false
		return
	if play_intro and not content.get("intro", []).is_empty():
		intro_active = true
		flow.phase = "intro"
		exploration.player.locked = true
		header.hide()
		advance.hide()
		help.hide()
		await play_actions(content.intro)
		var reveal: ColorRect = ColorRect.new()
		reveal.color = Color.BLACK
		reveal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ui.add_child(reveal)
		var reveal_tween: Tween = create_tween()
		reveal_tween.tween_property(reveal, "color:a", 0.0, 0.6)
		await reveal_tween.finished
		reveal.queue_free()
		intro_active = false
		flow.phase = "exploration"
		exploration.player.locked = false
		header.show()
		advance.show()
		help.show()

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
	if id.is_empty():
		exploration.player.locked = false
		exploration.release_interaction()
		return
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
	EffectResolver.apply(dialogue_data.get("effects", []), flow.world)
	EffectResolver.apply(choice.get("effects", []), flow.world)
	if dialogue_data.has("examined_id"):
		flow.world.data.examined[dialogue_data.examined_id] = true
	flow.world.data.conversations[conversation] = true
	evaluate_rules()
	dialog.queue_free()
	exploration.release_interaction()
	exploration.player.locked = flow.phase != "exploration"
	dialogue_finished.emit()

func confirm_continue() -> void:
	if exploration.player.locked or flow.phase != "exploration":
		return
	exploration.player.locked = true
	exploration.player.route.clear()
	var box: VBoxContainer = panel("¿Quieres continuar?")
	if not ConditionEvaluator.matches(content.get("continue_conditions", []), flow.world):
		host.text(box, content.get("continue_blocked", "Aún queda algo por descubrir."), 15)
		host.button(box, "Volver", func() -> void: dialog.queue_free(); exploration.player.locked = false)
		return
	host.text(box, content.get("continue_text", "Algunas conversaciones y oportunidades podrían dejar de estar disponibles."), 14)
	host.button(box, "Volver", func() -> void: dialog.queue_free(); exploration.player.locked = false)
	host.button(box, "Continuar", begin_sequence)

func begin_sequence() -> void:
	if sequence_running:
		return
	if content.has("continue_sequence"):
		if flow.phase != "exploration" or not ConditionEvaluator.matches(content.get("continue_conditions", []), flow.world):
			return
		flow.phase = "cinematic"
		sequence_running = true
		dialog.queue_free()
		await play_actions(content.continue_sequence)
		sequence_running = false
		return
	if not flow.consolidate(load(content.get("battle_mission", MissionCatalog.DEFAULT_MISSION)), content):
		return
	dialog.queue_free()
	await play_actions(content.sequence)

func play_actions(actions: Array) -> void:
	for action: Dictionary in actions:
		if intro_active and intro_skipped:
			break
		if not ConditionEvaluator.matches(action.get("conditions", []), flow.world):
			continue
		current_action = action
		action_started.emit(action)
		match action.type:
			"intro_card": await show_intro_card(action)
			"camera":
				var tween: Tween = create_tween()
				tween.tween_property(exploration.camera, "position", Vector2(action.position[0], action.position[1]), seconds(action, 0.7))
				await tween.finished
			"sound": host.audio.play(action.cue)
			"effects": EffectResolver.apply(action.get("effects", []), flow.world)
			"show", "hide":
				if action.has("actor"):
					var actor: Dictionary = action.actor.duplicate(true)
					actor.id = action.id
					exploration.add_actor(actor)
				if exploration.actors.has(action.id):
					exploration.actors[action.id].visible = action.type == "show"
					var node: ExplorationActor = exploration.actor_node(action.id)
					if node != null:
						node.visible = action.type == "show"
					if exploration.prop_actors.has(action.id):
						exploration.prop_actors[action.id].visible = action.type == "show"
			"move": await move_actor(action)
			"pose":
				var node: ExplorationActor = exploration.actor_node(action.id)
				if node != null:
					node.rotation_degrees = float(action.get("rotation", 0))
					if action.has("face"):
						node.visual.face(Vector2(action.face[0], action.face[1]))
			"environment": load_environment(action.id)
			"ambience": await set_ambience(action)
			"flash": await flash(action)
			"control":
				flow.phase = "exploration"
				exploration.player.locked = false
				exploration.camera.position = exploration.camera_focus()
				place.text = exploration.content.get("hud_title", content.get("hud_title", "UMBRAL"))
				advance.text = content.get("continue_label", "Continuar historia  ›")
				set_hud_visible(true)
			"chapter_end": show_boundary(action)
			"dialogue":
				conversation = "attack_sequence"
				dialogue_data = {"speaker": action.speaker, "lines": [action.text], "effects": action.get("effects", [])}
				line = 0
				show_line()
				await dialogue_finished
			"wait": await host.get_tree().create_timer(seconds(action, 0.5)).timeout
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
				fade_layer = shade
				ui.add_child(shade)
				var tween: Tween = create_tween()
				tween.tween_property(shade, "color:a", 1.0, seconds(action, 0.6))
				await tween.finished
			"reveal":
				if is_instance_valid(fade_layer):
					var tween: Tween = create_tween()
					tween.tween_property(fade_layer, "color:a", 0.0, seconds(action, 1))
					await tween.finished
					fade_layer.queue_free()
			"battle":
				flow.before_battle = flow.world.snapshot()
				flow.phase = "battle"
				host.start_battle(flow.prepared)
				return
			_:
				push_error("Acción de secuencia desconocida: " + str(action.type))
				return

func show_intro_card(action: Dictionary) -> void:
	card_generation += 1
	var generation: int = card_generation
	var duration: float = seconds(action, 8)
	var is_title: bool = bool(action.get("title", false))
	card = Control.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.clip_contents = true
	ui.add_child(card)
	var background: ColorRect = ColorRect.new()
	background.color = Color("070a10")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(background)
	if action.has("image"):
		var image: TextureRect = TextureRect.new()
		image.name = "Illustration"
		image.texture = load(action.image)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		image.size = Vector2(960, 540)
		image.pivot_offset = image.size * 0.5
		image.scale = Vector2.ONE * float(action.get("zoom_from", 1.02))
		card.add_child(image)
		var offset: Array = action.get("pan", [0, 0])
		var motion: Tween = image.create_tween().set_parallel(true)
		motion.tween_property(image, "scale", Vector2.ONE * float(action.get("zoom_to", 1.06)), duration).set_trans(Tween.TRANS_SINE)
		motion.tween_property(image, "position", Vector2(offset[0], offset[1]), duration).set_trans(Tween.TRANS_SINE)
		var gradient: Gradient = Gradient.new()
		gradient.set_color(0, Color(0.015, 0.02, 0.03, 0))
		gradient.set_color(1, Color(0.015, 0.02, 0.03, 0.98))
		var texture: GradientTexture2D = GradientTexture2D.new()
		texture.gradient = gradient
		texture.fill_from = Vector2(0.5, 0)
		texture.fill_to = Vector2(0.5, 1)
		var veil: TextureRect = TextureRect.new()
		veil.texture = texture
		veil.position = Vector2(0, 320)
		veil.size = Vector2(960, 220)
		card.add_child(veil)
	for y: int in [0, 520]:
		var bar: ColorRect = ColorRect.new()
		bar.position = Vector2(0, y)
		bar.size = Vector2(960, 20)
		bar.color = Color("070a10")
		card.add_child(bar)
	var caption_text: String = action.get("caption", "PRÓLOGO") if is_title else "%02d" % generation
	var caption: Label = host.text(card, "U M B R A L" + ("  /  " + caption_text if not caption_text.is_empty() else ""), 11)
	caption.position = Vector2(46, 358 if not is_title else 150)
	caption.modulate = Color("c4a46a")
	if is_title:
		caption.position.x = 400
	var label: RichTextLabel = RichTextLabel.new()
	label.name = "Narration"
	label.position = Vector2(46, 382) if not is_title else Vector2(120, 202)
	label.size = Vector2(780, 104) if not is_title else Vector2(720, 170)
	label.add_theme_font_size_override("normal_font_size", 20 if not is_title else 32)
	label.add_theme_font_override("normal_font", host.serif)
	label.add_theme_color_override("default_color", Color("eee1c7"))
	label.bbcode_enabled = is_title
	label.text = action.text if not is_title else "[center]" + action.text + "[/center]"
	label.visible_ratio = 0 if not is_title else 1
	label.scroll_active = false
	card.add_child(label)
	if not is_title:
		var typing: Tween = label.create_tween()
		typing.tween_property(label, "visible_ratio", 1.0, minf(4.0, label.text.length() * 0.035))
	var next: Button = host.button(card, "Continuar  ›", func() -> void: finish_card(generation))
	next.position = Vector2(730, 482)
	next.add_theme_font_size_override("font_size", 13)
	var skip: Button = host.button(card, "Saltar", skip_intro)
	skip.position = Vector2(852, 482)
	skip.add_theme_font_size_override("font_size", 13)
	skip.tooltip_text = "Saltar introducción"
	skip.visible = intro_active
	if action.has("audio"):
		host.audio.play(action.audio)
	card.modulate.a = 0
	var entrance: Tween = card.create_tween()
	entrance.tween_property(card, "modulate:a", 1.0, minf(float(action.get("transition", 0.6)), duration * 0.2))
	var exit_duration: float = minf(0.5, duration * 0.15)
	card_tween = card.create_tween()
	card_tween.tween_interval(maxf(0.001, duration - exit_duration))
	card_tween.tween_property(card, "modulate:a", 0.0, exit_duration)
	card_tween.tween_callback(func() -> void: finish_card(generation))
	await card_finished

func exploration_help() -> void:
	if exploration.player.locked or flow.phase != "exploration":
		return
	exploration.player.locked = true
	exploration.player.route.clear()
	exploration.release_interaction()
	var box: VBoxContainer = panel("Explorar el asentamiento")
	host.text(box, "WASD / flechas · Caminar     Shift · Correr", 16)
	host.text(box, "Clic sobre un habitante u objeto · Acercarse y conversar / examinar", 15)
	host.text(box, "Continuar historia · Confirmar el avance al siguiente acontecimiento", 15)
	host.button(box, "Volver al asentamiento", func() -> void:
		dialog.queue_free()
		exploration.player.locked = false)

func finish_card(generation: int) -> void:
	if generation != card_generation or not is_instance_valid(card) or card.is_queued_for_deletion():
		return
	card.queue_free()
	if card_tween != null:
		card_tween.kill()
	card_finished.emit()

func skip_intro() -> void:
	if not intro_active:
		return
	intro_skipped = true
	finish_card(card_generation)

func seconds(action: Dictionary, fallback: float) -> float:
	return maxf(0.001, float(action.get("seconds", fallback)) / maxf(0.01, playback_speed))

func set_hud_visible(value: bool) -> void:
	header.visible = value
	advance.visible = value
	help.visible = value

func load_environment(id: String) -> void:
	if is_instance_valid(exploration):
		exploration.get_parent().remove_child(exploration)
		exploration.queue_free()
	environment_id = id
	var data: Dictionary = NarrativeContent.merge(content, NarrativeContent.environment(content, id))
	exploration = load("res://scenes/exploration.tscn").instantiate() as ExplorationController
	exploration.world = flow.world
	host.screen.add_child(exploration)
	exploration.setup(data)
	exploration.player.locked = not entry_sequence.is_empty() or flow.phase != "exploration"
	exploration.dialogue_requested.connect(open_dialogue)

func evaluate_rules() -> void:
	for rule: Dictionary in content.get("state_rules", []):
		if ConditionEvaluator.matches(rule.get("conditions", []), flow.world):
			EffectResolver.apply(rule.get("effects", []), flow.world)

func move_actor(action: Dictionary) -> void:
	var start: Vector2 = exploration.actor_position(action.id)
	var target: Vector2 = Vector2(action.position[0], action.position[1])
	var duration: float = seconds(action, 0.8)
	var node: ExplorationActor = exploration.actor_node(action.id)
	if node != null:
		node.cinematic_velocity = (target - start) / duration
		node.cinematic_running = bool(action.get("run", false))
	var tween: Tween = create_tween()
	tween.tween_method(func(value: Vector2) -> void: exploration.position_actor(action.id, value), start, target, duration)
	await tween.finished
	if is_instance_valid(node):
		node.cinematic_velocity = Vector2.ZERO
		node.cinematic_running = false

func set_ambience(action: Dictionary) -> void:
	if ambience == null:
		ambience = AudioStreamPlayer.new()
		ambience.bus = "SFX"
		add_child(ambience)
		ambience.finished.connect(func() -> void: ambience.play())
	if action.has("cue") and not str(action.cue).is_empty():
		ambience.stop()
		ambience.stream = host.audio.stream(action.cue)
		ambience.volume_db = -60
		ambience.play()
	var tween: Tween = create_tween()
	tween.tween_property(ambience, "volume_db", float(action.get("volume", -60)), seconds(action, 1))
	await tween.finished
	if action.get("cue", "keep") == "":
		ambience.stop()

func flash(action: Dictionary) -> void:
	var overlay: ColorRect = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(action.get("color", "f2bd7e"))
	overlay.color.a = 0.65
	ui.add_child(overlay)
	var tween: Tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.0, seconds(action, 0.45))
	await tween.finished
	overlay.queue_free()

func show_boundary(action: Dictionary) -> void:
	flow.phase = "chapter_boundary"
	exploration.player.locked = true
	var box: VBoxContainer = panel(action.title)
	host.text(box, action.text, 15).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.button(box, "Volver a las ruinas", func() -> void:
		dialog.queue_free()
		flow.phase = "exploration"
		exploration.player.locked = false)
	host.button(box, "Menú principal", host.show_menu)

func _exit_tree() -> void:
	if is_instance_valid(ambience):
		ambience.stop()
		ambience.stream = null
	if card_tween != null:
		card_tween.kill()
