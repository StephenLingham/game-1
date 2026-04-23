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

var disk_scene: PackedScene = preload("res://scenes/bouncing_disk.tscn")
var spikes_scene: PackedScene = preload("res://scenes/floor_spikes.tscn")
var turret_scene: PackedScene = preload("res://scenes/turret.tscn")

func _ready() -> void:
	add_to_group("player")
	refresh_stats()
	health = max_health

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
	# Zephyros (speed_damage) logic
	if GameState.current_character == "speed_damage":
		GameState.run_speed_bonus += 0.05 * delta # Gradual speed boost (+5% per second)
	
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
	elif _has_click_target:
		var to_target := _click_target - global_position
		if to_target.length() <= 4.0:
			_has_click_target = false
			velocity = Vector2.ZERO
		else:
			velocity = to_target.normalized() * speed
	else:
		velocity = Vector2.ZERO
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
	
	if can_fire and nearest_enemy and GameState.run_abilities.get("handgun", 0) > 0:
		fire()

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

func get_damage() -> int:
	var dmg := float(base_damage + GameState.get_gun_damage_bonus())
	dmg *= GameState.get_damage_multiplier()
	return int(round(dmg))

func _get_final_damage(base_dmg: int) -> Dictionary:
	var dmg = GameState.get_total_damage(base_dmg)
	var is_crit = randf() < GameState.get_crit_chance()
	if is_crit:
		dmg = int(round(float(dmg) * GameState.get_crit_multiplier()))
	return {"damage": dmg, "is_crit": is_crit}

func _get_fire_interval() -> float:
	var atk_mult := GameState.get_atkspd_multiplier() * GameState.get_gun_atk_speed_mult() * _atk_speed_boost_multiplier
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

func fire() -> void:
	can_fire = false
	fire_timer = _get_fire_interval()
	
	var count = 1 + GameState.run_extra_projectiles
	for i in range(count):
		var bullet := bullet_scene.instantiate() as Area2D
		bullet.global_position = muzzle.global_position
		# Spread them slightly if extra
		var spread = 0.1 * i if count > 1 else 0.0
		bullet.rotation = rotation + spread - (0.05 * (count-1))
		bullet.direction = Vector2.RIGHT.rotated(bullet.rotation)
		var res = _get_final_damage(base_damage)
		bullet.damage = res.damage
		if "is_crit" in bullet: bullet.is_crit = res.is_crit
		get_tree().current_scene.add_child(bullet)
		
	# Lifesteal (Sanguis)

func _fire_shotgun(target: Node2D) -> void:
	var count := GameState.get_shotgun_bullet_count()
	if count <= 0: return
	
	var base_rot := rotation
	if is_instance_valid(target):
		base_rot = (target.global_position - global_position).angle()

	var spread := deg_to_rad(GameConstants.SHOTGUN_SPREAD_ANGLE)
	var start_angle := base_rot - spread / 2.0
	var step := 0.0
	if count > 1:
		step = spread / (count - 1)
	
	for i in range(count):
		var angle := start_angle + step * i
		var bullet := bullet_scene.instantiate() as Area2D
		bullet.global_position = muzzle.global_position
		bullet.rotation = angle
		bullet.direction = Vector2.RIGHT.rotated(angle)
		var res = _get_final_damage(base_damage)
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
			var res = _get_final_damage(99999) # Sniper always gets a 'final damage' check for crit consistency
			GameState.run_damage_sniper += target.take_damage(res.damage, "sniper", res.is_crit)
			GameState.run_damage_stats["sniper"] = GameState.run_damage_stats.get("sniper", 0) + res.damage

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
	
	var dir := Vector2.RIGHT.rotated(rotation)
	if is_instance_valid(target):
		dir = (target.global_position - global_position).normalized()
	
	ball.direction = dir
	var res = _get_final_damage(GameConstants.SPIKE_BALL_BASE_DAMAGE)
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
		var res = _get_final_damage(GameConstants.ROCKET_DAMAGE)
		rocket.damage = res.damage
		if "is_crit" in rocket: rocket.is_crit = res.is_crit
		rocket.blast_radius = GameState.get_rocket_blast_radius()
		
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
	disk.bounces_left = lvl # Increase with each upgrade
	var res = _get_final_damage(GameConstants.DISK_BASE_DAMAGE)
	disk.damage = res.damage
	if "is_crit" in disk: disk.is_crit = res.is_crit
	get_tree().current_scene.add_child(disk)

func _drop_spikes() -> void:
	var spikes = spikes_scene.instantiate()
	spikes.global_position = global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
	var res = _get_final_damage(GameConstants.SPIKES_BASE_DAMAGE)
	spikes.damage = res.damage
	if "is_crit" in spikes: spikes.is_crit = res.is_crit
	get_tree().current_scene.add_child(spikes)

func _place_turret() -> void:
	var t = turret_scene.instantiate()
	t.global_position = global_position + Vector2.RIGHT.rotated(randf() * TAU) * 100.0
	t.damage = GameConstants.TURRET_DAMAGE
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
	var res = _get_final_damage(GameConstants.MG_DAMAGE)
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
