extends Area2D

var rarity: String = "common"

const TEXTURE_PATH = "res://assets/gift.png"
const FLOATING_TEXT_SCRIPT = preload("res://scripts/floating_text.gd")
const GIFT_TEXT_MOTION := Vector2(0, -70)
const GIFT_TEXT_DURATION := 2.4

func _ready() -> void:
	add_to_group("gifts")

	if not GameConstants.GIFT_RARITY_VALUES.has(rarity):
		rarity = "common"

	_setup_visuals()
	body_entered.connect(_on_body_entered)

	var tween = create_tween().set_loops()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _process(_delta: float) -> void:
	if not GameState.has_run_item("gift_vacuum"):
		return
	var player = get_tree().get_first_node_in_group("player")
	if player and global_position.distance_to(player.global_position) <= GameState.get_pickup_radius():
		_collect()

func _get_rarity_multiplier() -> float:
	return float(GameConstants.RARITY_MULTIPLIERS.get(rarity, 1.0))

func _setup_visuals() -> void:
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	if ResourceLoader.exists(TEXTURE_PATH):
		sprite.texture = load(TEXTURE_PATH)
	else:
		sprite.texture = preload("res://icon.svg")
		sprite.modulate = Color.RED
		push_warning("Gift: Could not find texture at " + TEXTURE_PATH)

	sprite.modulate = GameConstants.RARITY_COLORS.get(rarity, Color.WHITE)
	sprite.scale = Vector2(0.03, 0.03)
	sprite.z_index = 5
	add_child(sprite)

	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 15.0
	shape.shape = circle
	add_child(shape)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect()

func _collect() -> void:
	var rarity_mult := _get_rarity_multiplier()
	var magnet_boost := GameConstants.GIFT_PICKUP_RADIUS_BOOST * rarity_mult
	var luck_boost := GameConstants.GIFT_LUCK_BOOST * rarity_mult

	var current_radius = GameState.run_gift_bonuses.get("pickup_radius", 0.0)
	GameState.run_gift_bonuses["pickup_radius"] = current_radius + magnet_boost

	var current_luck = GameState.run_gift_bonuses.get("luck", 0.0)
	GameState.run_gift_bonuses["luck"] = current_luck + luck_boost

	GameState.add_xp(GameConstants.GIFT_XP_AMOUNT)

	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_method("on_gift_collected"):
			player.on_gift_collected()
		if player.has_method("refresh_stats"):
			player.refresh_stats()

	_show_floating_text(magnet_boost, luck_boost)
	queue_free()

func _show_floating_text(magnet_boost: float, luck_boost: float) -> void:
	var text_color: Color = GameConstants.RARITY_COLORS.get(rarity, Color.WHITE)
	var magnet_text := "+%.1f Collection Range" % magnet_boost
	var luck_text := "+%.0f%% Luck" % (luck_boost * 100.0)

	_spawn_floating_text(magnet_text, text_color, Vector2.ZERO)
	_spawn_floating_text(luck_text, text_color, Vector2(0, 40))

func _spawn_floating_text(label_text: String, text_color: Color, spawn_offset: Vector2) -> void:
	var ft = Node2D.new()
	ft.set_script(FLOATING_TEXT_SCRIPT)
	ft.text = label_text
	ft.color = text_color
	ft.motion_offset = GIFT_TEXT_MOTION
	ft.motion_duration = GIFT_TEXT_DURATION
	ft.global_position = global_position + spawn_offset
	get_tree().current_scene.add_child(ft)
