class_name EffectResolver
extends RefCounted

static func apply(effects: Array, state: WorldState) -> void:
	for effect: Dictionary in effects:
		var bucket: String = effect.get("bucket", "flags")
		if bucket not in ["flags", "choices", "prepared", "events", "examined", "conversations"]:
			push_error("Tipo de efecto no soportado: " + bucket)
			continue
		state.data[bucket][effect.key] = effect.get("value", true)
