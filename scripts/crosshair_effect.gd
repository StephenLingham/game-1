extends Node2D

func _ready():
	modulate = Color(1.0, 0.2, 0.2, 1.0) # Bright red
	scale = Vector2(0.5, 0.5)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "modulate:a", 0.0, 0.25).set_delay(0.1)
	tween.chain().tween_callback(queue_free)

func _draw():
	var size = 25.0
	var thickness = 3.0
	var gap = 8.0
	
	# Draw crosshair lines with gaps for a "sniper" feel
	draw_line(Vector2(-size, 0), Vector2(-gap, 0), Color.RED, thickness)
	draw_line(Vector2(size, 0), Vector2(gap, 0), Color.RED, thickness)
	draw_line(Vector2(0, -size), Vector2(0, -gap), Color.RED, thickness)
	draw_line(Vector2(0, size), Vector2(0, gap), Color.RED, thickness)
	
	# Small outer circle
	draw_arc(Vector2.ZERO, size * 0.8, 0, TAU, 32, Color.RED, 1.5)
	# Center dot
	draw_circle(Vector2.ZERO, 2.0, Color.RED)
