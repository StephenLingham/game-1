extends CharacterBody2D

signal enemy_killed

@export_enum("Normal", "Fast", "Big", "Tree", "Elite", "Golem", "Boss") var enemy_type: String = "Normal"

var speed: float
var health: int
var max_health: int
var damage: int
var attack_cooldown: float
var xp_drop_min: int
var xp_drop_max: int

var target: Node2D = null
var can_attack: bool = true
var attack_timer: float = 0.0
var _freeze_timer: float = 0.0
var _slow_timer: float = 0.0
var _slow_factor: float = 1.0
var _burn_timer: float = 0.0
var _burn_dps: float = 0.0
var _burn_accumulator: float = 0.0
var _burn_spread_timer: float = 0.0
var _curse_timer: float = 0.0
var _curse_accumulator: float = 0.0
var _knockback_velocity: Vector2 = Vector2.ZERO
var _death_processed: bool = false
var _boss_health_bar: Node2D = null
var _boss_health_fill: ColorRect = null
var _boss_health_label: Label = null
const TEXTURE_NORMAL = preload("res://assets/Enemies/dark-creature.png")
const TEXTURE_FAST = preload("res://assets/Enemies/wisp.png")
const TEXTURE_BIG = preload("res://assets/Enemies/tree-ent.png")
const TEXTURE_TREE = preload("res://assets/Enemies/enemy6.png")
const TEXTURE_ELITE = preload("res://assets/Enemies/enemy5.png")
const TEXTURE_GOLEM = preload("res://assets/Enemies/stone-golem-3.png")
const BOSS_TEXTURE_PATH: String = "res://assets/Enemies/Bosses/fox-boss.png"

@onready var sprite: Sprite2D = $Sprite2D
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/HitboxShape

func _ready() -> void:
	z_index = 10
	add_to_group("enemies")
	target = _get_nearest_ally()

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
		"Tree":
			sprite.texture = TEXTURE_TREE
			sprite.scale = Vector2.ONE * GameConstants.ENEMY_TREE_SPRITE_SCALE
			speed = GameConstants.ENEMY_TREE_SPEED
			health = GameConstants.ENEMY_TREE_HEALTH
			damage = GameConstants.ENEMY_TREE_DAMAGE
			attack_cooldown = GameConstants.ENEMY_TREE_ATTACK_COOLDOWN
			xp_drop_min = GameConstants.ENEMY_TREE_XP_MIN
			xp_drop_max = GameConstants.ENEMY_TREE_XP_MAX
		"Elite":
			sprite.texture = TEXTURE_ELITE
			sprite.scale = Vector2.ONE * GameConstants.ENEMY_ELITE_SPRITE_SCALE
			speed = GameConstants.ENEMY_ELITE_SPEED
			health = GameConstants.ENEMY_ELITE_HEALTH
			damage = GameConstants.ENEMY_ELITE_DAMAGE
			attack_cooldown = GameConstants.ENEMY_ELITE_ATTACK_COOLDOWN
			xp_drop_min = GameConstants.ENEMY_ELITE_XP_MIN
			xp_drop_max = GameConstants.ENEMY_ELITE_XP_MAX
		"Golem":
			sprite.texture = TEXTURE_GOLEM
			sprite.scale = Vector2.ONE * GameConstants.ENEMY_GOLEM_SPRITE_SCALE
			speed = GameConstants.ENEMY_GOLEM_SPEED
			health = GameConstants.ENEMY_GOLEM_HEALTH
			damage = GameConstants.ENEMY_GOLEM_DAMAGE
			attack_cooldown = GameConstants.ENEMY_GOLEM_ATTACK_COOLDOWN
			xp_drop_min = GameConstants.ENEMY_GOLEM_XP_MIN
			xp_drop_max = GameConstants.ENEMY_GOLEM_XP_MAX
		"Boss":
			sprite.texture = _load_boss_texture()
			sprite.scale = Vector2.ONE * GameConstants.ENEMY_BOSS_SPRITE_SCALE
			speed = GameConstants.ENEMY_BOSS_SPEED
			health = GameConstants.ENEMY_BOSS_HEALTH
			damage = GameConstants.ENEMY_BOSS_DAMAGE
			attack_cooldown = GameConstants.ENEMY_BOSS_ATTACK_COOLDOWN
			xp_drop_min = GameConstants.ENEMY_BOSS_XP_MIN
			xp_drop_max = GameConstants.ENEMY_BOSS_XP_MAX
			_set_collision_radius(GameConstants.ENEMY_BOSS_COLLISION_RADIUS, GameConstants.ENEMY_BOSS_HITBOX_RADIUS)
		_, "Normal":
			sprite.texture = TEXTURE_NORMAL
			sprite.scale = Vector2.ONE * GameConstants.ENEMY_NORMAL_SPRITE_SCALE
			speed = GameConstants.ENEMY_NORMAL_SPEED
			health = GameConstants.ENEMY_NORMAL_HEALTH
			damage = GameConstants.ENEMY_NORMAL_DAMAGE
			attack_cooldown = GameConstants.ENEMY_NORMAL_ATTACK_COOLDOWN
			xp_drop_min = GameConstants.ENEMY_NORMAL_XP_MIN
			xp_drop_max = GameConstants.ENEMY_NORMAL_XP_MAX

	health = int(health * GameState.run_difficulty_health_mult)
	damage = int(damage * GameState.run_difficulty_damage_mult)
	max_health = health
	if enemy_type == "Boss":
		_create_boss_health_bar()
		_update_boss_health_bar()

