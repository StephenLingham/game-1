extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var wave_controller: Node = $WaveController
@onready var hud: CanvasLayer = $UI
@onready var shop_panel: Control = $UI/ShopPanel
@onready var game_over_panel: Control = $UI/GameOverPanel
@onready var pause_panel: Control = $UI/PausePanel

@onready var lbl_wave: Label = $UI/HUD/WaveLabel
@onready var lbl_time: Label = $UI/HUD/TimeLabel
@onready var lbl_gold: Label = $UI/HUD/GoldLabel
@onready var lbl_hp: Label = $UI/HUD/HPLabel

func _ready() -> void:
	player.player_died.connect(_on_player_died)

	# Wire shop buttons
	$UI/ShopPanel/VBox/BuyDamage.pressed.connect(_buy_damage)
	$UI/ShopPanel/VBox/BuyAtkSpd.pressed.connect(_buy_atkspd)
	$UI/ShopPanel/VBox/Continue.pressed.connect(_close_shop)

	# Game over buttons
	$UI/GameOverPanel/VBox/BackToLobby.pressed.connect(_back_to_lobby)
	$UI/GameOverPanel/VBox/Retry.pressed.connect(_retry)
	
	# Pause buttons
	$UI/PausePanel/VBox/Resume.pressed.connect(_resume)
	$UI/PausePanel/VBox/Abandon.pressed.connect(_abandon_run)

	shop_panel.visible = false
	game_over_panel.visible = false
	pause_panel.visible = false

	wave_controller.start_run()

func _process(_delta: float) -> void:
	lbl_gold.text = "Gold: %d" % GameState.run_gold
	lbl_hp.text = "HP: %d" % player.health

func on_wave_started(w: int) -> void:
	lbl_wave.text = "Wave: %d / 10" % w

func on_wave_time(t: float) -> void:
	lbl_time.text = "Time: %.0fs" % t

func open_shop(_wave: int) -> void:
	get_tree().paused = true
	shop_panel.visible = true
	shop_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_refresh_shop_text()

func _close_shop() -> void:
	shop_panel.visible = false
	get_tree().paused = false
	wave_controller.resume_after_shop()

func _refresh_shop_text() -> void:
	var dmg_cost := _shop_damage_cost()
	var spd_cost := _shop_atkspd_cost()
	$UI/ShopPanel/VBox/Info.text = "Gold: %d\nDamage bonus: +%d\nAttack speed mult: x%.2f" % [
		GameState.run_gold, GameState.run_damage_bonus, GameState.run_atkspd_mult
	]
	$UI/ShopPanel/VBox/BuyDamage.text = "Upgrade Damage (+5) - %d gold" % dmg_cost
	$UI/ShopPanel/VBox/BuyAtkSpd.text = "Upgrade Attack Speed (+10%%) - %d gold" % spd_cost

func _shop_damage_cost() -> int:
	# Scale with number of purchases
	return 10 + int(GameState.run_damage_bonus / 5) * 8

func _shop_atkspd_cost() -> int:
	# Scale with multiplier
	var steps := int(round((GameState.run_atkspd_mult - 1.0) / 0.10))
	return 12 + steps * 10

func _buy_damage() -> void:
	var cost := _shop_damage_cost()
	if GameState.run_gold < cost:
		return
	GameState.run_gold -= cost
	GameState.run_damage_bonus += 5
	_refresh_shop_text()

func _buy_atkspd() -> void:
	var cost := _shop_atkspd_cost()
	if GameState.run_gold < cost:
		return
	GameState.run_gold -= cost
	GameState.run_atkspd_mult *= 1.10
	_refresh_shop_text()

func _on_player_died() -> void:
	end_run(false, wave_controller.wave)

func end_run(won: bool, waves_completed: int) -> void:
	# Prevent double-end
	if game_over_panel.visible:
		return
	get_tree().paused = true

	# Gems reward: 2 per wave + 10 bonus if win
	var gems := waves_completed * 2
	if won:
		gems += 10
	GameState.award_gems(gems)

	game_over_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	game_over_panel.visible = true
	var result_text := "Victory!" if won else "Defeated!"
	$UI/GameOverPanel/VBox/Result.text = result_text + "\nWaves completed: %d\nGems earned: %d\nTotal gems: %d" % [
		waves_completed, gems, GameState.gems
	]

func _back_to_lobby() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")

func _retry() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if not shop_panel.visible and not game_over_panel.visible:
			_toggle_pause()

func _toggle_pause() -> void:
	var is_paused := get_tree().paused
	get_tree().paused = not is_paused
	pause_panel.visible = not is_paused

func _resume() -> void:
	_toggle_pause()

func _abandon_run() -> void:
	end_run(false, wave_controller.wave)
	pause_panel.visible = false
