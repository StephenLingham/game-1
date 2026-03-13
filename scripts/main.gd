extends Node2D

@onready var player: Node2D = $Player
@onready var wave_controller: Node = $WaveController
@onready var hud: CanvasLayer = $UI
@onready var shop_panel: Control = $UI/ShopPanel
@onready var game_over_panel: Control = $UI/GameOverPanel
@onready var pause_panel: Control = $UI/PausePanel

@onready var shop_grid: GridContainer = $UI/ShopPanel/Margin/VBox/Scroll/Grid
@onready var shop_col1: Label = $UI/ShopPanel/Margin/VBox/StatsGrid/Col1
@onready var shop_col2: Label = $UI/ShopPanel/Margin/VBox/StatsGrid/Col2
@onready var shop_col3: Label = $UI/ShopPanel/Margin/VBox/StatsGrid/Col3
@onready var shop_continue: Button = $UI/ShopPanel/Margin/VBox/Continue

@onready var lbl_wave: Label = $UI/HUD/WaveLabel
@onready var lbl_time: Label = $UI/HUD/TimeLabel
@onready var lbl_gold: Label = $UI/HUD/GoldLabel
@onready var lbl_gems: Label = $UI/HUD/GemsLabel
@onready var lbl_hp: Label = $UI/HUD/HPLabel

func _ready() -> void:
	player.player_died.connect(_on_player_died)

	# Wire shop buttons
	$UI/ShopPanel/Margin/VBox/Scroll/Grid/BuyGun.pressed.connect(_buy_gun)
	$UI/ShopPanel/Margin/VBox/Scroll/Grid/BuyMagnet.pressed.connect(_buy_magnet)
	$UI/ShopPanel/Margin/VBox/Scroll/Grid/BuyOrbs.pressed.connect(_buy_orbs)
	$UI/ShopPanel/Margin/VBox/Scroll/Grid/BuySpike.pressed.connect(_buy_spike_ball)
	$UI/ShopPanel/Margin/VBox/Scroll/Grid/BuyShotgun.pressed.connect(_buy_shotgun)
	$UI/ShopPanel/Margin/VBox/Scroll/Grid/BuySniper.pressed.connect(_buy_sniper)
	$UI/ShopPanel/Margin/VBox/Scroll/Grid/BuyRocket.pressed.connect(_buy_rocket)
	
	shop_continue.pressed.connect(_close_shop)

	# Game over buttons
	$UI/GameOverPanel/VBox/BackToLobby.pressed.connect(_back_to_lobby)
	$UI/GameOverPanel/VBox/Retry.pressed.connect(_retry)
	
	# Pause buttons
	$UI/PausePanel/VBox/Resume.pressed.connect(_resume)
	$UI/PausePanel/VBox/Abandon.pressed.connect(_abandon_run)

	shop_panel.visible = false
	# Make shop full screen
	shop_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	game_over_panel.visible = false
	pause_panel.visible = false

	_setup_arena()

	wave_controller.start_run()

