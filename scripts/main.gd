extends Control

var battle: BattleManager
var board: BoardView
var screen: Control
var side: VBoxContainer
var status: Label
var log_label: Label
var info: Label
var action_box: VBoxContainer
var overlay: Control
var messages: Array[String] = []
var serial: int = 0
var paused: bool = false
var enemy_running: bool = false
var portrait: TextureRect
var hp_bar: ProgressBar
var action_description: RichTextLabel
var context_hint: Label
var roster: VBoxContainer
var skill_menu: bool = false
var phase_seen: String = ""
var health_tween: Tween
var serif: SystemFont
var audio: UmbralAudio
var inspected_unit: TacticalUnit
var command_active: bool = false
var interaction_state: String = "waiting"
var pending_target: Vector2i = Vector2i(-1, -1)
var danger_button: Button
var range_hint: Label
var highlighted_action: String = "move"
var undo_button: Button
var phase_tween: Tween
var end_turn_button: Button
var displayed_unit_id: String = ""
var story_flow: MissionFlowController
var active_mission: BattleMissionData
var scenario_selector: OptionButton

const DESCRIPTIONS: Dictionary = {
	"move": ["Mover", "Elige una casilla azul. Obstáculos y unidades bloquean el paso."],
	"attack": ["Atacar", "Inflige daño físico a un enemigo adyacente. Alcance ortogonal: 1."],
	"heavy": ["Golpe contundente", "150 % del ataque menos defensa. Alcance 1. Descansa dos fases aliadas."],
	"jam": ["Interferencia", "Bloquea movimiento y captura en la siguiente fase enemiga. Alcance 3."],
	"heal": ["Primeros auxilios", "Restaura 12 PV a un aliado vivo, incluido quien la usa. Alcance 2."],
	"defend": ["Defender", "Reduce el daño recibido a la mitad hasta la siguiente fase aliada."],
	"wait": ["Esperar", "Termina la activación y cede el movimiento y la acción restantes."]
}

func _ready() -> void:
	audio = UmbralAudio.new()
	add_child(audio)
	var custom_theme: Theme = Theme.new()
	custom_theme.default_font_size = 16
	serif = SystemFont.new()
	serif.font_names = PackedStringArray(["Georgia", "Times New Roman"])
	custom_theme.set_font("font", "Button", serif)
	custom_theme.set_color("font_color", "Button", Color("e5ddc9"))
	custom_theme.set_color("font_hover_color", "Button", Color("fff0bd"))
	custom_theme.set_color("font_disabled_color", "Button", Color("62656a"))
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color(0.055, 0.075, 0.09, 0.94)
	normal.border_color = Color("63594e")
	normal.set_border_width_all(1)
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
	custom_theme.set_stylebox("normal", "Button", normal)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color("263c40")
	hover.border_color = Color("d7bb7c")
	custom_theme.set_stylebox("hover", "Button", hover)
	custom_theme.set_stylebox("focus", "Button", hover)
	custom_theme.set_stylebox("pressed", "Button", hover)
	var disabled_style: StyleBoxFlat = normal.duplicate()
	disabled_style.bg_color = Color(0.04, 0.05, 0.06, 0.88)
	disabled_style.border_color = Color("34383b")
	custom_theme.set_stylebox("disabled", "Button", disabled_style)
	theme = custom_theme
	show_menu()

func clear_screen() -> void:
	if health_tween != null:
		health_tween.kill()
	serial += 1
	if is_instance_valid(board):
		board.cancel_presentation()
	if is_instance_valid(audio):
		audio.clear_combat()
	command_active = false
	interaction_state = "waiting"
	inspected_unit = null
	displayed_unit_id = ""
	pending_target = Vector2i(-1, -1)
	paused = false
	enemy_running = false
	if is_instance_valid(screen):
		remove_child(screen)
		screen.queue_free()
	screen = Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen)
	overlay = null
	phase_seen = ""
	skill_menu = false
	info = null
	log_label = null

func text(parent: Node, value: String, size: int = 12) -> Label:
	var label: Label = Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.modulate = Color("e4dfd2")
	parent.add_child(label)
	return label

func button(parent: Node, value: String, callback: Callable) -> Button:
	var item: Button = Button.new()
	item.text = value
	item.focus_mode = Control.FOCUS_ALL
	item.pressed.connect(callback)
	wire_navigation(item, value)
	parent.add_child(item)
	return item

