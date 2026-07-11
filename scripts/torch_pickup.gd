extends Area2D

enum TorchType { BLUE, RED }

@export var torch_type: TorchType = TorchType.BLUE

const BLUE_TEXTURE := preload("res://assets/Torches/blue_torch.png")
const RED_TEXTURE := preload("res://assets/Torches/red_torch.png")
const FLOATING_TEXT_SCRIPT := preload("res://scripts/floating_text.gd")

var _collected := false

func _ready() -> void:
	add_to_group("torches")
	body_entered.connect(_on_body_entered)
	_setup_visuals()
	var pulse := create_tween().set_loops()
	pulse.tween_property(self, "scale", Vector2(1.08, 1.08), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(self, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _setup_visuals() -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	var light_texture := GradientTexture2D.new()
	light_texture.gradient = gradient
	light_texture.width = 128
	light_texture.height = 128
	light_texture.fill = GradientTexture2D.FILL_RADIAL
	light_texture.fill_from = Vector2(0.5, 0.5)
	light_texture.fill_to = Vector2(1.0, 0.5)
	var glow := PointLight2D.new()
	glow.energy = 0.7
	glow.texture_scale = 1.8
	glow.texture = light_texture
	glow.color = Color(0.25, 0.55, 1.0) if torch_type == TorchType.BLUE else Color(1.0, 0.2, 0.12)
	add_child(glow)

	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = BLUE_TEXTURE if torch_type == TorchType.BLUE else RED_TEXTURE
	sprite.scale = Vector2.ONE * GameConstants.TORCH_IMAGE_SCALE
	sprite.z_index = 5
	add_child(sprite)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = GameConstants.TORCH_PICKUP_RADIUS
	shape.shape = circle
	add_child(shape)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect()

func _collect() -> void:
	if _collected:
		return
	_collected = true

	var previous_spawn_rate := GameState.get_spawn_rate_multiplier()
	var stat_key := "xp_drop_multiplier"
	var bonus := GameConstants.BLUE_TORCH_XP_GAIN_BOOST
	var message := "+%.0f%% XP Gain" % (bonus * 100.0)
	var color := Color(0.35, 0.72, 1.0)
	if torch_type == TorchType.RED:
		stat_key = "spawn_rate_multiplier"
		bonus = GameConstants.RED_TORCH_SPAWN_RATE_BOOST
		message = "+%.0f%% Spawn Rate" % (bonus * 100.0)
		color = Color(1.0, 0.3, 0.2)

	GameState.run_gift_bonuses[stat_key] = GameState.run_gift_bonuses.get(stat_key, 0.0) + bonus
	_spawn_floating_text(message, color)
	if torch_type == TorchType.RED:
		var wave_controller := get_tree().current_scene.get_node_or_null("WaveController")
		if wave_controller and wave_controller.has_method("refresh_spawn_rate"):
			wave_controller.refresh_spawn_rate(previous_spawn_rate)

	queue_free()

func _spawn_floating_text(message: String, color: Color) -> void:
	var text := Node2D.new()
	text.set_script(FLOATING_TEXT_SCRIPT)
	text.text = message
	text.color = color
	text.motion_offset = Vector2(0, -85)
	text.motion_duration = 2.2
	text.global_position = global_position
	get_tree().current_scene.add_child(text)
