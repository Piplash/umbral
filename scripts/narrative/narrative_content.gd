class_name NarrativeContent
extends RefCounted

static func read(path: String, depth: int = 0) -> Dictionary:
	if depth > 8:
		push_error("Herencia narrativa circular o demasiado profunda: " + path)
		return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not value is Dictionary:
		push_error("Contenido narrativo inválido: " + path)
		return {}
	var data: Dictionary = value
	if data.has("base_content"):
		return merge(read(data.base_content, depth + 1), data)
	return data

static func merge(base: Dictionary, patch: Dictionary) -> Dictionary:
	var result: Dictionary = base.duplicate(true)
	for key: String in patch:
		if patch[key] is Dictionary and result.get(key) is Dictionary:
			result[key] = merge(result[key], patch[key])
		else:
			result[key] = patch[key].duplicate(true) if patch[key] is Array or patch[key] is Dictionary else patch[key]
	return result

static func environment(data: Dictionary, id: String, depth: int = 0) -> Dictionary:
	if depth > 8:
		push_error("Herencia ambiental circular: " + id)
		return {}
	var patch: Dictionary = data.get("environments", {}).get(id, {})
	if patch.has("base_environment"):
		return merge(environment(data, patch.base_environment, depth + 1), patch)
	return patch
