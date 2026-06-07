extends CharacterBody2D
class_name Player

signal player_died

var speed: float = GameConstants.PLAYER_SPEED
var fire_rate: float = GameConstants.PLAYER_FIRE_RATE
var max_health: int = GameConstants.PLAYER_MAX_HEALTH
var base_damage: int = GameConstants.PLAYER_BASE_DAMAGE

var health: int
var can_fire: bool = true
var fire_timer: float = 0.0

var _base_speed: float = GameConstants.PLAYER_SPEED
var _speed_boost_multiplier: float = 1.0
var _speed_boost_duration: float = 0.0
var _atk_speed_boost_multiplier: float = 1.0
var _atk_speed_boost_duration: float = 0.0
var _regen_timer: float = 0.0
var _regen_accumulator: float = 0.0

# Click / tap-to-move support
var _click_target: Vector2 = Vector2.ZERO
var _has_click_target: bool = false

@onready var muzzle: Marker2D = $Muzzle
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
var spike_ball_scene: PackedScene = preload("res://scenes/spike_ball.tscn")
var rocket_scene: PackedScene = load("res://scenes/rocket.tscn")
const RocketScript = preload("res://scripts/rocket.gd")

var spike_ball_timer: float = 0.0
var shotgun_timer: float = 0.0
var sniper_timer: float = 0.0
var rocket_timer: float = 0.0
var disk_timer: float = 0.0
var spikes_timer: float = 0.0
var turret_timer: float = 0.0
var ice_timer: float = 0.0
var mg_timer: float = 0.0

# New weapon timers
var weapon_timers: Dictionary = {}

var _arcane_field_visual: Node2D = null
const ARCANE_FIELD_VISUAL_SCRIPT = preload("res://scripts/arcane_field_visual.gd")

var disk_scene: PackedScene = preload("res://scenes/bouncing_disk.tscn")
var spikes_scene: PackedScene = preload("res://scenes/floor_spikes.tscn")
var turret_scene: PackedScene = preload("res://scenes/turret.tscn")

func _ready() -> void:
	add_to_group("player")
	refresh_stats()
	health = max_health
	
	# Load character texture
	var char_id = GameState.current_character
	var char_data = GameConstants.CHARACTERS.get(char_id, GameConstants.CHARACTERS["starter"])
	if char_data.has("texture"):
		sprite.texture = load(char_data.texture)
		# Adjust scale if needed. Many character assets are large.
		# A good default scale for these assets might be 0.05 or similar.
		sprite.scale = Vector2(0.05, 0.05)
	
	# Hide old visual nodes if they exist
	var gun = get_node_or_null("Sprite2D/Gun")
	if gun: gun.visible = false
	var body = get_node_or_null("Sprite2D/Body")
	if body: body.visible = false
	
	# Reset muzzle to center
	muzzle.position = Vector2.ZERO
	
	# Disable camera smoothing to reduce jitter
	var cam = get_node_or_null("Camera2D")
	if cam:
		cam.position_smoothing_enabled = false
		cam.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	
	var arcane_orb_controller = get_node_or_null("ArcaneOrbController")
	if arcane_orb_controller and "base_damage" in arcane_orb_controller:
		arcane_orb_controller.base_damage = GameConstants.ARCANE_ORBS_DAMAGE

func refresh_stats() -> void:
	var old_max = max_health
	max_health = GameState.get_max_health()
	if max_health > old_max:
		health += (max_health - old_max)
	
	_base_speed = GameConstants.PLAYER_SPEED * GameState.get_speed_multiplier(false)
	# Current speed is updated in _physics_process


func reset_state(pos: Vector2) -> void:
	global_position = pos
	_has_click_target = false
	velocity = Vector2.ZERO
	
	var cam = $Camera2D as Camera2D
	if cam:
		cam.reset_smoothing()
		cam.force_update_scroll()
	
	# Reset all ability timers at the start of each wave to ensure zero delay for most weapons
	# except for floor spikes and ice wave which use a bit of a countdown as requested.
	can_fire = true
	fire_timer = 0.0
	spike_ball_timer = 0.0
	shotgun_timer = 0.0
	sniper_timer = 0.0
	rocket_timer = 0.0
	disk_timer = 0.0
	mg_timer = 0.0
	
	# Floor spikes and Ice wave are reset to their full cooldown at the start of each wave
	# so they don't fire immediately.
	spikes_timer = GameConstants.SPIKES_BASE_COOLDOWN
	ice_timer = GameConstants.ICE_BASE_COOLDOWN
	
	# Turrets also use their cooldown for the initial delay
	if GameState.run_abilities.get("turret", 0) > 0:
		var lvl = GameState.run_abilities.get("turret", 1)
		turret_timer = (GameConstants.TURRET_BASE_COOLDOWN - lvl * GameConstants.TURRET_COOLDOWN_REDUCTION)

func reset_powerups() -> void:
	_speed_boost_duration = 0.0
	_speed_boost_multiplier = 1.0
	_atk_speed_boost_duration = 0.0
	_atk_speed_boost_multiplier = 1.0
	sprite.modulate = Color.WHITE