func _setup_arena() -> void:
	var screen_size := Vector2(1920, 1080)
	var arena_size := Vector2(screen_size.x * GameConstants.ARENA_WIDTH_MULTIPLIER, screen_size.y * GameConstants.ARENA_HEIGHT_MULTIPLIER)
	var center := screen_size / 2.0
	
	var floor_rect := $ArenaFloor
	floor_rect.size = arena_size
	floor_rect.position = center - (arena_size / 2.0)
	floor_rect.color = Color(0.15, 0.45, 0.2) # Green floor (Grass)
	
	$Background.color = Color(0.05, 0.2, 0.1) # Dark green background
	$Background.position = floor_rect.position - Vector2(2000, 2000)
	$Background.size = arena_size + Vector2(4000, 4000)
	
	var grass = preload("res://scripts/grass_drawer.gd").new()
	grass.arena_size = arena_size
	floor_rect.add_child(grass)
	
	var thickness := 100.0
	
	var wall_top = $ArenaWalls/WallTop
	wall_top.position = Vector2(center.x, floor_rect.position.y - thickness / 2.0)
	var top_shape := RectangleShape2D.new()
	top_shape.size = Vector2(arena_size.x + thickness * 2, thickness)
	wall_top.get_node("CollisionShape2D").shape = top_shape
	var wt_vis = wall_top.get_node("Visual") as ColorRect
	wt_vis.size = top_shape.size
	wt_vis.position = -wt_vis.size / 2.0
	wt_vis.color = Color(0.1, 0.1, 0.1)
	
	var wall_bottom = $ArenaWalls/WallBottom
	wall_bottom.position = Vector2(center.x, floor_rect.position.y + arena_size.y + thickness / 2.0)
	var bottom_shape := RectangleShape2D.new()
	bottom_shape.size = Vector2(arena_size.x + thickness * 2, thickness)
	wall_bottom.get_node("CollisionShape2D").shape = bottom_shape
	var wb_vis = wall_bottom.get_node("Visual") as ColorRect
	wb_vis.size = bottom_shape.size
	wb_vis.position = -wb_vis.size / 2.0
	wb_vis.color = Color(0.1, 0.1, 0.1)
	
	var wall_left = $ArenaWalls/WallLeft
	wall_left.position = Vector2(floor_rect.position.x - thickness / 2.0, center.y)
	var left_shape := RectangleShape2D.new()
	left_shape.size = Vector2(thickness, arena_size.y)
	wall_left.get_node("CollisionShape2D").shape = left_shape
	var wl_vis = wall_left.get_node("Visual") as ColorRect
	wl_vis.size = left_shape.size
	wl_vis.position = -wl_vis.size / 2.0
	wl_vis.color = Color(0.1, 0.1, 0.1)
	
	var wall_right = $ArenaWalls/WallRight
	wall_right.position = Vector2(floor_rect.position.x + arena_size.x + thickness / 2.0, center.y)
	var right_shape := RectangleShape2D.new()
	right_shape.size = Vector2(thickness, arena_size.y)
	wall_right.get_node("CollisionShape2D").shape = right_shape
	var wr_vis = wall_right.get_node("Visual") as ColorRect
	wr_vis.size = right_shape.size
	wr_vis.position = -wr_vis.size / 2.0
	wr_vis.color = Color(0.1, 0.1, 0.1)

	var arena_rect = Rect2(floor_rect.position, arena_size)
	wave_controller.set_arena_bounds(arena_rect)
	wave_controller.arena_radius = max(arena_size.x, arena_size.y) / 2.0
	if player.has_method("set_camera_limits"):
		player.set_camera_limits(arena_rect)

func _process(_delta: float) -> void:
	lbl_gold.text = "Gold: %d" % GameState.run_gold
	lbl_gems.text = "Gems: %d" % GameState.gems
	if is_instance_valid(player) and "health" in player:
		lbl_hp.text = "HP: %d" % player.health

func on_wave_started(w: int) -> void:
	lbl_wave.text = "Wave: %d / 10" % w

func on_wave_time(t: float) -> void:
	lbl_time.text = "Time: %.0fs" % t

func open_shop(w: int) -> void:
	get_tree().paused = true
	shop_panel.visible = true
	shop_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	
	$UI/ShopPanel/Margin/VBox/Title.text = "— ARMORY — WAVE %d COMPLETED" % w
	
	# Restore player health
	if is_instance_valid(player) and "health" in player:
		player.health = player.max_health
	
	_refresh_shop_text()

func _close_shop() -> void:
	shop_panel.visible = false
	get_tree().paused = false
	wave_controller.resume_after_shop()

