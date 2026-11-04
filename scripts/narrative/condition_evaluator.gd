class_name ConditionEvaluator
extends RefCounted

static func matches(conditions: Array, state: WorldState) -> bool:
	for condition: Dictionary in conditions:
		if condition.has("count"):
			var total: int = 0
			for path: Array in condition.count:
				if bool(at_path(state.data, path)):
					total += 1
			if total < int(condition.get("at_least", 1)):
				return false
			continue
		if condition.has("path"):
			if at_path(state.data, condition.path) != condition.get("value", true):
				return false
			continue
		var bucket: String = condition.get("bucket", "flags")
		if state.data.get(bucket, {}).get(condition.get("key", ""), false) != condition.get("value", true):
			return false
	return true

static func at_path(data: Dictionary, path: Array) -> Variant:
	var value: Variant = data
	for key: String in path:
		if not value is Dictionary or not value.has(key):
			return false
		value = value[key]
	return value