func set_camera_limits(rect: Rect2) -> void:
	var cam = $Camera2D as Camera2D
	if cam:
		cam.limit_left = int(rect.position.x)
		cam.limit_top = int(rect.position.y)
		cam.limit_right = int(rect.position.x + rect.size.x)
		cam.limit_bottom = int(rect.position.y + rect.size.y)
		# Snap camera instantly
		cam.reset_smoothing()
		cam.force_update_scroll()

func _physics_process(delta: float) -> void:
	if GameState.current_character == "speed_damage":
		GameState.run_speed_bonus = min(
			GameState.run_speed_bonus + GameConstants.ZEPHYROS_SPEED_GAIN_PER_SEC * delta,
			GameConstants.ZEPHYROS_MAX_SPEED_BONUS
		)
	
	if _speed_boost_duration > 0:
		_speed_boost_duration -= delta
		if _speed_boost_duration <= 0:
			_speed_boost_multiplier = 1.0
	
	# Update speed every frame to account for dynamic bonuses and boosts
	speed = GameConstants.PLAYER_SPEED * GameState.get_speed_multiplier(true) * _speed_boost_multiplier
			
	if _atk_speed_boost_duration > 0:
		_atk_speed_boost_duration -= delta
		if _atk_speed_boost_duration <= 0:
			_atk_speed_boost_multiplier = 1.0

	# Regen
	var regen = GameState.get_health_regen()
	if regen > 0 and health < max_health:
		_regen_timer += delta
		if _regen_timer >= 1.0:
			_regen_timer = 0.0
			# Add regen to an accumulator to allow fractional health to build up
			_regen_accumulator += regen
			if _regen_accumulator >= 1.0:
				var amount := int(floor(_regen_accumulator))
				health = min(health + amount, max_health)
				_regen_accumulator -= float(amount)

	# Movement
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")

	if input_dir.length() > 0.0:
		# Keyboard / controller input takes priority
		_has_click_target = false
		if input_dir.length() > 1.0:
			input_dir = input_dir.normalized()
		velocity = input_dir * speed
		
		# Flip sprite based on direction
		if input_dir.x != 0:
			sprite.flip_h = input_dir.x > 0
	elif _has_click_target:
		var to_target := _click_target - global_position
		if to_target.length() <= 4.0:
			_has_click_target = false
			velocity = Vector2.ZERO
		else:
			velocity = to_target.normalized() * speed
			# Flip sprite based on direction
			if velocity.x != 0:
				sprite.flip_h = velocity.x > 0
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	
	# Find nearest enemy for aiming (but don't rotate player)
	var nearest_enemy := _get_nearest_enemy()
	
	# Auto-fire
	if not can_fire:
		fire_timer -= delta
		if fire_timer <= 0.0:
			can_fire = true
	
	if can_fire and nearest_enemy and GameState.run_abilities.get("zap", 0) > 0:
		fire(nearest_enemy)

	# Spike ball logic
	if GameState.run_abilities.get("spike_ball", 0) > 0:
		spike_ball_timer -= delta
		if spike_ball_timer <= 0:
			_fire_spike_ball(nearest_enemy)
			spike_ball_timer = _get_spike_ball_cooldown()

	# Shotgun logic
	if GameState.run_abilities.get("shotgun", 0) > 0:
		shotgun_timer -= delta
		if shotgun_timer <= 0:
			var visible_enemies = _get_visible_enemies()
			if not visible_enemies.is_empty():
				_fire_shotgun(visible_enemies.pick_random())
				shotgun_timer = GameConstants.SHOTGUN_BASE_COOLDOWN / _atk_speed_boost_multiplier

	# Sniper logic
	if GameState.run_abilities.get("sniper", 0) > 0:
		sniper_timer -= delta
		if sniper_timer <= 0:
			_fire_sniper()
			sniper_timer = GameState.get_sniper_cooldown() / _atk_speed_boost_multiplier

	# Rocket logic
	if GameState.run_abilities.get("rocket", 0) > 0:
		rocket_timer -= delta
		if rocket_timer <= 0:
			_fire_rocket()
			rocket_timer = GameState.get_rocket_cooldown() / _atk_speed_boost_multiplier

	# New Abilities
	if GameState.run_abilities.get("bouncing_disk", 0) > 0:
		disk_timer -= delta
		if disk_timer <= 0:
			_fire_disk()
			disk_timer = GameConstants.DISK_BASE_COOLDOWN / _atk_speed_boost_multiplier
			
	if GameState.run_abilities.get("floor_spikes", 0) > 0:
		spikes_timer -= delta
		if spikes_timer <= 0:
			_drop_spikes()
			spikes_timer = GameConstants.SPIKES_BASE_COOLDOWN / _atk_speed_boost_multiplier

	if GameState.run_abilities.get("turret", 0) > 0:
		turret_timer -= delta
		if turret_timer <= 0:
			_place_turret()
			var lvl = GameState.run_abilities.get("turret", 1)
			turret_timer = (GameConstants.TURRET_BASE_COOLDOWN - lvl * GameConstants.TURRET_COOLDOWN_REDUCTION)

	if GameState.run_abilities.get("ice_wave", 0) > 0:
		ice_timer -= delta
		if ice_timer <= 0:
			_trigger_ice_wave()
			ice_timer = GameConstants.ICE_BASE_COOLDOWN / _atk_speed_boost_multiplier

	if GameState.run_abilities.get("machine_gun", 0) > 0:
		mg_timer -= delta
		if mg_timer <= 0:
			_fire_machine_gun(nearest_enemy)
			mg_timer = GameConstants.MG_BASE_COOLDOWN / _atk_speed_boost_multiplier

	_process_new_weapons(delta, nearest_enemy)
	_update_arcane_field_visual()

