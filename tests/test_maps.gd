extends SceneTree

var checks: int = 0
var failures: int = 0

# An extension used only by this test: core systems need no awareness of its rule.
class LocationCondition:
	extends BattleCondition
	var unit_id: String
	var location: Vector2i
	func evaluate(units: Array, _capture: CaptureSystem, _turns: TurnManager) -> bool:
		for unit: TacticalUnit in units:
			if unit.id == unit_id and unit.alive() and unit.cell == location:
				return true
		return false

func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + description)

func _initialize() -> void:
	call_deferred("run")

func copy_mission() -> BattleMissionData:
	# Godot 4.2 Resource.duplicate(true) does not isolate Resources inside typed arrays.
	# Production treats configuration as read-only; tests explicitly copy mutable fixtures.
	var source: BattleMissionData = MissionCatalog.default_mission()
	var copy: BattleMissionData = source.duplicate()
	copy.map = source.map.duplicate(true)
	copy.participants = []
	for spawn: UnitSpawnData in source.participants:
		copy.participants.append(spawn.duplicate())
	copy.victory_conditions = source.victory_conditions.duplicate()
	copy.defeat_conditions = source.defeat_conditions.duplicate()
	return copy

func adjacent_free(b: BattleManager, target: TacticalUnit) -> Vector2i:
	for direction: Vector2i in GridManager.DIRECTIONS:
		var cell: Vector2i = target.cell + direction
		if b.grid.is_walkable(cell, b.units):
			return cell
	return Vector2i(-1, -1)

func check_mission(mission: BattleMissionData) -> void:
	expect(mission.validation_errors().is_empty(), "valid resource " + mission.mission_id)
	var b: BattleManager = BattleManager.new(mission)
	var expected_stats: Dictionary = {"hero": [60, 12, 4, 4], "support": [40, 6, 2, 4], "soldier": [40, 10, 3, 3], "captor": [30, 7, 2, 3], "civil": [25, 0, 0, 0]}
	for id: String in expected_stats:
		var unit: TacticalUnit = b.unit_by_id(id)
		expect([unit.max_hp, unit.attack, unit.defense, unit.movement] == expected_stats[id], "original statistics unchanged " + id)
	expect(b.grid.size == mission.map.dimensions and b.grid.obstacles == mission.map.blocked_cells, "map configuration consumed")
	for spawn: UnitSpawnData in mission.participants:
		var unit: TacticalUnit = b.unit_by_id(spawn.instance_id)
		expect(unit != null and unit.cell == spawn.cell(mission.map), "mission spawn " + spawn.instance_id)
		expect(unit.max_hp == spawn.definition.max_hp and unit.attack == spawn.definition.attack and unit.abilities == spawn.definition.abilities, "definition preserved")
		var area: Dictionary = ThreatSystem.ranges(unit, b.grid, b.units)
		for destination: Vector2i in area.paths:
			var path: Array = area.paths[destination]
			expect(b.grid.inside(destination) and destination not in b.grid.obstacles, "dynamic movement bounds")
			expect(path.size() <= unit.movement + 1, "dynamic movement budget")
			for index: int in range(1, path.size()):
				expect(b.grid.is_walkable(path[index], b.units) and b.grid.distance(path[index - 1], path[index]) == 1, "route respects active map and occupants")
		for cell: Vector2i in area.current:
			expect(b.grid.inside(cell) and cell not in b.grid.obstacles and b.grid.distance(cell, unit.cell) == 1, "dynamic attack range")
	var soldier: TacticalUnit = b.unit_by_id("soldier")
	var hero: TacticalUnit = b.unit_by_id("hero")
	soldier.cell = adjacent_free(b, hero)
	b.selected = hero
	b.choose("heavy")
	var expected: int = CombatSystem.damage(hero, soldier, true)
	var old_hp: int = soldier.hp
	b.click(soldier.cell)
	expect(soldier.hp == old_hp - expected and hero.acted and hero.cooldowns.heavy == 3, "same heavy ability")
	b = BattleManager.new(mission)
	var support: TacticalUnit = b.unit_by_id("support")
	var captor: TacticalUnit = b.unit_by_id("captor")
	captor.cell = adjacent_free(b, support)
	b.selected = support
	b.choose("jam")
	b.click(captor.cell)
	expect(captor.jammed and support.acted, "same interference")
	b = BattleManager.new(mission)
	support = b.unit_by_id("support")
	support.hp -= 8
	b.selected = support
	b.choose("heal")
	b.click(support.cell)
	expect(support.hp == support.max_hp and support.acted, "same healing cap")
	b = BattleManager.new(mission)
	captor = b.unit_by_id("captor")
	captor.cell = adjacent_free(b, b.protected_unit())
	captor.jammed = true
	b.enemy_activation(captor)
	expect(b.capture.progress == 0 and not captor.jammed, "interference blocks capture")
	for index: int in range(mission.capture_limit):
		b.enemy_activation(captor)
	expect(b.ended and b.outcome.status == "defeat" and b.capture.progress == mission.capture_limit, "configured capture defeat")
	b = BattleManager.new(mission)
	for unit: TacticalUnit in b.units:
		if unit.team == "enemy":
			unit.hp = 0
	expect(b.check_end() and b.outcome.status == "victory", "configured enemy defeat victory")
	b = BattleManager.new(mission)
	for unit: TacticalUnit in b.allies():
		unit.hp = 0
	expect(b.check_end() and b.outcome.status == "defeat", "configured allied defeat")
	b = BattleManager.new(mission)
	expect(not b.ended and b.capture.progress == 0 and b.units[0].hp == b.units[0].max_hp, "fresh mission state")
	var independent: BattleManager = BattleManager.new(mission)
	b.units[0].hp -= 1
	b.units[0].cooldowns["heavy"] = 2
	b.grid.obstacles.append(Vector2i.ZERO)
	expect(independent.units[0].hp == independent.units[0].max_hp and independent.units[0].cooldowns.is_empty(), "runtime stats isolated between battles")
	expect(Vector2i.ZERO not in independent.grid.obstacles and Vector2i.ZERO not in mission.map.blocked_cells, "grid state does not mutate shared configuration")

