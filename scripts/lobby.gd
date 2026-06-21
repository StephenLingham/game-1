extends Control

@onready var start_btn: Button = $VBox/Start
@onready var exit_btn: Button = $VBox/Exit
@onready var upgrades_btn: Button = $VBox/Upgrades
@onready var unlocks_btn: Button = $VBox/Unlocks
@onready var stats_btn: Button = $VBox/Stats
@onready var reset_all_btn: Button = $VBox/ResetAll
@onready var reset_confirmation: ConfirmationDialog = $ResetConfirmation

func _ready() -> void:
	start_btn.pressed.connect(_on_start_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)
	upgrades_btn.pressed.connect(_on_upgrades_pressed)
	unlocks_btn.pressed.connect(_on_unlocks_pressed)
	stats_btn.pressed.connect(_on_stats_pressed)
	reset_all_btn.pressed.connect(_on_reset_all_pressed)
	reset_confirmation.confirmed.connect(_on_reset_confirmed)
	$VersionLabel.text = GameConstants.GAME_VERSION

func _on_upgrades_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/PermUpgrades.tscn")

func _on_unlocks_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Unlocks.tscn")

func _on_stats_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Stats.tscn")

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn")

func _on_reset_all_pressed() -> void:
	reset_confirmation.popup_centered()

func _on_reset_confirmed() -> void:
	GameState.reset_all_data()
	print("All data has been reset.")

func _on_exit_pressed() -> void:
	get_tree().quit()
