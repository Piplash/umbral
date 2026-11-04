class_name CaptureSystem
extends RefCounted

var progress: int = 0
var limit: int = 3
var enabled: bool = true

func attempt(captor: TacticalUnit, civil: TacticalUnit, grid: GridManager) -> bool:
	if enabled and captor != null and civil != null and captor.alive() and civil.alive() and not captor.jammed and grid.distance(captor.cell, civil.cell) == 1:
		progress += 1
		return true
	return false
