extends Node

@export var enemy_scene: PackedScene
@export var arena_radius: float = 420.0

const TOTAL_WAVES := 10
const WAVE_SECONDS := 30.0

var wave: int = 0
var wave_time_left: float = 0.0
var spawning: bool = false

@onready var spawn_timer: Timer = $SpawnTimer
@onready var game: Node = get_tree().current_scene

func _ready() -> void:
	spawn_timer.timeout.connect(_spawn_tick)

func start_run() -> void:
	GameState.reset_run()
	wave = 0
	_next_wave()

func _next_wave() -> void:
	wave += 1
	if wave > TOTAL_WAVES:
		game.call_deferred("end_run", true, TOTAL_WAVES)
		return

	wave_time_left = WAVE_SECONDS
	spawning = true

	# spawn rate ramps with wave (lower wait time == more enemies)
	var base_wait := 0.75
	var wait := max(base_wait - 0.05 * float(wave - 1), 0.25)
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
	for i in burst:
		var e := enemy_scene.instantiate()
		var ang := randf() * TAU
		var pos := Vector2(cos(ang), sin(ang)) * arena_radius
		e.global_position = pos
		game.get_node("EnemyContainer").add_child(e)
