extends Area2D

@export var speed: float = 800.0
@export var lifetime: float = 2.0
@export var damage: int = 1

var direction := Vector2.RIGHT
var time_alive: float = 0.0
var weapon_source: String = "zap"
var is_crit: bool = false
var bounces_left: int = 0
var last_hit_enemy: Node2D = null
## When > 0, hitting an enemy triggers an area explosion at that radius (e.g. fireball)
var area_radius: float = 0.0

var is_frozen_orb_shard: bool = false
var _frozen_orb_timer: float = 0.0
var _frozen_orb_angle: float = 0.0
var _exploded: bool = false

func _ready() -> void:
	add_to_group("projectiles")
	_setup_visuals()

func _setup_visuals() -> void:
	var cr = get_node_or_null("ColorRect")
	if cr:
		if weapon_source == "frozen_orb":
			if not is_frozen_orb_shard:
				cr.visible = false
				queue_redraw()
			else:
				# Shard base color to white so modulation is pure blue
				cr.color = Color.WHITE
		elif weapon_source != "zap":
			# Set base color to white for all other elemental weapons so their modulations are pure and beautiful!
			cr.color = Color.WHITE

func _draw() -> void:
	if weapon_source == "frozen_orb" and not is_frozen_orb_shard:
		# Draw a premium, beautiful glowing icy circle!
		draw_circle(Vector2.ZERO, 10.0, Color(0.0, 0.5, 1.0, 0.4)) # Outer glow
		draw_circle(Vector2.ZERO, 7.0, Color(0.2, 0.7, 1.0, 0.8)) # Mid layer
		draw_circle(Vector2.ZERO, 4.0, Color(0.8, 0.95, 1.0, 1.0)) # Icy white core

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	time_alive += delta
	if time_alive >= lifetime:
		_orb_free()

	if weapon_source == "frozen_orb" and not is_frozen_orb_shard:
		_frozen_orb_timer -= delta
		if _frozen_orb_timer <= 0:
			_frozen_orb_timer = 0.1
			_shoot_frozen_orb_shards()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		if body == last_hit_enemy: return # Prevent double hit
		
		if area_radius > 0.0:
			# Area explosion (e.g. fireball) — damage all enemies within radius
			var enemies = get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if is_instance_valid(e) and global_position.distance_to(e.global_position) <= area_radius:
					var actual = e.take_damage(damage, weapon_source, is_crit)
					GameState.run_damage_stats[weapon_source] = GameState.run_damage_stats.get(weapon_source, 0) + actual
			_orb_free()
		else:
			var actual_dmg = body.take_damage(damage, weapon_source, is_crit)
			GameState.run_damage_stats[weapon_source] = GameState.run_damage_stats.get(weapon_source, 0) + actual_dmg
			
			if bounces_left > 0 and _can_weapon_bounce(weapon_source):
				bounces_left -= 1
				last_hit_enemy = body
				_redirect_to_next_enemy(body.global_position)
			else:
				_orb_free()
	elif body.is_in_group("walls"):
		_orb_free()

func _orb_free() -> void:
	if _exploded: return
	_exploded = true
	if weapon_source == "frozen_orb" and not is_frozen_orb_shard:
		_explode_frozen_orb()
	queue_free()

func _can_weapon_bounce(source: String) -> bool:
	var bouncers = ["lightning_bolt", "ice_bolt", "fire_bolt", "arcane_bolt", "bouncing_disk"]
	return source in bouncers

func _redirect_to_next_enemy(current_pos: Vector2) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var dist := INF
	
	for e in enemies:
		if e == last_hit_enemy or not is_instance_valid(e): continue
		var d = current_pos.distance_to(e.global_position)
		if d < dist:
			dist = d
			nearest = e
	
	if nearest:
		direction = (nearest.global_position - current_pos).normalized()
		rotation = direction.angle()
	else:
		queue_free()

func _shoot_frozen_orb_shards() -> void:
	var directions = [
		Vector2.RIGHT.rotated(_frozen_orb_angle),
		Vector2.RIGHT.rotated(_frozen_orb_angle + PI)
	]
	
	var shard_scene = load("res://scenes/bullet.tscn")
	for dir in directions:
		var shard = shard_scene.instantiate()
		shard.global_position = global_position
		shard.direction = dir
		shard.rotation = dir.angle()
		shard.speed = 400.0
		shard.scale = Vector2(0.8, 0.8)
		shard.modulate = Color(0.6, 0.9, 1.0)
		shard.weapon_source = "frozen_orb"
		shard.is_frozen_orb_shard = true
		shard.damage = max(1, int(damage * 0.4))
		shard.is_crit = is_crit
		shard.lifetime = 0.8
		get_tree().current_scene.call_deferred("add_child", shard)
		
	_frozen_orb_angle += 0.35

func _explode_frozen_orb() -> void:
	var shard_scene = load("res://scenes/bullet.tscn")
	var num_shards = 16
	for i in range(num_shards):
		var angle = i * (TAU / num_shards)
		var dir = Vector2.RIGHT.rotated(angle)
		var shard = shard_scene.instantiate()
		shard.global_position = global_position
		shard.direction = dir
		shard.rotation = angle
		shard.speed = 500.0
		shard.scale = Vector2(1.0, 1.0)
		shard.modulate = Color(0.4, 0.8, 1.0)
		shard.weapon_source = "frozen_orb"
		shard.is_frozen_orb_shard = true
		shard.damage = max(1, int(damage * 0.6))
		shard.is_crit = is_crit
		shard.lifetime = 1.0
		get_tree().current_scene.call_deferred("add_child", shard)
