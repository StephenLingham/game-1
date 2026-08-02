extends StaticBody2D

var damage := GameConstants.TURRET_DAMAGE
var fire_rate := GameConstants.TURRET_FIRE_RATE
var timer := 0.0
var bullet_scene = preload("res://scenes/bullet.tscn")

func _ready() -> void:
	add_to_group("projectiles")
	z_index = -1
	# Completely disable collision
	collision_layer = 0
	collision_mask = 0
	
func _physics_process(delta: float) -> void:
	timer -= delta
	var target = _get_nearest_enemy()
	if target:
		look_at(target.global_position)
		if timer <= 0:
			_fire(target)
			var mult = 1.0
			var p = get_tree().get_first_node_in_group("player")
			if p != null and "_atk_speed_boost_multiplier" in p:
				mult = p._atk_speed_boost_multiplier
			timer = 1.0 / max(fire_rate * mult * GameState.get_atkspd_multiplier() * GameState.get_turret_atk_speed_mult(), 0.05)
	elif timer <= 0:
		timer = 0.0 # Reset so it fires as soon as it sees an enemy

func _get_nearest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var min_dist = 600.0 # Range
	
	for e in enemies:
		var d = global_position.distance_to(e.global_position)
		if d < min_dist:
			min_dist = d
			closest = e
	return closest

func _fire(target: Node2D) -> void:
	var count := GameState.get_projectiles()
	for i in range(count):
		var b = bullet_scene.instantiate()
		# Fire from the tip of the barrel (40px)
		b.global_position = global_position + Vector2.RIGHT.rotated(rotation) * 40.0
		var dir: Vector2 = (target.global_position - b.global_position).normalized()
		dir = dir.rotated((float(i) - float(count - 1) / 2.0) * 0.08)
		b.direction = dir
		b.rotation = dir.angle()
		var final_dmg := GameState.get_total_damage(damage)
		var is_crit := false
		var player := get_tree().get_first_node_in_group("player")
		if player and player.has_method("roll_weapon_damage"):
			var result: Dictionary = player.roll_weapon_damage(damage, "turret")
			final_dmg = int(result.damage)
			is_crit = bool(result.is_crit)
		else:
			is_crit = randf() < GameState.get_crit_chance()
			if is_crit:
				final_dmg = int(round(float(final_dmg) * GameState.get_crit_multiplier()))
		b.damage = final_dmg
		b.is_crit = is_crit
		b.weapon_source = "turret"
		get_tree().current_scene.add_child(b)
