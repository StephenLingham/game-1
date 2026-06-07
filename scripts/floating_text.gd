extends Node2D

var text: String = ""
var color: Color = Color.WHITE
var font_size: int = 24
var motion_offset: Vector2 = Vector2.ZERO
var motion_duration: float = 1.2

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
	
	var target_offset := motion_offset
	if target_offset == Vector2.ZERO:
		target_offset = Vector2(randf_range(-60, 60), -150)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position", position + target_offset, motion_duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, motion_duration * 0.85).set_delay(motion_duration * 0.15)
	scale = Vector2(0.5, 0.5)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	tween.chain().tween_callback(queue_free)