func wire_navigation(item: Button, key: String) -> void:
	item.mouse_entered.connect(func() -> void:
		if not item.disabled:
			audio.navigate(key))
	item.focus_entered.connect(func() -> void:
		if not item.disabled:
			audio.navigate(key))

func panel_at(rect: Rect2, parent: Node = null) -> OrnamentPanel:
	var panel: OrnamentPanel = OrnamentPanel.new()
	panel.position = rect.position
	panel.size = rect.size
	(parent if parent != null else screen).add_child(panel)
	return panel

func decorate_logo() -> void:
	var logo: Label = text(screen, "U M B R A L", 29)
	logo.add_theme_font_override("font", serif)
	logo.position = Vector2(24, 12)
	var subtitle: Label = text(screen, "DEFENSA DEL ASENTAMIENTO", 9)
	subtitle.position = Vector2(25, 52)
	subtitle.modulate = Color("cbb58c")
	if active_mission != null:
		subtitle.text = active_mission.display_name.to_upper()

func show_menu() -> void:
	clear_screen()
	battle = null
	var menu_map: BattleMapData = MissionCatalog.default_mission().map
	var landscape: MapVisual = MapVisual.create(menu_map, null, "ground")
	screen.add_child(landscape)
	var village: MapVisual = MapVisual.create(menu_map, null, "lower")
	screen.add_child(village)
	var canopy: MapVisual = MapVisual.create(menu_map, null, "upper")
	screen.add_child(canopy)
	var veil: ColorRect = ColorRect.new()
	veil.color = Color(0.015, 0.025, 0.035, 0.65)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(veil)
	var frame: OrnamentPanel = panel_at(Rect2(300, 92, 360, 355))
	var panel: VBoxContainer = VBoxContainer.new()
	panel.add_theme_constant_override("separation", 15)
	frame.add_child(panel)
	var title: Label = text(panel, "U M B R A L", 40)
	title.add_theme_font_override("font", serif)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text(panel, "DEFENSA DEL ASENTAMIENTO", 14).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var intro: Label = text(panel, "El planeta se agota. El pueblo resiste.\nDos hermanos. Una última defensa.", 14)
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scenario_selector = OptionButton.new()
	scenario_selector.visible = false
	scenario_selector.add_theme_font_size_override("font_size", 14)
	panel.add_child(scenario_selector)
	var missions: Array[BattleMissionData] = MissionCatalog.missions()
	if active_mission == null:
		active_mission = MissionCatalog.default_mission()
	for mission: BattleMissionData in missions:
		scenario_selector.add_item("%s (%d × %d)" % [mission.display_name, mission.map.dimensions.x, mission.map.dimensions.y])
		var index: int = scenario_selector.item_count - 1
		scenario_selector.set_item_metadata(index, mission)
		if mission.mission_id == active_mission.mission_id:
			scenario_selector.select(index)
	scenario_selector.item_selected.connect(func(index: int) -> void: active_mission = scenario_selector.get_item_metadata(index); audio.play("select"))
	button(panel, "Iniciar historia", start_exploration).grab_focus()
	button(panel, "Salir", func() -> void: get_tree().quit())
	text(panel, "COMBATE TÁCTICO · CIENCIA FICCIÓN RURAL", 10).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func start_exploration(content_path: String = "res://data/narrative/settlement.json", play_intro: bool = true) -> void:
	clear_screen()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle = null
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	story_flow = MissionFlowController.new()
	var session: StorySession = StorySession.new()
	session.host = self
	session.flow = story_flow
	session.play_intro = play_intro
	session.content = JSON.parse_string(FileAccess.get_file_as_string(content_path))
	screen.add_child(session)

