extends Area2D

@export var speed: float = 800.0
@export var lifetime: float = 2.0
@export var damage: int = 1

var direction := Vector2.RIGHT
var time_alive: float = 0.0
var weapon_source: String = "handgun" # "handgun", "shotgun"

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	time_alive += delta
	if time_alive >= lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		var actual_dmg = body.take_damage(damage)
		# Track damage dealt
		match weapon_source:
			"handgun":
				GameState.run_damage_handgun += actual_dmg
			"shotgun":
				GameState.run_damage_shotgun += actual_dmg
		queue_free()
	elif body.is_in_group("walls"):
		queue_free()

