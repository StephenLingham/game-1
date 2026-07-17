extends Area2D

var direction := Vector2.RIGHT
var speed := GameConstants.DISK_SPEED
var damage := GameConstants.DISK_BASE_DAMAGE
var is_crit := false
var bounces_left := 0
var last_enemy_hit: Node2D = null

func _ready() -> void:
	add_to_group("projectiles")
	body_entered.connect(_on_body_entered)
	# Mask 2 for enemies, 4 for walls
	collision_mask = 2 | 4
	
	# Hide the old placeholder if it exists
	if has_node("Visual"):
		$Visual.hide()
	queue_redraw()
	
	# Auto free after 10 seconds if it doesn't hit enough things
	get_tree().create_timer(10.0).timeout.connect(queue_free)

func _draw() -> void:
	# Draw a torus (thick ring)
	# Outer glow-ish ring
	draw_arc(Vector2.ZERO, 12, 0, TAU, 32, Color(1, 0.8, 0, 0.6), 8.0, true)
	# Main ring
	draw_arc(Vector2.ZERO, 12, 0, TAU, 32, Color(1, 0.9, 0.2), 4.0, true)
	# Central highlights
	draw_arc(Vector2.ZERO, 12, 0, TAU, 32, Color(1, 1, 0.8), 1.5, true)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	rotation += 15.0 * delta # Spinner

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		if is_instance_valid(body) and body != last_enemy_hit:
			if body.has_method("take_damage"):
				GameState.run_damage_stats["bouncing_disk"] = GameState.run_damage_stats.get("bouncing_disk", 0) + body.take_damage(damage, "bouncing_disk", is_crit)
			
			last_enemy_hit = body
			
			if bounces_left > 0:
				bounces_left -= 1
				_target_next_enemy()
			else:
				queue_free()
	elif body.is_in_group("walls"):
		if bounces_left > 0:
			bounces_left -= 1
			# Physical reflection bounce
			direction = direction.rotated(PI + randf_range(-0.5, 0.5))
			_target_next_enemy() # Also try to find a target
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
