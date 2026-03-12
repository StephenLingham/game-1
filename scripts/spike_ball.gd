extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 400.0
var damage: int = 10
var max_distance: float = 400.0
var travel_distance: float = 0.0

var _hit_enemies: Array = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	var motion = direction * speed * delta
	global_position += motion
	travel_distance += motion.length()
	
	rotation += 8.0 * delta # Spinnnn
	
	if travel_distance >= max_distance:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hitbox"):
		_damage_enemy(area.get_parent())

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		_damage_enemy(body)

func _damage_enemy(enemy: Node) -> void:
	if enemy in _hit_enemies:
		return
	
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
		_hit_enemies.append(enemy)
