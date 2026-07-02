extends Control

@onready var stats_list: GridContainer = $Margin/VBox/StatsScroll/StatsList
@onready var highest_level_value: Label = $Margin/VBox/StatsScroll/StatsList/HighestLevelValue
@onready var enemies_killed_value: Label = $Margin/VBox/StatsScroll/StatsList/EnemiesKilledValue
@onready var gifts_collected_value: Label = $Margin/VBox/StatsScroll/StatsList/GiftsCollectedValue
@onready var chests_opened_value: Label = $Margin/VBox/StatsScroll/StatsList/ChestsOpenedValue
@onready var shrines_activated_value: Label = $Margin/VBox/StatsScroll/StatsList/ShrinesActivatedValue
@onready var weapon_level_value: Label = $Margin/VBox/StatsScroll/StatsList/WeaponLevelValue
@onready var aura_level_value: Label = $Margin/VBox/StatsScroll/StatsList/AuraLevelValue
@onready var back_button: Button = $Margin/VBox/Back

func _ready() -> void:
	highest_level_value.text = str(GameState.best_run_player_level)
	enemies_killed_value.text = str(GameState.best_run_enemies_killed)
	gifts_collected_value.text = str(GameState.best_run_gifts_collected)
	chests_opened_value.text = str(GameState.best_run_chests_opened)
	shrines_activated_value.text = str(GameState.best_run_shrines_activated)
	weapon_level_value.text = str(GameState.best_weapon_level_reached)
	aura_level_value.text = str(GameState.best_aura_level_reached)
	_add_stat_row("Total time in game", _format_seconds(GameState.total_game_seconds))
	_add_stat_row("Time spent in runs", _format_seconds(GameState.total_run_seconds))
	_add_stat_row("Total enemies killed", str(GameState.lifetime_enemies_killed_total))
	for level_name in ["Level 1", "Level 2", "Level 3"]:
		_add_stat_row("Enemies killed on " + level_name, str(GameState.lifetime_enemies_killed_by_level.get(level_name, 0)))
	for level_name in ["Level 1", "Level 2", "Level 3"]:
		_add_stat_row("Fastest boss kill on " + level_name, _format_boss_kill_time(GameState.fastest_boss_kill_by_level.get(level_name, -1.0)))
	_add_stat_row("Successful runs completed", str(GameState.lifetime_successful_runs))
	back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")

func _add_stat_row(label_text: String, value_text: String) -> void:
	var label := Label.new()
	label.text = label_text
	stats_list.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats_list.add_child(value)

func _format_seconds(seconds_value: float) -> String:
	var total := int(floor(max(seconds_value, 0.0)))
	var hours := total / 3600
	var minutes := (total % 3600) / 60
	var seconds := total % 60
	if hours > 0:
		return "%dh %dm %ds" % [hours, minutes, seconds]
	return "%dm %ds" % [minutes, seconds]

func _format_boss_kill_time(seconds_value: float) -> String:
	if seconds_value < 0.0:
		return "-"
	return "%.1fs" % seconds_value