func _refresh_shop_text() -> void:
	var gun_cost := _shop_gun_cost()
	var magnet_cost := _shop_magnet_cost()
	var orb_cost := _shop_orb_cost()
	var spike_cost := _shop_spike_ball_cost()
	var shotgun_cost := _shop_shotgun_cost()
	var sniper_cost := _shop_sniper_cost()
	var rocket_cost := _shop_rocket_cost()
	
	shop_col1.text = "Gold: %d\nGun Lvl: %d\nMagnet Lvl: %d" % [GameState.run_gold, GameState.run_gun_level, GameState.run_magnet_level]
	shop_col2.text = "Radius: %.0fpx\nOrbs: %d\nSpike: %d" % [GameState.get_pickup_radius(), GameState.run_orb_level, GameState.run_spike_ball_level]
	shop_col3.text = "Shotgun: %d\nSniper: %d\nRocket: %d" % [GameState.run_shotgun_level, GameState.run_sniper_level, GameState.run_rocket_level]
	
	var grid = shop_grid
	var gun_btn = grid.get_node("BuyGun")
	if GameState.run_gun_level >= GameConstants.GUN_MAX_LEVEL:
		gun_btn.text = "Handgun\n(MAX LEVEL)"
		gun_btn.disabled = true
	else:
		gun_btn.text = "Upgrade Gun (Dmg+Spd)\nCost: %d Gold" % gun_cost
		gun_btn.disabled = false
	
	var magnet_btn = grid.get_node("BuyMagnet")
	if GameState.run_magnet_level >= GameConstants.MAGNET_MAX_LEVEL:
		magnet_btn.text = "Magnet\n(MAX LEVEL)"
		magnet_btn.disabled = true
	else:
		magnet_btn.text = "Upgrade Magnet (Radius+)\nCost: %d Gold" % magnet_cost
		magnet_btn.disabled = false
	
	var orb_btn = grid.get_node("BuyOrbs")
	if GameState.run_orb_level >= GameConstants.ORB_MAX_LEVEL:
		orb_btn.text = "Orb Ability\n(MAX LEVEL)"
		orb_btn.disabled = true
	else:
		var next_text = _get_orb_upgrade_desc(GameState.run_orb_level + 1)
		orb_btn.text = "Upgrade Orbs (%s)\nCost: %d Gold" % [next_text, orb_cost]
		orb_btn.disabled = false
	
	var spike_btn = grid.get_node("BuySpike")
	if GameState.run_spike_ball_level >= GameConstants.SPIKE_BALL_MAX_LEVEL:
		spike_btn.text = "Spike Ball\n(MAX LEVEL)"
		spike_btn.disabled = true
	elif GameState.run_spike_ball_level == 0:
		spike_btn.text = "Unlock Spike Ball\nCost: %d Gold" % spike_cost
		spike_btn.disabled = false
	else:
		spike_btn.text = "Upgrade Spike Ball\nCost: %d Gold" % spike_cost
		spike_btn.disabled = false

	var shotgun_btn = grid.get_node("BuyShotgun")
	if GameState.run_shotgun_level >= GameConstants.SHOTGUN_MAX_LEVEL:
		shotgun_btn.text = "Shotgun\n(MAX LEVEL)"
		shotgun_btn.disabled = true
	elif GameState.run_shotgun_level == 0:
		shotgun_btn.text = "Unlock Shotgun\nCost: %d Gold" % shotgun_cost
		shotgun_btn.disabled = false
	else:
		var next_bullets = (GameState.run_shotgun_level + 1) * 2 + 1
		shotgun_btn.text = "Upgrade Shotgun (%d bullets)\nCost: %d Gold" % [next_bullets, shotgun_cost]
		shotgun_btn.disabled = false

	var sniper_btn = grid.get_node("BuySniper")
	if GameState.run_sniper_level >= GameConstants.SNIPER_MAX_LEVEL:
		sniper_btn.text = "Sniper Gun\n(MAX LEVEL)"
		sniper_btn.disabled = true
	elif GameState.run_sniper_level == 0:
		sniper_btn.text = "Unlock Sniper Gun\nCost: %d Gold" % sniper_cost
		sniper_btn.disabled = false
	else:
		sniper_btn.text = "Upgrade Sniper (Fire Rate+)\nCost: %d Gold" % sniper_cost
		sniper_btn.disabled = false

	var rocket_btn = grid.get_node("BuyRocket")
	if GameState.run_rocket_level >= GameConstants.ROCKET_MAX_LEVEL:
		rocket_btn.text = "Rocket Launcher\n(MAX LEVEL)"
		rocket_btn.disabled = true
	elif GameState.run_rocket_level == 0:
		rocket_btn.text = "Unlock Rocket Launcher\nCost: %d Gold" % rocket_cost
		rocket_btn.disabled = false
	else:
		rocket_btn.text = "Upgrade Rocket (Blast+Rate)\nCost: %d Gold" % rocket_cost
		rocket_btn.disabled = false

func _shop_gun_cost() -> int:
	return GameConstants.GUN_BASE_COST + (GameState.run_gun_level - 1) * GameConstants.GUN_COST_INCREMENT