func run() -> void:
	var missions: Array[BattleMissionData] = MissionCatalog.missions()
	expect(missions.size() >= 2 and MissionCatalog.default_mission() in missions, "included scenarios discovered")
	for mission: BattleMissionData in missions:
		check_mission(mission)
	# No fixed count, index, instance name, or row ordering in objective/AI resolution.
	var renamed: BattleMissionData = copy_mission()
	renamed.participants.reverse()
	for index: int in range(renamed.participants.size()):
		var spawn: UnitSpawnData = renamed.participants[index]
		spawn.instance_id = "instance_%d" % index
		if spawn.definition.team == "neutral":
			renamed.protected_unit_id = spawn.instance_id
	var extra: UnitSpawnData = UnitSpawnData.new()
	extra.instance_id = "extra_guard"
	extra.definition = load("res://data/units/soldier.tres")
	extra.position = Vector2i.ZERO
	renamed.participants.append(extra)
	var b: BattleManager = BattleManager.new(renamed)
	var captor: TacticalUnit
	for unit: TacticalUnit in b.units:
		if unit.behavior == "capture":
			captor = unit
		if unit.team == "enemy" and unit.id != "extra_guard":
			unit.hp = 0
	expect(captor.capture_target == b.protected_unit(), "capture target independent of ID and order")
	expect(not b.check_end() and b.enemy_count() == 3, "victory not hardcoded to two enemies")
	b.unit_by_id("extra_guard").hp = 0
	expect(b.check_end() and b.outcome.status == "victory", "all configured enemies required")
	# Replace objectives by a new Resource subclass, without touching BattleManager or the view.
	var custom: BattleMissionData = copy_mission()
	var reach: LocationCondition = LocationCondition.new()
	reach.unit_id = "hero"
	reach.location = Vector2i(0, 4)
	reach.message = "Ubicación alcanzada."
	custom.victory_conditions = [reach]
	b = BattleManager.new(custom)
	expect(not b.check_end(), "custom objective initially pending")
	var reported: Array = []
	b.battle_completed.connect(func(id: String, outcome: Dictionary) -> void: reported.append([id, outcome]))
	b.selected = b.unit_by_id("hero")
	b.click(reach.location)
	expect(b.check_end() and b.outcome.reason == reach.message, "objective extension independent of visual map")
	expect(reported.size() == 1 and reported[0][1].status == "victory", "narrative can observe results")
	b.check_end()
	expect(reported.size() == 1, "completion emitted once")
	var guest_mission: BattleMissionData = copy_mission()
	var guest_definition: UnitDefinition = guest_mission.participants[0].definition.duplicate()
	guest_definition.definition_id = "guest_definition"
	guest_definition.display_name = "Unidad de prueba"
	guest_mission.participants[0].instance_id = "guest"
	guest_mission.participants[0].definition = guest_definition
	b = BattleManager.new(guest_mission)
	expect(b.unit_by_id("guest") != null and AbilitySystem.available(b.unit_by_id("guest"), "heavy"), "new definition and instance reuse abilities without code changes")
	expect(ArtLibrary.unit_texture(b.unit_by_id("guest")) != null, "art independent of instance identity")
	# Non-square topology and whitelist transitability use the same BFS.
	var map: BattleMapData = BattleMapData.new()
	map.map_id = "corridor"
	map.dimensions = Vector2i(13, 5)
	map.cell_size = 28
	map.walkable_cells = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)]
	map.blocked_cells = [Vector2i(2, 1)]
	var grid: GridManager = GridManager.new(map)
	var paths: Dictionary = MovementSystem.reachable(grid, [], Vector2i.ZERO, 10)
	expect(paths.has(Vector2i(1, 1)) and not paths.has(Vector2i(3, 1)) and not paths.has(Vector2i(0, 1)), "whitelist and obstacles both enforced")
	expect(Vector2i(0, 1) not in ThreatSystem.attack_cells(grid, Vector2i.ZERO), "attack range respects nonexistent terrain cells")
	map.spawn_points["entry"] = Vector2i(1, 1)
	var spawn_at_point: UnitSpawnData = UnitSpawnData.new()
	spawn_at_point.spawn_point = "entry"
	expect(spawn_at_point.cell(map) == Vector2i(1, 1), "named spawn points supported")
	map.dimensions = Vector2i(20, 20)
	map.cell_size = 60
	var fitted: BoardLayout = BoardLayout.new(map)
	expect(fitted.tile_size < map.cell_size and fitted.pixel(Vector2i(20, 20)).y <= 496, "presentation fits larger map without changing rules")
	var invalid: BattleMissionData = copy_mission()
	invalid.participants[1].position = invalid.participants[0].position
	expect(not invalid.validation_errors().is_empty(), "overlapping configuration rejected")
	invalid = copy_mission()
	invalid.map.blocked_cells.append(Vector2i(99, 99))
	expect(not invalid.validation_errors().is_empty(), "out of bounds map data rejected")
	# Both choices drive the same live controller and preserve the choice on restart.
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	expect(main.scenario_selector.item_count == missions.size(), "selector contains discovered missions")
	for index: int in range(main.scenario_selector.item_count):
		main.show_menu()
		main.scenario_selector.select(index)
		main.scenario_selector.item_selected.emit(index)
		var chosen: BattleMissionData = main.active_mission
		main.start_battle()
		await process_frame
		expect(main.battle.mission == chosen and main.battle.grid.size == chosen.map.dimensions, "menu launches selected configuration")
		expect(main.board.cell_at(main.board.layout.pixel(chosen.map.dimensions - Vector2i.ONE) + Vector2.ONE) == chosen.map.dimensions - Vector2i.ONE, "last cell mouse mapping")
		var actor: TacticalUnit = main.battle.allies()[0]
		main.on_cell(actor.cell)
		var reachable: Dictionary = MovementSystem.reachable(main.battle.grid, main.battle.units, actor.cell, actor.movement)
		var origin: Vector2i = actor.cell
		for cell: Vector2i in reachable:
			if cell != origin:
				main.board.set_cursor(cell)
				var expected: Array = main.board.preview_route()
				main.on_cell(cell)
				while main.board.busy:
					await process_frame
				expect(actor.cell == expected.back() and actor.moved, "shared view moves on chosen map")
				break
		main.undo_move()
		while main.board.busy:
			await process_frame
		expect(actor.cell == origin and not actor.moved, "shared undo on chosen map")
		main.end_turn()
		while main.enemy_running:
			await process_frame
		expect(main.battle.turns.number == 2 and not main.battle.ended, "same animated AI controller on chosen map")
		main.start_battle()
		expect(main.battle.mission == chosen and main.battle.turns.number == 1 and main.battle.capture.progress == 0, "restart preserves mission and resets runtime")
	main.show_menu()
	main.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("MAPS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
