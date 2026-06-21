extends Area2D

signal charged(shrine: Node2D)

@export var charge_radius: float = GameConstants.CHARGE_SHRINE_RADIUS
@export var charge_time: float = GameConstants.CHARGE_SHRINE_CHARGE_TIME

var charge_progress: float = 0.0
var _is_complete: bool = false
var _charge_ring: Polygon2D
var _radius_hint: Polygon2D
var _player_inside: bool = false

func _ready() -> void:
	add_to_group("shrines")
	var shape_node = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node and shape_node.shape is CircleShape2D:
		(shape_node.shape as CircleShape2D).radius = charge_radius
	_build_visuals()
	_update_visuals()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	monitoring = true

func _process(delta: float) -> void:
	if _is_complete:
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return
	
	if global_position.distance_to(player.global_position) <= charge_radius:
		charge_progress = min(charge_time, charge_progress + delta)
		_update_visuals()
		if charge_progress >= charge_time:
			_is_complete = true
			monitoring = false
			GameState.record_shrine_activated()
			emit_signal("charged", self)
	else:
		if charge_progress > 0.0:
			charge_progress = 0.0
			_update_visuals()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_update_visuals()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_update_visuals()

func _build_visuals() -> void:
	var sprite = get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.scale = Vector2.ONE * GameConstants.CHARGE_SHRINE_IMAGE_SCALE
		sprite.z_index = 2

	_radius_hint = Polygon2D.new()
	_radius_hint.color = Color(0.35, 0.85, 1.0, 0.5)
	_radius_hint.polygon = _circle_points(charge_radius, 64)
	_radius_hint.z_index = 0
	add_child(_radius_hint)

	_charge_ring = Polygon2D.new()
	_charge_ring.color = Color(1.0, 1.0, 1.0, 0.5)
	_charge_ring.polygon = _circle_points(24.0, 32)
	_charge_ring.z_index = 1
	add_child(_charge_ring)

	if sprite:
		move_child(_radius_hint, 0)
		move_child(_charge_ring, 1)

func _update_visuals() -> void:
	var player = get_tree().get_first_node_in_group("player")
	_player_inside = is_instance_valid(player) and global_position.distance_to(player.global_position) <= charge_radius
	var fill: float = charge_progress / max(charge_time, 0.001)

	if _radius_hint:
		_radius_hint.visible = _player_inside
		_radius_hint.scale = Vector2.ONE
		_radius_hint.modulate.a = 0.50

	if _charge_ring:
		_charge_ring.visible = true
		_charge_ring.scale = Vector2.ONE * lerp(0.20, charge_radius / 24.0, fill)
		_charge_ring.modulate.a = 0.35

func _circle_points(radius: float, points_count: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(points_count):
		var angle = TAU * float(i) / float(points_count)
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	return pts
