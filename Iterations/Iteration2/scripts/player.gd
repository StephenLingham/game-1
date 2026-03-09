extends CharacterBody2D

@export var move_speed: float = 220.0
@export var max_health: int = 100

# Base weapon stats (run + meta modifies these)
@export var base_damage: int = 10
@export var base_attack_interval: float = 0.35  # seconds per shot

var health: int

# Click / tap-to-move target (used especially on mobile)
var _click_target: Vector2 = Vector2.ZERO
var _has_click_target: bool = false

@onready var shoot_timer: Timer = $ShootTimer
@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	health = max_health
	hitbox.body_entered.connect(_on_body_entered)
	_configure_shoot_timer()

func _physics_process(_delta: float) -> void:
	var input_vec := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Keyboard / controller input takes priority when present
	if input_vec.length() > 0.0:
		_has_click_target = false
		velocity = input_vec.normalized() * move_speed
	elif _has_click_target:
		var to_target := _click_target - global_position
		if to_target.length() <= 4.0:
			_has_click_target = false
			velocity = Vector2.ZERO
		else:
			velocity = to_target.normalized() * move_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	# Support tap / click-to-move, mainly for mobile
	if event is InputEventScreenTouch and event.pressed:
		_set_click_target(event.position)
	elif event is InputEventScreenDrag:
		_set_click_target(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_set_click_target(event.position)

func _set_click_target(screen_pos: Vector2) -> void:
	var world_pos := screen_pos
	var cam := get_viewport().get_camera_2d()
	if cam:
		world_pos = cam.screen_to_world(screen_pos)
	_click_target = world_pos
	_has_click_target = true

func _configure_shoot_timer() -> void:
	shoot_timer.timeout.connect(_on_shoot_timer)
	shoot_timer.one_shot = false
	shoot_timer.autostart = true
	_update_attack_speed()

func _update_attack_speed() -> void:
	var atk_mult := GameState.get_atkspd_multiplier() * GameState.run_atkspd_mult
	var interval := base_attack_interval / max(atk_mult, 0.05)
	shoot_timer.wait_time = max(interval, 0.05)
	if not shoot_timer.is_stopped():
		shoot_timer.start()

func get_damage() -> int:
	var dmg := float(base_damage + GameState.run_damage_bonus)
	dmg *= GameState.get_damage_multiplier()
	return int(round(dmg))

func _on_shoot_timer() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return

	var nearest: Node2D = null
	var best_d2 := INF
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var d2 := global_position.distance_squared_to(e.global_position)
		if d2 < best_d2:
			best_d2 = d2
			nearest = e

	if nearest == null:
		return

	var dir := (nearest.global_position - global_position).normalized()
	var bullet := preload("res://scenes/Bullet.tscn").instantiate()
	bullet.global_position = global_position
	bullet.direction = dir
	bullet.damage = get_damage()
	get_tree().current_scene.get_node("BulletContainer").add_child(bullet)

func apply_damage(amount: int) -> void:
	health = max(health - amount, 0)
	if health == 0:
		emit_signal("died")

signal died

func _on_body_entered(body: Node) -> void:
	# For pickups
	if body.has_method("collect"):
		body.collect(self)
