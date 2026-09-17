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

var campaign_enemy_scene := preload("res://scenes/campaign_enemy.tscn")
var stage: int = 0
var stage_boss_killed := false
var bosses_defeated := 0
var completed_waves := 0
var finished := false
var failure_reason := ""
var _last_completed_wave := -1
var _roster_cursor := 0
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
	stage = clampi(GameConstants.DEBUG_STARTING_STAGE, 1, RunCampaign.NAMES.size()) - 1
	# _next_wave() increments first; the wave setting is local to this stage.
	wave = clampi(GameConstants.DEBUG_STARTING_WAVE, 1, GameConstants.TOTAL_WAVES) - 1
	# Treat skipped content as completed so portals and final victory still work.
	bosses_defeated = stage
	completed_waves = stage * GameConstants.TOTAL_WAVES + wave
	_last_completed_wave = completed_waves
	GameState.run_elapsed_seconds = float(stage) * RunCampaign.AREA_SECONDS + float(wave) * GameConstants.WAVE_SECONDS
	if stage > 0:
		game.transition_to_area(stage)
	_next_wave()

func _next_wave() -> void:
	wave += 1
	if wave > GameConstants.TOTAL_WAVES:
		return # The campaign clock owns all deadlines.

	wave_time_left = GameConstants.WAVE_SECONDS
	spawning = true

	var base_wait: float = GameConstants.WAVE_BASE_SPAWN_WAIT
	var wait: float = max(base_wait - (GameConstants.WAVE_SPAWN_WAIT_DECREMENT * float(wave - 1)), GameConstants.WAVE_MIN_SPAWN_WAIT)
	match wave if stage == 0 else -1:
		3:
			wait = GameConstants.WAVE_3_SPAWN_WAIT
		7:
			wait = GameConstants.WAVE_7_CLUMP_WAIT
		8:
			wait = GameConstants.WAVE_8_TREE_SPAWN_WAIT

	wait /= GameState.run_difficulty_spawn_mult
	wait /= GameState.get_spawn_rate_multiplier()

	spawn_timer.wait_time = wait
	spawn_timer.start()

	game.on_wave_started(wave)
	if stage == 0 and wave == 5:
		_spawn_tree_circle()
	if stage > 0 and wave in [4, 7]:
		_spawn_miniboss(0 if wave == 4 else 1)
	if wave == GameConstants.TOTAL_WAVES:
		_spawn_boss()
func refresh_spawn_rate(previous_multiplier: float) -> void:
	if not spawning or previous_multiplier <= 0.0:
		return
	var new_multiplier := GameState.get_spawn_rate_multiplier()
	if new_multiplier <= 0.0:
		return
	spawn_timer.wait_time *= previous_multiplier / new_multiplier


func _process(delta: float) -> void:
	advance_time(delta)

func advance_time(delta: float) -> void:
	if finished:
		return
	# One authoritative active-play clock; pauses and upgrade choices pause it.
	GameState.track_run_time(minf(maxf(delta, 0.0), float(stage + 1) * RunCampaign.AREA_SECONDS - GameState.run_elapsed_seconds))
	var elapsed := GameState.run_elapsed_seconds
	var deadline := float(stage + 1) * RunCampaign.AREA_SECONDS
	if elapsed >= deadline:
		if stage == 2 and stage_boss_killed and bosses_defeated == 3:
			_complete_wave()
			_finish(true, "")
		else:
			_finish(false, "Area deadline missed: defeat the boss and enter its portal." if stage < 2 else "The final boss survived the 15-minute deadline.")
		return
	# A portal moves the player immediately, but the next five-minute slot
	# starts on its fixed boundary, never shortening a successful run.
	var stage_start := float(stage) * RunCampaign.AREA_SECONDS
	if elapsed < stage_start:
		game.on_wave_time(stage_start - elapsed)
		return
	if wave == 0:
		_next_wave()
	while wave < GameConstants.TOTAL_WAVES and elapsed >= stage_start + float(wave) * GameConstants.WAVE_SECONDS:
		_complete_wave()
		_next_wave()
	wave_time_left = maxf(0.0, stage_start + float(wave) * GameConstants.WAVE_SECONDS - elapsed)
	game.on_wave_time(wave_time_left)

func _complete_wave() -> void:
	if wave <= 0 or _last_completed_wave == stage * 10 + wave:
		return
	_last_completed_wave = stage * 10 + wave
	completed_waves += 1
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("on_wave_completed"):
		player.on_wave_completed()

func _end_wave() -> void:
	_complete_wave()
	if wave < GameConstants.TOTAL_WAVES:
		_next_wave()

