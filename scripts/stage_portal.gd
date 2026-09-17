extends Node2D

var destination := 1
var controller: Node
var _age := 0.0
var _entered := false
var _label: Label

func _ready() -> void:
	add_to_group("stage_portals")
	z_index = 8
	_label = Label.new()
	_label.position = Vector2(-240, -108)
	_label.size = Vector2(480, 65)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_label.add_theme_constant_override("shadow_outline_size", 5)
	add_child(_label)

func _physics_process(delta: float) -> void:
	_age += delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	_label.text = "ENTER PORTAL\n" + RunCampaign.NAMES[destination]
	# Avoid accidental instant teleport on a melee kill.
	if not _entered and _age > 0.6 and player and player.global_position.distance_to(global_position) < 48:
		_entered = true
		controller.call_deferred("enter_portal")
	queue_redraw()

func _draw() -> void:
	var color := Color("ff8653") if destination == 1 else Color("b8a0ff")
	draw_circle(Vector2.ZERO, 52, Color(0.02, 0.01, 0.05, 0.9))
	for i in range(4):
		var radius := 49.0 + sin(_age * 3 + i) * 4
		draw_arc(Vector2.ZERO, radius, _age + i * 1.57, _age + i * 1.57 + 1.0, 24, color, 4, true)
	for i in range(12):
		var angle := float(i) * TAU / 12 + _age
		draw_circle(Vector2.from_angle(angle) * (30 + sin(_age + i) * 8), 2, color.lightened(0.3))
