extends Area2D


func _ready() -> void:
	add_to_group("chests")
	
	# Visual setup - use image if provided, otherwise procedural
	var texture: Texture2D = null
	var potential_paths = [
		"res://assets/treasure_chest.png",
		"res://assets/treasure_chest.jpg"
	]
	
	for path in potential_paths:
		if ResourceLoader.exists(path):
			texture = load(path)
			if texture: break
	
	if texture:
		$Sprite2D.texture = texture
		$Sprite2D.visible = true
		$Visual.visible = false
	else:
		# Fallback if image is missing or didn't load yet
		$Sprite2D.visible = false
		$Visual.visible = true

	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect()

func _collect() -> void:
	# Show the window - pause logic is inside Main.gd
	var main = get_tree().current_scene
	if main and main.has_method("show_item_window"):
		main.show_item_window()
		
	# Visual feedback for ground
	_spawn_particles()
	queue_free()



func _spawn_particles() -> void:
	var p = CPUParticles2D.new()
	p.global_position = global_position
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 30
	p.lifetime = 1.0
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 100.0
	p.initial_velocity_max = 200.0
	p.scale_amount_min = 4.0
	p.scale_amount_max = 8.0
	p.color = Color.GOLD
	
	get_tree().current_scene.add_child(p)
	
	var timer = get_tree().create_timer(1.2)
	timer.timeout.connect(p.queue_free)
