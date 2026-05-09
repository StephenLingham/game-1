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

@onready var spawn_timer: Timer = $SpawnTimer
@onready var game: Node = get_tree().current_scene

var powerup_spawn_timer: float = 0.0
var chest_spawn_timer: float = 0.0
var run_total_time: float = 0.0
var gem_intervals_spawned: Array = []


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
	
	# Difficulty adjustment
	wait /= GameState.run_difficulty_spawn_mult
	# Permanent upgrade adjustment
	wait /= GameState.get_spawn_rate_multiplier()
	
	spawn_timer.wait_time = wait
	spawn_timer.start()


	powerup_spawn_timer = randf_range(GameConstants.POWERUP_SPAWN_INTERVAL_MIN, GameConstants.POWERUP_SPAWN_INTERVAL_MAX)
	chest_spawn_timer = randf_range(GameConstants.CHEST_SPAWN_INTERVAL_MIN, GameConstants.CHEST_SPAWN_INTERVAL_MAX)


	game.on_wave_started(wave)

func _process(delta: float) -> void:
	if not spawning:
		return
	wave_time_left = max(wave_time_left - delta, 0.0)
	game.call_deferred("on_wave_time", wave_time_left)

	if wave_time_left <= 0.0:
		_end_wave()
	
	# Powerup spawning
	if spawning:
		powerup_spawn_timer -= delta
		if powerup_spawn_timer <= 0:
			_spawn_powerup()
			# Spawn every 8-12 seconds
			powerup_spawn_timer = randf_range(GameConstants.POWERUP_SPAWN_INTERVAL_MIN, GameConstants.POWERUP_SPAWN_INTERVAL_MAX)

	# Chest spawning
	if spawning:
		chest_spawn_timer -= delta
		if chest_spawn_timer <= 0:
			_spawn_chest()
			# Spawn interval scaling for character traits
			var mult = 1.0
			if GameState.current_character == "singular_luck":
				mult = 0.2 # 5x more often = 0.2x interval
			chest_spawn_timer = randf_range(GameConstants.CHEST_SPAWN_INTERVAL_MIN, GameConstants.CHEST_SPAWN_INTERVAL_MAX) * mult

	# Interval-based gem spawning
	if spawning:
		run_total_time += delta
		for drop_time in GameConstants.GEM_DROP_TIMES:
			if run_total_time >= drop_time and not gem_intervals_spawned.has(drop_time):
				if gem_intervals_spawned.size() < 5:
					_spawn_gem()
					gem_intervals_spawned.append(drop_time)


func _end_wave() -> void:
	spawning = false
	spawn_timer.stop()
	
	# We no longer clear XP, projectiles, or reset anything for a "continuous" feel.
	
	if wave < GameConstants.TOTAL_WAVES:
		# small delay between waves before spawning resumes
		var timer = get_tree().create_timer(2.0)
		timer.timeout.connect(_next_wave)
	else:
		# Final wave completed! Trigger victory.
		game.call_deferred("end_run", true, wave)

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
		
		# Wave-specific spawning
		if wave == 1:
			scene_to_spawn = enemy_tree_scene
		elif wave == 3:
			scene_to_spawn = enemy_elite_scene
		else:
			# Probability logic for Wave 2+
			if rand_val < GameConstants.PROB_BIG_ENEMY:
				scene_to_spawn = enemy_big_scene
			elif rand_val < (GameConstants.PROB_BIG_ENEMY + GameConstants.PROB_FAST_ENEMY):
				scene_to_spawn = enemy_fast_scene
			elif rand_val < (GameConstants.PROB_BIG_ENEMY + GameConstants.PROB_FAST_ENEMY + GameConstants.PROB_TREE_ENEMY):
				scene_to_spawn = enemy_tree_scene
			elif rand_val < (GameConstants.PROB_BIG_ENEMY + GameConstants.PROB_FAST_ENEMY + GameConstants.PROB_TREE_ENEMY + GameConstants.PROB_ELITE_ENEMY):
				scene_to_spawn = enemy_elite_scene
			
		var e := scene_to_spawn.instantiate()

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

func _spawn_powerup() -> void:
	if powerup_scene == null: return
	
	var p = powerup_scene.instantiate()
	
	
	# Randomly pick from: MAGNET, SPEED, HEAL, ROCKET, ATK_SPEED (No GEMS here)
	var types = [0, 1, 2, 3, 5]
	p.type = types.pick_random()
	
	# Spawn randomly within the arena bounds (with some margin)
	var margin := 100.0
	var spawn_pos := Vector2(
		randf_range(arena_rect.position.x + margin, arena_rect.position.x + arena_rect.size.x - margin),
		randf_range(arena_rect.position.y + margin, arena_rect.position.y + arena_rect.size.y - margin)
	)
	
	p.global_position = spawn_pos
	game.get_node("PickupContainer").add_child(p)

func _spawn_chest() -> void:
	if chest_scene == null: return
	
	var c = chest_scene.instantiate()
	
	# Spawn randomly within the arena bounds
	var margin := 150.0
	var spawn_pos := Vector2(
		randf_range(arena_rect.position.x + margin, arena_rect.position.x + arena_rect.size.x - margin),
		randf_range(arena_rect.position.y + margin, arena_rect.position.y + arena_rect.size.y - margin)
	)
	
	c.global_position = spawn_pos
	game.get_node("PickupContainer").add_child(c)

func _spawn_gem() -> void:
	if powerup_scene == null: return
	var p = powerup_scene.instantiate()
	p.type = 4 # GEM
	
	# Spawn near player but not on top
	var player = game.player
	var offset = Vector2(randf_range(-200, 200), randf_range(-200, 200))
	if offset.length() < 100: offset = offset.normalized() * 100
	
	var spawn_pos = player.global_position + offset
	# Clamp to arena
	var safety := 45.0
	spawn_pos.x = clamp(spawn_pos.x, arena_rect.position.x + safety, arena_rect.position.x + arena_rect.size.x - safety)
	spawn_pos.y = clamp(spawn_pos.y, arena_rect.position.y + safety, arena_rect.position.y + arena_rect.size.y - safety)
	
	p.global_position = spawn_pos
	game.get_node("PickupContainer").add_child(p)


