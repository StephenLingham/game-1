extends Area2D
class_name Rocket

var speed: float = GameConstants.ROCKET_SPEED
var turn_speed: float = GameConstants.ROCKET_TURN_SPEED
var damage: int = 1
var blast_radius: float = 100.0
var target: Node2D = null

var direction := Vector2.RIGHT
var lifetime: float = 5.0
var time_alive: float = 0.0

@onready var trail: CPUParticles2D = CPUParticles2D.new()

func _ready() -> void:
	# Connect signal manually since Tscn might have issues
	body_entered.connect(_on_body_entered)
	
	# Setup trail
	trail.amount = 30
	trail.lifetime = 0.3
	trail.local_coords = false
	trail.gravity = Vector2.ZERO
	trail.spread = 15.0
	trail.initial_velocity_min = 30.0
	trail.initial_velocity_max = 60.0
	trail.scale_amount_min = 2.0
	trail.scale_amount_max = 6.0
	trail.color = Color(0.8, 0.8, 0.8, 0.4)
	add_child(trail)

func _physics_process(delta: float) -> void:
	if is_instance_valid(target):
		var target_dir = (target.global_position - global_position).normalized()
		var current_dir = direction
		
		# Smoothly rotate direction towards target
		var angle_to = current_dir.angle_to(target_dir)
		var rotation_amount = sign(angle_to) * min(abs(angle_to), turn_speed * delta)
		direction = current_dir.rotated(rotation_amount)
		rotation = direction.angle()
	
	position += direction * speed * delta
	trail.direction = -direction
	
	time_alive += delta
	if time_alive >= lifetime:
		explode()

func _on_body_entered(body: Node2D) -> void:
	if body == target:
		explode()
	elif body.is_in_group("walls"):
		explode()

func explode() -> void:
	spawn_explosion(get_tree().current_scene, global_position, blast_radius)
	_do_aoe_damage()
	queue_free()

func _do_aoe_damage() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist <= blast_radius:
				if enemy.has_method("take_damage"):
					var prev_health = enemy.health
					GameState.run_damage_rocket += min(damage, prev_health)
					enemy.take_damage(damage)
					# If enemy died from this explosion, spawn another visual explosion there
					if enemy.health <= 0 and prev_health > 0:
						spawn_explosion(get_tree().current_scene, enemy.global_position, 0)

static func spawn_explosion(parent: Node, pos: Vector2, radius: float = 0.0) -> void:
	# 1. Main Explosion Particles
	var particles = CPUParticles2D.new()
	particles.global_position = pos
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 60
	particles.lifetime = 0.8
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 300.0
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 10.0
	
	var color_ramp = Gradient.new()
	var colors = PackedColorArray([
		Color(1, 1, 0.6), # Yellow
		Color(1, 0.5, 0), # Orange
		Color(0.8, 0.2, 0), # Red
		Color(0.2, 0.2, 0.2, 0) # Fade
	])
	var offsets = PackedFloat32Array([0.0, 0.2, 0.5, 1.0])
	color_ramp.colors = colors
	color_ramp.offsets = offsets
	particles.color_ramp = color_ramp
	
	parent.add_child(particles)
	parent.get_tree().create_timer(1.0).timeout.connect(particles.queue_free)

	# 2. Fiery Blast Circle (only if radius > 0)
	if radius > 0:
		var circle = Polygon2D.new()
		circle.global_position = pos
		var pts = []
		var segments = 32
		for i in range(segments):
			var a = i * TAU / segments
			pts.append(Vector2.RIGHT.rotated(a) * radius)
		circle.polygon = PackedVector2Array(pts)
		
		# Give it a fiery orange-red color
		circle.color = Color(1, 0.4, 0, 0.4)
		parent.add_child(circle)
		
		var tween = parent.create_tween()
		tween.set_parallel(true)
		tween.tween_property(circle, "scale", Vector2(1.1, 1.1), 0.25)
		tween.tween_property(circle, "modulate:a", 0.0, 0.25)
		tween.chain().tween_callback(circle.queue_free)
