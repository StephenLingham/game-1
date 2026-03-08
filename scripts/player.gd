extends CharacterBody2D

signal player_died

@export var speed: float = 300.0
@export var fire_rate: float = 0.15
@export var max_health: int = 5

var health: int
var can_fire: bool = true
var fire_timer: float = 0.0

@onready var muzzle: Marker2D = $Muzzle
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")

func _ready() -> void:
	health = max_health

func _physics_process(delta: float) -> void:
	# Movement
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")
	
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()
	
	velocity = input_dir * speed
	move_and_slide()
	
	# Find nearest enemy and aim at it
	var nearest_enemy := _get_nearest_enemy()
	
	if nearest_enemy:
		look_at(nearest_enemy.global_position)
	
	# Auto-fire
	if not can_fire:
		fire_timer -= delta
		if fire_timer <= 0.0:
			can_fire = true
	
	if can_fire and nearest_enemy:
		fire()

func _get_nearest_enemy() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var closest_dist := INF
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist := global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = enemy
	
	return closest

func fire() -> void:
	can_fire = false
	fire_timer = fire_rate
	
	var bullet := bullet_scene.instantiate() as Area2D
	bullet.global_position = muzzle.global_position
	bullet.rotation = rotation
	bullet.direction = Vector2.RIGHT.rotated(rotation)
	get_tree().current_scene.add_child(bullet)

func take_damage(amount: int = 1) -> void:
	health -= amount
	
	# Flash red
	sprite.modulate = Color(1, 0.3, 0.3)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
	
	if health <= 0:
		player_died.emit()