func _physics_process(delta: float) -> void:
	if not can_attack:
		attack_timer -= delta
		if attack_timer <= 0.0:
			can_attack = true
	if can_attack:
		_try_attack_overlapping_ally()

	if _freeze_timer > 0.0:
		_freeze_timer -= delta
	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_slow_factor = 1.0
	if _burn_timer > 0.0:
		_burn_timer -= delta
		_burn_accumulator += _burn_dps * delta
		while _burn_accumulator >= 1.0 and health > 0:
			_burn_accumulator -= 1.0
			GameState.record_damage("burn", take_damage(1, "burn"))
		_burn_spread_timer -= delta
		if _burn_spread_timer <= 0.0:
			_burn_spread_timer = 0.25
			_spread_burn()
		if _burn_timer <= 0.0:
			_burn_dps = 0.0
			_burn_accumulator = 0.0
	if _curse_timer > 0.0:
		_curse_timer -= delta
		_curse_accumulator += float(max_health) * 0.25 * delta
		while _curse_accumulator >= 1.0 and health > 0:
			var curse_damage := int(floor(_curse_accumulator))
			_curse_accumulator -= float(curse_damage)
			GameState.record_damage("curse", take_damage(curse_damage, "curse"))

	target = _get_nearest_ally()
	var desired_velocity := Vector2.ZERO
	if _freeze_timer <= 0.0 and target and is_instance_valid(target):
		var to_target := target.global_position - global_position
		var distance := to_target.length()
		var stop_distance := _get_approach_stop_distance(target)
		if distance > stop_distance and distance > 0.001:
			var dir := to_target / distance
			desired_velocity = dir * speed * _slow_factor
			if desired_velocity.x != 0.0:
				if enemy_type == "Normal" or enemy_type == "Tree" or enemy_type == "Elite" or enemy_type == "Fast" or enemy_type == "Big":
					sprite.flip_h = desired_velocity.x < 0
				else:
					sprite.flip_h = desired_velocity.x > 0

	velocity = desired_velocity + _knockback_velocity
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	move_and_slide()
	_update_boss_health_bar()

func take_damage(amount: int = 1, source: String = "", is_crit: bool = false) -> int:
	if _death_processed:
		return 0
	var actual_damage = max(0, min(amount, health))
	if actual_damage <= 0:
		return 0

	_spawn_damage_number(actual_damage, is_crit)
	var before_health = health
	health -= amount
	_update_boss_health_bar()

	sprite.modulate = Color(10, 10, 10)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)

	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("on_enemy_hit"):
		player.on_enemy_hit(self, actual_damage, source, is_crit)

	if health <= 0 and before_health > 0 and not _death_processed:
		_death_processed = true
		GameState.record_enemy_killed()
		if enemy_type == "Boss":
			GameState.run_boss_killed = true
			GameState.record_boss_kill()
		if source != "":
			GameState.record_kill(source)
		enemy_killed.emit()
		if player and player.has_method("on_enemy_killed"):
			player.on_enemy_killed(self, source, actual_damage, is_crit)
		_drop_xp()
		queue_free()

	return actual_damage

func freeze(duration: float) -> void:
	_freeze_timer = max(_freeze_timer, duration)
	sprite.modulate = Color(0.5, 0.8, 1.0)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, duration)

func apply_slow(multiplier: float, duration: float) -> void:
	_slow_factor = min(_slow_factor, multiplier)
	_slow_timer = max(_slow_timer, duration)

func apply_burn(dps: float, duration: float) -> void:
	_burn_dps = max(_burn_dps, dps)
	_burn_timer = max(_burn_timer, duration)
	_burn_spread_timer = min(_burn_spread_timer, 0.1)

func apply_curse(duration: float) -> void:
	_curse_timer = max(_curse_timer, duration)

func is_cursed() -> bool:
	return _curse_timer > 0.0

func apply_knockback(force: Vector2) -> void:
	_knockback_velocity += force

func _get_approach_stop_distance(ally: Node2D) -> float:
	return _get_collision_shape_radius(body_shape, 14.0) + _get_node_collision_radius(ally, 16.0) + 1.0

