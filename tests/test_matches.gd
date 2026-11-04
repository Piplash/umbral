extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func enemy_phase(b: BattleManager) -> void:
	b.turns.phase = "enemy"
	for unit: TacticalUnit in b.units:
		if unit.team == "enemy":
			b.enemy_activation(unit)
	if not b.ended:
		for unit: TacticalUnit in b.units:
			if unit.team == "neutral" and unit.alive() and unit.movement > 0:
				b.move_unit(unit, NeutralAI.plan(unit, b.grid, b.units, b.mission.shelter_cells, b.turns.number))
		b.start_allied_phase()

func use(b: BattleManager, actor: TacticalUnit, action: String, target: TacticalUnit = null) -> void:
	b.selected = actor
	b.mode = "move"
	b.choose(action)
	if target != null and target.cell in b.targets():
		b.click(target.cell)

func move_actor(b: BattleManager, actor: TacticalUnit, target: TacticalUnit, desired_range: int) -> void:
	var paths: Dictionary = MovementSystem.reachable(b.grid, b.units, actor.cell, actor.movement)
	var best: Vector2i = actor.cell
	var best_score: int = 100000
	for cell: Vector2i in paths:
		var score: int = absi(b.grid.distance(cell, target.cell) - desired_range) * 100 + paths[cell].size()
		if score < best_score:
			best_score = score
			best = cell
	if best != actor.cell:
		b.selected = actor
		b.mode = "move"
		b.click(best)

func play_mission(mission: BattleMissionData) -> void:
	# Full match using only public player commands and normal enemy activations.
	var b: BattleManager = BattleManager.new(mission)
	var hero: TacticalUnit = b.units[0]
	var sister: TacticalUnit = b.units[1]
	var soldier: TacticalUnit = b.units[2]
	var captor: TacticalUnit = b.units[3]
	var transcript: Array[String] = []
	b.event.connect(func(message: String) -> void: transcript.append(message))
	while not b.ended and b.turns.number <= 30:
		var remaining: Array = b.units.filter(func(u: TacticalUnit) -> bool: return u.team == "enemy" and u.alive())
		var target: TacticalUnit = captor if captor.alive() else remaining[0]
		if hero.alive():
			move_actor(b, hero, target, 1)
			if b.grid.distance(hero.cell, target.cell) == 1:
				use(b, hero, "heavy" if AbilitySystem.available(hero, "heavy") else "attack", target)
			else:
				use(b, hero, "defend")
		if b.ended:
			break
		if sister.alive():
			remaining = b.units.filter(func(u: TacticalUnit) -> bool: return u.team == "enemy" and u.alive())
			target = captor if captor.alive() else remaining[0]
			var action: String = "attack"
			var range_needed: int = 1
			if captor.alive() and AbilitySystem.available(sister, "jam"):
				action = "jam"
				range_needed = 3
			elif hero.alive() and hero.hp <= 40 and AbilitySystem.available(sister, "heal"):
				action = "heal"
				target = hero
				range_needed = 2
			move_actor(b, sister, target, range_needed)
			if b.grid.distance(sister.cell, target.cell) <= range_needed:
				use(b, sister, action, target)
			else:
				use(b, sister, "defend")
		if not b.ended:
			enemy_phase(b)
	if b.results.defeated(b.units) != b.enemy_count():
		failures += 1
		printerr("Full victory match failed: turn %d, capture %d, hero %d, sister %d" % [b.turns.number, b.capture.progress, hero.hp, sister.hp])
		for line: String in transcript:
			printerr(line)
	else:
		print(mission.mission_id + " PASS full victory: %d turns, %d damage received, %d abilities, capture %d/3" % [b.turns.number, b.results.damage_received, b.results.abilities_used, b.capture.progress])
	# Passive play must lead to capture defeat, without changing health or positions.
	b = BattleManager.new(mission)
	while not b.ended and b.turns.number <= 15:
		enemy_phase(b)
	if not b.ended or (b.capture.progress != 3 and not b.allies().is_empty()):
		failures += 1
		printerr("Passive capture defeat failed")
	else:
		print(mission.mission_id + " PASS full defeat in turn %d" % b.turns.number)



func run() -> void:
	for mission: BattleMissionData in MissionCatalog.missions():
		play_mission(mission)
	var content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/narrative/settlement.json"))
	for warned: bool in [false, true]:
		for terminal: bool in [false, true]:
			var flow: MissionFlowController = MissionFlowController.new()
			flow.world.data.flags.villager_warned = warned
			flow.world.data.prepared.terminal = terminal
			flow.consolidate(MissionCatalog.default_mission(), content)
			print("PREPARATION warned=%s terminal=%s" % [warned, terminal])
			play_mission(flow.prepared)
	print("MATCH TESTS: %d failures" % failures)
	quit(0 if failures == 0 else 1)
