extends Node2D

var orb_scene := preload("res://scenes/orb.tscn")
var orbs: Array[Node2D] = []
var rotation_angle: float = 0.0

func _process(delta: float) -> void:
	# Keep the controller locked to world rotation so orbs don't spin with the player
	global_rotation = 0.0
	
	var target_count = GameState.get_orb_count()
	
	# Update orb count if needed
	if orbs.size() != target_count:
		_refresh_orbs(target_count)
	
	if target_count == 0:
		return
		
	# Rotate
	rotation_angle += GameState.get_orb_speed() * delta
	if rotation_angle > TAU:
		rotation_angle -= TAU
		
	# Position orbs
	for i in range(orbs.size()):
		var angle = rotation_angle + (i * TAU / float(max(1, orbs.size())))
		orbs[i].position = Vector2.RIGHT.rotated(angle) * GameConstants.ORB_RADIUS

func _refresh_orbs(count: int) -> void:
	# Clear old
	for o in orbs:
		if is_instance_valid(o):
			o.queue_free()
	orbs.clear()
	
	# Spawn new
	for i in range(count):
		var orb = orb_scene.instantiate()
		add_child(orb)
		orbs.append(orb)
