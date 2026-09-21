extends CanvasLayer

## Lightweight runtime performance readout. Press F3 to show or hide it.

const UPDATE_INTERVAL := 0.25
const GOOD_FPS := 55
const WARNING_FPS := 30

var _elapsed := 0.0
var _label: Label


func _ready() -> void:
	layer = 1000
	_label = Label.new()
	_label.name = "FpsLabel"
	_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_label.offset_left = -172.0
	_label.offset_top = 12.0
	_label.offset_right = -12.0
	_label.offset_bottom = 38.0
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	_label.add_theme_constant_override("outline_size", 5)
	add_child(_label)
	_update_readout()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= UPDATE_INTERVAL:
		_elapsed = fmod(_elapsed, UPDATE_INTERVAL)
		_update_readout()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		_label.visible = not _label.visible
		get_viewport().set_input_as_handled()


func _update_readout() -> void:
	var fps := Engine.get_frames_per_second()
	var frame_time_ms := 0.0 if fps <= 0 else 1000.0 / float(fps)
	_label.text = "FPS: %d  |  %.1f ms" % [fps, frame_time_ms]

	if fps >= GOOD_FPS:
		_label.add_theme_color_override("font_color", Color("7df58a"))
	elif fps >= WARNING_FPS:
		_label.add_theme_color_override("font_color", Color("ffd166"))
	else:
		_label.add_theme_color_override("font_color", Color("ff6868"))
