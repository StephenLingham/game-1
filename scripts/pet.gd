extends CharacterBody2D
class_name RunPet

@export var pet_type: String = "chestling"
@export var move_speed: float = 260.0
@export var damage: int = 10
@export var max_health: int = 1
@export var lifetime: float = 20.0
@export var invulnerable: bool = false

var health: int = 1
var attack_cooldown: float = 0.6
var _attack_timer: float = 0.0
var _cat_dash_timer: float = 1.0
var _cat_dash_active: bool = false
var _cat_dash_direction: Vector2 = Vector2.RIGHT
var _cat_dash_speed: float = 1100.0

@onready var visual: ColorRect = $Visual

func _ready() -> void:
	add_to_group("pets")
	if not invulnerable:
		add_to_group("allies")
	health = max_health
	_update_visuals()

func _physics_process(delta: float) -> void:
	if lifetime > 0.0:
		lifetime -= delta
		if lifetime <= 0.0:
			queue_free()
			return

	if _attack_timer > 0.0:
		_attack_timer -= delta

	match pet_type:
		"cat":
			_process_cat(delta)
		_:
			_process_chaser(delta)

func _process_chaser(delta: float) -> void:
	var target = _get_nearest_enemy()
	if not is_instance_valid(target):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_target: Vector2 = target.global_position - global_position
	if to_target.length() <= 28.0:
		velocity = Vector2.ZERO
		if _attack_timer <= 0.0 and target.has_method("take_damage"):
			_attack_timer = attack_cooldown
			target.take_damage(damage, "pet")
	else:
		velocity = to_target.normalized() * move_speed
	move_and_slide()

func _process_cat(delta: float) -> void:
	if not _cat_dash_active:
		_cat_dash_timer -= delta
		if _cat_dash_timer <= 0.0:
			_start_cat_dash()
		return

	velocity = _cat_dash_direction * _cat_dash_speed
	move_and_slide()
	_destroy_touched_enemies()

	var cam := get_viewport().get_camera_2d()
	var center := cam.get_screen_center_position() if cam else global_position
	var viewport_size := get_viewport_rect().size
	if global_position.x > center.x + viewport_size.x:
		_cat_dash_active = false
		_cat_dash_timer = 8.0
		velocity = Vector2.ZERO

func _start_cat_dash() -> void:
	var cam := get_viewport().get_camera_2d()
	var center := cam.get_screen_center_position() if cam else global_position
	var viewport_size := get_viewport_rect().size
	global_position = Vector2(center.x - viewport_size.x * 0.75, center.y + randf_range(-viewport_size.y * 0.35, viewport_size.y * 0.35))
	_cat_dash_direction = Vector2.RIGHT
	_cat_dash_active = true
	velocity = _cat_dash_direction * _cat_dash_speed

func _destroy_touched_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and global_position.distance_to(enemy.global_position) <= 48.0:
			enemy.take_damage(max(enemy.health, damage), "ninja_wizard_cat")

func take_damage(amount: int = 1, _attacker: Node2D = null) -> void:
	if invulnerable or amount <= 0:
		return
	health -= amount
	if health <= 0:
		queue_free()

func _get_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_dist := INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var dist := global_position.distance_squared_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest

func _update_visuals() -> void:
	match pet_type:
		"cat":
			visual.color = Color(0.25, 0.35, 0.95, 1.0)
			visual.size = Vector2(44, 24)
			visual.position = -visual.size / 2.0
			move_speed = 0.0
			attack_cooldown = 0.0
		"spirit":
			visual.color = Color(0.75, 0.95, 1.0, 0.85)
			visual.size = Vector2(16, 16)
			visual.position = -visual.size / 2.0
			move_speed = 320.0
			attack_cooldown = 0.35
		_:
			visual.color = Color(0.95, 0.8, 0.35, 1.0)
			visual.size = Vector2(18, 18)
			visual.position = -visual.size / 2.0
