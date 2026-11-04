class_name ConditionEvaluator
extends RefCounted

static func matches(conditions: Array, state: WorldState) -> bool:
	for condition: Dictionary in conditions:
		var bucket: String = condition.get("bucket", "flags")
		if state.data.get(bucket, {}).get(condition.get("key", ""), false) != condition.get("value", true):
			return false
	return true
