class_name ArtLibrary
extends RefCounted

static var environment: Texture2D
static var characters: Texture2D
const IDS: Array[String] = ["hero", "support", "soldier", "captor", "civil"]
const BASE_SPRITE_FOOTPRINT: float = 46.0

static func unit_texture(unit: TacticalUnit, portrait: bool = false) -> Texture2D:
	var override_texture: Texture2D = unit.definition.portrait if portrait else unit.definition.sprite
	return override_texture if override_texture != null else character(unit.definition.art_key, portrait)

static func load_art() -> void:
	if environment == null and ResourceLoader.exists("res://assets/art/environment.png"):
		environment = load("res://assets/art/environment.png")
	if characters == null and ResourceLoader.exists("res://assets/art/characters.png"):
		characters = load("res://assets/art/characters.png")

static func prop(index: int) -> Texture2D:
	load_art()
	if environment == null:
		return null
	var texture: AtlasTexture = AtlasTexture.new()
	texture.atlas = environment
	var cell: Vector2 = environment.get_size() / 4.0
	texture.region = Rect2(Vector2(index % 4, floori(index / 4.0)) * cell, cell)
	return texture

static func character(id: String, portrait: bool = false) -> Texture2D:
	load_art()
	if characters == null:
		return null
	var index: int = IDS.find(id)
	if index < 0:
		return null
	var texture: AtlasTexture = AtlasTexture.new()
	texture.atlas = characters
	var dimensions: Vector2 = characters.get_size()
	# Atlas regions are normalized to the inspected generated sheet, not guessed sprite sizes.
	if portrait:
		texture.region = Rect2(Vector2(index * 0.2 + 0.015, 0.612) * dimensions, Vector2(0.182, 0.205) * dimensions)
	else:
		texture.region = Rect2(Vector2(index * 0.2, 0.175) * dimensions, Vector2(0.2, 0.325) * dimensions)
	return texture