func _update_arcane_field_visual() -> void:
	var lvl := int(GameState.run_abilities.get("arcane_field", 0))
	if lvl <= 0:
		if is_instance_valid(_arcane_field_visual):
			_arcane_field_visual.queue_free()
			_arcane_field_visual = null
		return

	if not is_instance_valid(_arcane_field_visual):
		_arcane_field_visual = Node2D.new()
		_arcane_field_visual.set_script(ARCANE_FIELD_VISUAL_SCRIPT)
		add_child(_arcane_field_visual)

	var radius := GameConstants.ARCANE_FIELD_BASE_RADIUS * GameState.get_weapon_size_multiplier("arcane_field")
	if _arcane_field_visual.has_method("set_field_radius"):
		_arcane_field_visual.set_field_radius(radius)

func _process_new_weapons(delta: float, nearest_enemy: Node2D) -> void:
	var new_weapons = [
		"arcane_missile", "fireball", "ice_shard", "meteor", "frozen_orb", 
		"lightning_bolt", "ice_bolt", "fire_bolt", "arcane_bolt", "lightning_fork", 
		"blizzard", "arcane_orbs", "arcane_field", "fire_trail"
	]
	
	for w_id in new_weapons:
		if GameState.run_abilities.get(w_id, 0) > 0:
			var timer = weapon_timers.get(w_id, 0.0)
			timer -= delta
			if timer <= 0:
				_fire_weapon(w_id, nearest_enemy)
				timer = _get_weapon_cooldown(w_id)
			weapon_timers[w_id] = timer

func _get_weapon_cooldown(id: String) -> float:
	var base = 1.0
	match id:
		"meteor": base = 3.0
		"frozen_orb": base = 4.0
		"blizzard": base = 2.5
		"arcane_field": base = GameConstants.ARCANE_FIELD_BASE_COOLDOWN
		"fire_trail": base = 0.2
		"arcane_orbs": base = 0.0 # Handled by permanent nodes
	
	var lvl = GameState.run_abilities.get(id, 1)
	var cooldown = base / (1.0 + (lvl - 1) * 0.2)
	return max(0.1, cooldown / _atk_speed_boost_multiplier)

func _fire_weapon(id: String, target: Node2D) -> void:
	match id:
		"arcane_missile": _fire_projectile_weapon(id, target, Color.PURPLE)
		"fireball": _fire_projectile_weapon(id, target, Color.ORANGE_RED, true)
		"ice_shard": _fire_projectile_weapon(id, target, Color.AQUA)
		"meteor": _fire_meteor()
		"frozen_orb": _fire_frozen_orb(target)
		"lightning_bolt": _fire_projectile_weapon(id, target, Color.YELLOW)
		"ice_bolt": _fire_projectile_weapon(id, target, Color.CORNFLOWER_BLUE)
		"fire_bolt": _fire_projectile_weapon(id, target, Color.ORANGE)
		"arcane_bolt": _fire_projectile_weapon(id, target, Color.MEDIUM_PURPLE)
		"lightning_fork": _fire_projectile_weapon(id, target, Color.GOLD)
		"blizzard": _fire_blizzard()
		"arcane_orbs": _update_arcane_orbs()
		"arcane_field": _trigger_arcane_field()
		"fire_trail": _leave_fire_trail()

func _fire_projectile_weapon(id: String, target: Node2D, color: Color, explode: bool = false) -> void:
	if not is_instance_valid(target): return
	
	# Determine projectile count: per-weapon trait if available, else global or fixed
	var count: int
	var weapon_trait_list: Array = GameConstants.WEAPON_TRAITS.get(id, [])
	if "projectiles" in weapon_trait_list:
		count = GameState.get_weapon_projectiles(id)
	elif id == "zap":
		count = 1
	else:
		count = GameState.get_projectiles()
	
	var effective_base = _get_weapon_base_damage(id) + GameState.get_weapon_damage_bonus(id)
	var bolt_targets := _get_bolt_targets(count) if _is_multi_target_bolt_weapon(id) else []
	
	for i in range(count):
		var b = bullet_scene.instantiate()
		b.global_position = global_position
		var bullet_dir: Vector2
		if not bolt_targets.is_empty():
			var assigned_target: Node2D = bolt_targets[i]
			bullet_dir = (assigned_target.global_position - global_position).normalized()
			if "launch_delay" in b:
				b.launch_delay = 0.035 * float(i)
		else:
			var dir = (target.global_position - global_position).normalized()
			var spread: float
			if i == 0:
				spread = 0.0
			else:
				var multiplier = int(floor((i + 1) / 2.0))
				if i % 2 == 1:
					spread = 0.2 * multiplier
				else:
					spread = -0.2 * multiplier
			bullet_dir = dir.rotated(spread)
		b.direction = bullet_dir
		b.rotation = bullet_dir.angle()
		b.modulate = color
		b.weapon_source = id
		
		var res = _get_final_damage_for_weapon(effective_base, id)
		b.damage = res.damage
		if "is_crit" in b: b.is_crit = res.is_crit
		
		if _can_weapon_bounce(id):
			if "bounces" in weapon_trait_list:
				b.bounces_left = GameState.get_weapon_bounces(id)
			else:
				b.bounces_left = GameState.get_bounces()
		
		# Fireball explosion: set area radius on bullet
		if explode:
			b.area_radius = GameConstants.FIREBALL_BASE_BLAST_RADIUS * GameState.get_weapon_size_multiplier(id)
		
		get_tree().current_scene.add_child(b)

