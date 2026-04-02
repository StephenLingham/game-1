extends Node2D

@onready var player: Node2D = $Player
@onready var wave_controller: Node = $WaveController
@onready var hud: CanvasLayer = $UI
@onready var shop_panel: Control = $UI/ShopPanel
@onready var game_over_panel: Control = $UI/GameOverPanel
@onready var pause_panel: Control = $UI/PausePanel
var item_popup_panel: Control



@onready var shop_grid: GridContainer = $UI/ShopPanel/Margin/VBox/Scroll/Grid
@onready var shop_lvl_label: Label = $UI/ShopPanel/Margin/VBox/InfoRow/LevelLabel
@onready var shop_continue: Button = $UI/ShopPanel/Margin/VBox/Continue
@onready var shop_capacity_label: Label = Label.new() # Will add to UI
@onready var xp_bar: ProgressBar = $UI/HUD/XPBar
@onready var lvl_xp_label: Label = $UI/HUD/HUDMargin/HUDVBox/LevelXPLabel
var current_chest_options: Array = []



var reroll_btn: Button
var banish_active: bool = false
var current_shop_options: Array = []

const ALL_ABILITIES = [
	{"id": "handgun", "name": "Handgun", "weapon": true},
	{"id": "shotgun", "name": "Shotgun", "weapon": true},
	{"id": "sniper", "name": "Sniper Gun", "weapon": true},
	{"id": "rocket", "name": "Rocket Launcher", "weapon": true},
	{"id": "machine_gun", "name": "Machine Gun", "weapon": true},
	{"id": "orbs", "name": "Energy Orbs", "weapon": false},
	{"id": "spike_ball", "name": "Spike Ball", "weapon": false},
	{"id": "bouncing_disk", "name": "Bouncing Disk", "weapon": false},
	{"id": "floor_spikes", "name": "Floor Spikes", "weapon": false},
	{"id": "turret", "name": "Turret", "weapon": false},
	{"id": "ice_wave", "name": "Ice Wave", "weapon": false}
]

@onready var lbl_wave: Label = $UI/HUD/HUDMargin/HUDVBox/WaveLabel
@onready var lbl_time: Label = $UI/HUD/HUDMargin/HUDVBox/TimeLabel
@onready var lbl_gems: Label = $UI/HUD/HUDMargin/HUDVBox/GemsLabel
@onready var lbl_hp: Label = $UI/HUD/HUDMargin/HUDVBox/HPLabel

func _ready() -> void:
	player.player_died.connect(_on_player_died)
	GameState.level_up.connect(_on_level_up)
	
	_ensure_item_popup_exists()

	# Shop Panel Styling
	shop_continue.visible = false
	shop_grid.columns = 1 # We will use HBoxContainers inside for true horizontal centering
	shop_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_grid.custom_minimum_size = Vector2(850, 0) # Force wide enough inside ScrollContainer
	
	var shop_scroll = shop_panel.get_node_or_null("Margin/VBox/Scroll")
	if shop_scroll:
		shop_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	# Make shop a popup overlay
	var overlay = shop_panel.get_node_or_null("ColorRect")
	if overlay:
		overlay.color = Color(0, 0, 0, 0.7)
	
	# Center the content container
	var shop_margin = shop_panel.get_node_or_null("Margin")
	if shop_margin:
		shop_margin.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		shop_margin.custom_minimum_size = Vector2(1000, 600)
		shop_margin.grow_horizontal = Control.GROW_DIRECTION_BOTH
		shop_margin.grow_vertical = Control.GROW_DIRECTION_BOTH
		# Add a background panel style to the margin
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.1, 0.1, 0.12, 1.0)
		sb.border_width_left = 4
		sb.border_width_top = 4
		sb.border_width_right = 4
		sb.border_width_bottom = 4
		sb.border_color = Color(0.4, 0.8, 1.0, 1.0)
		sb.corner_radius_top_left = 12
		sb.corner_radius_top_right = 12
		sb.corner_radius_bottom_left = 12
		sb.corner_radius_bottom_right = 12
		
		var pop_bg = Panel.new()
		pop_bg.name = "PopupBG"
		pop_bg.add_theme_stylebox_override("panel", sb)
		shop_margin.add_child(pop_bg)
		shop_margin.move_child(pop_bg, 0)
		pop_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
	# HUD Styling
	var hud_margin = hud.get_node_or_null("HUD/HUDMargin")
	if hud_margin:
		hud_margin.add_theme_constant_override("margin_top", 80)
	
	# XP Bar color (Blue)
	var bar_style = StyleBoxFlat.new()
	bar_style.bg_color = Color(0.1, 0.5, 1.0, 1.0) # Vibrant Blue
	bar_style.corner_radius_top_left = 4
	bar_style.corner_radius_top_right = 4
	bar_style.corner_radius_bottom_left = 4
	bar_style.corner_radius_bottom_right = 4
	xp_bar.add_theme_stylebox_override("fill", bar_style)
	
	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.1, 0.1, 0.15, 0.8)
	bar_bg.corner_radius_top_left = 4
	bar_bg.corner_radius_top_right = 4
	bar_bg.corner_radius_bottom_left = 4
	bar_bg.corner_radius_bottom_right = 4
	xp_bar.add_theme_stylebox_override("background", bar_bg)
	
	# Capacity Label
	shop_capacity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_capacity_label.add_theme_font_size_override("font_size", 22)
	$UI/ShopPanel/Margin/VBox.add_child(shop_capacity_label)
	$UI/ShopPanel/Margin/VBox.move_child(shop_capacity_label, $UI/ShopPanel/Margin/VBox/Scroll.get_index())

	# Game over buttons
	$UI/GameOverPanel/Margin/VBox/ButtonBox/BackToLobby.pressed.connect(_back_to_lobby)
	$UI/GameOverPanel/Margin/VBox/ButtonBox/Retry.pressed.connect(_retry)
	
	# Pause buttons
	$UI/PausePanel/VBox/Resume.pressed.connect(_resume)
	$UI/PausePanel/VBox/Abandon.pressed.connect(_abandon_run)

	shop_panel.visible = false
	shop_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	game_over_panel.visible = false
	pause_panel.visible = false
	
	# Position player at center of viewport dynamically first
	var screen_center := get_viewport().get_visible_rect().size / 2.0
	player.position = screen_center

	_setup_arena()
	wave_controller.start_run()

