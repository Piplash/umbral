class_name BattleMapData
extends Resource

@export var map_id: String = ""
@export var dimensions: Vector2i = Vector2i.ONE
@export_range(8, 128) var cell_size: int = 32
@export var board_origin: Vector2 = Vector2.ZERO
@export var walkable_cells: Array[Vector2i] = []
@export var blocked_cells: Array[Vector2i] = []
@export var default_terrain: int = 0
@export var terrain: Dictionary = {}
@export var spawn_points: Dictionary = {}
@export var visual_scene: PackedScene

func contains(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < dimensions.x and cell.y < dimensions.y

func traversable(cell: Vector2i) -> bool:
	return contains(cell) and cell not in blocked_cells and (walkable_cells.is_empty() or cell in walkable_cells)

func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = []
	if map_id.is_empty() or dimensions.x <= 0 or dimensions.y <= 0 or cell_size <= 0:
		errors.append("El mapa necesita identificador, dimensiones y tamaño de casilla positivos.")
	for cell: Vector2i in blocked_cells + walkable_cells:
		if not contains(cell):
			errors.append("Casilla fuera del mapa: %s" % cell)
	for key: Variant in terrain:
		if not key is Vector2i or not contains(key):
			errors.append("Terreno fuera del mapa o clave inválida: %s" % str(key))
	for key: Variant in spawn_points:
		if not spawn_points[key] is Vector2i or not traversable(spawn_points[key]):
			errors.append("Punto de aparición inválido: %s" % str(key))
	return errors