func _is_multi_target_bolt_weapon(id: String) -> bool:
	return id in ["lightning_bolt", "ice_bolt", "fire_bolt", "arcane_bolt"]

func _get_bolt_targets(count: int) -> Array:
	var visible_enemies = _get_visible_enemies()
	if visible_enemies.is_empty():
		return []
	
	visible_enemies.sort_custom(func(a, b): return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position))
	var targets: Array = []
	for i in range(count):
		targets.append(visible_enemies[i % visible_enemies.size()])
	return targets

func _get_weapon_base_damage(id: String) -> int:
	match id:
		"zap": return GameConstants.ZAP_BASE_DAMAGE
		"arcane_missile": return GameConstants.ARCANE_MISSILE_DAMAGE
		"fireball": return GameConstants.FIREBALL_DAMAGE
		"ice_shard": return GameConstants.ICE_SHARD_DAMAGE
		"meteor": return GameConstants.METEOR_DAMAGE
		"frozen_orb": return GameConstants.FROZEN_ORB_DAMAGE
		"lightning_bolt": return GameConstants.LIGHTNING_BOLT_DAMAGE
		"ice_bolt": return GameConstants.ICE_BOLT_DAMAGE
		"fire_bolt": return GameConstants.FIRE_BOLT_DAMAGE
		"arcane_bolt": return GameConstants.ARCANE_BOLT_DAMAGE
		"lightning_fork": return GameConstants.LIGHTNING_FORK_DAMAGE
		"blizzard": return GameConstants.BLIZZARD_DAMAGE
		"arcane_orbs": return GameConstants.ARCANE_ORBS_DAMAGE
		"arcane_field": return GameConstants.ARCANE_FIELD_DAMAGE
		"fire_trail": return GameConstants.FIRE_TRAIL_DAMAGE
	return 20

func _can_weapon_bounce(id: String) -> bool:
	return id in ["lightning_bolt", "ice_bolt", "fire_bolt", "arcane_bolt"]

func _fire_meteor() -> void:
	var count = GameState.get_projectiles()
	var size_mult = GameState.get_weapon_size_multiplier("meteor")
	var radius = GameConstants.METEOR_BASE_RADIUS * size_mult
	var effective_dmg = _get_weapon_base_damage("meteor") + GameState.get_weapon_damage_bonus("meteor")
	for i in range(count):
		var pos = global_position + Vector2(randf_range(-400, 400), randf_range(-400, 400))
		# Visual circle for meteor impact
		var circle = Polygon2D.new()
		var pts = []
		for j in range(32):
			pts.append(Vector2.RIGHT.rotated(j * TAU / 32) * radius)
		circle.polygon = PackedVector2Array(pts)
		circle.color = Color(1.0, 0.4, 0.0, 0.5)
		circle.global_position = pos
		get_tree().current_scene.add_child(circle)
		
		var timer = get_tree().create_timer(0.5)
		timer.timeout.connect(func():
			_apply_area_damage_for_weapon(pos, radius, effective_dmg, "meteor")
			circle.queue_free()
		)

func _fire_frozen_orb(target: Node2D) -> void:
	# Simplified: fire a big slow projectile that fires small ones
	var orb = bullet_scene.instantiate()
	orb.global_position = global_position
	orb.speed = 150.0
	orb.scale = Vector2(2, 2)
	orb.modulate = Color.CYAN
	orb.weapon_source = "frozen_orb"
	
	var effective_base = GameConstants.FROZEN_ORB_DAMAGE + GameState.get_weapon_damage_bonus("frozen_orb")
	var res = _get_final_damage_for_weapon(effective_base, "frozen_orb")
	orb.damage = res.damage
	if "is_crit" in orb:
		orb.is_crit = res.is_crit
		
	if is_instance_valid(target):
		orb.direction = (target.global_position - global_position).normalized()
	get_tree().current_scene.add_child(orb)

