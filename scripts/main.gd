extends Node2D

@onready var player: Node2D = $Player
@onready var wave_controller: Node = $WaveController
@onready var hud: CanvasLayer = $UI
@onready var shop_panel: Control = $UI/ShopPanel
@onready var game_over_panel: Control = $UI/GameOverPanel
@onready var pause_panel: Control = $UI/PausePanel
var item_popup_panel: Control



@onready var shop_grid: GridContainer = $UI/ShopPanel/Margin/VBox/Scroll/Grid
@onready var shop_gold_label: Label = $UI/ShopPanel/Margin/VBox/InfoRow/GoldLabel
@onready var shop_gems_label: Label = $UI/ShopPanel/Margin/VBox/InfoRow/GemsLabel
@onready var shop_continue: Button = $UI/ShopPanel/Margin/VBox/Continue
@onready var shop_capacity_label: Label = Label.new() # Will add to UI
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
@onready var lbl_gold: Label = $UI/HUD/HUDMargin/HUDVBox/GoldLabel
@onready var lbl_gems: Label = $UI/HUD/HUDMargin/HUDVBox/GemsLabel
@onready var lbl_hp: Label = $UI/HUD/HUDMargin/HUDVBox/HPLabel

func _ready() -> void:
	player.player_died.connect(_on_player_died)
	
	_ensure_item_popup_exists()


	# Shop is now dynamic, no need to wire hardcoded buttons
	
	shop_continue.pressed.connect(_close_shop)
	
	# Setup Reroll button
	reroll_btn = Button.new()
	reroll_btn.custom_minimum_size = Vector2(200, 50)
	$UI/ShopPanel/Margin/VBox.add_child(reroll_btn)
	$UI/ShopPanel/Margin/VBox.move_child(reroll_btn, $UI/ShopPanel/Margin/VBox/Continue.get_index())
	reroll_btn.pressed.connect(_reroll_shop)
	
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
	# Make shop full screen
	shop_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	game_over_panel.visible = false
	pause_panel.visible = false
	if item_popup_panel:
		item_popup_panel.visible = false
	
	# Setup Item Popup Close Button
	var item_ok_btn = item_popup_panel.get_node_or_null("Margin/VBox/CloseButton") as Button
	if item_ok_btn:
		item_ok_btn.pressed.connect(_close_item_window)



	# Position player at center of viewport dynamically first
	var screen_center := get_viewport().get_visible_rect().size / 2.0
	player.position = screen_center

	_setup_arena()

	wave_controller.start_run()

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
	lbl_gold.text = "Gold: %d" % GameState.run_gold
	lbl_gems.text = "Gems: %d" % GameState.gems
	if is_instance_valid(player) and "health" in player:
		lbl_hp.text = "HP: %d" % player.health

func on_wave_started(w: int) -> void:
	lbl_wave.text = "%s — Wave: %d / 10" % [GameState.run_level_name, w]
	
	# Reset player to center and clear movement
	var screen_center := get_viewport().get_visible_rect().size / 2.0
	player.reset_state(screen_center)

func on_wave_time(t: float) -> void:
	lbl_time.text = "Time: %.0fs" % t

func open_shop(w: int) -> void:
	get_tree().paused = true
	shop_panel.visible = true
	shop_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	
	$UI/ShopPanel/Margin/VBox/Title.text = "Armory — Wave %d Completed" % w
	
	GameState.run_reroll_cost = GameConstants.SHOP_REROLL_BASE_COST
	_generate_shop_options()
	_refresh_shop_ui()

func _close_shop() -> void:
	shop_panel.visible = false
	get_tree().paused = false
	wave_controller.resume_after_shop()
func _generate_shop_options() -> void:
	current_shop_options.clear()
	var pool = []
	
	for abi in ALL_ABILITIES:
		if not GameState.is_item_unlocked(abi.id): continue
		if GameState.run_banished_abilities.has(abi.id): continue
		
		var level = GameState.run_abilities.get(abi.id, 0)
		var max_level = _get_max_level(abi.id)
		
		# Skip if maxed
		if level >= max_level: continue
		
		pool.append(abi)
	
	pool.shuffle()
	for i in range(min(GameConstants.SHOP_OPTIONS_COUNT, pool.size())):
		current_shop_options.append(pool[i])

