extends Area2D

var rarity: String = "common"
var stat_key: String = "damage"
var stat_value: float = 0.0

const TEXTURE_PATH = "res://assets/gift.png"
const FLOATING_TEXT_SCENE = preload("res://scripts/floating_text.gd") # We'll instantiate the script directly or create a scene

func _ready() -> void:
	add_to_group("gifts")
	
	# Randomize rarity and stat if not set
	if rarity == "common": # Default value
		rarity = GameState.roll_rarity()
	
	var stats_keys = GameConstants.GIFT_STATS.keys()
	stat_key = stats_keys[randi() % stats_keys.size()]
	
	var base_amount = GameConstants.GIFT_RARITY_VALUES[rarity]
	var stat_data = GameConstants.GIFT_STATS[stat_key]
	stat_value = base_amount * stat_data["weight"]
	
	# Visuals
	_setup_visuals()
	
	body_entered.connect(_on_body_entered)
	
	# Subtle scale animation instead of bobbing
	var tween = create_tween().set_loops()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _setup_visuals() -> void:
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	if ResourceLoader.exists(TEXTURE_PATH):
		sprite.texture = load(TEXTURE_PATH)
	else:
		# Fallback if image is missing
		sprite.texture = preload("res://icon.svg")
		sprite.modulate = Color.RED
		push_warning("Gift: Could not find texture at " + TEXTURE_PATH)
		
	sprite.scale = Vector2(0.03, 0.03) # 0.25 of 0.12
	sprite.z_index = 5 # Above grass
	add_child(sprite)
	
	# Collision
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 15.0 # Scaled down collision
	shape.shape = circle
	add_child(shape)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect()

func _collect() -> void:
	# Apply stat boost
	var stat_data = GameConstants.GIFT_STATS[stat_key]
	var internal_stat = stat_data["internal_stat"]
	
	var current = GameState.run_gift_bonuses.get(internal_stat, 0.0)
	GameState.run_gift_bonuses[internal_stat] = current + stat_value
	
	# Refresh player stats if needed
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("refresh_stats"):
		player.refresh_stats()
	
	# Visual feedback: Floating Text
	_show_floating_text()
	
	queue_free()

func _show_floating_text() -> void:
	var stat_data = GameConstants.GIFT_STATS[stat_key]
	var display_text = ""
	
	if stat_key == "crit_chance" or stat_key == "speed" or stat_key == "atk_speed":
		display_text = stat_data["display"] % (stat_value * 100.0)
	else:
		display_text = stat_data["display"] % stat_value
		
	var rarity_color = GameConstants.RARITY_COLORS[rarity]
	
	var ft_script = load("res://scripts/floating_text.gd")
	var ft = Node2D.new()
	ft.set_script(ft_script)
	ft.text = display_text
	ft.color = rarity_color
	ft.global_position = global_position
	get_tree().current_scene.add_child(ft)

