extends Area2D

var damage := GameConstants.SPIKES_BASE_DAMAGE

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	# Disappear after 15 seconds
	get_tree().create_timer(15.0).timeout.connect(queue_free)
	
	# Scale animation
	scale = Vector2.ZERO
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hitbox"):
		var enemy = area.get_parent()
		if is_instance_valid(enemy):
			if enemy.has_method("take_damage"):
				GameState.run_damage_stats["floor_spikes"] = GameState.run_damage_stats.get("floor_spikes", 0) + enemy.take_damage(damage)
			queue_free()
