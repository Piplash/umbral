class_name MissionFlowController
extends RefCounted

var world: WorldState = WorldState.new()
var phase: String = "exploration"
var prepared: BattleMissionData
var continuation: Dictionary = {}
var before_battle: Dictionary = {}

func consolidate(base: BattleMissionData, content: Dictionary) -> bool:
	if phase != "exploration":
		return false
	prepared = BattlePreparationResolver.prepare(base, world, content.modifiers)
	if not prepared.validation_errors().is_empty():
		push_error("Preparación inválida: " + "; ".join(prepared.validation_errors()))
		return false
	prepared.shelter_cells = []
	for cell: Array in content.shelters:
		prepared.shelter_cells.append(Vector2i(cell[0], cell[1]))
	before_battle = world.snapshot()
	phase = "cinematic"
	return true

func record_result(battle: BattleManager) -> void:
	if phase != "battle" or not battle.ended or battle.outcome.status == "ongoing":
		return
	world.restore(before_battle)
	var states: Dictionary = {}
	for unit: TacticalUnit in battle.units:
		states[unit.id] = {"alive": unit.alive(), "hp": unit.hp}
	var protected: TacticalUnit = battle.protected_unit()
	world.data.results[battle.mission.mission_id] = {"outcome": battle.outcome.duplicate(), "units": states, "villager_survived": protected != null and protected.alive() and battle.capture.progress < battle.capture.limit, "preparations": world.data.prepared.duplicate(), "events": world.data.events.duplicate()}
	world.data.characters = states
	world.data.events["battle_completed"] = battle.outcome.status == "victory"
	phase = "results"

func can_continue() -> bool:
	if phase != "results" or prepared == null or continuation.is_empty():
		return false
	var result: Dictionary = world.data.results.get(prepared.mission_id, {})
	return result.get("outcome", {}).get("status", "") == "victory" and not world.data.events.get(continuation.id, false)

func claim_continuation() -> String:
	if not can_continue():
		return ""
	world.data.events[continuation.id] = true
	phase = "aftermath"
	return continuation.path
