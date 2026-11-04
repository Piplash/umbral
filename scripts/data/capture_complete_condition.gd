class_name CaptureCompleteCondition
extends BattleCondition

func evaluate(_units: Array, capture: CaptureSystem, _turns: TurnManager) -> bool:
	return capture.enabled and capture.progress >= capture.limit
