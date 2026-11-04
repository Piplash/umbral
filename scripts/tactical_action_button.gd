class_name TacticalActionButton
extends Button

var icon_kind: String = "move"

func _draw() -> void:
	var ink: Color = Color("cdb788") if not disabled else Color("626568")
	var p: Vector2 = Vector2(18, size.y * 0.5)
	match icon_kind:
		"attack", "heavy":
			draw_line(p + Vector2(-6, 7), p + Vector2(7, -7), ink, 2)
			draw_line(p + Vector2(-7, 1), p + Vector2(0, 7), ink, 2)
			draw_line(p + Vector2(2, -5), p + Vector2(7, -7), ink, 2)
		"defend":
			draw_polyline(PackedVector2Array([p + Vector2(-6, -7), p + Vector2(0, -9), p + Vector2(6, -7), p + Vector2(5, 2), p + Vector2(0, 8), p + Vector2(-5, 2), p + Vector2(-6, -7)]), ink, 1)
		"wait":
			draw_line(p + Vector2(-6, -7), p + Vector2(6, -7), ink, 1)
			draw_line(p + Vector2(-6, 7), p + Vector2(6, 7), ink, 1)
			draw_line(p + Vector2(-5, -6), p + Vector2(5, 6), ink, 1)
			draw_line(p + Vector2(5, -6), p + Vector2(-5, 6), ink, 1)
		"skill", "jam":
			for angle: float in [0.0, PI / 4, PI / 2, PI * 0.75]:
				var offset: Vector2 = Vector2.from_angle(angle) * 8
				draw_line(p - offset, p + offset, ink, 1)
		"heal":
			draw_line(p + Vector2(-6, 0), p + Vector2(6, 0), ink, 3)
			draw_line(p + Vector2(0, -6), p + Vector2(0, 6), ink, 3)
		_:
			draw_line(p + Vector2(0, 8), p + Vector2(0, -7), ink, 1)
			draw_line(p + Vector2(-5, -2), p + Vector2(0, -7), ink, 1)
			draw_line(p + Vector2(5, -2), p + Vector2(0, -7), ink, 1)