func _finish(won: bool, reason: String) -> void:
	finished = true
	spawning = false
	spawn_timer.stop()
	failure_reason = reason
	game.call_deferred("end_run", won, completed_waves)

func _on_boss_killed(enemy: Node2D) -> void:
	if stage_boss_killed or finished:
		return
	stage_boss_killed = true
	bosses_defeated += 1
	spawning = false
	spawn_timer.stop()
	if stage < 2:
		_create_portal.call_deferred(enemy.global_position)

func _create_portal(pos: Vector2) -> void:
	if finished or not is_inside_tree():
		return
	var portal := preload("res://scripts/stage_portal.gd").new()
	portal.destination = stage + 1
	portal.controller = self
	portal.position = _clamp_to_arena(pos, 80.0)
	game.add_child(portal)
	game.on_wave_time(wave_time_left)

func enter_portal() -> void:
	if finished or not stage_boss_killed or stage >= 2:
		return
	if GameState.run_elapsed_seconds >= float(stage + 1) * RunCampaign.AREA_SECONDS:
		return
	_complete_wave()
	stage += 1
	wave = 0
	stage_boss_killed = false
	spawning = false
	spawn_timer.stop()
	game.transition_to_area(stage)
	game.on_wave_started(0)

func resume_after_shop() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e):
			e.queue_free()
	_next_wave()

func _remove_oldest_enemy_if_needed() -> void:
	var valid_enemies: Array[Node] = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and not RunCampaign.is_boss(str(enemy.get("enemy_type"))) and not RunCampaign.is_miniboss(str(enemy.get("enemy_type"))):
			valid_enemies.append(enemy)

	if valid_enemies.size() < GameConstants.MAX_ENEMIES_ALIVE:
		return

	var oldest: Node = valid_enemies[0]
	for enemy in valid_enemies:
		if int(enemy.get_meta("_spawn_order", 0)) < int(oldest.get_meta("_spawn_order", 0)):
			oldest = enemy

	if is_instance_valid(oldest):
		oldest.free()

func _spawn_tick() -> void:
	if enemy_scene == null or not spawning or finished:
		return

	if stage == 0 and wave == 7:
		_spawn_clump_in_front_of_player()
		return

	var burst := _get_burst_count()
	for i in range(burst):
		var spawn_data := _choose_spawn_data_for_wave()
		_spawn_enemy(spawn_data, _get_random_offscreen_spawn_position())

func _get_burst_count() -> int:
	match wave if stage == 0 else -1:
		3:
			return 1
		8:
			return 5
		_:
			return 1 + int(floor((wave - 1) / 2.0))

func _choose_spawn_data_for_wave() -> Dictionary:
	if stage > 0:
		var roster: Array = RunCampaign.ENEMIES[stage]
		var kind: String = roster[_roster_cursor % roster.size()]
		_roster_cursor += 1
		return {"scene": campaign_enemy_scene, "type": kind}
	match wave:
		1:
			return {"scene": enemy_tree_scene, "type": ""}
		3:
			return {"scene": enemy_elite_scene, "type": ""}
		8:
			return {"scene": enemy_tree_scene, "type": ""}
		9:
			return {"scene": enemy_scene, "type": "Golem"}
		GameConstants.TOTAL_WAVES:
			return _choose_all_enemy_spawn_data()
		_:
			return _choose_basic_spawn_data()

func _choose_basic_spawn_data() -> Dictionary:
	var roll := randf()
	if roll < GameConstants.PROB_BIG_ENEMY:
		return {"scene": enemy_big_scene, "type": ""}
	if roll < GameConstants.PROB_BIG_ENEMY + GameConstants.PROB_FAST_ENEMY:
		return {"scene": enemy_fast_scene, "type": ""}
	return {"scene": enemy_scene, "type": ""}

func _choose_all_enemy_spawn_data() -> Dictionary:
	var roll := randf()
	if roll < 0.30:
		return {"scene": enemy_scene, "type": ""}
	if roll < 0.48:
		return {"scene": enemy_fast_scene, "type": ""}
	if roll < 0.62:
		return {"scene": enemy_big_scene, "type": ""}
	if roll < 0.78:
		return {"scene": enemy_tree_scene, "type": ""}
	if roll < 0.92:
		return {"scene": enemy_elite_scene, "type": ""}
	return {"scene": enemy_scene, "type": "Golem"}

