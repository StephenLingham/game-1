extends Control

func _ready() -> void:
	$VBox/Level1.pressed.connect(_on_level_1_pressed)
	$VBox/Level2.pressed.connect(_on_level_2_pressed)
	$VBox/Level3.pressed.connect(_on_level_3_pressed)
	$VBox/Back.pressed.connect(_on_back_pressed)
	
	# Lock logic
	_check_locks()

func _check_locks() -> void:
	if not GameState.is_level_unlocked("Level 2"):
		$VBox/Level2.disabled = true
		$VBox/Level2.text = "Complete Level 1 to Unlock"
	
	if not GameState.is_level_unlocked("Level 3"):
		$VBox/Level3.disabled = true
		$VBox/Level3.text = "Complete Level 2 to Unlock"

func _on_level_1_pressed() -> void:
	_start_level(1.0, 1.0, 1.0, "Level 1")

func _on_level_2_pressed() -> void:
	_start_level(2.0, 1.5, 1.3, "Level 2")

func _on_level_3_pressed() -> void:
	_start_level(5.0, 3.0, 1.8, "Level 3")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn")

func _start_level(h: float, d: float, s: float, name: String) -> void:
	GameState.run_difficulty_health_mult = h
	GameState.run_difficulty_damage_mult = d
	GameState.run_difficulty_spawn_mult = s
	GameState.run_level_name = name
	get_tree().change_scene_to_file("res://scenes/main.tscn")