func _refresh_shop_ui() -> void:
	shop_gold_label.text = "Gold: %d" % GameState.run_gold
	shop_gems_label.text = "Gems: %d" % GameState.gems
	
	reroll_btn.text = "Reroll (%d Gold)" % GameState.run_reroll_cost
	reroll_btn.disabled = GameState.run_gold < GameState.run_reroll_cost
	
	var abi_count = GameState.run_abilities.size()
	shop_capacity_label.text = "Abilities: %d / %d" % [abi_count, GameConstants.SHOP_MAX_ABILITIES]
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
	shop_grid.add_child(Control.new())
	shop_grid.add_child(Control.new())
	
	# Show currently owned abilities
	for abi_id in GameState.run_abilities.keys():
		var abi_data = null
		for a in ALL_ABILITIES:
			if a.id == abi_id:
				abi_data = a
				break
		
		if not abi_data: continue
		
		var level = GameState.run_abilities[abi_id]
		var cost = _get_ability_cost(abi_id, level)
		var max_lvl = _get_max_level(abi_id)
		
		var panel = PanelContainer.new()
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 10)
		vbox.custom_minimum_size = Vector2(240, 0)
		panel.add_child(vbox)
		
		var lbl = Label.new()
		var level_text = "(Lv. %d)" % level
		if level >= max_lvl:
			level_text = "(MAX)"
		lbl.text = abi_data.name + "\n" + level_text
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 22)
		vbox.add_child(lbl)
		
		# Upgrade button (if in shop it's already there? No, shop options might not include this.)
		# Actually, if it's already owned, it should show its level clearly.
		# The shop options below will show UPGRADE for these.
		# Maybe we only show SELL buttons here for ALREADY OWNED things.
		
		var sell_btn = Button.new()
		var sell_val = int(cost * 0.5)
		sell_btn.text = "Sell for %d Gold" % sell_val
		sell_btn.pressed.connect(_sell_ability.bind(abi_id, sell_val))
		vbox.add_child(sell_btn)
		
		# Highlight owned abilities slightly
		panel.self_modulate = Color(0.8, 1.0, 0.8, 0.5)
		
		shop_grid.add_child(panel)

	# Separator / Header for Shop
	# Fill current row first after owned items
	var total_nodes_so_far = 3 + GameState.run_abilities.size() # 3 for header row
	var remainder = total_nodes_so_far % shop_grid.columns
	if remainder > 0:
		for i in range(shop_grid.columns - remainder):
			shop_grid.add_child(Control.new())
	
	var h_shop = Label.new()
	h_shop.text = "--- SHOP OPTIONS ---"
	h_shop.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h_shop.modulate = Color.GOLD
	shop_grid.add_child(h_shop)
	# Add padding to make header take a whole row
	shop_grid.add_child(Control.new())
	shop_grid.add_child(Control.new())

	# Now show shop options
	for abi in current_shop_options:
		var level = GameState.run_abilities.get(abi.id, 0)
		var cost = _get_ability_cost(abi.id, level)
		
		var panel = PanelContainer.new()
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 10)
		vbox.custom_minimum_size = Vector2(240, 0)
		panel.add_child(vbox)
		
		var lbl = Label.new()
		lbl.text = abi.name + " (Lv. %d)" % level
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
			var prefix = "Buy" if level == 0 else "Upgrade"
			buy_btn.text = "%s: %d Gold" % [prefix, cost]
			buy_btn.disabled = GameState.run_gold < cost
			buy_btn.pressed.connect(_buy_ability.bind(abi.id))
		vbox.add_child(buy_btn)
		
		if GameState.run_banish_count > 0:
			var ban_btn = Button.new()
			ban_btn.text = "Banish (%d left)" % GameState.run_banish_count
			ban_btn.pressed.connect(_banish_ability.bind(abi.id))
			vbox.add_child(ban_btn)
		
		shop_grid.add_child(panel)

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
	var cost = _get_ability_cost(id, level)
	
	if GameState.run_gold >= cost and level < _get_max_level(id):
		GameState.run_gold -= cost
		GameState.run_gold_spent += cost
		GameState.run_abilities[id] = level + 1
		GameState.record_ability_upgrade(id, level + 1)
		
		# Remove from current options until next reroll
		for i in range(current_shop_options.size()):
			if current_shop_options[i].id == id:
				current_shop_options.remove_at(i)
				break
		
		_refresh_shop_ui()

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

	# Gold stats
	var gold_grid = stats_vbox.get_node("GoldGrid")
	gold_grid.get_node("GoldCollectedValue").text = "%d" % GameState.run_gold_collected
	gold_grid.get_node("GoldSpentValue").text = "%d" % GameState.run_gold_spent

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
	# Ignore the passed item_id, we generate 3 new ones here
	var all_keys = GameConstants.ITEMS.keys()
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
	skip_btn.text = "Skip Treasure (No Item)"
	skip_btn.custom_minimum_size = Vector2(300, 40)
	skip_btn.pressed.connect(_on_item_chosen.bind("skip"))
	skip_box.add_child(skip_btn)
	
	$UI.add_child(item_popup_panel)
	item_popup_panel.visible = false



func _close_item_window() -> void:
	item_popup_panel.visible = false
	get_tree().paused = false

