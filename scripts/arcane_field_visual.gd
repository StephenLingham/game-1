extends Node2D

var radius: float = 150.0
var _pulse_strength: float = 0.0

const FILL_COLOR := Color(0.55, 0.25, 0.95, 0.16)
const OUTLINE_COLOR := Color(0.78, 0.48, 1.0, 0.65)
const OUTLINE_WIDTH := 3.0

func _ready() -> void:
	z_index = -2

func _process(delta: float) -> void:
	if _pulse_strength > 0.0:
		_pulse_strength = move_toward(_pulse_strength, 0.0, delta * 5.0)
	queue_redraw()

func set_field_radius(r: float) -> void:
	if not is_equal_approx(radius, r):
		radius = r
		queue_redraw()

func pulse() -> void:
	_pulse_strength = 0.45

func _draw() -> void:
	var idle_pulse := 0.05 * sin(Time.get_ticks_msec() / 280.0)
	var fill := FILL_COLOR
	fill.a += idle_pulse + _pulse_strength * 0.25
	draw_circle(Vector2.ZERO, radius, fill)

	var outline := OUTLINE_COLOR
	outline.a += idle_pulse + _pulse_strength * 0.35
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 72, outline, OUTLINE_WIDTH, true)
