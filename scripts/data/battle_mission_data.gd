class_name BattleMissionData
extends Resource

@export var mission_id: String = ""
@export var display_name: String = ""
@export var victory_title: String = "MISIÓN CUMPLIDA"
@export var defeat_title: String = "DEFENSA FALLIDA"
@export var map: BattleMapData
@export var participants: Array[UnitSpawnData] = []
@export_multiline var objective_text: String = ""
@export var shelter_cells: Array[Vector2i] = []
@export var preparation_messages: Array[String] = []
@export var protected_unit_id: String = ""
@export_range(1, 100) var capture_limit: int = 3
@export var victory_conditions: Array[BattleCondition] = []
@export var defeat_conditions: Array[BattleCondition] = []

func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = []
	if mission_id.is_empty() or map == null:
		errors.append("La misión necesita identificador y mapa.")
		return errors
	errors.append_array(map.validation_errors())
	var ids: Dictionary = {}
	var occupied: Dictionary = {}
	for spawn: UnitSpawnData in participants:
		if spawn == null or spawn.definition == null:
			errors.append("Aparición sin definición de unidad.")
			continue
		if spawn.instance_id.is_empty() or ids.has(spawn.instance_id):
			errors.append("Identificador de instancia vacío o repetido: %s" % spawn.instance_id)
		ids[spawn.instance_id] = true
		if not spawn.spawn_point.is_empty() and not map.spawn_points.has(spawn.spawn_point):
			errors.append("Punto de aparición inexistente: %s" % spawn.spawn_point)
		var cell: Vector2i = spawn.cell(map)
		if not map.traversable(cell) or occupied.has(cell):
			errors.append("Posición inválida u ocupada: %s" % cell)
		occupied[cell] = true
		if spawn.definition.definition_id.is_empty() or spawn.definition.max_hp <= 0 or spawn.definition.movement < 0 or spawn.definition.attack < 0 or spawn.definition.defense < 0:
			errors.append("Estadísticas inválidas: %s" % spawn.instance_id)
		if spawn.definition.team not in ["ally", "enemy", "neutral"] or spawn.definition.behavior not in ["player", "aggressive", "capture", "passive", "wander", "seek_shelter", "flanker"]:
			errors.append("Equipo o comportamiento inválido: %s" % spawn.instance_id)
	if not protected_unit_id.is_empty() and not ids.has(protected_unit_id):
		errors.append("La unidad protegida no participa en la misión.")
	if not protected_unit_id.is_empty() and capture_limit <= 0:
		errors.append("El límite de captura debe ser positivo.")
	if victory_conditions.is_empty() or defeat_conditions.is_empty():
		errors.append("Configura condiciones de victoria y derrota.")
	for condition: BattleCondition in victory_conditions + defeat_conditions:
		if condition == null:
			errors.append("Condición nula.")
	return errors
