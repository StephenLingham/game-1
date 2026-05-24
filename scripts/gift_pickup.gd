extends Area2D

var rarity: String = "common"
var stat_key: String = "damage"
var stat_value: float = 0.0

const TEXTURE_PATH = "res://assets/gift.png"
const FLOATING_TEXT_SCENE = preload("res://scripts/floating_text.gd") # We'll instantiate the script directly or create a scene

func _ready() -> void:
	add_to_group("gifts")
	
	# Gifts currently use a single common tier.
	rarity = "common"
	
	var stats_keys = GameConstants.GIFT_STATS.keys()
	stat_key = stats_keys[randi() % stats_keys.size()]
	
	var base_amount = GameConstants.GIFT_RARITY_VALUES["common"]
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
	if GameConstants.FEATURE_GIFTS_GIVE_RANDOM_STAT:
		# Apply random stat boost
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
	
	if GameConstants.FEATURE_GIFTS_GIVE_RANDOM_STAT:
		if stat_key == "pickup_radius":
			# Combined text: main stat rolled is pickup_radius + fixed boost
			var total_radius_boost = stat_value + GameConstants.GIFT_PICKUP_RADIUS_BOOST
			var display_text = GameConstants.GIFT_STATS["pickup_radius"]["display"] % total_radius_boost
			
			var ft = Node2D.new()
			ft.set_script(ft_script)
			ft.text = display_text
			ft.color = text_color
			ft.global_position = global_position
			get_tree().current_scene.add_child(ft)
			
			# Trailing luck boost text
			var ft_luck = Node2D.new()
			ft_luck.set_script(ft_script)
			ft_luck.text = luck_text
			ft_luck.color = text_color
			ft_luck.global_position = global_position + Vector2(0, 25)
			get_tree().current_scene.add_child(ft_luck)
		else:
			# Main stat text
			var stat_data = GameConstants.GIFT_STATS[stat_key]
			var display_text = ""
			if stat_key == "crit_chance" or stat_key == "speed" or stat_key == "atk_speed":
				display_text = stat_data["display"] % (stat_value * 100.0)
			else:
				display_text = stat_data["display"] % stat_value
				
			var ft1 = Node2D.new()
			ft1.set_script(ft_script)
			ft1.text = display_text
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
	else:
		# Random stat boost is disabled. Only show fixed pickup radius and luck boosts!
		var display_text = GameConstants.GIFT_STATS["pickup_radius"]["display"] % GameConstants.GIFT_PICKUP_RADIUS_BOOST
		
		var ft = Node2D.new()
		ft.set_script(ft_script)
		ft.text = display_text
		ft.color = text_color
		ft.global_position = global_position
		get_tree().current_scene.add_child(ft)
		
		var ft_luck = Node2D.new()
		ft_luck.set_script(ft_script)
		ft_luck.text = luck_text
		ft_luck.color = text_color
		ft_luck.global_position = global_position + Vector2(0, 25)
		get_tree().current_scene.add_child(ft_luck)




