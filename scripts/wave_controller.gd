extends Node
class_name WaveController

@export var enemy_scene: PackedScene
@export var arena_radius: float = 420.0

var enemy_fast_scene := preload("res://scenes/enemy_fast.tscn")
var enemy_big_scene := preload("res://scenes/enemy_big.tscn")
var enemy_tree_scene := preload("res://scenes/enemy_tree.tscn")
var enemy_elite_scene := preload("res://scenes/enemy_elite.tscn")
var powerup_scene := preload("res://scenes/PowerupPickup.tscn")
var chest_scene := preload("res://scenes/TreasureChest.tscn")


var wave: int = 0
var wave_time_left: float = 0.0
var spawning: bool = false
var _next_spawn_order: int = 0

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
	
	if wave == 3:
		wait = GameConstants.WAVE_3_SPAWN_WAIT
	elif wave == GameConstants.TOTAL_WAVES:
		wait = GameConstants.FINAL_WAVE_SPAWN_WAIT
	
	# Difficulty adjustment
	wait /= GameState.run_difficulty_spawn_mult
	# Permanent upgrade adjustment
	wait /= GameState.get_spawn_rate_multiplier()
	
	spawn_timer.wait_time = wait
	spawn_timer.start()





	game.on_wave_started(wave)

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

	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("on_wave_completed"):
		player.on_wave_completed()

	if wave < GameConstants.TOTAL_WAVES:
		var timer = get_tree().create_timer(2.0)
		timer.timeout.connect(_next_wave)
	else:
		game.call_deferred("end_run", true, wave)

func resume_after_shop() -> void:
	# Optionally clear enemies between waves for clarity
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e):
			e.queue_free()
	_next_wave()

func _remove_oldest_enemy_if_needed() -> void:
	var valid_enemies: Array[Node] = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			valid_enemies.append(enemy)

	if valid_enemies.size() < GameConstants.MAX_ENEMIES_ALIVE:
		return

	var oldest: Node = valid_enemies[0]
	for enemy in valid_enemies:
		if int(enemy.get_meta("_spawn_order", 0)) < int(oldest.get_meta("_spawn_order", 0)):
			oldest = enemy

	if is_instance_valid(oldest):
		# Free immediately so the cap is enforced for the current frame as well.
		oldest.free()

func _spawn_tick() -> void:
	if enemy_scene == null:
		return

	if wave == GameConstants.TOTAL_WAVES:
		var first_wall_end := GameConstants.WAVE_SECONDS - GameConstants.FINAL_WAVE_PAUSE_SECONDS
		var pause_end := GameConstants.WAVE_SECONDS - (GameConstants.FINAL_WAVE_PAUSE_SECONDS * 2.0)
		if wave_time_left > first_wall_end:
			pass
		elif wave_time_left > pause_end:
			return
		# otherwise the final wave is in its active wall phases

	# spawn a small burst each tick as waves increase
	var burst := 1 + int(floor((wave - 1) / 2.0))
	if wave == GameConstants.TOTAL_WAVES:
		burst = 6
	for i in range(burst):
		# Enforce the cap before every spawn in the burst, not just once at the start.
		_remove_oldest_enemy_if_needed()
		var rand_val := randf()
		var scene_to_spawn := enemy_scene
		
		var is_golem = false
		# Wave-specific spawning
		if wave == 1:
			scene_to_spawn = enemy_tree_scene
		elif wave == 3:
			scene_to_spawn = enemy_elite_scene
		else:
			if wave >= 8 and rand_val < GameConstants.PROB_GOLEM_ENEMY:
				scene_to_spawn = enemy_scene
				is_golem = true
			else:
				var check_val = rand_val
				if wave >= 8:
					check_val = randf()
				
				# Probability logic for Wave 2+
				if check_val < GameConstants.PROB_BIG_ENEMY:
					scene_to_spawn = enemy_big_scene
				elif check_val < (GameConstants.PROB_BIG_ENEMY + GameConstants.PROB_FAST_ENEMY):
					scene_to_spawn = enemy_fast_scene
				elif check_val < (GameConstants.PROB_BIG_ENEMY + GameConstants.PROB_FAST_ENEMY + GameConstants.PROB_TREE_ENEMY):
					scene_to_spawn = enemy_tree_scene
				elif check_val < (GameConstants.PROB_BIG_ENEMY + GameConstants.PROB_FAST_ENEMY + GameConstants.PROB_TREE_ENEMY + GameConstants.PROB_ELITE_ENEMY):
					scene_to_spawn = enemy_elite_scene
			
		var e := scene_to_spawn.instantiate()
		if wave == GameConstants.TOTAL_WAVES:
			e.enemy_type = "Golem"
			is_golem = true
		elif is_golem:
			e.enemy_type = "Golem"
		e.set_meta("_spawn_order", _next_spawn_order)
		_next_spawn_order += 1

		# Get the current screen center and dimensions
		var cam := get_viewport().get_camera_2d()
		var center: Vector2 = cam.get_screen_center_position() if cam else game.player.global_position
		var viewport_size := get_viewport().get_visible_rect().size
		
		# Define spawn margin just off-screen
		var margin := 100.0
		var spawn_pos := Vector2.ZERO
		var side := randi() % 4

		match side:
			0: # Above screen
				spawn_pos = Vector2(
					randf_range(center.x - viewport_size.x / 2.0, center.x + viewport_size.x / 2.0),
					center.y - viewport_size.y / 2.0 - margin
				)
			1: # Below screen
				spawn_pos = Vector2(
					randf_range(center.x - viewport_size.x / 2.0, center.x + viewport_size.x / 2.0),
					center.y + viewport_size.y / 2.0 + margin
				)
			2: # Left of screen
				spawn_pos = Vector2(
					center.x - viewport_size.x / 2.0 - margin,
					randf_range(center.y - viewport_size.y / 2.0, center.y + viewport_size.y / 2.0)
				)
			3: # Right of screen
				spawn_pos = Vector2(
					center.x + viewport_size.x / 2.0 + margin,
					randf_range(center.y - viewport_size.y / 2.0, center.y + viewport_size.y / 2.0)
				)

		# Clamp spawn position to stay within arena walls (with safety margin)
		var safety := 45.0
		spawn_pos.x = clamp(spawn_pos.x, arena_rect.position.x + safety, arena_rect.position.x + arena_rect.size.x - safety)
		spawn_pos.y = clamp(spawn_pos.y, arena_rect.position.y + safety, arena_rect.position.y + arena_rect.size.y - safety)

		e.global_position = spawn_pos
		game.get_node("EnemyContainer").add_child(e)
		# Reset physics interpolation so the enemy doesn't flash at its
		# default (large) scale for a single frame on spawn.
		e.reset_physics_interpolation()