func start_battle(mission: BattleMissionData = null) -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if mission != null:
		active_mission = mission
	if active_mission == null:
		active_mission = MissionCatalog.default_mission()
	var errors: PackedStringArray = active_mission.validation_errors()
	if not errors.is_empty():
		push_error("Misión inválida: " + "; ".join(errors))
		return
	if story_flow != null and active_mission == story_flow.prepared:
		story_flow.world.restore(story_flow.before_battle)
		story_flow.phase = "battle"
	clear_screen()
	messages.clear()
	battle = BattleManager.new(active_mission)
	battle.changed.connect(refresh)
	battle.event.connect(record)
	battle.finished.connect(queue_results)
	board = BoardView.new()
	board.z_index = -10
	board.size = Vector2(720, 540)
	board.battle = battle
	board.cell_clicked.connect(on_cell)
	battle.impact.connect(board.effect)
	battle.animation_requested.connect(board.play_animation)
	battle.route_requested.connect(board.play_route)
	battle.sound_requested.connect(audio.play)
	battle.invalid_action.connect(func() -> void: audio.play("invalid"))
	board.cursor_changed.connect(func(_cell: Vector2i) -> void: update_target_info())
	screen.add_child(board)
	decorate_logo()
	var phase_panel: OrnamentPanel = panel_at(Rect2(269, 13, 434, 36))
	status = text(phase_panel, "", 17)
	status.add_theme_font_override("font", serif)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var order_panel: OrnamentPanel = panel_at(Rect2(10, 92, 61, 287))
	roster = VBoxContainer.new()
	roster.add_theme_constant_override("separation", 5)
	var roster_scroll: ScrollContainer = ScrollContainer.new()
	roster_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	order_panel.add_child(roster_scroll)
	roster_scroll.add_child(roster)
	text(roster, "ORDEN", 10).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var card: OrnamentPanel = panel_at(Rect2(723, 60, 224, 138))
	var card_box: VBoxContainer = VBoxContainer.new()
	card.add_child(card_box)
	var heading: HBoxContainer = HBoxContainer.new()
	card_box.add_child(heading)
	portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(75, 79)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	heading.add_child(portrait)
	var details: VBoxContainer = VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(details)
	info = text(details, "", 14)
	info.add_theme_font_override("font", serif)
	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(115, 8)
	hp_bar.show_percentage = false
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = Color("8fbe85")
	hp_bar.add_theme_stylebox_override("fill", fill)
	var background: StyleBoxFlat = StyleBoxFlat.new()
	background.bg_color = Color("202d2c")
	hp_bar.add_theme_stylebox_override("background", background)
	details.add_child(hp_bar)
	side = VBoxContainer.new()
	card_box.add_child(side)
	action_box = VBoxContainer.new()
	action_box.position = Vector2(729, 211)
	action_box.size = Vector2(212, 205)
	action_box.add_theme_constant_override("separation", 5)
	screen.add_child(action_box)
	var description_panel: OrnamentPanel = panel_at(Rect2(723, 413, 224, 81))
	action_description = RichTextLabel.new()
	action_description.add_theme_font_size_override("normal_font_size", 11)
	action_description.scroll_active = false
	action_description.fit_content = false
	action_description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	description_panel.add_child(action_description)
	var objective: OrnamentPanel = panel_at(Rect2(10, 465, 263, 66))
	var objective_text: Label = text(objective, "◈ Objetivo\n" + battle.mission.objective_text, 12)
	objective_text.add_theme_font_override("font", serif)
	context_hint = text(screen, "", 12)
	context_hint.position = Vector2(277, 58)
	context_hint.size = Vector2(425, 38)
	context_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	context_hint.modulate = Color("d8c69b")
	var range_controls: HBoxContainer = HBoxContainer.new()
	range_controls.position = Vector2(278, 88)
	screen.add_child(range_controls)
	danger_button = button(range_controls, "Tab · Peligro: no", toggle_danger)
	danger_button.add_theme_font_size_override("font_size", 11)
	undo_button = button(range_controls, "Z · Deshacer movimiento", undo_move)
	undo_button.add_theme_font_size_override("font_size", 11)
	range_hint = text(range_controls, "Azul: mover · Rojo: atacar", 9)
	var footer: OrnamentPanel = panel_at(Rect2(578, 503, 369, 28))
	var controls: HBoxContainer = HBoxContainer.new()
	footer.add_child(controls)
	text(controls, "Enter confirmar · Esc cancelar", 10)
	end_turn_button = button(controls, "F  Fin de turno", end_turn)
	end_turn_button.add_theme_font_size_override("font_size", 10)
	button(controls, "H  Ayuda", show_help).add_theme_font_size_override("font_size", 10)
	battle.selected = battle.allies()[0] if not battle.allies().is_empty() else null
	if battle.selected != null:
		board.set_cursor(battle.selected.cell)
	refresh()
	battle.check_end()
	if not battle.mission.preparation_messages.is_empty():
		record(" · ".join(battle.mission.preparation_messages))