func _get_node_collision_radius(node: Node2D, fallback: float) -> float:
	if node == null:
		return fallback
	var collision_shape := node.get_node_or_null("CollisionShape2D") as CollisionShape2D
	return _get_collision_shape_radius(collision_shape, fallback)

func _get_collision_shape_radius(collision_shape: CollisionShape2D, fallback: float) -> float:
	if collision_shape == null or collision_shape.shape == null:
		return fallback
	var shape := collision_shape.shape
	var scale_factor = max(abs(collision_shape.global_scale.x), abs(collision_shape.global_scale.y))
	if shape is CircleShape2D:
		return (shape as CircleShape2D).radius * scale_factor
	if shape is RectangleShape2D:
		return (shape as RectangleShape2D).size.length() * 0.5 * scale_factor
	if shape is CapsuleShape2D:
		var capsule := shape as CapsuleShape2D
		return max(capsule.radius, capsule.height * 0.5) * scale_factor
	return fallback

func _load_boss_texture() -> Texture2D:
	# Load the imported Texture2D resource so Godot owns and releases its GPU RID.
	# Creating an ImageTexture manually here bypassed the importer and leaked it
	# when a run containing a boss was stopped from the editor.
	return load(BOSS_TEXTURE_PATH) as Texture2D

func _set_collision_radius(body_radius: float, hitbox_radius: float) -> void:
	if body_shape and body_shape.shape is CircleShape2D:
		body_shape.shape = body_shape.shape.duplicate()
		body_shape.shape.radius = body_radius
	if hitbox_shape and hitbox_shape.shape is CircleShape2D:
		hitbox_shape.shape = hitbox_shape.shape.duplicate()
		hitbox_shape.shape.radius = hitbox_radius

func _create_boss_health_bar() -> void:
	_boss_health_bar = Node2D.new()
	_boss_health_bar.z_index = 40
	add_child(_boss_health_bar)

	var bg := ColorRect.new()
	bg.position = Vector2(-80, -110)
	bg.size = Vector2(160, 14)
	bg.color = Color(0.08, 0.02, 0.02, 0.9)
	_boss_health_bar.add_child(bg)

	_boss_health_fill = ColorRect.new()
	_boss_health_fill.position = bg.position
	_boss_health_fill.size = bg.size
	_boss_health_fill.color = Color(0.9, 0.05, 0.03, 1.0)
	_boss_health_bar.add_child(_boss_health_fill)

	_boss_health_label = Label.new()
	_boss_health_label.position = Vector2(-80, -134)
	_boss_health_label.size = Vector2(160, 24)
	_boss_health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_boss_health_label.add_theme_font_size_override("font_size", 16)
	_boss_health_label.add_theme_color_override("font_color", Color.WHITE)
	_boss_health_bar.add_child(_boss_health_label)

func _update_boss_health_bar() -> void:
	if enemy_type != "Boss" or _boss_health_bar == null or max_health <= 0:
		return
	var hp = max(health, 0)
	var pct = clamp(float(hp) / float(max_health), 0.0, 1.0)
	if _boss_health_fill:
		_boss_health_fill.size.x = 160.0 * pct
	if _boss_health_label:
		_boss_health_label.text = "%d / %d" % [hp, max_health]

func _spread_burn() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == self or not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) <= 34.0 and enemy.has_method("apply_burn"):
			enemy.apply_burn(_burn_dps * 0.75, 2.5)

func _drop_xp() -> void:
	var base_xp = randi_range(xp_drop_min, xp_drop_max)
	_spawn_xp_pickup(base_xp)

	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("should_spawn_extra_xp_drop") and player.should_spawn_extra_xp_drop():
		_spawn_xp_pickup(base_xp)

func _spawn_xp_pickup(amount: int) -> void:
	var pickup: Area2D = preload("res://scenes/XPPickup.tscn").instantiate()
	pickup.global_position = global_position
	pickup.value = amount

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
	_try_attack_ally(body)

func _try_attack_overlapping_ally() -> void:
	if hitbox == null:
		return
	for body in hitbox.get_overlapping_bodies():
		if _try_attack_ally(body):
			return

func _try_attack_ally(body: Node2D) -> bool:
	if not can_attack or body == null:
		return false
	if body.is_in_group("allies") and body.has_method("take_damage"):
		can_attack = false
		attack_timer = attack_cooldown
		body.take_damage(damage, self)
		return true
	return false

func _get_nearest_ally() -> Node2D:
	var nearest: Node2D = null
	var nearest_dist := INF
	for ally in get_tree().get_nodes_in_group("allies"):
		if not is_instance_valid(ally):
			continue
		var dist := global_position.distance_squared_to(ally.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = ally
	return nearest
