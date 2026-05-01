extends CharacterBody2D

signal enemy_killed

@export_enum("Normal", "Fast", "Big", "Cute") var enemy_type: String = "Normal"

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
const TEXTURE_NORMAL = preload("res://assets/Enemies/enemy1-cropped.png")
const TEXTURE_FAST = preload("res://assets/Enemies/enemy2-cropped.png")
const TEXTURE_BIG = preload("res://assets/Enemies/enemy3-cropped.png")
const TEXTURE_CUTE = preload("res://assets/Enemies/enemy4-cropped.png")

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("enemies")
	target = get_tree().get_first_node_in_group("player")
	
	match enemy_type:
		"Fast":
			sprite.texture = TEXTURE_FAST
			sprite.scale = Vector2.ONE * GameConstants.ENEMY_FAST_SPRITE_SCALE
			speed = GameConstants.ENEMY_FAST_SPEED
			health = GameConstants.ENEMY_FAST_HEALTH
			damage = GameConstants.ENEMY_FAST_DAMAGE
			attack_cooldown = GameConstants.ENEMY_FAST_ATTACK_COOLDOWN
			xp_drop_min = GameConstants.ENEMY_FAST_XP_MIN
			xp_drop_max = GameConstants.ENEMY_FAST_XP_MAX
		"Big":
			sprite.texture = TEXTURE_BIG
			sprite.scale = Vector2.ONE * GameConstants.ENEMY_BIG_SPRITE_SCALE
			speed = GameConstants.ENEMY_BIG_SPEED
			health = GameConstants.ENEMY_BIG_HEALTH
			damage = GameConstants.ENEMY_BIG_DAMAGE
			attack_cooldown = GameConstants.ENEMY_BIG_ATTACK_COOLDOWN
			xp_drop_min = GameConstants.ENEMY_BIG_XP_MIN
			xp_drop_max = GameConstants.ENEMY_BIG_XP_MAX
		"Cute":
			sprite.texture = TEXTURE_CUTE
			sprite.scale = Vector2.ONE * GameConstants.ENEMY_CUTE_SPRITE_SCALE
			speed = GameConstants.ENEMY_CUTE_SPEED
			health = GameConstants.ENEMY_CUTE_HEALTH
			damage = GameConstants.ENEMY_CUTE_DAMAGE
			attack_cooldown = GameConstants.ENEMY_CUTE_ATTACK_COOLDOWN
			xp_drop_min = GameConstants.ENEMY_CUTE_XP_MIN
			xp_drop_max = GameConstants.ENEMY_CUTE_XP_MAX
		_, "Normal":
			sprite.texture = TEXTURE_NORMAL
			sprite.scale = Vector2.ONE * GameConstants.ENEMY_NORMAL_SPRITE_SCALE
			speed = GameConstants.ENEMY_NORMAL_SPEED
			health = GameConstants.ENEMY_NORMAL_HEALTH
			damage = GameConstants.ENEMY_NORMAL_DAMAGE
			attack_cooldown = GameConstants.ENEMY_NORMAL_ATTACK_COOLDOWN
			xp_drop_min = GameConstants.ENEMY_NORMAL_XP_MIN
			xp_drop_max = GameConstants.ENEMY_NORMAL_XP_MAX
	
	# Apply difficulty multipliers
	health = int(health * GameState.run_difficulty_health_mult)
	damage = int(damage * GameState.run_difficulty_damage_mult)

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
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()

func take_damage(amount: int = 1, source: String = "", is_crit: bool = false) -> int:
	var actual_damage = max(0, min(amount, health))
	
	# Spawn damage number
	_spawn_damage_number(amount, is_crit)
	
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
		
		# Lifesteal (Sanguis)
		if GameState.run_lifesteal > 0:
			var p = get_tree().get_first_node_in_group("player")
			if p and "health" in p:
				var heal = max(1, int(actual_damage * GameState.run_lifesteal))
				p.health = min(p.health + heal, p.max_health)
				
		queue_free()
	
	return actual_damage

func freeze(duration: float) -> void:
	_freeze_timer = duration
	sprite.modulate = Color(0.5, 0.8, 1.0)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, duration)

func _drop_xp() -> void:
	var pickup: Area2D = preload("res://scenes/XPPickup.tscn").instantiate()
	pickup.global_position = global_position
	var base_xp = randi_range(xp_drop_min, xp_drop_max)
	pickup.value = base_xp # Multipliers handled in GameState.add_xp
	
	var container = get_tree().current_scene.get_node_or_null("PickupContainer")
	if container:
		container.call_deferred("add_child", pickup)
	else:
		get_tree().current_scene.call_deferred("add_child", pickup)

func _spawn_damage_number(dmg: int, is_crit: bool) -> void:
	var dn_script = preload("res://scripts/damage_number.gd")
	var dn = Node2D.new()
	dn.set_script(dn_script)
	dn.damage = dmg
	dn.is_crit = is_crit
	dn.global_position = global_position + Vector2(0, -20)
	get_tree().current_scene.add_child(dn)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and can_attack:
		can_attack = false
		attack_timer = attack_cooldown
		body.take_damage(damage, self)