func record(message: String) -> void:
	messages.append(message)
	while messages.size() > 4:
		messages.pop_front()
	if is_instance_valid(context_hint):
		context_hint.text = message

func refresh() -> void:
	if battle == null or not is_instance_valid(info):
		return
	highlighted_action = battle.mode
	end_turn_button.disabled = input_locked()
	var phase_label: String = "FASE ALIADA" if battle.turns.phase == "ally" else "FASE ENEMIGA" if battle.turns.phase == "enemy" else "FASE NEUTRAL" if battle.turns.phase == "neutral" else "FIN"
	status.text = "TURNO %02d · %s" % [battle.turns.number, phase_label]
	if battle.capture.enabled:
		status.text += "     |     CAPTURA %d/%d" % [battle.capture.progress, battle.capture.limit]
	if phase_seen != battle.turns.phase:
		phase_seen = battle.turns.phase
		phase_transition(phase_label)
	for child: Node in action_box.get_children():
		action_box.remove_child(child)
		child.queue_free()
	for child: Node in side.get_children():
		side.remove_child(child)
		child.queue_free()
	while roster.get_child_count() > 1:
		var child: Node = roster.get_child(1)
		roster.remove_child(child)
		child.queue_free()
	for unit: TacticalUnit in battle.units:
		var icon: Button = button(roster, "", func() -> void: inspect_unit(unit))
		icon.custom_minimum_size = Vector2(39, 42)
		icon.icon = ArtLibrary.unit_texture(unit, true)
		icon.expand_icon = true
		icon.add_theme_constant_override("icon_max_width", 36)
		icon.tooltip_text = "%s · %d/%d PV" % [unit.unit_name, unit.hp, unit.max_hp]
		icon.modulate = Color.WHITE if unit.alive() else Color("555963")
		if unit == (inspected_unit if inspected_unit != null else battle.selected):
			var selected_style: StyleBoxFlat = StyleBoxFlat.new()
			selected_style.bg_color = Color("293e40")
			selected_style.border_color = Color("d1b67c")
			selected_style.set_border_width_all(2)
			icon.add_theme_stylebox_override("normal", selected_style)
	var selected: TacticalUnit = battle.selected
	undo_button.visible = selected != null and inspected_unit == null and not battle.undo_route(selected).is_empty()
	undo_button.disabled = input_locked()
	if inspected_unit != null and not inspected_unit.alive():
		inspected_unit = null
		board.inspected = null
	var displayed: TacticalUnit = inspected_unit if inspected_unit != null else selected if selected != null and selected.alive() else battle.protected_unit()
	if displayed == null:
		displayed = battle.units[0] if not battle.units.is_empty() else null
	if displayed == null:
		info.text = "Sin unidades"
		return
	portrait.texture = ArtLibrary.unit_texture(displayed, true)
	info.text = "%s\n\nPV  %d / %d" % [displayed.unit_name, displayed.hp, displayed.max_hp]
	hp_bar.max_value = displayed.max_hp
	if health_tween != null:
		health_tween.kill()
	if displayed_unit_id != displayed.id:
		hp_bar.value = displayed.hp
		displayed_unit_id = displayed.id
	else:
		health_tween = hp_bar.create_tween()
		health_tween.tween_property(hp_bar, "value", float(displayed.hp), 0.25)
	text(side, "ATQ %d     DEF %d     MOV %d" % [displayed.attack, displayed.defense, displayed.movement], 12)
	if inspected_unit != null:
		text(action_box, "INSPECCIÓN · %s" % ("ENEMIGO" if displayed.team == "enemy" else "CIVIL"), 13)
		if displayed.team == "enemy":
			var potential_button: Button = button(action_box, "Amenaza potencial: " + ("sí" if board.potential_enabled else "no"), func() -> void: board.potential_enabled = not board.potential_enabled; refresh())
			potential_button.add_theme_font_size_override("font_size", 13)
		text(action_box, "Ámbar: movimiento\nRojo fuerte: ataque actual\nRojo tenue: tras moverse\nDorado: posible captura", 11)
		button(action_box, "Volver a los aliados", clear_inspection).add_theme_font_size_override("font_size", 13)
	elif selected != null and selected.alive():
		text(side, "%s · %s" % ["Mov. usado" if selected.moved else "Mov. listo", "Acción usada" if selected.acted else "Acción lista"], 10).modulate = Color("bca47d")
		if skill_menu:
			for ability: String in selected.abilities:
				var cooldown: int = selected.cooldowns.get(ability, 0)
				var suffix: String = " · lista" if cooldown == 0 else " · T%02d" % (battle.turns.number + cooldown)
				add_action(str(AbilitySystem.LABELS[ability]) + suffix, ability, selected.acted or cooldown > 0)
			button(action_box, "‹ Volver", func() -> void: skill_menu = false; refresh())
		else:
			add_action("Mover", "move", selected.moved)
			add_action("Atacar", "attack", selected.acted)
			var skills: TacticalActionButton = TacticalActionButton.new()
			skills.text = "      Habilidad"
			skills.icon_kind = "skill"
			skills.alignment = HORIZONTAL_ALIGNMENT_LEFT
			skills.pressed.connect(func() -> void: skill_menu = true; refresh())
			wire_navigation(skills, "skills")
			action_box.add_child(skills)
			skills.disabled = selected.acted or input_locked()
			if battle.mode in selected.abilities:
				skills.modulate = Color("ead49c")
			add_action("Defender", "defend", selected.acted)
			add_action("Esperar", "wait", selected.acted)
	else:
		text(action_box, "Selecciona una unidad aliada.", 14)
	var description: Array = DESCRIPTIONS.get(battle.mode, DESCRIPTIONS.move)
	show_description(description)
	update_target_info()
	board.queue_redraw()

