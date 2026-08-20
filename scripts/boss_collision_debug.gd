extends Node2D

const BODY_FILL := Color(0.0, 0.8, 1.0, 0.16)
const BODY_OUTLINE := Color(0.0, 0.9, 1.0, 0.95)
const HITBOX_FILL := Color(1.0, 0.12, 0.12, 0.12)
const HITBOX_OUTLINE := Color(1.0, 0.18, 0.18, 0.95)

var _body_radius: float = 0.0
var _hitbox_radius: float = 0.0

func set_radii(body_radius: float, hitbox_radius: float) -> void:
	_body_radius = body_radius
	_hitbox_radius = hitbox_radius
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, _hitbox_radius, HITBOX_FILL)
	draw_arc(Vector2.ZERO, _hitbox_radius, 0.0, TAU, 96, HITBOX_OUTLINE, 3.0, true)
	draw_circle(Vector2.ZERO, _body_radius, BODY_FILL)
	draw_arc(Vector2.ZERO, _body_radius, 0.0, TAU, 96, BODY_OUTLINE, 3.0, true)
