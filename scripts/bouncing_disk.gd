extends Area2D

var direction := Vector2.RIGHT
var speed := GameConstants.DISK_SPEED
var damage := GameConstants.DISK_BASE_DAMAGE
var bounces_left := 0
var last_enemy_hit: Node2D = null

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	# Auto free after 10 seconds if it doesn't hit enough things
	get_tree().create_timer(10.0).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hitbox"):
		var enemy = area.get_parent()
		if is_instance_valid(enemy) and enemy != last_enemy_hit:
			if enemy.has_method("take_damage"):
				GameState.run_damage_stats["bouncing_disk"] = GameState.run_damage_stats.get("bouncing_disk", 0) + enemy.take_damage(damage)
			
			last_enemy_hit = enemy
			
			if bounces_left > 0:
				bounces_left -= 1
				_target_next_enemy()
			else:
				queue_free()

func _target_next_enemy() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var min_dist = INF
	
	for e in enemies:
		if e == last_enemy_hit: continue
		var d = global_position.distance_to(e.global_position)
		if d < min_dist:
			min_dist = d
			closest = e
	
	if closest:
		direction = (closest.global_position - global_position).normalized()
	else:
		# Just bounce in a random direction if no enemies
		direction = direction.rotated(PI + randf_range(-1, 1))