func show_description(description: Array) -> void:
	if is_instance_valid(action_description):
		action_description.text = "%s\n%s" % [description[0], description[1]]

func inspect_unit(unit: TacticalUnit) -> void:
	if paused or command_active or board.busy or battle.ended or not unit.alive():
		return
	if unit.team == "ally" and battle.turns.phase == "ally":
		skill_menu = false
		battle.mode = "move"
		battle.selected = unit
		inspected_unit = null
		board.inspected = null
		board.set_cursor(unit.cell)
		pending_target = Vector2i(-1, -1)
		audio.play("select")
		refresh()
	else:
		inspected_unit = unit
		board.inspected = unit
		board.set_cursor(unit.cell)
		audio.play("select")
		refresh()

func clear_inspection() -> void:
	inspected_unit = null
	board.inspected = null
	refresh()

func toggle_danger() -> void:
	if battle == null or battle.ended or paused:
		return
	board.danger_enabled = not board.danger_enabled
	danger_button.text = "Tab · Peligro: " + ("sí" if board.danger_enabled else "no")
	audio.play("select")

func update_target_info() -> void:
	if battle == null or not is_instance_valid(action_description):
		return
	if board.cursor != pending_target:
		pending_target = Vector2i(-1, -1)
	if inspected_unit != null:
		action_description.text = "Inspección sin gastar acciones.\nÁmbar: ruta · Rojo: ataque.\nInterferencia bloquea mover/capturar."
		return
	var target: TacticalUnit = battle.grid.occupant(board.cursor, battle.units)
	if target != null and target.cell in battle.targets() and battle.mode in ["attack", "heavy"]:
		var estimate: Dictionary = battle.damage_preview(battle.selected, target, battle.mode)
		action_description.text = "%s\n%s · PV %d → %d\nDaño previsto: %d\n%s" % [estimate.action, estimate.name, estimate.hp, estimate.remaining, estimate.damage, "Enter / clic: confirmar" if pending_target == target.cell else "Elige objetivo para confirmar"]
	else:
		show_description(DESCRIPTIONS.get(highlighted_action, DESCRIPTIONS.move))

func input_locked() -> bool:
	return paused or command_active or board.busy or battle.ended or battle.turns.phase != "ally"

func sync_interaction_state() -> void:
	interaction_state = "finished" if battle.ended else "enemy" if enemy_running else "targeting" if battle.mode != "move" else "destination" if battle.selected != null else "waiting"

