extends Area2D

var value: int = 1
var is_magnetized: bool = false
var player: Node2D = null

func _ready() -> void:
	add_to_group("xp_drops")
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	body_entered.connect(_on_body_entered)
	
	# Scale slightly based on value
	var s := 0.8 + (float(value) / 100.0)
	scale = Vector2(s, s)
	
	modulate = Color(0.1, 0.4, 1.0) # Deep vibrant blue
	if has_node("CoinVisual"):
		$CoinVisual.modulate = Color(1.2, 1.4, 3.0) # Boost brightness for a glow effect

func _process(delta: float) -> void:
	if not is_magnetized:
		# Check if player is in range
		var p = get_tree().get_first_node_in_group("player")
		if p:
			var dist := global_position.distance_to(p.global_position)
			if dist <= GameState.get_pickup_radius():
				is_magnetized = true
				player = p
	
	if is_magnetized and is_instance_valid(player):
		var direction := (player.global_position - global_position).normalized()
		global_position += direction * GameConstants.MAGNET_SPEED * delta
		
		# If somehow missed or passed through, check distance again
		if global_position.distance_to(player.global_position) < 15.0:
			collect(player)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		collect(body)

func collect(_player: Node) -> void:
	GameState.add_xp(value)
	queue_free()

