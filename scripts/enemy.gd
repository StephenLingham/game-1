extends CharacterBody2D

signal enemy_killed

@export_enum("Normal", "Fast", "Big") var enemy_type: String = "Normal"

var speed: float
var health: int
var damage: int
var attack_cooldown: float
var gold_drop_min: int
var gold_drop_max: int

var target: Node2D = null
var can_attack: bool = true
var attack_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("enemies")
	target = get_tree().get_first_node_in_group("player")
	
	match enemy_type:
		"Fast":
			speed = GameConstants.ENEMY_FAST_SPEED
			health = GameConstants.ENEMY_FAST_HEALTH
			damage = GameConstants.ENEMY_FAST_DAMAGE
			attack_cooldown = GameConstants.ENEMY_FAST_ATTACK_COOLDOWN
			gold_drop_min = GameConstants.ENEMY_FAST_GOLD_MIN
			gold_drop_max = GameConstants.ENEMY_FAST_GOLD_MAX
		"Big":
			speed = GameConstants.ENEMY_BIG_SPEED
			health = GameConstants.ENEMY_BIG_HEALTH
			damage = GameConstants.ENEMY_BIG_DAMAGE
			attack_cooldown = GameConstants.ENEMY_BIG_ATTACK_COOLDOWN
			gold_drop_min = GameConstants.ENEMY_BIG_GOLD_MIN
			gold_drop_max = GameConstants.ENEMY_BIG_GOLD_MAX
		_, "Normal":
			speed = GameConstants.ENEMY_NORMAL_SPEED
			health = GameConstants.ENEMY_NORMAL_HEALTH
			damage = GameConstants.ENEMY_NORMAL_DAMAGE
			attack_cooldown = GameConstants.ENEMY_NORMAL_ATTACK_COOLDOWN
			gold_drop_min = GameConstants.ENEMY_NORMAL_GOLD_MIN
			gold_drop_max = GameConstants.ENEMY_NORMAL_GOLD_MAX

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
		_drop_gold()
		queue_free()

func _drop_gold() -> void:
	call_deferred("_spawn_gold_pickup")

func _spawn_gold_pickup() -> void:
	var pickup: Area2D = preload("res://scenes/GoldPickup.tscn").instantiate()
	pickup.global_position = global_position
	pickup.value = randi_range(gold_drop_min, gold_drop_max)
	get_tree().current_scene.get_node("PickupContainer").add_child(pickup)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and can_attack:
		can_attack = false
		attack_timer = attack_cooldown
		body.take_damage(damage)
