extends Node2D

@onready var player: Node2D = $Player
@onready var wave_controller: Node = $WaveController
@onready var hud: CanvasLayer = $UI
@onready var shop_panel: Control = $UI/ShopPanel
@onready var game_over_panel: Control = $UI/GameOverPanel
@onready var pause_panel: Control = $UI/PausePanel

@onready var shop_grid: GridContainer = $UI/ShopPanel/Margin/VBox/Scroll/Grid
@onready var shop_gold_label: Label = $UI/ShopPanel/Margin/VBox/InfoRow/GoldLabel
@onready var shop_gems_label: Label = $UI/ShopPanel/Margin/VBox/InfoRow/GemsLabel
@onready var shop_continue: Button = $UI/ShopPanel/Margin/VBox/Continue

@onready var lbl_wave: Label = $UI/HUD/HUDMargin/HUDVBox/WaveLabel
@onready var lbl_time: Label = $UI/HUD/HUDMargin/HUDVBox/TimeLabel
@onready var lbl_gold: Label = $UI/HUD/HUDMargin/HUDVBox/GoldLabel
@onready var lbl_gems: Label = $UI/HUD/HUDMargin/HUDVBox/GemsLabel
@onready var lbl_hp: Label = $UI/HUD/HUDMargin/HUDVBox/HPLabel

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
	$UI/GameOverPanel/Margin/VBox/ButtonBox/BackToLobby.pressed.connect(_back_to_lobby)
	$UI/GameOverPanel/Margin/VBox/ButtonBox/Retry.pressed.connect(_retry)
	
	# Pause buttons
	$UI/PausePanel/VBox/Resume.pressed.connect(_resume)
	$UI/PausePanel/VBox/Abandon.pressed.connect(_abandon_run)

	shop_panel.visible = false
	# Make shop full screen
	shop_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	game_over_panel.visible = false
	pause_panel.visible = false

	_setup_arena()

	# Position player at center of viewport dynamically
	var screen_center := get_viewport().get_visible_rect().size / 2.0
	player.position = screen_center

	wave_controller.start_run()

func _setup_arena() -> void:
	var screen_size := get_viewport().get_visible_rect().size
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
	
	$UI/ShopPanel/Margin/VBox/Title.text = "Armory — Wave %d Completed" % w
	
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
	
	shop_gold_label.text = "Gold: %d" % GameState.run_gold
	shop_gems_label.text = "Gems: %d" % GameState.gems
	
	var grid = shop_grid
	var gun_btn = grid.get_node("BuyGun")
	if GameState.run_gun_level >= GameConstants.GUN_MAX_LEVEL:
		gun_btn.text = "Handgun (Lv. %d)\nMAX LEVEL" % GameState.run_gun_level
		gun_btn.disabled = true
	else:
		gun_btn.text = "Handgun (Lv. %d → %d)\nCost: %d Gold" % [GameState.run_gun_level, GameState.run_gun_level + 1, gun_cost]
		gun_btn.disabled = false
	
	var magnet_btn = grid.get_node("BuyMagnet")
	if GameState.run_magnet_level >= GameConstants.MAGNET_MAX_LEVEL:
		magnet_btn.text = "Magnet (Lv. %d)\nMAX LEVEL" % GameState.run_magnet_level
		magnet_btn.disabled = true
	elif GameState.run_magnet_level == 0:
		magnet_btn.text = "Buy Magnet\nCost: %d Gold" % magnet_cost
		magnet_btn.disabled = false
	else:
		magnet_btn.text = "Magnet (Lv. %d → %d)\nCost: %d Gold" % [GameState.run_magnet_level, GameState.run_magnet_level + 1, magnet_cost]
		magnet_btn.disabled = false
	
	var orb_btn = grid.get_node("BuyOrbs")
	if GameState.run_orb_level >= GameConstants.ORB_MAX_LEVEL:
		orb_btn.text = "Orbs (Lv. %d)\nMAX LEVEL" % GameState.run_orb_level
		orb_btn.disabled = true
	elif GameState.run_orb_level == 0:
		orb_btn.text = "Buy Orbs\nCost: %d Gold" % orb_cost
		orb_btn.disabled = false
	else:
		var next_text = _get_orb_upgrade_desc(GameState.run_orb_level + 1)
		orb_btn.text = "Orbs (Lv. %d → %d: %s)\nCost: %d Gold" % [GameState.run_orb_level, GameState.run_orb_level + 1, next_text, orb_cost]
		orb_btn.disabled = false
	
	var spike_btn = grid.get_node("BuySpike")
	if GameState.run_spike_ball_level >= GameConstants.SPIKE_BALL_MAX_LEVEL:
		spike_btn.text = "Spike Ball (Lv. %d)\nMAX LEVEL" % GameState.run_spike_ball_level
		spike_btn.disabled = true
	elif GameState.run_spike_ball_level == 0:
		spike_btn.text = "Buy Spike Ball\nCost: %d Gold" % spike_cost
		spike_btn.disabled = false
	else:
		spike_btn.text = "Spike Ball (Lv. %d → %d)\nCost: %d Gold" % [GameState.run_spike_ball_level, GameState.run_spike_ball_level + 1, spike_cost]
		spike_btn.disabled = false

	var shotgun_btn = grid.get_node("BuyShotgun")
	if GameState.run_shotgun_level >= GameConstants.SHOTGUN_MAX_LEVEL:
		shotgun_btn.text = "Shotgun (Lv. %d)\nMAX LEVEL" % GameState.run_shotgun_level
		shotgun_btn.disabled = true
	elif GameState.run_shotgun_level == 0:
		shotgun_btn.text = "Buy Shotgun\nCost: %d Gold" % shotgun_cost
		shotgun_btn.disabled = false
	else:
		shotgun_btn.text = "Shotgun (Lv. %d → %d)\nCost: %d Gold" % [GameState.run_shotgun_level, GameState.run_shotgun_level + 1, shotgun_cost]
		shotgun_btn.disabled = false

	var sniper_btn = grid.get_node("BuySniper")
	if GameState.run_sniper_level >= GameConstants.SNIPER_MAX_LEVEL:
		sniper_btn.text = "Sniper (Lv. %d)\nMAX LEVEL" % GameState.run_sniper_level
		sniper_btn.disabled = true
	elif GameState.run_sniper_level == 0:
		sniper_btn.text = "Buy Sniper Gun\nCost: %d Gold" % sniper_cost
		sniper_btn.disabled = false
	else:
		sniper_btn.text = "Sniper (Lv. %d → %d)\nCost: %d Gold" % [GameState.run_sniper_level, GameState.run_sniper_level + 1, sniper_cost]
		sniper_btn.disabled = false

	var rocket_btn = grid.get_node("BuyRocket")
	if GameState.run_rocket_level >= GameConstants.ROCKET_MAX_LEVEL:
		rocket_btn.text = "Rocket (Lv. %d)\nMAX LEVEL" % GameState.run_rocket_level
		rocket_btn.disabled = true
	elif GameState.run_rocket_level == 0:
		rocket_btn.text = "Buy Rocket Launcher\nCost: %d Gold" % rocket_cost
		rocket_btn.disabled = false
	else:
		rocket_btn.text = "Rocket (Lv. %d → %d)\nCost: %d Gold" % [GameState.run_rocket_level, GameState.run_rocket_level + 1, rocket_cost]
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
	GameState.run_gold_spent += cost
	GameState.run_gun_level += 1
	_refresh_shop_text()

