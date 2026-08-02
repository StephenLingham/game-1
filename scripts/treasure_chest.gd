extends Area2D

func _ready() -> void:
	add_to_group("chests")

	$Sprite2D.scale = Vector2.ONE * GameConstants.CHEST_SPRITE_SCALE
	var collision_shape := $CollisionShape2D.shape as CircleShape2D
	collision_shape.radius = GameConstants.CHEST_COLLISION_RADIUS

	var texture: Texture2D = null
	var potential_paths = [
		"res://assets/chest2.png"
	]

	for path in potential_paths:
		if ResourceLoader.exists(path):
			texture = load(path)
			if texture:
				break

	if texture:
		$Sprite2D.texture = texture
		$Sprite2D.visible = true
		$Visual.visible = false
	else:
		$Sprite2D.visible = false
		$Visual.visible = true

	body_entered.connect(_on_body_entered)

func _process(_delta: float) -> void:
	if not GameState.has_run_item("chest_vacuum"):
		return
	var player = get_tree().get_first_node_in_group("player")
	if player and global_position.distance_to(player.global_position) <= GameState.get_pickup_radius():
		_collect()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect()

func _collect() -> void:
	var main = get_tree().current_scene
	if main and main.has_method("show_item_window"):
		main.show_item_window()

	GameState.record_chest_opened()

	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("on_chest_opened"):
		player.on_chest_opened()

	queue_free()
