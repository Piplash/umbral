class_name UnitDefinition
extends Resource

@export var definition_id: String = ""
@export var display_name: String = ""
@export_enum("ally", "enemy", "neutral") var team: String = "ally"
@export var max_hp: int = 1
@export var attack: int = 0
@export var defense: int = 0
@export var movement: int = 0
@export var abilities: Array[String] = []
@export_enum("player", "aggressive", "capture", "passive", "wander", "seek_shelter") var behavior: String = "player"
@export var art_key: String = ""
@export var sprite: Texture2D
@export var portrait: Texture2D
@export var tactical_color: Color = Color("70c6d6")