func navigate_options(reverse: bool) -> void:
	var current: Control = get_viewport().gui_get_focus_owner()
	if current == null:
		for item: Node in action_box.get_children():
			if item is Button and not item.disabled:
				item.grab_focus()
				break
	else:
		var next: Control = current.find_prev_valid_focus() if reverse else current.find_next_valid_focus()
		if next != null:
			next.grab_focus()

func undo_move() -> void:
	if input_locked():
		return
	var token: int = serial
	if not battle.undo_movement():
		return
	audio.play("cancel")
	command_active = true
	interaction_state = "moving"
	if board.busy:
		await board.settled
	if token != serial:
		return
	command_active = false
	sync_interaction_state()
	refresh()

func phase_transition(value: String) -> void:
	if battle.ended:
		return
	if phase_tween != null:
		phase_tween.kill()
	status.modulate = Color("ed9d87") if value == "FASE ENEMIGA" else Color("f6dfac")
	phase_tween = status.create_tween()
	phase_tween.tween_property(status, "modulate", Color("e4dfd2"), 0.8)

func add_action(value: String, action: String, disabled: bool) -> void:
	var item: TacticalActionButton = TacticalActionButton.new()
	item.text = "      " + value
	item.icon_kind = action
	item.pressed.connect(func() -> void: choose(action))
	wire_navigation(item, "action:" + action)
	item.set_meta("action", action)
	action_box.add_child(item)
	item.alignment = HORIZONTAL_ALIGNMENT_LEFT
	item.disabled = disabled or input_locked()
	item.add_theme_font_size_override("font_size", 17 if not skill_menu else 13)
	if battle.mode == action:
		item.modulate = Color("ead49c")
	var description: Array = DESCRIPTIONS.get(action, DESCRIPTIONS.move)
	item.tooltip_text = description[1]
	item.mouse_entered.connect(func() -> void:
		if not item.disabled:
			highlight_action(action))
	item.focus_entered.connect(func() -> void:
		if not item.disabled:
			highlight_action(action))
	item.mouse_exited.connect(func() -> void: highlight_action(battle.mode))

func highlight_action(action: String) -> void:
	highlighted_action = action
	for child: Node in action_box.get_children():
		if child.has_meta("action"):
			child.modulate = Color("ead49c") if child.get_meta("action") == action else Color.WHITE
	show_description(DESCRIPTIONS.get(action, DESCRIPTIONS.move))
	if action == battle.mode:
		update_target_info()

func choose(action: String) -> void:
	if input_locked() or inspected_unit != null:
		return
	pending_target = Vector2i(-1, -1)
	highlighted_action = action
	var token: int = serial
	battle.choose(action)
	command_active = board.busy
	interaction_state = "acting" if command_active else "targeting"
	clear_ui_focus()
	if board.busy:
		await board.settled
	if token != serial:
		return
	command_active = false
	sync_interaction_state()
	advance_if_done()

func on_cell(cell: Vector2i) -> void:
	if paused or command_active or board.busy or battle.ended:
		return
	var target: TacticalUnit = battle.grid.occupant(cell, battle.units)
	if target != null and target.team != "ally" and (battle.mode == "move" or inspected_unit != null):
		inspect_unit(target)
		return
	if inspected_unit != null:
		if target != null and target.team == "ally":
			inspect_unit(target)
		return
	if battle.turns.phase != "ally":
		return
	if cell in battle.targets() and battle.mode in ["attack", "heavy"] and pending_target != cell:
		pending_target = cell
		board.cursor = cell
		audio.play("select")
		update_target_info()
		return
	var token: int = serial
	var old_selection: TacticalUnit = battle.selected
	if cell in battle.targets() or (battle.selected != null and target == null and not battle.selected.moved and MovementSystem.reachable(battle.grid, battle.units, battle.selected.cell, battle.selected.movement).has(cell)):
		audio.play("confirm")
	battle.click(cell)
	command_active = board.busy
	interaction_state = "moving" if not board.travel.is_empty() else "resolving" if command_active else "waiting"
	if old_selection != battle.selected:
		audio.play("select")
		skill_menu = false
		refresh()
	clear_ui_focus()
	pending_target = Vector2i(-1, -1)
	if board.busy:
		await board.settled
	if token != serial:
		return
	command_active = false
	sync_interaction_state()
	refresh()
	advance_if_done()

func clear_ui_focus() -> void:
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused != null:
		focused.release_focus()

