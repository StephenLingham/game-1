extends Area2D

var damage: int = GameConstants.ORB_DAMAGE
var weapon_source: String = "orbs"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		var final_damage := damage
		var is_crit := false
		var player := get_tree().get_first_node_in_group("player")
		if player and player.has_method("roll_weapon_damage"):
			var result: Dictionary = player.roll_weapon_damage(damage, weapon_source)
			final_damage = int(result.damage)
			is_crit = bool(result.is_crit)
		else:
			final_damage = GameState.get_total_damage(damage)
		var actual_dmg: int = body.take_damage(final_damage, weapon_source, is_crit)
		GameState.run_damage_stats[weapon_source] = GameState.run_damage_stats.get(weapon_source, 0) + actual_dmg
