extends StaticBody2D

var damage := GameConstants.TURRET_DAMAGE
var fire_rate := GameConstants.TURRET_FIRE_RATE
var timer := 0.0
var bullet_scene = preload("res://scenes/bullet.tscn")

func _ready() -> void:
	add_to_group("projectiles")
	z_index = -1
	# Completely disable collision
	collision_layer = 0
	collision_mask = 0
	
	# Disappear after 10 seconds
	get_tree().create_timer(10.0).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	timer -= delta
	if timer <= 0:
		var target = _get_nearest_enemy()
		if target:
			_fire(target)
			timer = 1.0 / fire_rate

func _get_nearest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var min_dist = 600.0 # Range
	
	for e in enemies:
		var d = global_position.distance_to(e.global_position)
		if d < min_dist:
			min_dist = d
			closest = e
	return closest

func _fire(target: Node2D) -> void:
	var b = bullet_scene.instantiate()
	b.global_position = global_position
	var dir = (target.global_position - global_position).normalized()
	b.direction = dir
	b.rotation = dir.angle()
	b.damage = damage
	b.weapon_source = "turret"
	get_tree().current_scene.add_child(b)