func _fire_blizzard() -> void:
	var size_mult = GameState.get_weapon_size_multiplier("blizzard")
	var spawn_range = GameConstants.BLIZZARD_BASE_RADIUS * size_mult
	var strike_radius = 40.0 * size_mult
	var count = max(1, GameState.get_projectiles() * 3)
	var effective_dmg = _get_weapon_base_damage("blizzard") + GameState.get_weapon_damage_bonus("blizzard")
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearby_enemies: Array[Node2D] = []
	for enemy in enemies:
		if is_instance_valid(enemy) and global_position.distance_to(enemy.global_position) <= spawn_range:
			nearby_enemies.append(enemy)
	for i in range(count):
		var pos = global_position + Vector2(randf_range(-spawn_range, spawn_range), randf_range(-spawn_range, spawn_range))
		if not nearby_enemies.is_empty():
			var target_enemy = nearby_enemies[randi() % nearby_enemies.size()]
			pos = target_enemy.global_position + Vector2(randf_range(-strike_radius, strike_radius), randf_range(-strike_radius, strike_radius))
		_apply_blizzard_hit(pos, strike_radius, effective_dmg)

func _update_arcane_orbs() -> void:
	var arcane_orb_controller = get_node_or_null("ArcaneOrbController")
	if arcane_orb_controller and "base_damage" in arcane_orb_controller:
		arcane_orb_controller.base_damage = GameConstants.ARCANE_ORBS_DAMAGE

func _trigger_arcane_field() -> void:
	var radius = GameConstants.ARCANE_FIELD_BASE_RADIUS * GameState.get_weapon_size_multiplier("arcane_field")
	var effective_dmg = _get_weapon_base_damage("arcane_field") + GameState.get_weapon_damage_bonus("arcane_field")
	_apply_area_damage_for_weapon(global_position, radius, effective_dmg, "arcane_field")
	if is_instance_valid(_arcane_field_visual) and _arcane_field_visual.has_method("pulse"):
		_arcane_field_visual.pulse()

func _leave_fire_trail() -> void:
	var fire = spikes_scene.instantiate() # Reuse floor spikes for trail
	fire.global_position = global_position
	fire.modulate = Color.RED
	get_tree().current_scene.add_child(fire)

func _apply_area_damage(pos: Vector2, radius: float, base_dmg: int, source: String) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and pos.distance_to(e.global_position) <= radius:
			var res = _get_final_damage(base_dmg)
			e.take_damage(res.damage, source, res.is_crit)
			GameState.run_damage_stats[source] = GameState.run_damage_stats.get(source, 0) + res.damage

## Weapon-trait-aware area damage: includes per-weapon crit chance bonus.
func _apply_area_damage_for_weapon(pos: Vector2, radius: float, effective_dmg: int, source: String) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and pos.distance_to(e.global_position) <= radius:
			var res = _get_final_damage_for_weapon(effective_dmg, source)
			e.take_damage(res.damage, source, res.is_crit)
			GameState.run_damage_stats[source] = GameState.run_damage_stats.get(source, 0) + res.damage

func _apply_blizzard_hit(pos: Vector2, radius: float, effective_dmg: int) -> void:
	_show_blizzard_strike(pos, radius)
	_apply_area_damage_for_weapon(pos, radius, effective_dmg, "blizzard")

	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and pos.distance_to(e.global_position) <= radius and e.has_method("freeze"):
			e.freeze(GameConstants.ICE_FREEZE_DURATION)

func _show_blizzard_strike(pos: Vector2, radius: float) -> void:
	var circle := Polygon2D.new()
	var pts := []
	for i in range(24):
		var angle := i * TAU / 24.0
		var wobble := randf_range(0.82, 1.08)
		pts.append(Vector2.RIGHT.rotated(angle) * radius * wobble)
	circle.polygon = PackedVector2Array(pts)
	circle.color = Color(0.75, 0.9, 1.0, 0.32)
	circle.global_position = pos
	circle.scale = Vector2(0.45, 0.45)
	circle.rotation = randf_range(-0.35, 0.35)
	circle.add_to_group("projectiles")
	get_tree().current_scene.add_child(circle)

	var tween := create_tween()
	tween.tween_property(circle, "scale", Vector2.ONE, 0.12)
	tween.parallel().tween_property(circle, "modulate:a", 0.0, 0.28)
	tween.tween_callback(circle.queue_free)

func get_damage() -> int:
	var dmg := float(base_damage + GameState.get_zap_damage_bonus())
	dmg *= GameState.get_damage_multiplier()
	return int(round(dmg))

func _get_final_damage(base_dmg: int) -> Dictionary:
	var dmg = GameState.get_total_damage(base_dmg)
	var is_crit = randf() < GameState.get_crit_chance()
	if is_crit:
		dmg = int(round(float(dmg) * GameState.get_crit_multiplier()))
	return {"damage": dmg, "is_crit": is_crit}

## Includes per-weapon crit chance bonus on top of the global crit chance.
func _get_final_damage_for_weapon(base_dmg: int, weapon_id: String) -> Dictionary:
	var dmg = GameState.get_total_damage(base_dmg)
	var crit_chance = GameState.get_crit_chance() + GameState.get_weapon_crit_chance_bonus(weapon_id)
	var is_crit = randf() < crit_chance
	if is_crit:
		dmg = int(round(float(dmg) * GameState.get_crit_multiplier()))
	return {"damage": dmg, "is_crit": is_crit}

func _get_fire_interval() -> float:
	var atk_mult := GameState.get_atkspd_multiplier() * GameState.get_zap_atk_speed_mult() * _atk_speed_boost_multiplier
	# Apply same logic to other timers
	var interval: float = fire_rate / max(atk_mult, 0.05)
	return max(interval, 0.02)

