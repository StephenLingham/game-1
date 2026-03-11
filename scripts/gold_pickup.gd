extends Area2D

var value: int = 1
var is_magnetized: bool = false
var player: Node2D = null

func _ready() -> void:
	add_to_group("gold_pickups")
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	body_entered.connect(_on_body_entered)
	
	# Scale based on value
	# Base scale is 1.0 for 1 gold, grows slightly for more.
	var s := 1.0 + (value - 1) * 0.2
	scale = Vector2(s, s)

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
		if global_position.distance_to(player.global_position) < 10.0:
			collect(player)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		collect(body)

func collect(_player: Node) -> void:
	GameState.run_gold += value
	queue_free()