func _spawn_boss() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var center: Vector2 = player.global_position if player else arena_rect.get_center()
	var spawn_pos: Vector2 = _clamp_to_arena(center + Vector2(0, 280), 70.0)
	GameState.record_boss_spawn()
	var boss_scene: PackedScene = enemy_scene if stage == 0 else campaign_enemy_scene
	_spawn_enemy({"scene": boss_scene, "type": RunCampaign.BOSSES[stage]}, spawn_pos, true)

func _spawn_tree_circle() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var outer_radius: float = max(620.0, viewport_size.length() * 0.55)
	var row_spacing := 40.0
	var radii: Array[float] = []
	for row in range(10):
		radii.append(outer_radius - (row_spacing * float(9 - row)))
	for radius: float in radii:
		var count: int = max(12, int(round(TAU * radius / 45.0)))
		for i in range(count):
			var angle: float = TAU * ((float(i) + randf_range(-0.22, 0.22)) / float(count))
			var jittered_radius: float = radius + randf_range(-16.0, 16.0)
			var pos: Vector2 = player.global_position + Vector2(cos(angle), sin(angle)) * jittered_radius
			_spawn_enemy({"scene": enemy_tree_scene, "type": ""}, _clamp_to_arena(pos))

func _spawn_clump_in_front_of_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		return
	var dir := Vector2.ZERO
	if "velocity" in player and player.velocity.length() > 10.0:
		dir = player.velocity.normalized()
	else:
		var angle := randf() * TAU
		dir = Vector2(cos(angle), sin(angle))
	var viewport_size := get_viewport().get_visible_rect().size
	var clump_distance: float = max(360.0, min(viewport_size.x, viewport_size.y) * 0.48)
	var clump_center: Vector2 = _clamp_to_arena(player.global_position + dir * clump_distance)
	for i in range(10):
		var offset: Vector2 = Vector2(randf_range(-45.0, 45.0), randf_range(-45.0, 45.0))
		_spawn_enemy({"scene": enemy_tree_scene, "type": ""}, _clamp_to_arena(clump_center + offset))

func _spawn_enemy(spawn_data: Dictionary, spawn_pos: Vector2, ignore_cap: bool = false) -> Node2D:
	if not ignore_cap:
		_remove_oldest_enemy_if_needed()

	var scene_to_spawn: PackedScene = spawn_data.get("scene", enemy_scene)
	var e: Node2D = scene_to_spawn.instantiate()
	var enemy_type_override: String = spawn_data.get("type", "")
	if enemy_type_override != "":
		e.enemy_type = enemy_type_override
	e.set_meta("_spawn_order", _next_spawn_order)
	_next_spawn_order += 1
	e.global_position = spawn_pos
	game.get_node("EnemyContainer").add_child(e)
	if RunCampaign.is_boss(e.enemy_type):
		e.enemy_killed.connect(_on_boss_killed.bind(e))
	e.reset_physics_interpolation()
	return e

func _get_random_offscreen_spawn_position() -> Vector2:
	var cam := get_viewport().get_camera_2d()
	var center: Vector2 = cam.get_screen_center_position() if cam else game.player.global_position
	var viewport_size := get_viewport().get_visible_rect().size
	var margin := 100.0
	var spawn_pos := Vector2.ZERO
	var side := randi() % 4

	match side:
		0:
			spawn_pos = Vector2(randf_range(center.x - viewport_size.x / 2.0, center.x + viewport_size.x / 2.0), center.y - viewport_size.y / 2.0 - margin)
		1:
			spawn_pos = Vector2(randf_range(center.x - viewport_size.x / 2.0, center.x + viewport_size.x / 2.0), center.y + viewport_size.y / 2.0 + margin)
		2:
			spawn_pos = Vector2(center.x - viewport_size.x / 2.0 - margin, randf_range(center.y - viewport_size.y / 2.0, center.y + viewport_size.y / 2.0))
		3:
			spawn_pos = Vector2(center.x + viewport_size.x / 2.0 + margin, randf_range(center.y - viewport_size.y / 2.0, center.y + viewport_size.y / 2.0))

	return _clamp_to_arena(spawn_pos)

func _clamp_to_arena(pos: Vector2, safety: float = 45.0) -> Vector2:
	if arena_rect.size == Vector2.ZERO:
		return pos
	return Vector2(
		clamp(pos.x, arena_rect.position.x + safety, arena_rect.position.x + arena_rect.size.x - safety),
		clamp(pos.y, arena_rect.position.y + safety, arena_rect.position.y + arena_rect.size.y - safety)
	)

func _spawn_miniboss(index: int) -> void:
	var kind: String = RunCampaign.MINIBOSSES[stage][index]
	_spawn_enemy({"scene": campaign_enemy_scene, "type": kind}, _get_random_offscreen_spawn_position(), true)
