extends Node2D

var arena_size: Vector2

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 12345
	var tufts = int((arena_size.x * arena_size.y) / 2000.0)
	for i in range(tufts):
		var x = rng.randf_range(0, arena_size.x)
		var y = rng.randf_range(0, arena_size.y)
		var tuft_color = Color(0.2, 0.8, 0.2, rng.randf_range(0.3, 0.7))
		var offset = Vector2(rng.randf_range(-4, 4), rng.randf_range(4, 12))
		draw_line(Vector2(x, y), Vector2(x + offset.x, y - offset.y), tuft_color, 2.0)
