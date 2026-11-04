class_name BoardLayout
extends RefCounted

var origin: Vector2
var tile_size: int

func _init(map: BattleMapData) -> void:
	tile_size = map.cell_size
	# Preserve the authored origin when it fits; center/reduce only for larger maps.
	var available: Rect2 = Rect2(190, 128, 505, 368)
	if map.dimensions.x * tile_size > available.size.x or map.dimensions.y * tile_size > available.size.y:
		tile_size = maxi(1, mini(tile_size, floori(minf(available.size.x / map.dimensions.x, available.size.y / map.dimensions.y))))
		origin = available.position + (available.size - Vector2(map.dimensions * tile_size)) * 0.5
	elif map.board_origin == Vector2.ZERO or not available.encloses(Rect2(map.board_origin, Vector2(map.dimensions * tile_size))):
		origin = available.position + (available.size - Vector2(map.dimensions * tile_size)) * 0.5
	else:
		origin = map.board_origin

func pixel(cell: Vector2i) -> Vector2:
	return origin + Vector2(cell) * tile_size

func cell_at(point: Vector2) -> Vector2i:
	return Vector2i(floori((point.x - origin.x) / tile_size), floori((point.y - origin.y) / tile_size))