func _on_level_up(new_level: int) -> void:
	_generate_shop_options()
	if current_shop_options.is_empty():
		# Maxed out abilities! Reward with a free item from chests instead.
		show_item_window()
		return
	open_shop(new_level)

func _setup_arena() -> void:
	var screen_size := get_viewport().get_visible_rect().size
	var arena_size := Vector2(screen_size.x * GameConstants.ARENA_WIDTH_MULTIPLIER, screen_size.y * GameConstants.ARENA_HEIGHT_MULTIPLIER)
	var center := screen_size / 2.0
	
	var floor_rect := $ArenaFloor
	floor_rect.size = arena_size
	floor_rect.position = center - (arena_size / 2.0)
	floor_rect.color = Color(0.15, 0.45, 0.2) # Green floor (Grass)
	floor_rect.z_index = -100 # Ensure it's behind everything
	
	$Background.color = Color(0.05, 0.2, 0.1) # Dark green background
	$Background.position = floor_rect.position - Vector2(2000, 2000)
	$Background.size = arena_size + Vector2(4000, 4000)
	$Background.z_index = -101
	
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
	lvl_xp_label.text = "Level: %d" % GameState.run_level
	xp_bar.max_value = GameState.run_xp_to_next_level
	xp_bar.value = GameState.run_xp
	
	lbl_gems.text = "Gems: %d" % GameState.gems
	if is_instance_valid(player) and "health" in player:
		lbl_hp.text = "HP: %d" % player.health

func on_wave_started(w: int) -> void:
	lbl_wave.text = "Wave: %d / 10" % w
	# No longer reset player to center for continuous play

func on_wave_time(t: float) -> void:
	lbl_time.text = "Time: %.0fs" % t

func open_shop(lvl: int) -> void:
	# Options already generated by _on_level_up or caller
	get_tree().paused = true
	shop_panel.visible = true
	shop_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	
	$UI/ShopPanel/Margin/VBox/Title.text = "Level Up! — Choose a Weapon"
	shop_lvl_label.text = "Level: %d" % lvl
	
	_refresh_shop_ui()

func _close_shop() -> void:
	shop_panel.visible = false
	get_tree().paused = false
func _generate_shop_options() -> void:
	current_shop_options.clear()
	var pool = []
	
	var current_abi_count = GameState.run_abilities.size()
	var at_capacity = current_abi_count >= GameConstants.SHOP_MAX_ABILITIES

	for abi in ALL_ABILITIES:
		if not GameState.is_item_unlocked(abi.id): continue
		if GameState.run_banished_abilities.has(abi.id): continue
		
		var level = GameState.run_abilities.get(abi.id, 0)
		var max_level = _get_max_level(abi.id)
		
		# Skip if maxed
		if level >= max_level: continue
		
		# If at capacity, only show upgrades for things we already have
		if at_capacity and level == 0: continue
		
		pool.append(abi)
	
	pool.shuffle()
	for i in range(min(GameConstants.SHOP_OPTIONS_COUNT, pool.size())):
		current_shop_options.append(pool[i])

