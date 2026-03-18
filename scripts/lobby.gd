extends Control

@onready var gems_label: Label = $VBox/GemsLabel
@onready var start_btn: Button = $VBox/Start
@onready var exit_btn: Button = $VBox/Exit
@onready var upgrades_btn: Button = $VBox/Upgrades
@onready var unlocks_btn: Button = $VBox/Unlocks

func _ready() -> void:
	start_btn.pressed.connect(_on_start_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)
	upgrades_btn.pressed.connect(_on_upgrades_pressed)
	unlocks_btn.pressed.connect(_on_unlocks_pressed)
	
	_refresh_gems()
	$VersionLabel.text = GameConstants.GAME_VERSION

func _refresh_gems() -> void:
	gems_label.text = "Gems: %d" % GameState.gems

func _on_upgrades_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/PermUpgrades.tscn")

func _on_unlocks_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Unlocks.tscn")

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
