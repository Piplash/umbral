class_name TacticalUnit
extends RefCounted

var definition: UnitDefinition
var behavior: String
var capture_target: TacticalUnit
var id: String
var unit_name: String
var team: String
var hp: int
var max_hp: int
var attack: int
var defense: int
var movement: int
var cell: Vector2i
var abilities: Array
var moved: bool = false
var acted: bool = false
var defending: bool = false
var jammed: bool = false
var cooldowns: Dictionary = {}

func _init(kind: String, position: Vector2i, data: UnitDefinition = null, instance_id: String = "") -> void:
	definition = data if data != null else load("res://data/units/%s.tres" % kind) as UnitDefinition
	id = instance_id if not instance_id.is_empty() else kind
	unit_name = definition.display_name
	team = definition.team
	behavior = definition.behavior
	max_hp = definition.max_hp
	hp = max_hp
	attack = definition.attack
	defense = definition.defense
	movement = definition.movement
	abilities = definition.abilities.duplicate()
	cell = position

func alive() -> bool:
	return hp > 0
