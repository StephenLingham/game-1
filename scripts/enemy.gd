extends CharacterBody2D

signal enemy_killed

@export var speed: float = 120.0
@export var health: int = 2
@export var damage: int = 1
@export var attack_cooldown: float = 0.5

var target: Node2D = null
var can_attack: bool = true
var attack_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("enemies")
	# Find the player
	target = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if not can_attack:
		attack_timer -= delta
		if attack_timer <= 0.0:
			can_attack = true
	
	if target and is_instance_valid(target):
		var dir := (target.global_position - global_position).normalized()
		velocity = dir * speed
		look_at(target.global_position)
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()

func take_damage(amount: int = 1) -> void:
	health -= amount
	
	# Flash white
	sprite.modulate = Color(10, 10, 10)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)
	
	if health <= 0:
		enemy_killed.emit()
		queue_free()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and can_attack:
		can_attack = false
		attack_timer = attack_cooldown
		body.take_damage(damage)