func _unhandled_input(event: InputEvent) -> void:
	# Tap / click-to-move for mobile & mouse
	if event is InputEventScreenTouch and event.pressed:
		_set_click_target(event.position)
	elif event is InputEventScreenDrag:
		_set_click_target(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_set_click_target(event.position)

func _set_click_target(screen_pos: Vector2) -> void:
	_click_target = get_canvas_transform().affine_inverse() * screen_pos
	_has_click_target = true

func _get_nearest_enemy() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var closest_dist := INF
	
	var cam := get_viewport().get_camera_2d()
	var screen_rect := Rect2()
	if cam:
		var center := cam.get_screen_center_position()
		var size := get_viewport_rect().size
		# Grow by slightly expanding the bounds so it acts right as they touch the edge
		screen_rect = Rect2(center - size / 2.0, size).grow(16.0)
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			if cam and not screen_rect.has_point(enemy.global_position):
				continue
				
			var dist := global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = enemy
	
	return closest

func fire(target: Node2D) -> void:
	can_fire = false
	fire_timer = _get_fire_interval()
	
	var count = 1 + GameState.run_extra_projectiles
	var dir = (target.global_position - global_position).normalized()
	
	for i in range(count):
		var bullet := bullet_scene.instantiate() as Area2D
		bullet.global_position = muzzle.global_position
		# Spread them slightly if extra
		var spread: float
		if i == 0:
			spread = 0.0
		else:
			var multiplier = int(floor((i + 1) / 2.0))
			if i % 2 == 1:
				spread = 0.2 * multiplier
			else:
				spread = -0.2 * multiplier
		var bullet_dir = dir.rotated(spread)
		bullet.rotation = bullet_dir.angle()
		bullet.direction = bullet_dir
		
		var zap_dmg = GameConstants.ZAP_BASE_DAMAGE + GameState.get_weapon_damage_bonus("zap")
		var res = _get_final_damage_for_weapon(zap_dmg, "zap")
		bullet.damage = res.damage
		if "is_crit" in bullet: bullet.is_crit = res.is_crit
		bullet.weapon_source = "zap"
		get_tree().current_scene.add_child(bullet)
		
	# Lifesteal (Sanguis)

func _fire_shotgun(target: Node2D) -> void:
	var count := GameState.get_shotgun_bullet_count()
	if count <= 0: return
	
	var base_rot := 0.0
	if is_instance_valid(target):
		base_rot = (target.global_position - global_position).angle()

	var spread := deg_to_rad(GameConstants.SHOTGUN_SPREAD_ANGLE)
	var start_angle := base_rot - spread / 2.0
	var step := 0.0
	if count > 1:
		step = spread / (count - 1)
	
	for i in range(count):
		var angle: float
		if i == 0:
			angle = base_rot
		else:
			var step_val = spread / (count - 1) if count > 1 else 0.0
			var multiplier = int(floor((i + 1) / 2.0))
			if i % 2 == 1:
				angle = base_rot + step_val * multiplier
			else:
				angle = base_rot - step_val * multiplier
		var bullet := bullet_scene.instantiate() as Area2D
		bullet.global_position = muzzle.global_position
		bullet.rotation = angle
		bullet.direction = Vector2.RIGHT.rotated(angle)
		var shotgun_dmg = base_damage + GameState.get_weapon_damage_bonus("shotgun")
		var res = _get_final_damage_for_weapon(shotgun_dmg, "shotgun")
		bullet.damage = res.damage
		if "is_crit" in bullet: bullet.is_crit = res.is_crit
		bullet.weapon_source = "shotgun"
		get_tree().current_scene.add_child(bullet)

func _get_visible_enemies() -> Array:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var visible_enemies: Array = []
	
	var cam := get_viewport().get_camera_2d()
	var screen_rect := Rect2()
	if cam:
		var center := cam.get_screen_center_position()
		var size := get_viewport_rect().size
		screen_rect = Rect2(center - size / 2.0, size).grow(16.0)
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			if cam and not screen_rect.has_point(enemy.global_position):
				continue
			visible_enemies.append(enemy)
	return visible_enemies

func _fire_sniper() -> void:
	var visible_enemies = _get_visible_enemies()
	if visible_enemies.is_empty():
		return
	
	# Target the enemy with the highest health
	var target = visible_enemies[0]
	for e in visible_enemies:
		if e.health > target.health:
			target = e
	
	if is_instance_valid(target):
		# Create visuals at target position
		_create_blood_effect(target.global_position)
		_create_crosshair_effect(target.global_position)
		# Instantly kill enemy
		if target.has_method("take_damage"):
			var sniper_dmg = GameConstants.SNIPER_DAMAGE + GameState.get_weapon_damage_bonus("sniper")
			var res = _get_final_damage_for_weapon(sniper_dmg, "sniper")
			var actual_dmg = target.take_damage(res.damage, "sniper", res.is_crit)
			GameState.run_damage_stats["sniper"] = GameState.run_damage_stats.get("sniper", 0) + actual_dmg

func _create_crosshair_effect(pos: Vector2) -> void:
	var ch = Node2D.new()
	ch.set_script(load("res://scripts/crosshair_effect.gd"))
	ch.global_position = pos
	ch.add_to_group("projectiles")
	get_tree().current_scene.add_child(ch)

func _create_blood_effect(pos: Vector2) -> void:
	var particles = CPUParticles2D.new()
	particles.global_position = pos
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 20
	particles.lifetime = 0.5
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 150.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 5.0
	particles.color = Color(0.8, 0.1, 0.1) # Blood red
	
	particles.add_to_group("projectiles")
	get_tree().current_scene.add_child(particles)
	
	# Auto free after emitting
	var timer = get_tree().create_timer(1.0)
	timer.timeout.connect(particles.queue_free)

func take_damage(amount: int = 1, attacker: Node2D = null) -> void:
	var percent_red = GameState.get_armor_percent()
	var after_percent = float(amount) * (1.0 - percent_red)
	var reduced = max(1, int(round(after_percent)) - GameState.get_armor())
	
	health -= reduced
	
	# Zephyros trait: Speed halved on damage
	if GameState.current_character == "speed_damage":
		GameState.run_speed_bonus *= 0.5
	
	# Thorns
	var thorns_pct = GameState.get_thorns_percentage()
	if thorns_pct > 0 and attacker and is_instance_valid(attacker):
		if attacker.has_method("take_damage"):
			# Enemies take a percentage of the damage they deal *before* armor
			attacker.take_damage(int(round(float(amount) * thorns_pct)), "thorns")
	
	# Flash red
	sprite.modulate = Color(1, 0.3, 0.3)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
	
	if health <= 0:
		player_died.emit()

func _get_spike_ball_cooldown() -> float:
	var lvl = GameState.run_abilities.get("spike_ball", 0)
	var cooldown = GameConstants.SPIKE_BALL_BASE_COOLDOWN - (lvl - 1) * GameConstants.SPIKE_BALL_COOLDOWN_REDUCTION_PER_LEVEL
	return max(0.5, cooldown)

func _fire_spike_ball(target: Node2D) -> void:
	var ball = spike_ball_scene.instantiate() as Area2D
	ball.global_position = global_position
	
	var dir := Vector2.RIGHT
	if is_instance_valid(target):
		dir = (target.global_position - global_position).normalized()
	
	ball.direction = dir
	var spike_dmg = GameConstants.SPIKE_BALL_BASE_DAMAGE + GameState.get_weapon_damage_bonus("spike_ball")
	var res = _get_final_damage_for_weapon(spike_dmg, "spike_ball")
	ball.damage = res.damage
	if "is_crit" in ball: ball.is_crit = res.is_crit
	var lvl = GameState.run_abilities.get("spike_ball", 0)
	ball.max_distance = GameConstants.SPIKE_BALL_BASE_DISTANCE + (lvl - 1) * GameConstants.SPIKE_BALL_DISTANCE_PER_LEVEL
	get_tree().current_scene.add_child(ball)

func _fire_rocket() -> void:
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	var candidates: Array = []
	
	for enemy in all_enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist <= GameConstants.ROCKET_TARGET_RADIUS:
				candidates.append(enemy)
				
	if candidates.is_empty():
		return
	
	var target = candidates.pick_random()
	if is_instance_valid(target):
		var rocket = rocket_scene.instantiate()
		rocket.global_position = muzzle.global_position
		rocket.target = target
		var rocket_dmg = GameConstants.ROCKET_DAMAGE + GameState.get_weapon_damage_bonus("rocket")
		var res = _get_final_damage_for_weapon(rocket_dmg, "rocket")
		rocket.damage = res.damage
		if "is_crit" in rocket: rocket.is_crit = res.is_crit
		rocket.blast_radius = GameState.get_rocket_blast_radius() * GameState.get_weapon_size_multiplier("rocket")
		
		# Initial direction towards target
		var dir = (target.global_position - muzzle.global_position).normalized()
		rocket.direction = dir
		rocket.rotation = dir.angle()
		
		get_tree().current_scene.add_child(rocket)

func heal_full() -> void:
	health = max_health
	# Flash green
	sprite.modulate = Color(0.3, 1.0, 0.3)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)

