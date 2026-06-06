extends Area2D

var rarity: String = "common"
var stat_key: String = "damage"
var stat_value: float = 0.0

const TEXTURE_PATH = "res://assets/gift.png"
const FLOATING_TEXT_SCENE = preload("res://scripts/floating_text.gd") # We'll instantiate the script directly or create a scene

func _ready() -> void:
	add_to_group("gifts")
	
	if not GameConstants.GIFT_RARITY_VALUES.has(rarity):
		rarity = "common"
	
	var stats_keys = GameConstants.GIFT_STATS.keys()
	if not GameConstants.GIFT_STATS.has(stat_key):
		stat_key = stats_keys[randi() % stats_keys.size()]
	
	var rarity_amount = float(GameConstants.GIFT_RARITY_VALUES.get(rarity, 0.0))
	var stat_data = GameConstants.GIFT_STATS[stat_key]
	stat_value = rarity_amount * float(stat_data.get("weight", 0.0))
	
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
	
	sprite.modulate = GameConstants.RARITY_COLORS.get(rarity, Color.WHITE)
		
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
	# Apply the main stat boost selected for this gift.
	var stat_data = GameConstants.GIFT_STATS[stat_key]
	var internal_stat = stat_data["internal_stat"]
	var current = GameState.run_gift_bonuses.get(internal_stat, 0.0)
	GameState.run_gift_bonuses[internal_stat] = current + stat_value
	
	# All gifts increase pickup radius by a fixed amount each time!
	var current_radius = GameState.run_gift_bonuses.get("pickup_radius", 0.0)
	GameState.run_gift_bonuses["pickup_radius"] = current_radius + GameConstants.GIFT_PICKUP_RADIUS_BOOST
	
	# All gifts increase luck by a fixed amount each time!
	var current_luck = GameState.run_gift_bonuses.get("luck", 0.0)
	GameState.run_gift_bonuses["luck"] = current_luck + GameConstants.GIFT_LUCK_BOOST
	
	# Award a small amount of XP
	GameState.add_xp(GameConstants.GIFT_XP_AMOUNT)
	
	# Refresh player stats if needed
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("refresh_stats"):
		player.refresh_stats()
	
	# Visual feedback: Floating Text
	_show_floating_text()
	
	queue_free()


func _show_floating_text() -> void:
	var text_color = Color.WHITE
	var ft_script = load("res://scripts/floating_text.gd")
	var luck_percent = GameConstants.GIFT_LUCK_BOOST * 100.0
	var luck_text = "+%.0f%% Luck" % luck_percent
	var stat_text = _build_stat_text()
	
	var ft1 = Node2D.new()
	ft1.set_script(ft_script)
	ft1.text = stat_text
	ft1.color = text_color
	ft1.global_position = global_position
	get_tree().current_scene.add_child(ft1)
	
	# Secondary pickup radius text (trail)
	var ft2 = Node2D.new()
	ft2.set_script(ft_script)
	ft2.text = GameConstants.GIFT_STATS["pickup_radius"]["display"] % GameConstants.GIFT_PICKUP_RADIUS_BOOST
	ft2.color = text_color
	ft2.global_position = global_position + Vector2(0, 25)
	get_tree().current_scene.add_child(ft2)
	
	# Tertiary luck boost text (trail)
	var ft3 = Node2D.new()
	ft3.set_script(ft_script)
	ft3.text = luck_text
	ft3.color = text_color
	ft3.global_position = global_position + Vector2(0, 50)
	get_tree().current_scene.add_child(ft3)

func _build_stat_text() -> String:
	var stat_data = GameConstants.GIFT_STATS.get(stat_key, {})
	if stat_data.is_empty():
		return ""
	if stat_key == "crit_chance" or stat_key == "speed" or stat_key == "atk_speed":
		return stat_data["display"] % (stat_value * 100.0)
	return stat_data["display"] % stat_value




