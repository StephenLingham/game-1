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
	
	if not $UI/ShopPanel/VBox.has_node("BuyRadius"):
		var btn := Button.new()
		btn.name = "BuyRadius"
		$UI/ShopPanel/VBox.add_child(btn)
		$UI/ShopPanel/VBox.move_child(btn, $UI/ShopPanel/VBox/BuyAtkSpd.get_index() + 1)
	
	if not $UI/ShopPanel/VBox.has_node("BuyOrbs"):
		var btn := Button.new()
		btn.name = "BuyOrbs"
		$UI/ShopPanel/VBox.add_child(btn)
		$UI/ShopPanel/VBox.move_child(btn, $UI/ShopPanel/VBox/BuyRadius.get_index() + 1)

	$UI/ShopPanel/VBox/BuyRadius.pressed.connect(_buy_radius)
	$UI/ShopPanel/VBox/BuyOrbs.pressed.connect(_buy_orbs)
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

	_setup_arena()

	wave_controller.start_run()

func _setup_arena() -> void:
	var screen_size := Vector2(1920, 1080)
	var arena_size := Vector2(screen_size.x * GameConstants.ARENA_WIDTH_MULTIPLIER, screen_size.y * GameConstants.ARENA_HEIGHT_MULTIPLIER)
	var center := screen_size / 2.0
	
	var floor_rect := $ArenaFloor
	floor_rect.size = arena_size
	floor_rect.position = center - (arena_size / 2.0)
	floor_rect.color = Color(0.15, 0.45, 0.2)
	
	$Background.color = Color(0.05, 0.2, 0.1)
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
	if is_instance_valid(player):
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
	var rad_cost := _shop_radius_cost()
	var orb_cost := _shop_orb_cost()
	
	$UI/ShopPanel/VBox/Info.text = "Gold: %d\nDamage bonus: +%d\nAttack speed mult: x%.2f\nPickup Radius: %.0fpx\nOrb Level: %d" % [
		GameState.run_gold, GameState.run_damage_bonus, GameState.run_atkspd_mult, GameState.get_pickup_radius(), GameState.run_orb_level
	]
	$UI/ShopPanel/VBox/BuyDamage.text = "Upgrade Damage (+5) - %d gold" % dmg_cost
	$UI/ShopPanel/VBox/BuyAtkSpd.text = "Upgrade Attack Speed (+10%%) - %d gold" % spd_cost
	$UI/ShopPanel/VBox/BuyRadius.text = "Upgrade Pickup Radius (+25px) - %d gold" % rad_cost
	
	var orb_btn = $UI/ShopPanel/VBox/BuyOrbs
	if GameState.run_orb_level >= GameConstants.ORB_MAX_LEVEL:
		orb_btn.text = "Orb Ability (MAX LEVEL)"
		orb_btn.disabled = true
	else:
		var next_text = _get_orb_upgrade_desc(GameState.run_orb_level + 1)
		orb_btn.text = "Upgrade Orbs (%s) - %d gold" % [next_text, orb_cost]
		orb_btn.disabled = false

func _shop_damage_cost() -> int:
	# Scale with number of purchases
	return 10 + int(GameState.run_damage_bonus / 5) * 8

func _shop_atkspd_cost() -> int:
	# Scale with multiplier
	var steps := int(round((GameState.run_atkspd_mult - 1.0) / 0.10))
	return 12 + steps * 10

func _shop_radius_cost() -> int:
	var steps := int(round(GameState.run_pickup_radius_bonus / GameConstants.COLLECTION_RADIUS_UPGRADE_AMOUNT))
	return 15 + steps * 10

func _shop_orb_cost() -> int:
	if GameState.run_orb_level == 0: return 50
	return 40 + GameState.run_orb_level * 30

func _get_orb_upgrade_desc(lvl: int) -> String:
	match lvl:
		1: return "1 Orb"
		2: return "Speed+"
		3: return "2 Orbs"
		4: return "Speed++"
		5: return "3 Orbs"
		6: return "Max Speed"
	return "Level %d" % lvl

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

func _buy_radius() -> void:
	var cost := _shop_radius_cost()
	if GameState.run_gold < cost:
		return
	GameState.run_gold -= cost
	GameState.run_pickup_radius_bonus += GameConstants.COLLECTION_RADIUS_UPGRADE_AMOUNT
	_refresh_shop_text()

func _buy_orbs() -> void:
	var cost := _shop_orb_cost()
	if GameState.run_gold < cost or GameState.run_orb_level >= GameConstants.ORB_MAX_LEVEL:
		return
	GameState.run_gold -= cost
	GameState.run_orb_level += 1
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