func apply_speed_boost(multiplier: float, duration: float) -> void:
	_speed_boost_multiplier = multiplier
	_speed_boost_duration = duration
	var tween := create_tween()
	sprite.modulate = Color(0.3, 0.3, 1.0)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.5)

func apply_atk_speed_boost(multiplier: float, duration: float) -> void:
	_atk_speed_boost_multiplier = multiplier
	_atk_speed_boost_duration = duration
	var tween := create_tween()
	sprite.modulate = Color(1.0, 0.3, 0.3)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.5)

func _fire_disk() -> void:
	var disk = disk_scene.instantiate()
	disk.global_position = global_position
	var lvl = GameState.run_abilities.get("bouncing_disk", 1)
	disk.bounces_left = GameState.get_weapon_bounces("bouncing_disk") if GameState.get_weapon_bounces("bouncing_disk") > 0 else lvl
	var disk_dmg = GameConstants.DISK_BASE_DAMAGE + GameState.get_weapon_damage_bonus("bouncing_disk")
	var res = _get_final_damage_for_weapon(disk_dmg, "bouncing_disk")
	disk.damage = res.damage
	if "is_crit" in disk: disk.is_crit = res.is_crit
	get_tree().current_scene.add_child(disk)

func _drop_spikes() -> void:
	var spikes = spikes_scene.instantiate()
	spikes.global_position = global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
	var spike_dmg = GameConstants.SPIKES_BASE_DAMAGE + GameState.get_weapon_damage_bonus("floor_spikes")
	var res = _get_final_damage_for_weapon(spike_dmg, "floor_spikes")
	spikes.damage = res.damage
	if "is_crit" in spikes: spikes.is_crit = res.is_crit
	get_tree().current_scene.add_child(spikes)