func advance_if_done() -> void:
	if not battle.ended and battle.turns.phase == "ally" and battle.turns.all_finished(battle.units):
		end_turn()

func end_turn() -> void:
	if battle == null or input_locked() or enemy_running:
		return
	audio.play("turn")
	enemy_running = true
	interaction_state = "enemy"
	inspected_unit = null
	board.inspected = null
	battle.selected = null
	battle.mode = "move"
	battle.turns.phase = "enemy"
	record("FASE ENEMIGA")
	refresh()
	var token: int = serial
	for enemy: TacticalUnit in battle.units:
		if enemy.team != "enemy" or not enemy.alive():
			continue
		# Yield a frame for the phase HUD and allow pause before the next activation.
		await get_tree().process_frame
		if token != serial:
			return
		while paused:
			await get_tree().process_frame
			if token != serial:
				return
		battle.enemy_move(enemy)
		if board.busy:
			await board.settled
		if token != serial:
			return
		while paused:
			await get_tree().process_frame
			if token != serial:
				return
		battle.enemy_action(enemy)
		if board.busy:
			await board.settled
		if token != serial:
			return
		if battle.ended:
			enemy_running = false
			return
	await get_tree().process_frame
	if token != serial:
		return
	while paused:
		await get_tree().process_frame
		if token != serial:
			return
	for neutral: TacticalUnit in battle.units:
		if neutral.team == "neutral" and neutral.alive() and neutral.movement > 0:
			battle.turns.phase = "neutral"
			refresh()
			battle.move_unit(neutral, NeutralAI.plan(neutral, battle.grid, battle.units, battle.mission.shelter_cells, battle.turns.number))
			if board.busy:
				await board.settled
			if token != serial:
				return
	battle.start_allied_phase()
	enemy_running = false
	if battle.ended:
		return
	sync_interaction_state()
	record("FASE ALIADA · Movimiento y acción renovados.")
	refresh()

func modal(title: String) -> VBoxContainer:
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(overlay)
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.035, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var frame: OrnamentPanel = panel_at(Rect2(260, 70, 440, 400), overlay)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	frame.add_child(box)
	var heading: Label = text(box, title, 25)
	heading.add_theme_font_override("font", serif)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return box

func show_results(won: bool) -> void:
	if story_flow != null and story_flow.phase == "battle":
		story_flow.record_result(battle)
	interaction_state = "finished"
	audio.play("victory" if won else "defeat")
	var box: VBoxContainer = modal(battle.mission.victory_title if won else battle.mission.defeat_title)
	text(box, battle.outcome.reason)
	text(box, "Turnos: %d\nEnemigos derrotados: %d/%d\nDaño recibido por aliados: %d\nHabilidades utilizadas: %d" % [battle.turns.number, battle.results.defeated(battle.units), battle.enemy_count(), battle.results.damage_received, battle.results.abilities_used], 14)
	button(box, "Reiniciar combate", start_battle).grab_focus()
	button(box, "Menú principal", show_menu)

func queue_results(won: bool) -> void:
	var token: int = serial
	if board.busy:
		await board.settled
	if token != serial:
		return
	show_results(won)

func toggle_pause() -> void:
	if battle.ended:
		return
	if paused:
		paused = false
		board.presentation_paused = false
		audio.set_combat_paused(false)
		audio.play("pause")
		overlay.queue_free()
		overlay = null
		clear_ui_focus()
		return
	paused = true
	board.presentation_paused = true
	audio.set_combat_paused(true)
	audio.play("pause")
	var box: VBoxContainer = modal("PAUSA")
	button(box, "Continuar", toggle_pause).grab_focus()
	button(box, "Reiniciar combate", start_battle)
	button(box, "Menú principal", show_menu)
	button(box, "Ajustes de audio", show_audio_settings)