func _buy_magnet() -> void:
	var cost := _shop_magnet_cost()
	if GameState.run_gold < cost or GameState.run_magnet_level >= GameConstants.MAGNET_MAX_LEVEL:
		return
	GameState.run_gold -= cost
	GameState.run_gold_spent += cost
	GameState.run_magnet_level += 1
	_refresh_shop_text()

func _buy_orbs() -> void:
	var cost := _shop_orb_cost()
	if GameState.run_gold < cost or GameState.run_orb_level >= GameConstants.ORB_MAX_LEVEL:
		return
	GameState.run_gold -= cost
	GameState.run_gold_spent += cost
	GameState.run_orb_level += 1
	_refresh_shop_text()

func _buy_spike_ball() -> void:
	var cost := _shop_spike_ball_cost()
	if GameState.run_gold < cost or GameState.run_spike_ball_level >= GameConstants.SPIKE_BALL_MAX_LEVEL:
		return
	GameState.run_gold -= cost
	GameState.run_gold_spent += cost
	GameState.run_spike_ball_level += 1
	_refresh_shop_text()

func _buy_shotgun() -> void:
	var cost := _shop_shotgun_cost()
	if GameState.run_gold < cost or GameState.run_shotgun_level >= GameConstants.SHOTGUN_MAX_LEVEL:
		return
	GameState.run_gold -= cost
	GameState.run_gold_spent += cost
	GameState.run_shotgun_level += 1
	_refresh_shop_text()

func _buy_sniper() -> void:
	var cost := _shop_sniper_cost()
	if GameState.run_gold < cost or GameState.run_sniper_level >= GameConstants.SNIPER_MAX_LEVEL:
		return
	GameState.run_gold -= cost
	GameState.run_gold_spent += cost
	GameState.run_sniper_level += 1
	_refresh_shop_text()

func _buy_rocket() -> void:
	var cost := _shop_rocket_cost()
	if GameState.run_gold < cost or GameState.run_rocket_level >= GameConstants.ROCKET_MAX_LEVEL:
		return
	GameState.run_gold -= cost
	GameState.run_gold_spent += cost
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
	$UI/GameOverPanel/Margin/VBox/Result.text = result_text + "  —  Waves completed: %d" % waves_completed

	# Populate stats
	var stats_vbox = $UI/GameOverPanel/Margin/VBox/StatsScroll/StatsVBox
	stats_vbox.get_node("KillsLabel").text = "Enemies Killed: %d" % GameState.run_enemies_killed

	# Damage breakdown
	var dmg_grid = stats_vbox.get_node("DmgGrid")
	dmg_grid.get_node("DmgHandgunValue").text = "%d" % GameState.run_damage_handgun
	dmg_grid.get_node("DmgShotgunValue").text = "%d" % GameState.run_damage_shotgun
	dmg_grid.get_node("DmgSniperValue").text = "%d" % GameState.run_damage_sniper
	dmg_grid.get_node("DmgRocketValue").text = "%d" % GameState.run_damage_rocket
	dmg_grid.get_node("DmgSpikeValue").text = "%d" % GameState.run_damage_spike_ball
	dmg_grid.get_node("DmgOrbsValue").text = "%d" % GameState.run_damage_orbs

	# Gold stats
	var gold_grid = stats_vbox.get_node("GoldGrid")
	gold_grid.get_node("GoldCollectedValue").text = "%d" % GameState.run_gold_collected
	gold_grid.get_node("GoldSpentValue").text = "%d" % GameState.run_gold_spent

	# Gems
	stats_vbox.get_node("GemsLabel").text = "Gems earned: %d  |  Total gems: %d" % [gems, GameState.gems]

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
