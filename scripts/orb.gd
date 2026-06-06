extends Area2D

var damage: int = GameConstants.ORB_DAMAGE
var weapon_source: String = "orbs"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		var stat_source := weapon_source
		if stat_source == "arcane_orbs":
			stat_source = "orbs"
		var actual_dmg = body.take_damage(damage, weapon_source)
		GameState.run_damage_orbs += actual_dmg
		GameState.run_damage_stats[stat_source] = GameState.run_damage_stats.get(stat_source, 0) + actual_dmg
