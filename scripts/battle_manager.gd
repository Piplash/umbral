class_name BattleManager
extends RefCounted

signal changed
signal event(message: String)
signal impact(cell: Vector2i, text: String, color: Color)
signal finished(won: bool)
signal animation_requested(unit_id: String, animation: String)
signal route_requested(unit_id: String, route: Array)
signal invalid_action
signal sound_requested(cue: String)
signal battle_completed(mission_id: String, outcome: Dictionary)

var mission: BattleMissionData
var grid: GridManager
var objectives: ObjectiveSystem
var outcome: Dictionary = {"status": "ongoing", "reason": ""}
var configuration_errors: PackedStringArray = []
var turns: TurnManager = TurnManager.new()
var capture: CaptureSystem = CaptureSystem.new()
var results: BattleResults = BattleResults.new()
var units: Array = []
var selected: TacticalUnit
var mode: String = "move"
var ended: bool = false
var movement_origins: Dictionary = {}
var movement_routes: Dictionary = {}

func _init(data: BattleMissionData = null) -> void:
	mission = data if data != null else MissionCatalog.default_mission()
	configuration_errors = mission.validation_errors()
	if not configuration_errors.is_empty():
		push_error("Configuración de misión inválida: " + "; ".join(configuration_errors))
		ended = true
		return
	grid = GridManager.new(mission.map)
	objectives = ObjectiveSystem.new(mission)
	capture.limit = mission.capture_limit
	capture.enabled = not mission.protected_unit_id.is_empty()
	for spawn: UnitSpawnData in mission.participants:
		units.append(TacticalUnit.new(spawn.definition.definition_id, spawn.cell(mission.map), spawn.definition, spawn.instance_id))
	for unit: TacticalUnit in units:
		if unit.behavior == "capture":
			unit.capture_target = unit_by_id(mission.protected_unit_id)

func unit_by_id(instance_id: String) -> TacticalUnit:
	for unit: TacticalUnit in units:
		if unit.id == instance_id:
			return unit
	return null

func protected_unit() -> TacticalUnit:
	return unit_by_id(mission.protected_unit_id)

func enemy_count() -> int:
	return units.filter(func(unit: TacticalUnit) -> bool: return unit.team == "enemy").size()

func allies() -> Array:
	return units.filter(func(u: TacticalUnit) -> bool: return u.team == "ally" and u.alive())

func invalid(message: String) -> void:
	invalid_action.emit()
	event.emit(message)
	changed.emit()

func targets() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if selected == null or selected.acted or not AbilitySystem.RANGES.has(mode):
		return cells
	for target: TacticalUnit in units:
		var correct_team: bool = target.team == "ally" if mode == "heal" else target.team == "enemy"
		if target.alive() and correct_team and grid.distance(selected.cell, target.cell) <= int(AbilitySystem.RANGES[mode]):
			cells.append(target.cell)
	return cells

func click(cell: Vector2i) -> void:
	if ended or turns.phase != "ally" or not grid.inside(cell):
		return
	var target: TacticalUnit = grid.occupant(cell, units)
	if selected != null and mode != "move":
		if cell not in targets():
			invalid("Objetivo inválido para esta acción.")
			return
		perform(target)
		return
	if target != null and target.team == "ally":
		selected = target
		mode = "move"
		event.emit("%s seleccionado. Mueve o elige una acción." % target.unit_name)
		changed.emit()
		return
	if selected == null:
		invalid("Selecciona una unidad aliada.")
		return
	if selected.moved:
		invalid("Ya utilizó su movimiento. Elige una acción.")
		return
	var paths: Dictionary = MovementSystem.reachable(grid, units, selected.cell, selected.movement)
	if paths.has(cell) and cell != selected.cell:
		movement_origins[selected.id] = selected.cell
		movement_routes[selected.id] = paths[cell].duplicate()
		move_unit(selected, paths[cell])
		selected.moved = true
		check_end()
		event.emit("%s se desplaza a %s%d." % [selected.unit_name, char(65 + cell.x), cell.y + 1])
		changed.emit()
	else:
		invalid("Casilla ocupada, bloqueada o fuera de alcance.")

func move_unit(unit: TacticalUnit, route: Array) -> void:
	if route.size() <= 1:
		return
	unit.cell = route.back()
	route_requested.emit(unit.id, route.duplicate())

func undo_route(unit: TacticalUnit) -> Array:
	if ended or turns.phase != "ally" or unit == null or unit.team != "ally" or not unit.alive() or unit.acted or not unit.moved or not movement_origins.has(unit.id):
		return []
	var paths: Dictionary = MovementSystem.reachable(grid, units, unit.cell, grid.size.x * grid.size.y)
	return paths.get(movement_origins[unit.id], [])

func undo_movement() -> bool:
	var route: Array = undo_route(selected)
	if route.is_empty():
		invalid("No se puede deshacer este movimiento: origen ocupado o acción comprometida.")
		return false
	move_unit(selected, route)
	selected.moved = false
	movement_origins.erase(selected.id)
	movement_routes.erase(selected.id)
	mode = "move"
	check_end()
	event.emit("%s regresa a su posición inicial." % selected.unit_name)
	changed.emit()
	return true

