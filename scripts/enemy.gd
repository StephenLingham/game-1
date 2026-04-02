extends CharacterBody2D

signal enemy_killed

@export_enum("Normal", "Fast", "Big") var enemy_type: String = "Normal"

var speed: float
var health: int
var damage: int
var attack_cooldown: float
var xp_drop_min: int
var xp_drop_max: int

var target: Node2D = null
var can_attack: bool = true
var attack_timer: float = 0.0
var _freeze_timer: float = 0.0

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
			xp_drop_min = GameConstants.ENEMY_FAST_XP_MIN
			xp_drop_max = GameConstants.ENEMY_FAST_XP_MAX
		"Big":
			speed = GameConstants.ENEMY_BIG_SPEED
			health = GameConstants.ENEMY_BIG_HEALTH
			damage = GameConstants.ENEMY_BIG_DAMAGE
			attack_cooldown = GameConstants.ENEMY_BIG_ATTACK_COOLDOWN
			xp_drop_min = GameConstants.ENEMY_BIG_XP_MIN
			xp_drop_max = GameConstants.ENEMY_BIG_XP_MAX
		_, "Normal":
			speed = GameConstants.ENEMY_NORMAL_SPEED
			health = int(GameConstants.ENEMY_NORMAL_HEALTH * GameState.run_difficulty_health_mult)
			damage = int(GameConstants.ENEMY_NORMAL_DAMAGE * GameState.run_difficulty_damage_mult)
			attack_cooldown = GameConstants.ENEMY_NORMAL_ATTACK_COOLDOWN
			xp_drop_min = GameConstants.ENEMY_NORMAL_XP_MIN
			xp_drop_max = GameConstants.ENEMY_NORMAL_XP_MAX
	
	# Apply multipliers to already set values for other types if they were set in match
	if enemy_type == "Fast":
		health = int(GameConstants.ENEMY_FAST_HEALTH * GameState.run_difficulty_health_mult)
		damage = int(GameConstants.ENEMY_FAST_DAMAGE * GameState.run_difficulty_damage_mult)
	elif enemy_type == "Big":
		health = int(GameConstants.ENEMY_BIG_HEALTH * GameState.run_difficulty_health_mult)
		damage = int(GameConstants.ENEMY_BIG_DAMAGE * GameState.run_difficulty_damage_mult)

func _physics_process(delta: float) -> void:
	if not can_attack:
		attack_timer -= delta
		if attack_timer <= 0.0:
			can_attack = true
	
	if _freeze_timer > 0:
		_freeze_timer -= delta
		velocity = Vector2.ZERO
	elif target and is_instance_valid(target):
		var dir := (target.global_position - global_position).normalized()
		velocity = dir * speed
		look_at(target.global_position)
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()

func take_damage(amount: int = 1, source: String = "") -> int:
	var actual_damage = max(0, min(amount, health))
	var before_health = health
	health -= amount
	
	# Flash white
	sprite.modulate = Color(10, 10, 10)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)
	
	if health <= 0 and before_health > 0:
		GameState.run_enemies_killed += 1
		if source != "":
			GameState.record_kill(source)
		enemy_killed.emit()
		_drop_xp()
		queue_free()
	
	return actual_damage

func freeze(duration: float) -> void:
	_freeze_timer = duration
	sprite.modulate = Color(0.5, 0.8, 1.0)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, duration)

func _drop_xp() -> void:
	call_deferred("_spawn_xp_drop")

func _spawn_xp_drop() -> void:
	var pickup: Area2D = preload("res://scenes/XPPickup.tscn").instantiate()
	pickup.global_position = global_position
	var base_xp = randi_range(xp_drop_min, xp_drop_max)
	pickup.value = base_xp # Multipliers handled in GameState.add_xp
	get_tree().current_scene.get_node("PickupContainer").add_child(pickup)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and can_attack:
		can_attack = false
		attack_timer = attack_cooldown
		body.take_damage(damage, self)
