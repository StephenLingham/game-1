extends Area2D

signal charged(shrine: Node2D)

@export var charge_radius: float = GameConstants.CHARGE_SHRINE_RADIUS
@export var charge_time: float = GameConstants.CHARGE_SHRINE_CHARGE_TIME

var charge_progress: float = 0.0
var _is_complete: bool = false
var _glow: Polygon2D
var _core: Polygon2D
var _spark: Polygon2D

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
	_glow = Polygon2D.new()
	_glow.color = Color(0.35, 0.8, 1.0, 0.18)
	_glow.polygon = _circle_points(42.0, 28)
	_glow.z_index = 6
	add_child(_glow)
	
	_core = Polygon2D.new()
	_core.color = Color(0.18, 0.72, 1.0, 0.55)
	_core.polygon = _circle_points(28.0, 24)
	_core.z_index = 7
	add_child(_core)
	
	_spark = Polygon2D.new()
	_spark.color = Color(0.92, 0.98, 1.0, 0.95)
	_spark.polygon = _circle_points(12.0, 18)
	_spark.z_index = 8
	add_child(_spark)

func _update_visuals() -> void:
	var fill: float = charge_progress / max(charge_time, 0.001)
	if _glow:
		_glow.scale = Vector2.ONE * lerp(0.90, 1.12, fill)
		_glow.modulate.a = lerp(0.18, 0.38, fill)
	if _core:
		_core.scale = Vector2.ONE * lerp(0.88, 1.10, fill)
		_core.modulate.a = lerp(0.55, 0.85, fill)
	if _spark:
		_spark.scale = Vector2.ONE * lerp(0.85, 1.35, fill)
		_spark.modulate.a = lerp(0.55, 1.0, fill)
		_spark.rotation = fill * TAU * 0.5

func _circle_points(radius: float, points_count: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(points_count):
		var angle = TAU * float(i) / float(points_count)
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	return pts
