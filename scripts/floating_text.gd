extends Node2D

var text: String = ""
var color: Color = Color.WHITE
var font_size: int = 24
var velocity: Vector2 = Vector2.UP * 120.0

func _ready() -> void:
	var label = Label.new()
	label.text = text
	
	var settings = LabelSettings.new()
	settings.font_size = font_size
	settings.font_color = color
	settings.outline_size = 3
	settings.outline_color = Color.BLACK
	settings.shadow_size = 2
	settings.shadow_color = Color(0, 0, 0, 0.6)
	
	label.label_settings = settings
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = -label.get_minimum_size() / 2.0
	label.z_index = 200 # Higher than most UI
	add_child(label)
	
	var tween = create_tween().set_parallel(true)
	# Rise up with a slight curve
	var target_pos = position + Vector2(randf_range(-60, 60), -150)
	tween.tween_property(self, "position", target_pos, 1.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, 1.0).set_delay(0.2)
	# Scale up slightly at start
	scale = Vector2(0.5, 0.5)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	tween.chain().tween_callback(queue_free)
