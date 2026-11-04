class_name OrnamentPanel
extends PanelContainer

var accent: Color = Color("947252")

func _ready() -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.047, 0.058, 0.95)
	style.border_color = accent.darkened(0.35)
	style.set_border_width_all(1)
	style.set_content_margin_all(10)
	add_theme_stylebox_override("panel", style)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var inset: Rect2 = Rect2(Vector2(3, 3), size - Vector2(6, 6))
	draw_rect(inset, Color(accent, 0.25), false)
	for corner: Vector2 in [Vector2(3, 3), Vector2(size.x - 3, 3), Vector2(3, size.y - 3), size - Vector2(3, 3)]:
		var sign_x: float = 1.0 if corner.x < size.x * 0.5 else -1.0
		var sign_y: float = 1.0 if corner.y < size.y * 0.5 else -1.0
		draw_line(corner + Vector2(0, sign_y * 10), corner + Vector2(sign_x * 10, 0), accent, 1)
		draw_circle(corner + Vector2(sign_x * 5, sign_y * 5), 1.3, accent.lightened(0.3))
