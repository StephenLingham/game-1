extends Node

@export var enemy_scene: PackedScene
@export var arena_radius: float = 420.0

var enemy_fast_scene := preload("res://scenes/enemy_fast.tscn")
var enemy_big_scene := preload("res://scenes/enemy_big.tscn")

var wave: int = 0
var wave_time_left: float = 0.0
var spawning: bool = false

@onready var spawn_timer: Timer = $SpawnTimer
@onready var game: Node = get_tree().current_scene

var arena_rect: Rect2

func set_arena_bounds(rect: Rect2) -> void:
	arena_rect = rect

func _ready() -> void:
	spawn_timer.timeout.connect(_spawn_tick)

func start_run() -> void:
	GameState.reset_run()
	wave = 0
	_next_wave()

func _next_wave() -> void:
	wave += 1
	if wave > GameConstants.TOTAL_WAVES:
		game.call_deferred("end_run", true, GameConstants.TOTAL_WAVES)
		return

	wave_time_left = GameConstants.WAVE_SECONDS
	spawning = true

	# spawn rate ramps with wave
	var base_wait: float = GameConstants.WAVE_BASE_SPAWN_WAIT
	var wait: float = max(base_wait - (GameConstants.WAVE_SPAWN_WAIT_DECREMENT * float(wave - 1)), GameConstants.WAVE_MIN_SPAWN_WAIT)
	spawn_timer.wait_time = wait
	spawn_timer.start()

	game.call_deferred("on_wave_started", wave)

func _process(delta: float) -> void:
	if not spawning:
		return
	wave_time_left = max(wave_time_left - delta, 0.0)
	game.call_deferred("on_wave_time", wave_time_left)

	if wave_time_left <= 0.0:
		_end_wave()

func _end_wave() -> void:
	spawning = false
	spawn_timer.stop()
	
	# Clear uncollected gold at the end of the wave
	for g in get_tree().get_nodes_in_group("gold_pickups"):
		if is_instance_valid(g):
			g.queue_free()
	
	if wave < GameConstants.TOTAL_WAVES:
		game.call_deferred("open_shop", wave)

func resume_after_shop() -> void:
	# Optionally clear enemies between waves for clarity
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e):
			e.queue_free()
	_next_wave()

func _spawn_tick() -> void:
	if enemy_scene == null:
		return
	# spawn a small burst each tick as waves increase
	var burst := 1 + int(floor((wave - 1) / 2.0))
	for i in range(burst):
		var rand_val := randf()
		var scene_to_spawn := enemy_scene
		
		# Probability logic
		if rand_val < GameConstants.PROB_BIG_ENEMY:
			scene_to_spawn = enemy_big_scene
		elif rand_val < (GameConstants.PROB_BIG_ENEMY + GameConstants.PROB_FAST_ENEMY):
			scene_to_spawn = enemy_fast_scene
			
		var e := scene_to_spawn.instantiate()

		# Spawn just inside the arena walls instead of outside
		var inner_left := arena_rect.position.x + 35.0
		var inner_right := arena_rect.position.x + arena_rect.size.x - 35.0
		var inner_top := arena_rect.position.y + 35.0
		var inner_bottom := arena_rect.position.y + arena_rect.size.y - 35.0
		var edge_margin := 40.0  # How close to the wall they spawn

		var spawn_pos := Vector2.ZERO
		var side := randi() % 4

		match side:
			0: # Top edge (inside)
				spawn_pos = Vector2(randf_range(inner_left + edge_margin, inner_right - edge_margin), inner_top + 5.0)
			1: # Bottom edge (inside)
				spawn_pos = Vector2(randf_range(inner_left + edge_margin, inner_right - edge_margin), inner_bottom - 5.0)
			2: # Left edge (inside)
				spawn_pos = Vector2(inner_left + 5.0, randf_range(inner_top + edge_margin, inner_bottom - edge_margin))
			3: # Right edge (inside)
				spawn_pos = Vector2(inner_right - 5.0, randf_range(inner_top + edge_margin, inner_bottom - edge_margin))

		e.global_position = spawn_pos
		game.get_node("EnemyContainer").add_child(e)

