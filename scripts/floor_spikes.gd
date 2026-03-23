extends Area2D

var damage := GameConstants.SPIKES_BASE_DAMAGE

func _ready() -> void:
	add_to_group("projectiles")
	z_index = -1
	# Mask 2 for enemies
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	if has_node("Visual"):
		$Visual.hide()
	queue_redraw()
	
	# Scale animation
	scale = Vector2.ZERO
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)

func _draw() -> void:
	# Draw 4 small triangular spikes in a cluster
	var spike_color = Color(0.7, 0.7, 0.75)
	var spike_points = [
		[Vector2(-15, 15), Vector2(-5, 15), Vector2(-10, -5)], # Top Left
		[Vector2(5, 15), Vector2(15, 15), Vector2(10, -5)],  # Top Right
		[Vector2(-15, 5), Vector2(-5, 5), Vector2(-10, -15)], # Bottom Left
		[Vector2(5, 5), Vector2(15, 5), Vector2(10, -15)]    # Bottom Right
	]
	
	for pts in spike_points:
		draw_colored_polygon(PackedVector2Array(pts), spike_color)
		# Add a small outline
		draw_polyline(PackedVector2Array([pts[0], pts[2], pts[1]]), Color(0.4, 0.4, 0.4), 1.0)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		if is_instance_valid(body):
			if body.has_method("take_damage"):
				GameState.run_damage_stats["floor_spikes"] = GameState.run_damage_stats.get("floor_spikes", 0) + body.take_damage(damage, "floor_spikes")
