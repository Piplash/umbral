class_name ExplorationAtmosphere
extends Node2D

var content: Dictionary
var lights: Array[PointLight2D] = []
var energies: Array[float] = []
var phase: float = 0
var fire_texture: AtlasTexture

func _ready() -> void:
	ArtLibrary.load_art()
	fire_texture = AtlasTexture.new()
	fire_texture.atlas = ArtLibrary.environment
	var atlas_size: Vector2 = ArtLibrary.environment.get_size()
	fire_texture.region = Rect2(Vector2(0.082, 0.765) * atlas_size, Vector2(0.075, 0.087) * atlas_size)
	var shade: CanvasModulate = CanvasModulate.new()
	shade.color = Color(content.get("ambient", "aeb8ce"))
	add_child(shade)
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1, 1, 1, 0))
	var glow: GradientTexture2D = GradientTexture2D.new()
	glow.gradient = gradient
	glow.width = 128
	glow.height = 128
	glow.fill = GradientTexture2D.FILL_RADIAL
	glow.fill_from = Vector2(0.5, 0.5)
	glow.fill_to = Vector2(1, 0.5)
	for source: Dictionary in content.get("lights", []):
		var light: PointLight2D = PointLight2D.new()
		light.position = Vector2(source.position[0], source.position[1])
		light.color = Color(source.get("color", "ffb565"))
		light.texture = glow
		light.texture_scale = float(source.get("radius", 90)) / 64.0
		light.energy = float(source.get("energy", 0.6))
		energies.append(light.energy)
		lights.append(light)
		add_child(light)

func _process(delta: float) -> void:
	phase += delta
	for index: int in range(lights.size()):
		lights[index].energy = energies[index] * (1.0 + sin(phase * 1.6 + index * 2.1) * float(content.get("flicker", 0.025)))
	queue_redraw()

func _draw() -> void:
	for source: Dictionary in content.get("steam", []):
		var origin: Vector2 = Vector2(source.position[0], source.position[1])
		for index: int in range(5):
			var age: float = fmod(phase * 0.18 + index * 0.2, 1.0)
			var drift: Vector2 = Vector2(sin(age * 5 + index) * 5 + age * 9, -age * 48)
			draw_rect(Rect2((origin + drift).round(), Vector2(4 + floorf(age * 5), 4 + floorf(age * 5))), Color(0.65, 0.69, 0.74, (1 - age) * 0.15))

	for source: Dictionary in content.get("fires", []):
		var origin: Vector2 = Vector2(source.position[0], source.position[1])
		var height: float = float(source.get("height", 50))
		for index: int in range(3):
			var scale: float = 0.85 + sin(phase * 5 + index * 1.7) * 0.12
			var size: Vector2 = Vector2(height * 0.72, height) * scale
			var offset: Vector2 = Vector2((index - 1) * height * 0.22 + sin(phase * 2 + index) * 2, 0)
			draw_texture_rect(fire_texture, Rect2(origin + offset - Vector2(size.x * 0.5, size.y), size), false)
