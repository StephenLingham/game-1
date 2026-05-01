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

func _ready() -> void:
	add_to_group("projectiles")

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	time_alive += delta
	if time_alive >= lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		if body == last_hit_enemy: return # Prevent double hit
		
		var actual_dmg = body.take_damage(damage, weapon_source, is_crit)
		GameState.run_damage_stats[weapon_source] = GameState.run_damage_stats.get(weapon_source, 0) + actual_dmg
		
		if bounces_left > 0 and _can_weapon_bounce(weapon_source):
			bounces_left -= 1
			last_hit_enemy = body
			_redirect_to_next_enemy(body.global_position)
		else:
			queue_free()
	elif body.is_in_group("walls"):
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
