class_name UmbralAudio
extends Node

signal cue_played(cue: String, bus: String)
const BUSES: Array[String] = ["Master", "Music", "SFX", "UI"]
const UI_CUES: Array[String] = ["navigate", "select", "confirm", "cancel", "invalid", "turn", "pause"]
var volumes: Dictionary = {"Master": 0.8, "Music": 0.5, "SFX": 0.7, "UI": 0.45}
var muted: Dictionary = {"SFX": false, "UI": false}
var clips: Dictionary = {}
var sfx: AudioStreamPlayer
var ui: AudioStreamPlayer
var queue: Array[String] = []
var last_navigation: String = ""
var last_cue: String = ""
var last_frame: int = -1
var settings_path: String = "user://audio.cfg"
var pending_ui: String = ""
var ui_scheduled: bool = false
var sfx_scheduled: bool = false
var combat_paused: bool = false

func _ready() -> void:
	for bus: String in BUSES:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	sfx = AudioStreamPlayer.new()
	sfx.bus = "SFX"
	add_child(sfx)
	sfx.finished.connect(schedule_sfx)
	ui = AudioStreamPlayer.new()
	ui.bus = "UI"
	add_child(ui)
	load_preferences()

func load_preferences() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(settings_path)
	for bus: String in BUSES:
		set_volume(bus, float(config.get_value("volume", bus, volumes[bus])), false)
	for bus: String in muted:
		set_muted(bus, bool(config.get_value("muted", bus, false)), false)

func save_preferences() -> void:
	var config: ConfigFile = ConfigFile.new()
	for bus: String in BUSES:
		config.set_value("volume", bus, volumes[bus])
	for bus: String in muted:
		config.set_value("muted", bus, muted[bus])
	config.save(settings_path)

func set_volume(bus: String, value: float, save: bool = true) -> void:
	volumes[bus] = clampf(value, 0, 1)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), linear_to_db(maxf(0.0001, volumes[bus])))
	if save:
		save_preferences()

func set_muted(bus: String, value: bool, save: bool = true) -> void:
	muted[bus] = value
	AudioServer.set_bus_mute(AudioServer.get_bus_index(bus), value)
	if save:
		save_preferences()

func navigate(option: String) -> void:
	if option == last_navigation:
		return
	last_navigation = option
	play("navigate")

func stream(cue: String) -> AudioStream:
	if not clips.has(cue):
		clips[cue] = load("res://assets/audio/%s.wav" % cue)
	return clips[cue]

func play(cue: String) -> void:
	var frame: int = Engine.get_process_frames()
	if cue == last_cue and frame == last_frame:
		return
	last_cue = cue
	last_frame = frame
	if cue in UI_CUES:
		# Coalesce focus/mouse/click changes in one event cycle before opening playback.
		if cue != "navigate" or pending_ui.is_empty():
			pending_ui = cue
		if not ui_scheduled:
			ui_scheduled = true
			flush_ui.call_deferred()
	else:
		queue.append(cue)
		if not sfx.playing:
			schedule_sfx()

func flush_ui() -> void:
	ui_scheduled = false
	if pending_ui.is_empty() or not playback_allowed():
		return
	var cue: String = pending_ui
	pending_ui = ""
	ui.stop()
	ui.stream = stream(cue)
	ui.play()
	cue_played.emit(cue, "UI")

func schedule_sfx() -> void:
	if not sfx_scheduled:
		sfx_scheduled = true
		next_sfx.call_deferred()

func next_sfx() -> void:
	sfx_scheduled = false
	if queue.is_empty() or sfx.playing or combat_paused or not playback_allowed():
		return
	var cue: String = queue.pop_front()
	sfx.stream = stream(cue)
	sfx.play()
	cue_played.emit(cue, "SFX")

func playback_allowed() -> bool:
	if not is_inside_tree():
		return false
	var ancestor: Node = self
	while ancestor != null:
		if ancestor.is_queued_for_deletion():
			return false
		ancestor = ancestor.get_parent()
	return true

func clear_combat() -> void:
	queue.clear()
	combat_paused = false
	if sfx != null:
		sfx.stop()
		sfx.stream_paused = false
	last_navigation = ""

func set_combat_paused(value: bool) -> void:
	combat_paused = value
	sfx.stream_paused = value
	if not value and not queue.is_empty() and not sfx.playing:
		schedule_sfx()

func _exit_tree() -> void:
	pending_ui = ""
	queue.clear()
	if sfx != null:
		sfx.stop()
		sfx.stream = null
	if ui != null:
		ui.stop()
		ui.stream = null
	clips.clear()
