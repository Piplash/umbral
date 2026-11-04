class_name WorldState
extends RefCounted

var data: Dictionary = {"flags": {}, "choices": {}, "conversations": {}, "examined": {}, "prepared": {}, "characters": {}, "events": {}, "results": {}}

func snapshot() -> Dictionary:
	return data.duplicate(true)

func restore(value: Dictionary) -> void:
	data = value.duplicate(true)
