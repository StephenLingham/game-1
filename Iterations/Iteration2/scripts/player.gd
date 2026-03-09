extends CharacterBody2D

@export var move_speed: float = 220.0
@export var max_health: int = 100

# Base weapon stats (run + meta modifies these)
@export var base_damage: int = 10
@export var base_attack_interval: float = 0.35  # seconds per shot

var health: int

@onready var shoot_timer: Timer = $ShootTimer
@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	health = max_health
	hitbox.body_entered.connect(_on_body_entered)
	_configure_shoot_timer()

func _physics_process(_delta: float) -> void:
	var input_vec := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_vec * move_speed
	move_and_slide()

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