func _place_turret() -> void:
	var t = turret_scene.instantiate()
	t.global_position = global_position + Vector2.RIGHT.rotated(randf() * TAU) * 100.0
	t.damage = GameConstants.TURRET_DAMAGE + GameState.get_weapon_damage_bonus("turret")
	get_tree().current_scene.add_child(t)

func _trigger_ice_wave() -> void:
	var lvl = GameState.run_abilities.get("ice_wave", 1)
	var radius = GameConstants.ICE_BASE_RADIUS + lvl * GameConstants.ICE_RADIUS_INCREMENT
	
	# Visual effect
	var circle = Polygon2D.new()
	var pts = []
	var segments = 64
	for i in range(segments):
		var a = i * TAU / segments
		pts.append(Vector2.RIGHT.rotated(a) * radius)
	circle.polygon = PackedVector2Array(pts)
	circle.color = Color(0.4, 0.7, 1.0, 0.3)
	circle.global_position = global_position
	circle.add_to_group("projectiles")
	get_tree().current_scene.add_child(circle)
	
	var tween = create_tween()
	tween.tween_property(circle, "modulate:a", 0.0, 0.5)
	tween.tween_callback(circle.queue_free)
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and global_position.distance_to(e.global_position) <= radius:
			if e.has_method("freeze"):
				e.freeze(GameConstants.ICE_FREEZE_DURATION)
				GameState.record_kill("ice_wave")

func _fire_machine_gun(target: Node2D) -> void:
	if not target: return
	var b = bullet_scene.instantiate()
	b.global_position = muzzle.global_position
	var dir = (target.global_position - global_position).normalized()
	b.direction = dir
	b.rotation = dir.angle()
	var mg_dmg = GameConstants.MG_DAMAGE + GameState.get_weapon_damage_bonus("machine_gun")
	var res = _get_final_damage_for_weapon(mg_dmg, "machine_gun")
	b.damage = res.damage
	if "is_crit" in b: b.is_crit = res.is_crit
	b.weapon_source = "machine_gun"
	get_tree().current_scene.add_child(b)

func trigger_rocket_blast() -> void:
	var blast_pos = global_position
	
	# Calculate radius based on largest screen dimension
	var viewport_size = get_viewport_rect().size
	var largest_dim = max(viewport_size.x, viewport_size.y)
	var radius = largest_dim * GameConstants.PICKUP_EXPLOSION_RADIUS_MULTIPLIER
	
	var final_res = _get_final_damage(GameConstants.PICKUP_EXPLOSION_DAMAGE)
	var damage = final_res.damage
	
	var rocket_script = null
	if ResourceLoader.exists("res://scripts/rocket.gd"):
		rocket_script = load("res://scripts/rocket.gd")
	
	# Spawn visual circle at pickup position (no particles at pickup pos)
	if rocket_script and rocket_script.has_method("spawn_explosion"):
		rocket_script.spawn_explosion(get_tree().current_scene, blast_pos, radius, false, true, GameConstants.PICKUP_EXPLOSION_EXPAND_TIME)
	
	var affected_enemies = get_tree().get_nodes_in_group("enemies").duplicate()
	var current_scene = get_tree().current_scene
	var tween = get_tree().create_tween()
	
	# Use a tween to expand the "active" radius linearly over the expand time
	# This matches the visual expansion in rocket.gd and checks enemies in real-time
	tween.tween_method(func(current_radius: float):
		if not is_instance_valid(self) or not is_instance_valid(current_scene):
			return
			
		var remaining = []
		for enemy in affected_enemies:
			if is_instance_valid(enemy):
				var dist = blast_pos.distance_to(enemy.global_position)
				if dist <= current_radius:
					_apply_explosion_damage(enemy, damage, rocket_script)
				else:
					remaining.append(enemy)
		
		affected_enemies = remaining
	, 0.0, radius, GameConstants.PICKUP_EXPLOSION_EXPAND_TIME)

func _apply_explosion_damage(enemy, damage, rocket_script) -> void:
	if is_instance_valid(enemy):
		if enemy.has_method("take_damage"):
			var before_health = enemy.health
			var actual_dmg = enemy.take_damage(damage, "explosion_pickup")
			GameState.run_damage_stats["explosion_pickup"] = GameState.run_damage_stats.get("explosion_pickup", 0) + actual_dmg
			
			# Particle effect only on position of enemy that explosion kills
			if enemy.health <= 0 and before_health > 0:
				if rocket_script and rocket_script.has_method("spawn_explosion"):
					rocket_script.spawn_explosion(get_tree().current_scene, enemy.global_position, 0, true, false)