func _refresh_shop_ui() -> void:
	var abi_count = GameState.run_abilities.size()
	shop_capacity_label.text = "Weapons: %d / %d" % [abi_count, GameConstants.SHOP_MAX_ABILITIES]
	if abi_count >= GameConstants.SHOP_MAX_ABILITIES:
		shop_capacity_label.modulate = Color.VIOLET
	else:
		shop_capacity_label.modulate = Color.WHITE
	
	# Clear grid
	for child in shop_grid.get_children():
		child.queue_free()
	
	# Header for owned
	var h_owned = Label.new()
	h_owned.text = "--- YOUR LOADOUT ---"
	h_owned.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h_owned.modulate = Color.CYAN
	
	shop_grid.add_child(h_owned)
	
	# Create centered HBoxContainer for loadout items
	var loadout_box = HBoxContainer.new()
	loadout_box.alignment = BoxContainer.ALIGNMENT_CENTER
	loadout_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	loadout_box.add_theme_constant_override("separation", 20)
	shop_grid.add_child(loadout_box)
	
	# Show currently owned abilities
	var owned_ids = GameState.run_abilities.keys()
	for abi_id in owned_ids:
		var abi_data = null
		for a in ALL_ABILITIES:
			if a.id == abi_id:
				abi_data = a
				break
		if not abi_data: continue
		
		var level = GameState.run_abilities[abi_id]
		var max_lvl = _get_max_level(abi_id)
		
		var panel = PanelContainer.new()
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 10)
		vbox.custom_minimum_size = Vector2(200, 100) # Give fixed height for perfect alignment
		panel.add_child(vbox)
		
		var lbl = Label.new()
		var level_text = "(Lvl %d)" % level
		if level >= max_lvl: level_text = "(MAX)"
		lbl.text = abi_data.name + "\n" + level_text
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 22)
		vbox.add_child(lbl)
		
		panel.self_modulate = Color(0.8, 1.0, 0.8, 0.5)
		loadout_box.add_child(panel)

	# Optional vertical space
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	shop_grid.add_child(spacer)

	# --- SELECT UPGRADE ---
	var h_shop = Label.new()
	h_shop.text = "--- SELECT UPGRADE ---"
	h_shop.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h_shop.modulate = Color.GOLD
	
	shop_grid.add_child(h_shop)
	
	# Create centered HBoxContainer for shop options
	var upgrades_box = HBoxContainer.new()
	upgrades_box.alignment = BoxContainer.ALIGNMENT_CENTER
	upgrades_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrades_box.add_theme_constant_override("separation", 20)
	shop_grid.add_child(upgrades_box)

	for abi in current_shop_options:
		var level = GameState.run_abilities.get(abi.id, 0)
		var panel = PanelContainer.new()
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 10)
		vbox.custom_minimum_size = Vector2(240, 140) # Ensure fixed height so buttons align
		panel.add_child(vbox)
		
		var lbl = Label.new()
		lbl.text = abi.name + " (Lvl %d)" % level
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 22)
		vbox.add_child(lbl)
		
		var buy_btn = Button.new()
		var max_lvl = _get_max_level(abi.id)
		var is_limit_reached = level == 0 and GameState.run_abilities.size() >= GameConstants.SHOP_MAX_ABILITIES
		
		if level >= max_lvl:
			buy_btn.text = "MAXED"
			buy_btn.disabled = true
		elif is_limit_reached:
			buy_btn.text = "Limit Reached"
			buy_btn.disabled = true
		else:
			var prefix = "Select" if level == 0 else "Upgrade"
			buy_btn.text = "%s" % prefix
			buy_btn.pressed.connect(_buy_ability.bind(abi.id))
			
		buy_btn.custom_minimum_size = Vector2(180, 40)
		vbox.add_child(buy_btn)
		upgrades_box.add_child(panel)