func show_audio_settings() -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
	var box: VBoxContainer = modal("AUDIO")
	box.add_theme_constant_override("separation", 8)
	for bus: String in UmbralAudio.BUSES:
		var row: HBoxContainer = HBoxContainer.new()
		box.add_child(row)
		var caption: Label = text(row, bus, 13)
		caption.custom_minimum_size.x = 65
		var slider: HSlider = HSlider.new()
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.01
		slider.value = audio.volumes[bus]
		slider.custom_minimum_size = Vector2(220, 22)
		slider.value_changed.connect(func(value: float) -> void: audio.set_volume(bus, value))
		row.add_child(slider)
		var percent: Label = text(row, "%d %%" % roundi(slider.value * 100), 12)
		slider.value_changed.connect(func(value: float) -> void: percent.text = "%d %%" % roundi(value * 100))
	for bus: String in ["SFX", "UI"]:
		var mute: CheckButton = CheckButton.new()
		mute.text = "Silenciar " + ("efectos" if bus == "SFX" else "interfaz")
		mute.button_pressed = audio.muted[bus]
		mute.toggled.connect(func(value: bool) -> void: audio.set_muted(bus, value))
		box.add_child(mute)
	text(box, "Se guarda automáticamente. Music no contiene pistas.", 11)
	button(box, "Volver al combate", toggle_pause)

func show_help() -> void:
	if paused or battle == null or battle.ended:
		return
	paused = true
	board.presentation_paused = true
	audio.set_combat_paused(true)
	audio.play("pause")
	var box: VBoxContainer = modal("ÓRDENES DE CAMPO")
	text(box, "Ratón: unidad, acción y destino. Enemigo: inspección.\nWASD / flechas: cursor · Enter / Espacio: confirmar.\nQ / Mayús+Q: opciones · Tab: peligro global.\nM mover · X atacar · G defender · E esperar.\n1 / 2 habilidades · Z deshacer · F fin de turno.\nEsc / clic derecho: cancelar · H ayuda.\n\nAtaque: elige objetivo y confirma con Enter o clic.\nAzul: mover · Rojo fuerte: ataque desde posición actual.\nRojo tenue: amenaza tras mover · Dorado: captura.\nNo puedes deshacer después de actuar.\nInterferencia bloquea mover/capturar, no ataques.\nConsulta el objetivo de la misión y su progreso de captura.", 14)
	button(box, "Volver al combate", toggle_pause).grab_focus()

func _input(event: InputEvent) -> void:
	if battle == null:
		return
	var cancel: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT
	if event is InputEventKey and event.pressed and not event.echo:
		cancel = cancel or event.keycode == KEY_ESCAPE
	if cancel:
		get_viewport().set_input_as_handled()
		if battle.ended:
			return
		if paused:
			toggle_pause()
		elif command_active or board.busy:
			toggle_pause()
		elif inspected_unit != null:
			audio.play("cancel")
			clear_inspection()
		elif battle.selected != null:
			audio.play("cancel")
			pending_target = Vector2i(-1, -1)
			if battle.mode != "move":
				battle.mode = "move"
			else:
				battle.selected = null
			refresh()
		else:
			toggle_pause()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_Q:
		navigate_options(event.shift_pressed)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB and not paused and not battle.ended:
		toggle_danger()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_H and not paused and not battle.ended:
		show_help()
		get_viewport().set_input_as_handled()
		return
	if not event is InputEventKey or not event.pressed or event.echo or paused or battle.ended or battle.turns.phase != "ally":
		return
	var key: int = event.keycode
	var direction: Vector2i = Vector2i.ZERO
	match key:
		KEY_W, KEY_UP: direction = Vector2i.UP
		KEY_S, KEY_DOWN: direction = Vector2i.DOWN
		KEY_A, KEY_LEFT: direction = Vector2i.LEFT
		KEY_D, KEY_RIGHT: direction = Vector2i.RIGHT
	if direction != Vector2i.ZERO:
		clear_ui_focus()
		board.set_cursor((board.cursor + direction).clamp(Vector2i.ZERO, battle.grid.size - Vector2i.ONE))
		get_viewport().set_input_as_handled()
	elif key in [KEY_ENTER, KEY_SPACE] and get_viewport().gui_get_focus_owner() == null:
		on_cell(board.cursor)
		get_viewport().set_input_as_handled()
	elif key == KEY_F:
		end_turn()
	elif key == KEY_M:
		choose("move")
	elif key == KEY_E:
		choose("wait")
	elif key == KEY_X:
		choose("attack")
	elif key == KEY_G:
		choose("defend")
	elif key == KEY_Z:
		undo_move()
	elif key in [KEY_1, KEY_2] and battle.selected != null:
		var index: int = key - KEY_1
		if index < battle.selected.abilities.size():
			choose(battle.selected.abilities[index])

