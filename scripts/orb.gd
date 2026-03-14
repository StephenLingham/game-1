extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		var actual_dmg = body.take_damage(GameConstants.ORB_DAMAGE)
		GameState.run_damage_orbs += actual_dmg