func _get_max_level(id: String) -> int:
	match id:
		"handgun": return GameConstants.GUN_MAX_LEVEL
		"orbs": return GameConstants.ORB_MAX_LEVEL
		"spike_ball": return GameConstants.SPIKE_BALL_MAX_LEVEL
		"shotgun": return GameConstants.SHOTGUN_MAX_LEVEL
		"sniper": return GameConstants.SNIPER_MAX_LEVEL
		"rocket": return GameConstants.ROCKET_MAX_LEVEL
		"bouncing_disk": return GameConstants.DISK_MAX_LEVEL
		"floor_spikes": return GameConstants.SPIKES_MAX_LEVEL
		"turret": return GameConstants.TURRET_MAX_LEVEL
		"machine_gun": return GameConstants.MG_MAX_LEVEL
		"ice_wave": return GameConstants.ICE_MAX_LEVEL
	return 5

func _get_ability_cost(id: String, level: int) -> int:
	var base = 15
	var inc = 10
	match id:
		"handgun": base = GameConstants.GUN_BASE_COST; inc = GameConstants.GUN_COST_INCREMENT
		"orbs": base = GameConstants.ORB_BASE_COST; inc = GameConstants.ORB_COST_INCREMENT_PER_LEVEL
		"spike_ball": base = GameConstants.SPIKE_BALL_BASE_COST; inc = GameConstants.SPIKE_BALL_COST_INCREMENT_PER_LEVEL
		"shotgun": base = GameConstants.SHOTGUN_BASE_COST; inc = GameConstants.SHOTGUN_COST_INCREMENT_PER_LEVEL
		"sniper": base = GameConstants.SNIPER_BASE_COST; inc = GameConstants.SNIPER_COST_INCREMENT_PER_LEVEL
		"rocket": base = GameConstants.ROCKET_BASE_COST; inc = GameConstants.ROCKET_COST_INCREMENT_PER_LEVEL
		# New ones use defaults if not specific
	
	if level == 0: return base
	return base + level * inc

func _buy_ability(id: String) -> void:
	var level = GameState.run_abilities.get(id, 0)
	
	if level < _get_max_level(id):
		GameState.run_abilities[id] = level + 1
		GameState.record_ability_upgrade(id, level + 1)
		_close_shop()

func _sell_ability(id: String, value: int) -> void:
	if GameState.run_abilities.has(id):
		GameState.run_abilities.erase(id)
		GameState.run_gold += value
		_refresh_shop_ui()

func _reroll_shop() -> void:
	if GameState.run_gold >= GameState.run_reroll_cost:
		GameState.run_gold -= GameState.run_reroll_cost
		GameState.run_reroll_cost += GameConstants.SHOP_REROLL_INCREMENT
		_generate_shop_options()
		_refresh_shop_ui()

func _banish_ability(id: String) -> void:
	if GameState.run_banish_count > 0:
		GameState.run_banish_count -= 1
		GameState.run_banished_abilities.append(id)
		
		# Remove from current options until next reroll
		for i in range(current_shop_options.size()):
			if current_shop_options[i].id == id:
				current_shop_options.remove_at(i)
				break
				
		_refresh_shop_ui()

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
		GameState.mark_level_completed(GameState.run_level_name)
	
	# Handle delayed unlocks
	var newly_unlocked = []
	for id in GameState.run_unlocked_items:
		newly_unlocked.append(id)
	GameState.finalize_run_unlocks()
	
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
	var dmg_stats = [
		["DmgHandgun", GameState.run_damage_handgun],
		["DmgShotgun", GameState.run_damage_shotgun],
		["DmgSniper", GameState.run_damage_sniper],
		["DmgRocket", GameState.run_damage_rocket],
		["DmgSpike", GameState.run_damage_spike_ball],
		["DmgOrbs", GameState.run_damage_orbs],
		["DmgTurret", GameState.run_damage_turret],
		["DmgDisk", GameState.run_damage_bouncing_disk],
		["DmgFloorSpikes", GameState.run_damage_floor_spikes],
		["DmgExplosion", GameState.run_damage_explosion_pickup]
	]

	for stat in dmg_stats:
		var prefix = stat[0]
		var amt = stat[1]
		var lbl_node = dmg_grid.get_node_or_null(prefix + "Label")
		var val_node = dmg_grid.get_node_or_null(prefix + "Value")
		if lbl_node and val_node:
			if amt > 0:
				lbl_node.visible = true
				val_node.visible = true
				val_node.text = str(amt)
			else:
				lbl_node.visible = false
				val_node.visible = false

	# XP stats
	var gold_grid = stats_vbox.get_node("GoldGrid")
	gold_grid.get_node("GoldCollectedLabel").text = "XP Collected:"
	gold_grid.get_node("GoldCollectedValue").text = "%d" % GameState.run_xp_collected
	gold_grid.get_node("GoldSpentLabel").visible = false
	gold_grid.get_node("GoldSpentValue").visible = false

	# Gems
	stats_vbox.get_node("GemsLabel").text = "Gems earned: %d  |  Total gems: %d" % [gems, GameState.gems]

	# Unlocks
	if newly_unlocked.size() > 0:
		var unlock_lbl = Label.new()
		unlock_lbl.text = "\n[ New Unlocks! ]"
		unlock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		unlock_lbl.modulate = Color.GOLD
		stats_vbox.add_child(unlock_lbl)
		
		for id in newly_unlocked:
			var item_name = id
			for abi in ALL_ABILITIES:
				if abi.id == id:
					item_name = abi.name
					break
			
			var l = Label.new()
			l.text = "★ %s" % item_name
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			stats_vbox.add_child(l)

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

