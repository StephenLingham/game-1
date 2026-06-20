extends Area2D

var value: int = 1
var is_magnetized: bool = false
var player: Node2D = null

const TEXTURE_1 = preload("res://assets/xp-pick-up-cropped.png")
#const TEXTURE_2 = preload("res://assets/xp-pick-up-2-cropped.png")

func _ready() -> void:
	add_to_group("xp_drops")
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	body_entered.connect(_on_body_entered)
	
	if has_node("CoinVisual"):
		$CoinVisual.texture = TEXTURE_1 # if randf() < 0.5 else TEXTURE_2
	
	# Scale slightly based on value
	var s := 0.8 + (float(value) / 100.0)
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
		if global_position.distance_to(player.global_position) < 15.0:
			collect(player)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		collect(body)

func collect(player: Node) -> void:
	GameState.add_xp(value)
	if player and player.has_method("on_xp_collected"):
		player.on_xp_collected(value)
	queue_free()

