class_name ExplorationProp
extends Node2D

# Presentation only. Collisions remain explicit data owned by the map controller.
static var sheets: Dictionary = {}
var texture: Texture2D
var footprint: Rect2

static func texture_for(data: Dictionary) -> Texture2D:
	var path: String = data.sheet
	if not sheets.has(path):
		sheets[path] = load(path)
	if not data.has("region"):
		return sheets[path]
	var region: Array = data.region
	var result: AtlasTexture = AtlasTexture.new()
	result.atlas = sheets[path]
	result.region = Rect2(region[0], region[1], region[2], region[3])
	return result

func configure(image: Texture2D, rect: Rect2, depth: float = -1) -> void:
	texture = image
	position = Vector2(rect.get_center().x, rect.end.y if depth < 0 else depth)
	footprint = Rect2(rect.position - position, rect.size)
	queue_redraw()

func _draw() -> void:
	draw_texture_rect(texture, footprint, false)