func show_item_window(_deprecated_item_id: String = "") -> void:
	# Only show items the player has unlocked
	var all_keys = GameState.unlocked_treasure_items.duplicate()
	all_keys.shuffle()
	current_chest_options = all_keys.slice(0, 3)
	
	if not item_popup_panel:
		_ensure_item_popup_exists()

	get_tree().paused = true
	item_popup_panel.visible = true
	item_popup_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var grid = item_popup_panel.get_node("Margin/VBox/ItemGrid")
	for child in grid.get_children():
		child.queue_free()
	
	for item_id in current_chest_options:
		if not GameConstants.ITEMS.has(item_id):
			continue
		var item_data = GameConstants.ITEMS[item_id]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(250, 180)
		btn.add_theme_font_size_override("font_size", 18)
		
		# Build description text
		var text = item_data.name + "\n\n"
		var stats = item_data.get("stats", {})
		for stat_key in stats.keys():
			var val = stats[stat_key]
			var sign_str = "+" if val > 0 else ""
			var percent = ""
			if stat_key.ends_with("_multiplier") or stat_key.ends_with("_percent") or stat_key.ends_with("_chance") or stat_key == "thorns_percentage" or stat_key == "gem_drop_chance_bonus":
				val *= 100.0
				percent = "%"
			
			var human_name = stat_key.replace("_", " ").capitalize()
			if stat_key == "atkspd_multiplier":
				human_name = "Attack Speed Multiplier"
				
			text += "%s%s%s %s\n" % [sign_str, str(val), percent, human_name]

		
		btn.text = text
		btn.pressed.connect(_on_item_chosen.bind(item_id))
		grid.add_child(btn)

func _on_item_chosen(item_id: String) -> void:
	if item_id != "skip":
		GameState.add_run_item(item_id)
	_close_item_window()

func _ensure_item_popup_exists() -> void:
	if has_node("UI/ItemPopupPanel"):
		item_popup_panel = get_node("UI/ItemPopupPanel")
		return
	
	# Build it programmatically if missing
	item_popup_panel = PanelContainer.new()
	item_popup_panel.name = "ItemPopupPanel"
	
	# Solid dark background with gold border
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.1, 0.15, 1.0) # Solid, no transparency
	sb.border_width_left = 5
	sb.border_width_top = 5
	sb.border_width_right = 5
	sb.border_width_bottom = 5
	sb.border_color = Color(0.8, 0.6, 0.1, 1.0) # Gold border
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	item_popup_panel.add_theme_stylebox_override("panel", sb)

	item_popup_panel.custom_minimum_size = Vector2(900, 450)
	
	# Centering logic
	item_popup_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	item_popup_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	item_popup_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var margin = MarginContainer.new()

	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	item_popup_panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 25)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "Choose Your Item"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.modulate = Color.GOLD
	vbox.add_child(title)
	
	var grid = HBoxContainer.new()
	grid.name = "ItemGrid"
	grid.alignment = BoxContainer.ALIGNMENT_CENTER
	grid.add_theme_constant_override("separation", 30)
	vbox.add_child(grid)
	
	var skip_box = CenterContainer.new()
	vbox.add_child(skip_box)
	
	var skip_btn = Button.new()
	skip_btn.text = "Skip"
	skip_btn.custom_minimum_size = Vector2(300, 40)
	skip_btn.pressed.connect(_on_item_chosen.bind("skip"))
	skip_box.add_child(skip_btn)
	
	$UI.add_child(item_popup_panel)
	item_popup_panel.visible = false



func _close_item_window() -> void:
	item_popup_panel.visible = false
	get_tree().paused = false

