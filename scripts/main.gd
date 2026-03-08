extends Node2D

@export var spawn_interval: float = 1.5
@export var min_spawn_interval: float = 0.3
@export var spawn_interval_decay: float = 0.98
@export var spawn_margin: float = 50.0

var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
var spawn_timer: float = 0.0
var score: int = 0

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var arena_walls: Node2D = $ArenaWalls
@onready var game_over_panel: PanelContainer = $HUD/GameOverPanel

func _ready() -> void:
	spawn_timer = spawn_interval
	player.player_died.connect(_on_player_died)
	game_over_panel.visible = false

func _process(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_enemy()
		spawn_interval = max(min_spawn_interval, spawn_interval * spawn_interval_decay)
		spawn_timer = spawn_interval
	
	# Update HUD
	hud.get_node("ScoreLabel").text = "SCORE: " + str(score)
	hud.get_node("HealthBar").value = player.health
	hud.get_node("HealthBar").max_value = player.max_health

func spawn_enemy() -> void:
	var enemy := enemy_scene.instantiate()
	
	# Spawn inside the arena near the edges
	# Arena interior is roughly x: 30-1250, y: 30-690 (inside the walls)
	var inner_left := 35.0
	var inner_right := 1245.0
	var inner_top := 35.0
	var inner_bottom := 685.0
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
	
	enemy.global_position = spawn_pos
	enemy.enemy_killed.connect(_on_enemy_killed)
	add_child(enemy)

func _on_enemy_killed() -> void:
	score += 100

func _on_player_died() -> void:
	# Show game over
	game_over_panel.visible = true
	get_tree().paused = true
	game_over_panel.get_node("VBoxContainer/FinalScoreLabel").text = "FINAL SCORE: " + str(score)

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
