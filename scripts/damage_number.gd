extends Node2D

var damage: int = 0
var is_crit: bool = false
var velocity: Vector2 = Vector2.UP * 100.0
var fade_speed: float = 1.0

func _ready() -> void:
	var label = Label.new()
	label.text = str(damage)
	
	# Rich aesthetics
	var settings = LabelSettings.new()
	settings.font_size = 24 if not is_crit else 32
	settings.font_color = Color.WHITE if not is_crit else Color(1.0, 0.2, 0.2)
	settings.outline_size = 2
	settings.outline_color = Color.BLACK
	settings.shadow_size = 2
	settings.shadow_color = Color(0, 0, 0, 0.5)
	
	label.label_settings = settings
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = -label.get_minimum_size() / 2.0
	label.z_index = 100
	add_child(label)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(randf_range(-40, 40), -120), 0.8).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.8).set_delay(0.2)
	tween.chain().tween_callback(queue_free)

func _process(delta: float) -> void:
	pass # Tween handles everything