func _shop_magnet_cost() -> int:
	return GameConstants.MAGNET_BASE_COST + GameState.run_magnet_level * GameConstants.MAGNET_COST_INCREMENT

func _shop_orb_cost() -> int:
	if GameState.run_orb_level == 0: 
		return GameConstants.ORB_BASE_COST
	return GameConstants.ORB_BASE_COST + GameState.run_orb_level * GameConstants.ORB_COST_INCREMENT_PER_LEVEL

func _shop_spike_ball_cost() -> int:
	if GameState.run_spike_ball_level == 0:
		return GameConstants.SPIKE_BALL_BASE_COST
	return GameConstants.SPIKE_BALL_BASE_COST + GameState.run_spike_ball_level * GameConstants.SPIKE_BALL_COST_INCREMENT_PER_LEVEL

func _shop_shotgun_cost() -> int:
	if GameState.run_shotgun_level == 0:
		return GameConstants.SHOTGUN_BASE_COST
	return GameConstants.SHOTGUN_BASE_COST + GameState.run_shotgun_level * GameConstants.SHOTGUN_COST_INCREMENT_PER_LEVEL

func _shop_sniper_cost() -> int:
	if GameState.run_sniper_level == 0:
		return GameConstants.SNIPER_BASE_COST
	return GameConstants.SNIPER_BASE_COST + GameState.run_sniper_level * GameConstants.SNIPER_COST_INCREMENT_PER_LEVEL

func _shop_rocket_cost() -> int:
	if GameState.run_rocket_level == 0:
		return GameConstants.ROCKET_BASE_COST
	return GameConstants.ROCKET_BASE_COST + GameState.run_rocket_level * GameConstants.ROCKET_COST_INCREMENT_PER_LEVEL

func _get_orb_upgrade_desc(lvl: int) -> String:
	match lvl:
		1: return "1 Orb"
		2: return "Speed+"
		3: return "2 Orbs"
		4: return "Speed++"
		5: return "3 Orbs"
		6: return "Max Speed"
	return "Level %d" % lvl

func _buy_gun() -> void:
	var cost := _shop_gun_cost()
	if GameState.run_gold < cost or GameState.run_gun_level >= GameConstants.GUN_MAX_LEVEL:
		return
	GameState.run_gold -= cost
	GameState.run_gun_level += 1
	_refresh_shop_text()

func _buy_magnet() -> void:
	var cost := _shop_magnet_cost()
	if GameState.run_gold < cost or GameState.run_magnet_level >= GameConstants.MAGNET_MAX_LEVEL:
		return
	GameState.run_gold -= cost
	GameState.run_magnet_level += 1
	_refresh_shop_text()

func _buy_orbs() -> void:
	var cost := _shop_orb_cost()
	if GameState.run_gold < cost or GameState.run_orb_level >= GameConstants.ORB_MAX_LEVEL:
		return
	GameState.run_gold -= cost
	GameState.run_orb_level += 1
	_refresh_shop_text()

func _buy_spike_ball() -> void:
	var cost := _shop_spike_ball_cost()
	if GameState.run_gold < cost or GameState.run_spike_ball_level >= GameConstants.SPIKE_BALL_MAX_LEVEL:
		return
	GameState.run_gold -= cost
	GameState.run_spike_ball_level += 1
	_refresh_shop_text()

func _buy_shotgun() -> void:
	var cost := _shop_shotgun_cost()
	if GameState.run_gold < cost or GameState.run_shotgun_level >= GameConstants.SHOTGUN_MAX_LEVEL:
		return
	GameState.run_gold -= cost
	GameState.run_shotgun_level += 1
	_refresh_shop_text()

func _buy_sniper() -> void:
	var cost := _shop_sniper_cost()
	if GameState.run_gold < cost or GameState.run_sniper_level >= GameConstants.SNIPER_MAX_LEVEL:
		return
	GameState.run_gold -= cost
	GameState.run_sniper_level += 1
	_refresh_shop_text()

func _buy_rocket() -> void:
	var cost := _shop_rocket_cost()
	if GameState.run_gold < cost or GameState.run_rocket_level >= GameConstants.ROCKET_MAX_LEVEL:
		return
	GameState.run_gold -= cost
	GameState.run_rocket_level += 1
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