func damage_preview(attacker: TacticalUnit, target: TacticalUnit, action: String) -> Dictionary:
	if attacker == null or target == null or not target.alive() or action not in ["attack", "heavy"]:
		return {}
	var amount: int = mini(target.hp, CombatSystem.damage(attacker, target, action == "heavy"))
	return {"name": target.unit_name, "hp": target.hp, "damage": amount, "remaining": maxi(0, target.hp - amount), "action": "Ataque básico" if action == "attack" else AbilitySystem.LABELS.heavy}

func choose(action: String) -> void:
	if ended or turns.phase != "ally" or selected == null:
		return
	if action == "move":
		mode = "move"
		check_end()
		changed.emit()
		return
	if selected.acted:
		invalid("La acción de este personaje ya fue utilizada.")
		return
	if action in ["defend", "wait"]:
		sound_requested.emit("confirm")
		selected.acted = true
		selected.defending = action == "defend"
		# Waiting explicitly relinquishes both resources; defending preserves movement.
		if action == "wait":
			selected.moved = true
		event.emit("%s: %s." % [selected.unit_name, "defensa activa" if action == "defend" else "espera"])
		mode = "move"
		changed.emit()
		return
	if action != "attack" and not AbilitySystem.available(selected, action):
		invalid("Habilidad en enfriamiento.")
		return
	mode = action
	changed.emit()

func perform(target: TacticalUnit) -> void:
	sound_requested.emit("heal" if mode == "heal" else "jam" if mode == "jam" else "attack")
	if mode in ["heal", "jam"]:
		animation_requested.emit(selected.id, "attack")
	if mode == "heal":
		var healed: int = AbilitySystem.heal(target)
		impact.emit(target.cell, "+%d" % healed, Color("86efac"))
		event.emit("%s cura %d PV a %s." % [selected.unit_name, healed, target.unit_name])
	elif mode == "jam":
		target.jammed = true
		impact.emit(target.cell, "BLOQUEO", Color("c4b5fd"))
		event.emit("Interferencia: %s no podrá moverse ni capturar esta fase." % target.unit_name)
	else:
		strike(selected, target, mode == "heavy")
	if mode != "attack":
		AbilitySystem.consume(selected, mode)
		results.abilities_used += 1
	selected.acted = true
	mode = "move"
	check_end()
	changed.emit()

func strike(attacker: TacticalUnit, target: TacticalUnit, heavy: bool = false) -> void:
	var amount: int = CombatSystem.hit(attacker, target, heavy)
	animation_requested.emit(attacker.id, "attack")
	animation_requested.emit(target.id, "hurt" if target.alive() else "defeat")
	sound_requested.emit("impact")
	if target.team == "ally":
		sound_requested.emit("damage")
	if not target.alive():
		sound_requested.emit("unit_defeat")
	if target.team == "ally":
		results.damage_received += amount
	impact.emit(target.cell, "−%d" % amount, Color("fda4af"))
	event.emit("%s → %s: %d de daño.%s" % [attacker.unit_name, target.unit_name, amount, " Derrotado." if not target.alive() else ""])

func check_end() -> bool:
	if ended:
		return true
	outcome = objectives.evaluate(units, capture, turns)
	if outcome.status != "ongoing":
		ended = true
		turns.phase = "ended"
		finished.emit(outcome.status == "victory")
		battle_completed.emit(mission.mission_id, {"status": outcome.status, "reason": outcome.reason, "turns": turns.number, "enemies_defeated": results.defeated(units), "damage_received": results.damage_received, "abilities_used": results.abilities_used})
	return ended

func enemy_activation(enemy: TacticalUnit) -> void:
	if not enemy.alive() or ended:
		return
	enemy_move(enemy)
	enemy_action(enemy)

func start_allied_phase() -> void:
	if ended:
		return
	turns.start_allies(units)
	movement_origins.clear()
	movement_routes.clear()
	check_end()
	changed.emit()

func enemy_move(enemy: TacticalUnit) -> void:
	if not enemy.alive() or ended:
		return
	var target: TacticalUnit = EnemyAI.attack_target(enemy, units, grid)
	if enemy.behavior == "passive":
		return
	if enemy.behavior != "aggressive" or target == null:
		var route: Array = EnemyAI.plan(enemy, units, grid)
		if not route.is_empty():
			move_unit(enemy, route)
			check_end()

func enemy_action(enemy: TacticalUnit) -> void:
	if not enemy.alive() or ended:
		return
	var civil: TacticalUnit = enemy.capture_target
	if enemy.behavior == "capture" and capture.attempt(enemy, civil, grid):
		event.emit("Captura en curso: %d/%d. ¡Protege a %s!" % [capture.progress, capture.limit, civil.unit_name])
		impact.emit(civil.cell, "%d/%d" % [capture.progress, capture.limit], Color("fbbf24"))
	else:
		var target: TacticalUnit = EnemyAI.attack_target(enemy, units, grid)
		if target != null:
			sound_requested.emit("attack")
			strike(enemy, target)
		else:
			event.emit("%s %s." % [enemy.unit_name, "sufre interferencia" if enemy.jammed else "espera"])
	enemy.jammed = false
	check_end()
	changed.emit()
