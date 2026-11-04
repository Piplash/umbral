extends SceneTree

var checks: int = 0
var failures: int = 0

func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var b: BattleManager = BattleManager.new()
	var hero: TacticalUnit = b.units[0]
	var sister: TacticalUnit = b.units[1]
	var soldier: TacticalUnit = b.units[2]
	var captor: TacticalUnit = b.units[3]
	var civil: TacticalUnit = b.units[4]
	expect(b.grid.size == Vector2i(8, 8), "8x8 grid")
	var occupied: Dictionary = {}
	for unit: TacticalUnit in b.units:
		expect(b.grid.inside(unit.cell) and unit.cell not in b.grid.obstacles and not occupied.has(unit.cell), "legal unique spawn " + unit.id)
		occupied[unit.cell] = true
	var paths: Dictionary = MovementSystem.reachable(b.grid, b.units, hero.cell, 4)
	for cell: Vector2i in paths:
		expect(paths[cell].size() <= 5, "movement budget")
		for step: Vector2i in paths[cell]:
			expect(step not in b.grid.obstacles, "obstacles block")
			expect(step == hero.cell or b.grid.occupant(step, b.units) == null, "occupancy blocks")
	expect(not paths.has(Vector2i(7, 7)), "distant cell unreachable")
	b.selected = hero
	b.click(sister.cell)
	expect(hero.cell == Vector2i(1, 4), "cannot overlap ally")
	b.selected = hero
	b.click(Vector2i(0, 4))
	expect(hero.cell == Vector2i(0, 4) and hero.moved, "legal move")
	b.click(Vector2i(0, 3))
	expect(hero.cell == Vector2i(0, 4), "no duplicate movement")
	expect(CombatSystem.damage(hero, soldier) == 9, "basic damage")
	expect(CombatSystem.damage(hero, soldier, true) == 15, "heavy damage")
	hero.defending = true
	expect(CombatSystem.damage(soldier, hero) == 3, "defense halves")
	sister.defending = true
	captor.attack = 7
	expect(CombatSystem.damage(captor, sister) == 3, "defense rounds up")
	sister.hp = 35
	expect(AbilitySystem.heal(sister) == 5 and sister.hp == 40, "healing capped")
	AbilitySystem.consume(hero, "heavy")
	for index: int in range(2):
		AbilitySystem.new_phase(hero)
		expect(not AbilitySystem.available(hero, "heavy"), "two full heavy cooldown phases")
	AbilitySystem.new_phase(hero)
	expect(AbilitySystem.available(hero, "heavy"), "heavy ready third subsequent phase")
	for ability: String in ["jam", "heal"]:
		AbilitySystem.consume(sister, ability)
		AbilitySystem.new_phase(sister)
		expect(not AbilitySystem.available(sister, ability), "support full cooldown phase")
		AbilitySystem.new_phase(sister)
		expect(AbilitySystem.available(sister, ability), "support ready")
	captor.cell = civil.cell + Vector2i.RIGHT
	captor.jammed = true
	b.enemy_activation(captor)
	expect(b.capture.progress == 0 and not captor.jammed, "jam prevents capture once")
	b.enemy_activation(captor)
	expect(b.capture.progress == 1, "one capture per activation")
	captor.cell = Vector2i(7, 7)
	expect(b.capture.progress == 1, "capture progress persists")
	captor.cell = civil.cell + Vector2i.RIGHT
	b.enemy_activation(captor)
	b.enemy_activation(captor)
	expect(b.ended and b.capture.progress == 3, "capture defeat")
	b = BattleManager.new()
	b.units[0].hp = 0
	b.units[1].hp = 0
	expect(b.check_end(), "both twins defeated")
	b = BattleManager.new()
	b.units[2].hp = 0
	b.units[3].hp = 0
	expect(b.check_end() and b.results.defeated(b.units) == 2, "victory")
	b = BattleManager.new()
	expect(not b.ended and b.capture.progress == 0 and b.results.damage_received == 0 and b.turns.number == 1, "clean restart")
	# Attack before movement; attempted second action must leave health unchanged.
	hero = b.units[0]
	soldier = b.units[2]
	soldier.cell = hero.cell + Vector2i.RIGHT
	b.selected = hero
	b.choose("attack")
	b.click(soldier.cell)
	var hp: int = soldier.hp
	b.choose("attack")
	b.click(soldier.cell)
	expect(soldier.hp == hp and hero.acted and not hero.moved, "single action, movement retained")
	b.choose("move")
	b.click(Vector2i(0, 4))
	expect(hero.moved and hero.acted, "move after attack")
	# Enemy route and interference respect occupied cells and movement allowance.
	b = BattleManager.new()
	for enemy: TacticalUnit in [b.units[2], b.units[3]]:
		var route: Array = EnemyAI.plan(enemy, b.units, b.grid)
		expect(route.size() <= enemy.movement + 1, "AI movement allowance")
		for index: int in range(1, route.size()):
			expect(b.grid.is_walkable(route[index], b.units) and b.grid.distance(route[index - 1], route[index]) == 1, "AI legal path")
		enemy.jammed = true
		expect(EnemyAI.plan(enemy, b.units, b.grid) == [enemy.cell], "jam immobilizes")
	# Scene flow smoke test: menu, battle, pause, results, restart and menu.
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main: Control = scene.instantiate()
	root.add_child(main)
	expect(main.battle == null, "menu loads")
	main.start_battle()
	expect(main.battle.units.size() == 5 and main.board != null, "battle UI loads")
	main.toggle_pause()
	expect(main.paused, "pause opens")
	main.toggle_pause()
	expect(not main.paused, "pause closes")
	main.battle.units[2].hp = 0
	main.battle.units[3].hp = 0
	main.battle.check_end()
	expect(main.overlay != null, "result UI loads")
	main.start_battle()
	expect(not main.battle.ended and main.battle.units[2].hp == 40, "UI restart")
	main.show_menu()
	expect(main.battle == null, "return to menu")
	main.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("TESTS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
