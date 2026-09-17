extends Node2D
# Scene-owned, finite-lived attacks. Warning circles lock before damage.
var direction := Vector2.ZERO
var speed := 0.0
var radius := 12.0
var damage := 20
var warning := 0.0
var lifetime := 3.0
var tint := Color("ff7848")
var _age := 0.0
var _hit: Array[int] = []

func _ready() -> void:
	add_to_group("enemy_hazards")
	z_index = 3

func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= warning + lifetime:
		queue_free()
		return
	if _age >= warning:
		position += direction * speed * delta
		for ally in get_tree().get_nodes_in_group("allies"):
			if not is_instance_valid(ally) or not ally.has_method("take_damage"):
				continue
			if ally.get_instance_id() in _hit:
				continue
			if global_position.distance_to(ally.global_position) <= radius + 12.0:
				_hit.append(ally.get_instance_id())
				ally.take_damage(damage, self)
				if speed > 0.0:
					queue_free()
					break
	queue_redraw()

func _draw() -> void:
	if _age < warning:
		draw_circle(Vector2.ZERO, radius, Color(tint, 0.12))
		draw_arc(Vector2.ZERO, radius, 0, TAU, 48, Color(tint, 0.9), 2.0, true)
		draw_arc(Vector2.ZERO, radius * clampf(_age / warning, 0, 1), 0, TAU, 40, Color(tint, 0.65), 2.0, true)
	else:
		draw_circle(Vector2.ZERO, radius, Color(tint, 0.4))
		draw_circle(Vector2.ZERO, radius * 0.55, Color(tint.lightened(0.4), 0.9))
		if speed > 0:
			draw_line(Vector2.ZERO, -direction * 25, Color(tint, 0.5), radius, true)
