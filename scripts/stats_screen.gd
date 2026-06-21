extends Control

@onready var highest_level_value: Label = $Margin/VBox/StatsList/HighestLevelValue
@onready var enemies_killed_value: Label = $Margin/VBox/StatsList/EnemiesKilledValue
@onready var gifts_collected_value: Label = $Margin/VBox/StatsList/GiftsCollectedValue
@onready var chests_opened_value: Label = $Margin/VBox/StatsList/ChestsOpenedValue
@onready var shrines_activated_value: Label = $Margin/VBox/StatsList/ShrinesActivatedValue
@onready var weapon_level_value: Label = $Margin/VBox/StatsList/WeaponLevelValue
@onready var aura_level_value: Label = $Margin/VBox/StatsList/AuraLevelValue
@onready var back_button: Button = $Margin/VBox/Back

func _ready() -> void:
	highest_level_value.text = str(GameState.best_run_player_level)
	enemies_killed_value.text = str(GameState.best_run_enemies_killed)
	gifts_collected_value.text = str(GameState.best_run_gifts_collected)
	chests_opened_value.text = str(GameState.best_run_chests_opened)
	shrines_activated_value.text = str(GameState.best_run_shrines_activated)
	weapon_level_value.text = str(GameState.best_weapon_level_reached)
	aura_level_value.text = str(GameState.best_aura_level_reached)
	back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
