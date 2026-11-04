extends SceneTree

var checks: int = 0
var failures: int = 0
var played: Array[String] = []

func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for index: int in [0, 1]:
		var b: BattleManager = BattleManager.new()
		var unit: TacticalUnit = b.units[index]
		unit.cell = Vector2i(1, 2)
		b.selected = unit
		var route: Array = MovementSystem.reachable(b.grid, b.units, unit.cell, unit.movement)[Vector2i(3, 2)]
		expect(route.size() == 5, "detour around obstacle for " + unit.id)
		var emitted: Array = []
		b.route_requested.connect(func(_id: String, value: Array) -> void: emitted.append_array(value))
		b.click(Vector2i(3, 2))
		expect(emitted == route, "validated BFS is emitted unchanged")
		for step: int in range(1, emitted.size()):
			expect(b.grid.distance(emitted[step - 1], emitted[step]) == 1 and emitted[step] not in b.grid.obstacles, "orthogonal detour segment")
		expect(not b.undo_route(unit).is_empty(), "undo available before action")
		expect(b.undo_movement() and unit.cell == Vector2i(1, 2) and not unit.moved and not unit.acted, "undo restores origin and movement")
		b.click(Vector2i(3, 2))
		b.choose("defend")
		expect(b.undo_route(unit).is_empty() and not b.undo_movement(), "defending commits movement")
	var b: BattleManager = BattleManager.new()
	var hero: TacticalUnit = b.units[0]
	var enemy: TacticalUnit = b.units[2]
	b.selected = hero
	b.click(Vector2i(2, 4))
	b.units[1].cell = Vector2i(1, 4)
	expect(b.undo_route(hero).is_empty(), "occupied origin denies undo")
	b.units[1].cell = Vector2i(2, 5)
	b.turns.phase = "enemy"
	expect(not b.undo_movement(), "no undo during enemy phase")
	for heavy: bool in [false, true]:
		for defending: bool in [false, true]:
			enemy.hp = enemy.max_hp
			enemy.defending = defending
			var estimate: Dictionary = b.damage_preview(hero, enemy, "heavy" if heavy else "attack")
			CombatSystem.hit(hero, enemy, heavy)
			expect(enemy.hp == estimate.remaining, "preview equals actual damage with defense")
	enemy.hp = 2
	enemy.defending = false
	var overkill: Dictionary = b.damage_preview(hero, enemy, "heavy")
	expect(CombatSystem.hit(hero, enemy, true) == overkill.damage and overkill.remaining == 0, "forecast reports effective damage without overkill")
	b = BattleManager.new()
	enemy = b.units[2]
	var area: Dictionary = ThreatSystem.ranges(enemy, b.grid, b.units)
	for destination: Vector2i in area.paths:
		var path: Array = area.paths[destination]
		expect(path.size() <= enemy.movement + 1, "enemy movement budget")
		for index: int in range(1, path.size()):
			expect(b.grid.is_walkable(path[index], b.units), "enemy range respects occupancy and obstacles")
	for target: Vector2i in area.potential:
		var proven: bool = false
		for origin: Vector2i in area.paths:
			proven = proven or b.grid.distance(origin, target) == 1
		expect(proven and target not in b.grid.obstacles, "potential attack has real reachable origin")
	var before: Dictionary = ThreatSystem.global_danger(b.grid, b.units)
	var ally_ranges: Dictionary = ThreatSystem.ranges(b.units[0], b.grid, b.units)
	expect(ally_ranges.paths == MovementSystem.reachable(b.grid, b.units, b.units[0].cell, b.units[0].movement), "ally range uses actual BFS")
	expect(area.current.size() == 4, "four orthogonal current enemy attack cells")
	var old_cell: Vector2i = enemy.cell
	enemy.cell = Vector2i.ZERO
	expect(ThreatSystem.global_danger(b.grid, b.units).attacks != before.attacks, "global danger changes with enemy position")
	enemy.cell = old_cell
	enemy.jammed = true
	var jammed: Dictionary = ThreatSystem.ranges(enemy, b.grid, b.units)
	expect(jammed.paths.size() == 1 and jammed.potential.size() <= 4, "jam removes move threat but retains adjacent attacks")
	b.units[3].jammed = true
	expect(ThreatSystem.ranges(b.units[3], b.grid, b.units).capture.is_empty(), "jam removes capture positions")
	b.units[2].hp = 0
	b.units[3].hp = 0
	expect(not before.attacks.is_empty() and ThreatSystem.global_danger(b.grid, b.units).attacks.is_empty(), "global danger removes defeated enemies")
	# Real scene: inspect, preview, animate route, undo, target confirmation, sound and audio persistence.
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.start_battle()
	await process_frame
	main.audio.cue_played.connect(func(cue: String, _bus: String) -> void: played.append(cue))
	var turn: int = main.battle.turns.number
	main.on_cell(main.battle.units[2].cell)
	expect(main.inspected_unit == main.battle.units[2] and main.battle.turns.number == turn and not main.battle.units[0].acted, "enemy inspection costs no resources")
	expect(main.info.text.contains("Soldado"), "enemy statistics in character card")
	expect(main.hp_bar.value == 40 and main.hp_bar.max_value == 40, "switching inspected unit sets correct health immediately")
	main.toggle_danger()
	expect(main.board.danger_enabled, "danger toggle")
	main.toggle_danger()
	expect(not main.board.danger_enabled, "danger optional")
	main.inspect_unit(main.battle.units[0])
	main.battle.units[0].cell = Vector2i(1, 2)
	main.board.render_positions["hero"] = main.board.origin + Vector2(1, 2) * main.board.tile_size
	main.board.set_cursor(Vector2i(3, 2))
	var preview: Array = main.board.preview_route().duplicate()
	var walked: Array = [Vector2i(1, 2)]
	main.board.route_step.connect(func(id: String, cell: Vector2i) -> void:
		if id == "hero":
			walked.append(cell))
	main.on_cell(Vector2i(3, 2))
	expect(main.board.busy and main.command_active, "movement locks immediately")
	main.end_turn()
	expect(main.battle.turns.phase == "ally", "cannot finish phase during movement")
	while main.board.busy:
		await process_frame
	expect(walked == preview, "animated path exactly matches preview")
	expect(main.board.animation_states.hero == "idle", "idle restored after route")
	main.undo_move()
	while main.board.busy:
		await process_frame
	expect(main.battle.units[0].cell == Vector2i(1, 2) and not main.battle.units[0].moved, "animated undo finishes cleanly")
	main.battle.units[2].cell = Vector2i(1, 1)
	main.board.render_positions.soldier = main.board.origin + Vector2(1, 1) * main.board.tile_size
	main.choose("heavy")
	main.board.set_cursor(Vector2i(1, 1))
	var hp: int = main.battle.units[2].hp
	main.on_cell(Vector2i(1, 1))
	expect(main.battle.units[2].hp == hp and main.pending_target == Vector2i(1, 1), "first target click previews without damage")
	expect(main.action_description.text.contains("Daño previsto: 15"), "forecast displays shared heavy formula")
	main.on_cell(Vector2i(1, 1))
	main.on_cell(Vector2i(1, 1))
	while main.board.busy:
		await process_frame
	expect(main.battle.units[2].hp == hp - 15, "one confirmed strike despite duplicate input")
	expect(played.has("attack") and played.has("impact"), "action plays differentiated combat cues")
	played.clear()
	main.audio.last_navigation = ""
	main.audio.last_cue = ""
	main.audio.navigate("test-option")
	main.audio.navigate("test-option")
	await process_frame
	await process_frame
	main.audio.navigate("test-option")
	expect(played.count("navigate") == 1, "no repeated navigation cue for same option")
	var old_path: String = main.audio.settings_path
	main.audio.settings_path = "user://iteration2-test-audio.cfg"
	main.audio.set_volume("SFX", 0.23)
	main.audio.set_muted("UI", true)
	main.audio.set_volume("SFX", 0.8, false)
	main.audio.set_muted("UI", false, false)
	main.audio.load_preferences()
	expect(is_equal_approx(main.audio.volumes.SFX, 0.23) and main.audio.muted.UI, "audio preferences reload saved values")
	main.audio.settings_path = old_path
	main.audio.load_preferences()
	for bus: String in UmbralAudio.BUSES:
		expect(AudioServer.get_bus_index(bus) >= 0, "bus " + bus)
	for cue: String in ["attack", "impact", "damage", "heal", "jam", "unit_defeat", "victory", "defeat", "navigate", "select", "confirm", "cancel", "invalid", "turn", "pause"]:
		expect(main.audio.stream(cue).get_length() > 0, "valid original waveform " + cue)
	main.start_battle()
	main.inspect_unit(main.battle.units[1])
	main.battle.units[1].cell = Vector2i(1, 2)
	main.board.render_positions.support = main.board.origin + Vector2(1, 2) * main.board.tile_size
	main.board.set_cursor(Vector2i(3, 2))
	var lira_preview: Array = main.board.preview_route().duplicate()
	var lira_walked: Array = [Vector2i(1, 2)]
	main.board.route_step.connect(func(id: String, cell: Vector2i) -> void:
		if id == "support":
			lira_walked.append(cell))
	main.on_cell(Vector2i(3, 2))
	while main.board.busy:
		await process_frame
	expect(lira_walked == lira_preview and lira_walked.size() == 5, "Lira visually follows obstacle detour")
	main.start_battle()
	var routes_in_progress: Dictionary = {}
	var requests: Array = []
	main.battle.route_requested.connect(func(id: String, route: Array) -> void:
		routes_in_progress[id] = route.duplicate()
		requests.append(id))
	main.board.route_finished.connect(func(id: String) -> void: routes_in_progress.erase(id))
	main.battle.animation_requested.connect(func(_id: String, animation: String) -> void:
		if animation == "attack":
			expect(routes_in_progress.is_empty(), "attack starts only after movement finishes"))
	main.on_cell(Vector2i(4, 4))
	while main.board.busy:
		await process_frame
	main.end_turn()
	while main.enemy_running:
		await process_frame
	expect(requests.has("soldier") and requests.has("captor"), "both enemies use animated route pipeline")
	expect(routes_in_progress.is_empty() and main.battle.turns.number == 2, "enemy phase waits for every route")
	main.start_battle()
	while not main.battle.ended and main.battle.turns.number <= 8:
		main.end_turn()
		while main.enemy_running:
			await process_frame
	expect(main.battle.ended and main.battle.capture.progress == 3 and main.overlay != null, "animated passive match reaches capture defeat and results")
	main.show_menu()
	main.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("ITERATION 2: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
