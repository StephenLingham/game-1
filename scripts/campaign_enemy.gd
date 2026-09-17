extends "res://scripts/enemy.gd"

const FIRE_ATLAS := preload("res://assets/campaign/crimson-creatures.png")
const DARK_ATLAS := preload("res://assets/campaign/obsidian-creatures.png")
const HAZARD := preload("res://scripts/enemy_hazard.gd")
var behavior := ""
var ability_time := 2.0
var life_time := 0.0
var charge_left := 0.0
var charge_direction := Vector2.ZERO
var windup := 0.0
var tint := Color("ff7848")
var attacks_cast := 0

func _ready() -> void:
	super._ready()
	var data := RunCampaign.enemy_data(enemy_type)
	health = int(data.health * GameState.run_difficulty_health_mult)
	max_health = health
	damage = int(data.damage * GameState.run_difficulty_damage_mult)
	speed = float(data.speed)
	attack_cooldown = 1.0
	xp_drop_min = int(data.xp)
	xp_drop_max = int(data.xp * 1.3)
	behavior = data.behavior
	ability_time = randf_range(1.2, 2.8)
	tint = Color("b8a0ff") if data.dark else Color("ff7848")
	var atlas := AtlasTexture.new()
	atlas.atlas = DARK_ATLAS if data.dark else FIRE_ATLAS
	var cell_size := atlas.atlas.get_size() / Vector2(3, 2)
	var index := int(data.cell)
	atlas.region = Rect2(Vector2(index % 3, index / 3) * cell_size, cell_size)
	# The dark atlas has a shorter top row; crop at its actual transparent
	# gutter so neighboring crowns/scythes never appear beneath normal mobs.
	if data.dark:
		atlas.region = Rect2(Vector2((index % 3) * cell_size.x, 0 if index < 3 else 450), Vector2(cell_size.x, 450 if index < 3 else 574))
	atlas.filter_clip = true
	sprite.texture = atlas
	sprite.scale = Vector2.ONE * float(data.size) / maxf(atlas.region.size.x, atlas.region.size.y)
	_set_collision_radius(float(data.size) * 0.24, float(data.size) * 0.29)
	if _boss_health_bar:
		_boss_health_bar.position.y = -maxf(0.0, float(data.size) * 0.5 - 90.0)
		var title := Label.new()
		title.text = enemy_type.capitalize()
		title.position = Vector2(-140, -160)
		title.size.x = 280
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 16)
		title.add_theme_color_override("font_color", tint)
		_boss_health_bar.add_child(title)
	_update_boss_health_bar()

func _modify_movement(default_velocity: Vector2, delta: float) -> Vector2:
	if _death_processed or _freeze_timer > 0 or not is_instance_valid(target):
		return Vector2.ZERO
	life_time += delta
	ability_time -= delta
	var offset := target.global_position - global_position
	var distance := offset.length()
	var dir := offset.normalized()
	if charge_left > 0:
		charge_left -= delta
		return charge_direction * speed * 4.5 * _slow_factor
	if windup > 0:
		windup -= delta
		queue_redraw()
		if windup <= 0:
			charge_left = 0.7
		return Vector2.ZERO
	if ability_time <= 0 and distance < 850:
		_cast_ability(dir)
		ability_time = 3.6 if RunCampaign.is_boss(enemy_type) else 4.5
	match behavior:
		"orbit":
			return (dir * clampf((distance - 230.0) / 100.0, -1, 1) + dir.orthogonal() * 0.8).normalized() * speed * _slow_factor
		"breath":
			return dir * speed * _slow_factor * clampf((distance - 220.0) / 90.0, -0.7, 1.0)
		"phase":
			var phasing := fmod(life_time, 4.0) < 1.2
			sprite.self_modulate.a = 0.38 if phasing else 1.0
			return default_velocity * (2.0 if phasing else 0.65)
	return default_velocity

func _cast_ability(dir: Vector2) -> void:
	attacks_cast += 1
	match behavior:
		"breath":
			_fan(dir, 5 if RunCampaign.is_miniboss(enemy_type) else 3)
		"slam":
			_slam(target.global_position, 105 if RunCampaign.is_miniboss(enemy_type) else 70)
		"orbit":
			_bolt(dir)
		"charge":
			charge_direction = dir
			windup = 0.85
		"banshee":
			_ring(10)
			_slam(target.global_position, 85)
		"inferno":
			_fan(dir, 7)
			for i in range(3):
				_slam(target.global_position + Vector2.from_angle(TAU * float(i) / 3.0) * 115.0, 85)
		"death":
			_ring(14)
			_slam(target.global_position, 115)
			charge_direction = dir
			windup = 1.0

func _fan(dir: Vector2, count: int) -> void:
	for i in range(count):
		_bolt(dir.rotated((float(i) - float(count - 1) / 2.0) * 0.18))

func _ring(count: int) -> void:
	for i in range(count):
		_bolt(Vector2.from_angle(TAU * float(i) / float(count) + life_time * 0.3))

func _bolt(dir: Vector2) -> void:
	var attack := HAZARD.new()
	attack.position = global_position
	attack.direction = dir
	attack.speed = 210.0
	attack.damage = maxi(1, int(damage * 0.65))
	attack.tint = tint
	get_tree().current_scene.add_child(attack)

func _slam(pos: Vector2, size: float) -> void:
	var attack := HAZARD.new()
	attack.position = pos
	attack.radius = size
	attack.warning = 1.1
	attack.lifetime = 0.45
	attack.damage = damage
	attack.tint = tint
	get_tree().current_scene.add_child(attack)

func _draw() -> void:
	if windup > 0:
		draw_line(Vector2.ZERO, charge_direction * speed * 4.5 * 0.7, Color(tint, 0.65), 8.0, true)
