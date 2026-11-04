class_name MissionCatalog
extends RefCounted

const DEFAULT_MISSION: String = "res://data/missions/settlement.tres"
const DIRECTORY: String = "res://data/missions"

static func default_mission() -> BattleMissionData:
	return load(DEFAULT_MISSION) as BattleMissionData

static func missions() -> Array[BattleMissionData]:
	var result: Array[BattleMissionData] = []
	var directory: DirAccess = DirAccess.open(DIRECTORY)
	if directory == null:
		push_error("No se pudo abrir el directorio de misiones.")
		return result
	var names: PackedStringArray = directory.get_files()
	names.sort()
	for file: String in names:
		if file.ends_with(".tres") or file.ends_with(".tres.remap"):
			var path: String = DIRECTORY.path_join(file.trim_suffix(".remap"))
			var mission: BattleMissionData = load(path) as BattleMissionData
			if mission != null and not result.has(mission):
				result.append(mission)
	return result
