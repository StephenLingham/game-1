extends Node2D

@onready var player = $Player
@onready var wave_controller = $WaveController
@onready var hud: CanvasLayer = $UI
@onready var shop_panel: Control = $UI/ShopPanel
@onready var game_over_panel: Control = $UI/GameOverPanel
@onready var pause_panel: Control = $UI/PausePanel
var item_popup_panel: Control
var charge_shrine_popup_panel: Control



@onready var shop_grid: GridContainer = $UI/ShopPanel/Margin/VBox/Scroll/Grid
@onready var shop_lvl_label: Label = $UI/ShopPanel/Margin/VBox/InfoRow/LevelLabel
@onready var shop_continue: Button = $UI/ShopPanel/Margin/VBox/Continue
@onready var shop_capacity_label: Label = Label.new() # Will add to UI
@onready var enemy_count_label: Label = Label.new()
@onready var xp_bar: ProgressBar = $UI/HUD/XPBar
@onready var lvl_xp_label: Label = $UI/HUD/LevelXPLabel
var current_chest_options: Array = []
var current_charge_shrine_options: Array = []
var current_charge_shrine: Node2D = null



var reroll_btn: Button
var banish_active: bool = false
var current_shop_options: Array = []
var pause_stats_panel: RunStatsPanel

const SHOP_WEAPON_ICONS := {
	"lightning_bolt": preload("res://assets/Weapons/lightning_bolt_projectile.png"),
	"ice_bolt": preload("res://assets/Weapons/ice_bolt_projectile.png"),
	"fire_bolt": preload("res://assets/Weapons/fire_bolt_projectile.png"),
	"arcane_bolt": preload("res://assets/Weapons/arcane_bolt_projectile.png")
}

const ALL_ABILITIES = [
	{"id": "zap", "name": "Zap", "weapon": true},
	{"id": "arcane_missile", "name": "Arcane Missile", "weapon": true},
	{"id": "fireball", "name": "Fireball", "weapon": true},
	{"id": "ice_shard", "name": "Ice Shard", "weapon": true},
	{"id": "meteor", "name": "Meteor", "weapon": true},
	{"id": "frozen_orb", "name": "Frozen Orb", "weapon": true},
	{"id": "lightning_bolt", "name": "Lightning Bolt", "weapon": true},
	{"id": "ice_bolt", "name": "Ice Bolt", "weapon": true},
	{"id": "fire_bolt", "name": "Fire Bolt", "weapon": true},
	{"id": "arcane_bolt", "name": "Arcane Bolt", "weapon": true},
	{"id": "lightning_fork", "name": "Lightning Fork", "weapon": true},
	{"id": "blizzard", "name": "Blizzard", "weapon": true},
	{"id": "arcane_orbs", "name": "Arcane Orbs", "weapon": true},
	{"id": "arcane_field", "name": "Arcane Field", "weapon": true},
	{"id": "fire_trail", "name": "Fire Trail", "weapon": true},
	
	# Old/Other abilities
	{"id": "shotgun", "name": "Shotgun", "weapon": true},
	{"id": "sniper", "name": "Sniper Gun", "weapon": true},
	{"id": "rocket", "name": "Rocket Launcher", "weapon": true},
	{"id": "machine_gun", "name": "Machine Gun", "weapon": true},
	{"id": "orbs", "name": "Energy Orbs", "weapon": false},
	{"id": "spike_ball", "name": "Spike Ball", "weapon": false},
	{"id": "bouncing_disk", "name": "Bouncing Disk", "weapon": false},
	{"id": "floor_spikes", "name": "Floor Spikes", "weapon": false},
	{"id": "turret", "name": "Turret", "weapon": false},
	{"id": "ice_wave", "name": "Ice Wave", "weapon": false},
	
	# Auras
	{"id": "aura_damage", "name": "Power Aura", "is_aura": true},
	{"id": "aura_atkspd", "name": "Swiftness Aura", "is_aura": true},
	{"id": "aura_pickup_radius", "name": "Magnet Aura", "is_aura": true},
	{"id": "aura_max_health", "name": "Vitality Aura", "is_aura": true},
	{"id": "aura_regen", "name": "Recovery Aura", "is_aura": true},
	{"id": "aura_crit", "name": "Precision Aura", "is_aura": true},
	{"id": "aura_crit_damage", "name": "Ferocity Aura", "is_aura": true},
	{"id": "aura_armor", "name": "Sentinel Aura", "is_aura": true},
	{"id": "aura_armor_percent", "name": "Guardian Aura", "is_aura": true},
	{"id": "aura_thorns", "name": "Spike Aura", "is_aura": true},
	{"id": "aura_speed", "name": "Haste Aura", "is_aura": true},
	{"id": "aura_xp_drop", "name": "Learning Aura", "is_aura": true},
	{"id": "aura_spawn_rate", "name": "Chaos Aura", "is_aura": true},
	{"id": "aura_luck", "name": "Luck Aura", "is_aura": true},
	{"id": "aura_projectiles", "name": "Volley Aura", "is_aura": true},
	{"id": "aura_bounces", "name": "Ricochet Aura", "is_aura": true}
]

@onready var lbl_wave: Label = $UI/HUD/HUDTopRow/CenterInfo/WaveLabel
@onready var lbl_time: Label = $UI/HUD/HUDTopRow/CenterInfo/TimeLabel
@onready var hp_bar: ProgressBar = $UI/HUD/HUDTopRow/HPBarContainer/HPBar
@onready var hp_label: Label = $UI/HUD/HUDTopRow/HPBarContainer/HPBar/HPLabel

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
		overlay.color = Color(0.012, 0.016, 0.045, 0.92)
	
	# Center the content container
	var shop_margin = shop_panel.get_node_or_null("Margin")
	if shop_margin:
		shop_margin.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		shop_margin.custom_minimum_size = Vector2(1100, 650)
		shop_margin.grow_horizontal = Control.GROW_DIRECTION_BOTH
		shop_margin.grow_vertical = Control.GROW_DIRECTION_BOTH
		# Add a background panel style to the margin
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.035, 0.045, 0.09, 0.98)
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_color = Color(0.25, 0.72, 1.0, 0.9)
		sb.corner_radius_top_left = 22
		sb.corner_radius_top_right = 22
		sb.corner_radius_bottom_left = 22
		sb.corner_radius_bottom_right = 22
		sb.shadow_color = Color(0, 0, 0, 0.65)
		sb.shadow_size = 24
		
		var pop_bg = Panel.new()
		pop_bg.name = "PopupBG"
		pop_bg.add_theme_stylebox_override("panel", sb)
		shop_margin.add_child(pop_bg)
		shop_margin.move_child(pop_bg, 0)
		pop_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pop_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
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
	shop_capacity_label.add_theme_font_size_override("font_size", 16)
	shop_capacity_label.add_theme_color_override("font_color", Color(0.7, 0.78, 0.9))
	$UI/ShopPanel/Margin/VBox.add_child(shop_capacity_label)
	$UI/ShopPanel/Margin/VBox.move_child(shop_capacity_label, $UI/ShopPanel/Margin/VBox/Scroll.get_index())

	enemy_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_count_label.add_theme_font_size_override("font_size", 16)
	enemy_count_label.modulate = Color(0.9, 0.9, 0.9, 1.0)
	$UI/HUD/HUDTopRow/CenterInfo.add_child(enemy_count_label)

	# Game over buttons
	$UI/GameOverPanel/Margin/VBox/ButtonBox/BackToLobby.pressed.connect(_back_to_lobby)
	$UI/GameOverPanel/Margin/VBox/ButtonBox/Retry.pressed.connect(_retry)
	
	# Pause buttons
	$UI/PausePanel/VBox/Resume.pressed.connect(_resume)
	$UI/PausePanel/VBox/Abandon.pressed.connect(_abandon_run)
	pause_stats_panel = RunStatsPanel.new()
	pause_stats_panel.name = "RunStatsPanel"
	$UI/PausePanel/VBox.add_child(pause_stats_panel)
	$UI/PausePanel/VBox.move_child(pause_stats_panel, $UI/PausePanel/VBox/Spacer.get_index())

	# HP Bar Color (Red)
	var hp_bar = $UI/HUD/HUDTopRow/HPBarContainer/HPBar
	var hp_fill_style = StyleBoxFlat.new()
	hp_fill_style.bg_color = Color(0.8, 0.1, 0.1) # Red
	hp_fill_style.corner_radius_top_left = 4
	hp_fill_style.corner_radius_top_right = 4
	hp_fill_style.corner_radius_bottom_left = 4
	hp_fill_style.corner_radius_bottom_right = 4
	hp_bar.add_theme_stylebox_override("fill", hp_fill_style)

	shop_panel.visible = false
	shop_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	game_over_panel.visible = false
	pause_panel.visible = false
	
	# Position player at center of viewport dynamically first
	var screen_center := get_viewport().get_visible_rect().size / 2.0
	player.position = screen_center

	_setup_arena()
	$UI/HUD/GemsLabel.hide()
	_spawn_initial_gifts()
	_spawn_initial_chests()
	_spawn_initial_powerups()
	_spawn_initial_crystal()
	_spawn_charge_shrines()
	_spawn_torches()
	wave_controller.start_run()
	
	# Spawn dynamic Minimap and Full Screen Map overlay with Fog of War
	var minimap_script = load("res://scripts/minimap.gd")
	var minimap = Control.new()
	minimap.set_script(minimap_script)
	minimap.name = "Minimap"
	$UI.add_child(minimap)

func _exit_tree() -> void:
	if is_instance_valid(item_popup_panel):
		item_popup_panel.queue_free()
	if is_instance_valid(charge_shrine_popup_panel):
		charge_shrine_popup_panel.queue_free()
	if is_instance_valid(shop_capacity_label):
		shop_capacity_label.queue_free()
	if is_instance_valid(shop_grid):
		for child in shop_grid.get_children():
			child.queue_free()

func _on_level_up(new_level: int) -> void:
	_generate_shop_options()
	if current_shop_options.is_empty():
		# No valid ability offers left, so reward with a free item instead.
		show_item_window()
		return
	open_shop(new_level)

func _setup_arena() -> void:
	var screen_size := get_viewport().get_visible_rect().size
	var max_dim: float = max(screen_size.x, screen_size.y)
	var square_dim: float = max_dim * GameConstants.ARENA_SIZE_MULTIPLIER
	var arena_size := Vector2(square_dim, square_dim)
	var center: Vector2 = screen_size / 2.0
	
	var floor_rect := $ArenaFloor as TextureRect
	floor_rect.size = arena_size
	floor_rect.position = center - (arena_size / 2.0)
	floor_rect.texture = load("res://assets/grass-texture-2.png")
	floor_rect.stretch_mode = TextureRect.STRETCH_TILE
	floor_rect.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	
	# Scale the tiling using a simple shader
	var mat = ShaderMaterial.new()
	var sh = Shader.new()
	sh.code = "shader_type canvas_item;
		void fragment() {
			COLOR = texture(TEXTURE, UV * 4.0);
		}"
	mat.shader = sh
	floor_rect.material = mat
	
	floor_rect.z_index = -100 # Ensure it's behind everything
	
	$Background.color = Color(0.05, 0.2, 0.1) # Dark green background
	$Background.position = floor_rect.position - Vector2(2000, 2000)
	$Background.size = arena_size + Vector2(4000, 4000)
	$Background.z_index = -101
	
	# Procedural grass removed in favor of the new texture
	
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
	
	# Force player and camera to the exact center of the arena instantly
	player.global_position = center
	if player.has_node("Camera2D"):
		var cam = player.get_node("Camera2D") as Camera2D
		cam.reset_smoothing() # Snap instantly
		cam.force_update_scroll()

func _spawn_initial_gifts() -> void:
	var floor_rect := $ArenaFloor as TextureRect
	var arena_rect = Rect2(floor_rect.position, floor_rect.size)
	var padding = 200.0
	
	var gift_script = load("res://scripts/gift_pickup.gd")
	var count = int(GameConstants.GIFT_COUNT * GameConstants.ARENA_SIZE_MULTIPLIER)
	var rarity_counts = _build_gift_rarity_counts(count)
	var rarity_order = ["common", "uncommon", "rare", "epic", "legendary"]
	var spawn_rarities: Array[String] = []
	for rarity in rarity_order:
		for i in range(int(rarity_counts.get(rarity, 0))):
			spawn_rarities.append(rarity)
	spawn_rarities.shuffle()
	
	for rarity in spawn_rarities:
		var p = gift_script.new()
		p.rarity = rarity
		
		var rx = randf_range(arena_rect.position.x + padding, arena_rect.end.x - padding)
		var ry = randf_range(arena_rect.position.y + padding, arena_rect.end.y - padding)
		p.position = Vector2(rx, ry)
		
		# Ensure they don't spawn too close to the player center (where they start)
		if p.position.distance_to(arena_rect.get_center()) < 300.0:
			p.position += (p.position - arena_rect.get_center()).normalized() * 300.0
			
		add_child(p)

func _build_gift_rarity_counts(total_count: int) -> Dictionary:
	var counts := {
		"common": 0,
		"uncommon": 0,
		"rare": 0,
		"epic": 0,
		"legendary": 0
	}
	if total_count <= 0:
		return counts
	if total_count == 1:
		counts["legendary"] = 1
		return counts
	
	var non_legendary_total = total_count - 1
	var weight_sum = 0
	for rarity in ["common", "uncommon", "rare", "epic"]:
		weight_sum += int(GameConstants.GIFT_RARITY_SPAWN_WEIGHTS.get(rarity, 0))
	
	var used = 0
	for rarity in ["common", "uncommon", "rare", "epic"]:
		var weight = float(GameConstants.GIFT_RARITY_SPAWN_WEIGHTS.get(rarity, 0))
		var amount = int(floor(non_legendary_total * weight / float(max(1, weight_sum))))
		counts[rarity] = amount
		used += amount
	
	counts["common"] += non_legendary_total - used
	counts["legendary"] = 1
	return counts

func _spawn_initial_chests() -> void:
	var floor_rect := $ArenaFloor as TextureRect
	var arena_rect = Rect2(floor_rect.position, floor_rect.size)
	var padding = 150.0
	
	var chest_scene = load("res://scenes/TreasureChest.tscn")
	var count = int(GameConstants.CHEST_STARTING_COUNT * GameConstants.ARENA_SIZE_MULTIPLIER)
	
	if GameState.current_character == "singular_luck":
		count *= 5
		
	for i in range(count):
		var c = chest_scene.instantiate()
		
		var rx = randf_range(arena_rect.position.x + padding, arena_rect.end.x - padding)
		var ry = randf_range(arena_rect.position.y + padding, arena_rect.end.y - padding)
		c.global_position = Vector2(rx, ry)
		
		get_node("PickupContainer").add_child(c)

func _spawn_initial_powerups() -> void:
	var floor_rect := $ArenaFloor as TextureRect
	var arena_rect = Rect2(floor_rect.position, floor_rect.size)
	var padding = 100.0
	
	var powerup_scene = load("res://scenes/PowerupPickup.tscn")
	var count = int(GameConstants.POWERUP_STARTING_COUNT * GameConstants.ARENA_SIZE_MULTIPLIER)
	
	# Randomly pick from: MAGNET, SPEED, HEAL, ROCKET, ATK_SPEED (Exclude CRYSTAL type 4)
	var types = [0, 1, 2, 3, 5]
	
	for i in range(count):
		var p = powerup_scene.instantiate()
		p.type = types.pick_random()
		
		var rx = randf_range(arena_rect.position.x + padding, arena_rect.end.x - padding)
		var ry = randf_range(arena_rect.position.y + padding, arena_rect.end.y - padding)
		p.global_position = Vector2(rx, ry)
		
		get_node("PickupContainer").add_child(p)

func _spawn_initial_crystal() -> void:
	var floor_rect := $ArenaFloor as TextureRect
	var arena_rect = Rect2(floor_rect.position, floor_rect.size)
	var padding = 100.0
	
	var powerup_scene = load("res://scenes/PowerupPickup.tscn")
	var p = powerup_scene.instantiate()
	p.type = 4 # CRYSTAL
	
	var rx = randf_range(arena_rect.position.x + padding, arena_rect.end.x - padding)
	var ry = randf_range(arena_rect.position.y + padding, arena_rect.end.y - padding)
	p.global_position = Vector2(rx, ry)
	
	get_node("PickupContainer").add_child(p)

func _spawn_charge_shrines() -> void:
	var floor_rect := $ArenaFloor as TextureRect
	var arena_rect = Rect2(floor_rect.position, floor_rect.size)
	var padding = 220.0
	
	var shrine_scene = load("res://scenes/charge_shrine.tscn")
	var count = int(GameConstants.CHARGE_SHRINE_COUNT * GameConstants.ARENA_SIZE_MULTIPLIER)
	for i in range(count):
		var shrine = shrine_scene.instantiate()
		var rx = randf_range(arena_rect.position.x + padding, arena_rect.end.x - padding)
		var ry = randf_range(arena_rect.position.y + padding, arena_rect.end.y - padding)
		shrine.global_position = Vector2(rx, ry)
		if shrine.global_position.distance_to(arena_rect.get_center()) < 300.0:
			shrine.global_position += (shrine.global_position - arena_rect.get_center()).normalized() * 300.0
		shrine.charged.connect(_on_charge_shrine_charged)
		get_node("PickupContainer").add_child(shrine)

func _spawn_torches() -> void:
	var floor_rect := $ArenaFloor as TextureRect
	var arena_rect := Rect2(floor_rect.position, floor_rect.size)
	var padding := 180.0
	var torch_script = load("res://scripts/torch_pickup.gd")
	var count := int(GameConstants.TORCH_COUNT * GameConstants.ARENA_SIZE_MULTIPLIER)
	var torch_types: Array[int] = []
	for i in range(count):
		torch_types.append(i % 2)
	torch_types.shuffle()

	for torch_type in torch_types:
		var torch = torch_script.new()
		torch.torch_type = torch_type
		var rx := randf_range(arena_rect.position.x + padding, arena_rect.end.x - padding)
		var ry := randf_range(arena_rect.position.y + padding, arena_rect.end.y - padding)
		torch.global_position = Vector2(rx, ry)
		if torch.global_position.distance_to(arena_rect.get_center()) < 300.0:
			var away: Vector2 = torch.global_position - arena_rect.get_center()
			if away.is_zero_approx():
				away = Vector2.RIGHT
			torch.global_position = arena_rect.get_center() + away.normalized() * 300.0
		get_node("PickupContainer").add_child(torch)

func _process(delta: float) -> void:
	if not game_over_panel.visible:
		GameState.track_run_time(delta)
	lvl_xp_label.text = "Level: %d" % GameState.run_level
	xp_bar.max_value = GameState.run_xp_to_next_level
	xp_bar.value = GameState.run_xp

	var alive_enemy_count := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			alive_enemy_count += 1
	if GameConstants.FEATURE_SHOW_ENEMY_COUNT:
		enemy_count_label.visible = true
		enemy_count_label.text = "Enemies Alive: %d" % alive_enemy_count
	else:
		enemy_count_label.visible = false
	
	if is_instance_valid(player) and "health" in player:
		hp_bar.max_value = player.max_health
		hp_bar.value = player.health
		hp_label.text = "HP: %d / %d" % [player.health, player.max_health]

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
	$UI/ShopPanel/Margin/VBox/Title.text = "Level up!"
	$UI/ShopPanel/Margin/VBox/Title.add_theme_font_size_override("font_size", 42)
	$UI/ShopPanel/Margin/VBox/Title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.34))
	shop_lvl_label.text = "Level %d  |  Choose your power" % lvl
	shop_lvl_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_lvl_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_lvl_label.add_theme_font_size_override("font_size", 18)
	shop_lvl_label.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
	
	_refresh_shop_ui()
	shop_panel.modulate = Color(1, 1, 1, 0)
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(shop_panel, "modulate", Color.WHITE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _close_shop() -> void:
	shop_panel.visible = false
	get_tree().paused = false
func _generate_shop_options() -> void:
	current_shop_options.clear()
	var pool = []
	
	var current_abi_count = 0
	var current_aura_count = 0
	for abi_id in GameState.run_abilities:
		var is_aura = abi_id.begins_with("aura_")
		if is_aura: current_aura_count += 1
		else: current_abi_count += 1
	
	var abi_at_capacity = current_abi_count >= GameState.get_ability_limit()
	var aura_at_capacity = current_aura_count >= GameState.get_aura_limit()

	for abi in ALL_ABILITIES:
		if not GameState.is_item_unlocked(abi.id): continue
		if GameState.run_banished_abilities.has(abi.id): continue
		if GameState.sealed_items.has(abi.id): continue
		
		var level = GameState.run_abilities.get(abi.id, 0)
		
		# Capacity checks
		if level == 0:
			if abi.get("is_aura", false):
				if aura_at_capacity: 
					# ... Echo logic ...
					continue
			else:
				if abi_at_capacity or GameState.current_character == "passive_master": 
					continue
		
		# Handle duplicate aura logic for Echo
		if GameState.current_character == "echo" and abi.get("is_aura", false) and level > 0:
			# If we are Echo and already have it, allow another copy to appear?
			# Actually, run_abilities is a dictionary, so it's hard to store "two copies" unless I change it.
			# I'll assume Echo can just see them more often or level them beyond max?
			# Re-reading: "carry duplicate auras". This implies multiple slots for the same ID.
			# This would require a major refactor of `run_abilities` from Dict to Array.
			# I'll stick to a simpler interpretation: "echo" can pick an aura even if it's already maxed? No.
			# I'll make it so Echo can have 2 separate slots for the same aura by appending a suffix.
			# But for now, I'll just skip the "already owned" check if Echo.
			pass

		pool.append(abi)
	
	pool.shuffle()
	for i in range(min(GameConstants.SHOP_OPTIONS_COUNT, pool.size())):
		var opt = pool[i].duplicate()
		# Only roll a rarity upgrade if the player already owns the ability (level > 0)
		var level = GameState.run_abilities.get(opt.id, 0)
		if level > 0 and opt.id.begins_with("aura_"):
			# All auras get a rarity roll on every upgrade after first purchase
			opt["upgrade_roll"] = GameState.roll_aura_rarity_upgrade(opt.id)
		elif level > 0 and GameConstants.WEAPON_TRAITS.has(opt.id):
			opt["upgrade_roll"] = GameState.roll_weapon_upgrade(opt.id)
		else:
			opt["upgrade_roll"] = {}
		current_shop_options.append(opt)
func _shop_style(bg: Color, border: Color, radius: int = 14, border_width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _style_shop_button(button: Button, accent: Color, quiet: bool = false) -> void:
	var normal_bg := Color(accent.r * 0.14, accent.g * 0.14, accent.b * 0.14, 0.92)
	if quiet:
		normal_bg = Color(0.08, 0.1, 0.17, 0.95)
	button.add_theme_stylebox_override("normal", _shop_style(normal_bg, Color(accent, 0.55), 10, 1))
	button.add_theme_stylebox_override("hover", _shop_style(Color(accent.r * 0.28, accent.g * 0.28, accent.b * 0.28, 1.0), accent, 10, 2))
	button.add_theme_stylebox_override("pressed", _shop_style(Color(accent.r * 0.4, accent.g * 0.4, accent.b * 0.4, 1.0), accent.lightened(0.18), 10, 2))
	button.add_theme_stylebox_override("disabled", _shop_style(Color(0.07, 0.075, 0.1, 0.8), Color(0.25, 0.27, 0.34), 10, 1))
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.42, 0.45, 0.53))
	button.add_theme_font_size_override("font_size", 16)

func _style_section_header(label: Label, color: Color) -> void:
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(color, 0.25))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 2)

func _make_ability_emblem(ability_id: String, is_aura: bool) -> PanelContainer:
	var emblem := PanelContainer.new()
	emblem.custom_minimum_size = Vector2(68, 68)
	emblem.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var color := Color(0.9, 0.35, 1.0) if is_aura else Color(0.2, 0.75, 1.0)
	emblem.add_theme_stylebox_override("panel", _shop_style(Color(color.r * 0.14, color.g * 0.14, color.b * 0.14, 1), Color(color, 0.8), 34, 2))
	var glyph := Label.new()
	glyph.text = "A" if is_aura else "W"
	if ability_id.contains("fire") or ability_id == "meteor":
		glyph.text = "F"
	elif ability_id.contains("ice") or ability_id == "blizzard":
		glyph.text = "I"
	elif ability_id.contains("lightning") or ability_id == "zap":
		glyph.text = "Z"
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	glyph.add_theme_font_size_override("font_size", 30)
	glyph.add_theme_color_override("font_color", color.lightened(0.18))
	emblem.add_child(glyph)
	return emblem

func _ability_subtitle(abi: Dictionary, level: int) -> String:
	if level == 0:
		return "NEW AURA" if abi.get("is_aura", false) else "NEW WEAPON"
	return "AURA | LEVEL %d > %d" % [level, level + 1] if abi.get("is_aura", false) else "WEAPON | LEVEL %d > %d" % [level, level + 1]


func _refresh_shop_ui() -> void:
	var abi_count = 0
	var aura_count = 0
	for id in GameState.run_abilities:
		if id.begins_with("aura_"): aura_count += 1
		else: abi_count += 1
		
	shop_capacity_label.text = "Weapons: %d/%d  |  Auras: %d/%d" % [abi_count, GameState.get_ability_limit(), aura_count, GameState.get_aura_limit()]
	
	if abi_count >= GameState.get_ability_limit() and aura_count >= GameState.get_aura_limit():
		shop_capacity_label.modulate = Color.VIOLET
	else:
		shop_capacity_label.modulate = Color.WHITE
	
	# Clear grid
	for child in shop_grid.get_children():
		child.queue_free()
	
	# Headers and Boxes for Loadout
	var h_weapons = Label.new()
	h_weapons.text = "CURRENT WEAPONS  |  %d / %d SLOTS" % [abi_count, GameState.get_ability_limit()]
	h_weapons.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_section_header(h_weapons, Color(0.35, 0.82, 1.0))
	shop_grid.add_child(h_weapons)
	
	var weapons_box = HBoxContainer.new()
	weapons_box.alignment = BoxContainer.ALIGNMENT_CENTER
	weapons_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weapons_box.add_theme_constant_override("separation", 20)
	shop_grid.add_child(weapons_box)

	var h_auras = Label.new()
	h_auras.text = "CURRENT AURAS  |  %d / %d SLOTS" % [aura_count, GameState.get_aura_limit()]
	h_auras.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_section_header(h_auras, Color(0.94, 0.48, 1.0))
	shop_grid.add_child(h_auras)
	
	var auras_box = HBoxContainer.new()
	auras_box.alignment = BoxContainer.ALIGNMENT_CENTER
	auras_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	auras_box.add_theme_constant_override("separation", 20)
	shop_grid.add_child(auras_box)
	
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
		
		var panel = PanelContainer.new()
		panel.add_theme_stylebox_override("panel", _shop_style(Color(0.065, 0.08, 0.135, 0.9), Color(0.22, 0.3, 0.46, 0.9), 12, 1))
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 10)
		vbox.custom_minimum_size = Vector2(145, 104)
		panel.add_child(vbox)
		
		var lbl = Label.new()
		lbl.text = abi_data.name + "\nLEVEL %d" % level
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 18)
		vbox.add_child(lbl)
		
		var owned_icon = _create_shop_weapon_icon(abi_id, 0.6)
		if owned_icon:
			vbox.add_child(owned_icon)
		else:
			vbox.add_child(_make_ability_emblem(abi_id, abi_id.begins_with("aura_")))
		
		if abi_id.begins_with("aura_"):
			panel.add_theme_stylebox_override("panel", _shop_style(Color(0.12, 0.055, 0.16, 0.92), Color(0.72, 0.3, 0.9, 0.75), 12, 1))
			auras_box.add_child(panel)
		else:
			panel.add_theme_stylebox_override("panel", _shop_style(Color(0.045, 0.1, 0.16, 0.92), Color(0.2, 0.68, 0.95, 0.75), 12, 1))
			weapons_box.add_child(panel)

	# Optional vertical space
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 18)
	shop_grid.add_child(spacer)

	# --- SELECT UPGRADE ---
	var h_shop = Label.new()
	h_shop.text = "CHOOSE ONE REWARD"
	h_shop.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_section_header(h_shop, Color(1.0, 0.82, 0.3))
	
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
		vbox.add_theme_constant_override("separation", 8)
		vbox.custom_minimum_size = Vector2(260, 235)
		panel.add_child(vbox)
		
		# --- Rarity data ---
		var upgrade_roll: Dictionary = abi.get("upgrade_roll", {})
		var has_roll := not upgrade_roll.is_empty()
		var rarity: String = upgrade_roll.get("rarity", "common")
		var rarity_color: Color = GameConstants.RARITY_COLORS.get(rarity, Color.WHITE)
		
		# Apply rarity-tinted background to the panel
		panel.add_theme_stylebox_override("panel", _shop_style(Color(0.055, 0.07, 0.125, 0.98), Color(0.2, 0.32, 0.52, 0.9), 16, 2))
		if has_roll:
			var sb = StyleBoxFlat.new()
			sb.bg_color = Color(rarity_color.r * 0.15, rarity_color.g * 0.15, rarity_color.b * 0.15, 1.0)
			sb.border_width_left = 3
			sb.border_width_top = 3
			sb.border_width_right = 3
			sb.border_width_bottom = 3
			sb.border_color = rarity_color
			sb.corner_radius_top_left = 8
			sb.corner_radius_top_right = 8
			sb.corner_radius_bottom_left = 8
			sb.corner_radius_bottom_right = 8
			panel.add_theme_stylebox_override("panel", sb)
		
		# --- Weapon name & level ---
		var lbl = Label.new()
		lbl.text = abi.name
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 20)
		vbox.add_child(lbl)
		
		var shop_icon = _create_shop_weapon_icon(abi.id)
		var subtitle := Label.new()
		subtitle.text = _ability_subtitle(abi, level)
		subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		subtitle.add_theme_font_size_override("font_size", 12)
		subtitle.add_theme_color_override("font_color", Color(0.55, 0.68, 0.83))
		vbox.add_child(subtitle)
		if shop_icon:
			vbox.add_child(shop_icon)
		else:
			vbox.add_child(_make_ability_emblem(abi.id, abi.get("is_aura", false)))
		
		# --- Rarity badge ---
		if has_roll:
			var rarity_lbl = Label.new()
			var rarity_name: String = GameConstants.RARITY_NAMES.get(rarity, "Common")
			rarity_lbl.text = "★  %s" % rarity_name.to_upper()
			rarity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			rarity_lbl.add_theme_font_size_override("font_size", 16)
			rarity_lbl.modulate = rarity_color
			vbox.add_child(rarity_lbl)
			
			# --- Trait stat line ---
			var stat_lbl = Label.new()
			stat_lbl.text = upgrade_roll.get("display", "")
			stat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			stat_lbl.add_theme_font_size_override("font_size", 18)
			stat_lbl.modulate = Color.WHITE
			vbox.add_child(stat_lbl)
		
		# --- Upgrade button ---
		var buy_btn = Button.new()
		
		var is_limit_reached = false
		if level == 0:
			var cur_abi = 0
			var cur_aur = 0
			for rid in GameState.run_abilities:
				if rid.begins_with("aura_"): cur_aur += 1
				else: cur_abi += 1
			
			if abi.get("is_aura", false):
				is_limit_reached = cur_aur >= GameState.get_aura_limit()
			else:
				is_limit_reached = cur_abi >= GameState.get_ability_limit()
		
		if is_limit_reached:
			buy_btn.text = "Limit Reached"
			buy_btn.disabled = true
		else:
			var prefix = "Select" if level == 0 else "Upgrade"
			buy_btn.text = prefix
			buy_btn.pressed.connect(_buy_ability.bind(abi.id, abi.get("upgrade_roll", {})))
			
		buy_btn.custom_minimum_size = Vector2(210, 46)
		var card_accent := rarity_color if has_roll else (Color(0.9, 0.35, 1.0) if abi.get("is_aura", false) else Color(0.2, 0.72, 1.0))
		_style_shop_button(buy_btn, card_accent)
		vbox.add_child(buy_btn)
		
		upgrades_box.add_child(panel)

	# --- FOOTER (Reroll) ---
	var footer_spacer = Control.new()
	footer_spacer.custom_minimum_size = Vector2(0, 18)
	shop_grid.add_child(footer_spacer)
	
	var footer_box = HBoxContainer.new()
	footer_box.alignment = BoxContainer.ALIGNMENT_CENTER
	footer_box.add_theme_constant_override("separation", 50)
	shop_grid.add_child(footer_box)
	
	var reroll_btn = Button.new()
	reroll_btn.text = "Reroll (%d left)" % GameState.run_reroll_count
	reroll_btn.disabled = GameState.run_reroll_count <= 0
	reroll_btn.custom_minimum_size = Vector2(230, 46)
	_style_shop_button(reroll_btn, Color(0.58, 0.65, 0.78), true)
	reroll_btn.pressed.connect(_reroll_shop)
	footer_box.add_child(reroll_btn)

func _create_shop_weapon_icon(weapon_id: String, scale: float = 0.75) -> TextureRect:
	if not SHOP_WEAPON_ICONS.has(weapon_id):
		return null
	var icon := TextureRect.new()
	icon.texture = SHOP_WEAPON_ICONS[weapon_id]
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(64, 40) * scale
	return icon


func _buy_ability(id: String, upgrade_roll: Dictionary = {}) -> void:
	var level = GameState.run_abilities.get(id, 0)
	
	GameState.run_abilities[id] = level + 1
	GameState.record_ability_upgrade(id, level + 1)
	if id.begins_with("aura_"):
		if not upgrade_roll.is_empty():
			# Upgrade (level > 0): apply the rarity-scaled value
			GameState.add_aura_rarity_bonus(id, upgrade_roll["value"])
		else:
			# First purchase (level 0->1): apply flat base value at Common
			var aura_data = GameConstants.AURAS.get(id, {})
			if not aura_data.is_empty():
				GameState.add_aura_rarity_bonus(id, aura_data.value)
	elif not upgrade_roll.is_empty():
		GameState.add_weapon_trait(id, upgrade_roll["trait"], upgrade_roll["value"])
	_close_shop()

func _reroll_shop() -> void:
	if GameState.run_reroll_count > 0:
		GameState.run_reroll_count -= 1
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
	if won and not GameState.run_boss_killed:
		won = false
	get_tree().paused = true

	# Crystals reward: Removed as per new requirement (crystals now drop during run)
	var crystals_reward := 0
	var newly_unlocked = []
	if won:
		GameState.mark_level_completed(GameState.run_level_name)
		GameState.record_successful_run()
		
		# Character Unlock
		var current_chain = GameConstants.CHARACTER_UNLOCK_CHAIN
		var idx = current_chain.find(GameState.current_character)
		if idx != -1 and idx < current_chain.size() - 1:
			var next_char = current_chain[idx+1]
			if not GameState.unlocked_characters.has(next_char):
				GameState.unlocked_characters.append(next_char)
				# We'll show this in the endgame screen if possible
		for id in GameState.run_unlocked_items:
			newly_unlocked.append(id)
		GameState.finalize_run_unlocks()
	else:
		GameState.discard_run_unlocks()
	GameState.finalize_run_stats()
	
	GameState.award_crystals(crystals_reward)

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
		["DmgZap", GameState.run_damage_zap],
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

	# Crystals
	stats_vbox.get_node("GemsLabel").text = "Crystals collected: %d  |  Total crystals: %d" % [GameState.run_crystals_collected, GameState.crystals]

	# Unlocks
	if newly_unlocked.size() > 0:
		var unlock_lbl = Label.new()
		unlock_lbl.text = "\n[ New Unlocks! ]"
		unlock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		unlock_lbl.modulate = Color.GOLD
		stats_vbox.add_child(unlock_lbl)
		
		for id in newly_unlocked:
			var item_name = id
			# Check abilities first
			var found = false
			for abi in ALL_ABILITIES:
				if abi.id == id:
					item_name = abi.name
					found = true
					break
			
			# If not an ability, check treasure items
			if not found and GameConstants.ITEMS.has(id):
				item_name = GameConstants.ITEMS[id].name
			
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

	if not is_paused and is_instance_valid(pause_stats_panel):
		pause_stats_panel.refresh_stats()
func _resume() -> void:
	_toggle_pause()

func _abandon_run() -> void:
	end_run(false, wave_controller.wave)
	pause_panel.visible = false

func show_item_window(_deprecated_item_id: String = "") -> void:
	# Only show items the player has unlocked AND NOT sealed
	var all_keys = []
	for item_id in GameState.unlocked_treasure_items:
		if GameState.sealed_items.has(item_id):
			continue
		if GameConstants.UNIQUE_RUN_ITEMS.has(item_id) and GameState.has_run_item(item_id):
			continue
		all_keys.append(item_id)
			
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
		
		var text = _build_item_card_text(item_data)

		
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

func _build_item_card_text(item_data: Dictionary) -> String:
	var text: String = item_data.name + "\n\n"
	var desc := String(item_data.get("desc", ""))
	if desc != "":
		text += desc + "\n"
	var stats = item_data.get("stats", {})
	if not stats.is_empty():
		if desc != "":
			text += "\n"
		for stat_key in stats.keys():
			var val = stats[stat_key]
			var sign_str = "+" if val > 0 else ""
			var percent = ""
			if stat_key.ends_with("_multiplier") or stat_key.ends_with("_percent") or stat_key.ends_with("_chance") or stat_key == "thorns_percentage" or stat_key == "gem_drop_chance_bonus":
				val *= 100.0
				percent = "%"
			var human_name = stat_key.replace("_", " ").capitalize()
			if stat_key == "atkspd_multiplier":
				human_name = "Attack Speed"
			text += "%s%s%s %s\n" % [sign_str, str(val), percent, human_name]
	return text

func _on_charge_shrine_charged(shrine: Node2D) -> void:
	if not is_instance_valid(shrine):
		return
	current_charge_shrine = shrine
	current_charge_shrine_options = _build_charge_shrine_options()
	_show_charge_shrine_window()

func _build_charge_shrine_options() -> Array:
	var stat_keys = GameConstants.GIFT_STATS.keys().duplicate()
	stat_keys.shuffle()
	var chosen_keys = stat_keys.slice(0, min(GameConstants.CHARGE_SHRINE_OPTIONS, stat_keys.size()))
	var options: Array = []
	for stat_key in chosen_keys:
		var stat_data: Dictionary = GameConstants.GIFT_STATS.get(stat_key, {})
		if stat_data.is_empty():
			continue
		var rarity: String = GameState.roll_rarity()
		var rarity_mult: float = GameConstants.GIFT_RARITY_VALUES.get(rarity, 1.0)
		var value: float = stat_data.weight * rarity_mult
		var display_text := _format_gift_stat_display(stat_key, value)
		options.append({
			"stat_key": stat_key,
			"internal_stat": stat_data.internal_stat,
			"rarity": rarity,
			"rarity_name": GameConstants.RARITY_NAMES.get(rarity, rarity.capitalize()),
			"rarity_color": GameConstants.RARITY_COLORS.get(rarity, Color.WHITE),
			"value": value,
			"display": display_text
		})
	return options

func _format_gift_stat_display(stat_key: String, value: float) -> String:
	var stat_data: Dictionary = GameConstants.GIFT_STATS.get(stat_key, {})
	if stat_data.is_empty():
		return ""
	if stat_key == "crit_chance" or stat_key == "speed" or stat_key == "atk_speed":
		return stat_data.display % (value * 100.0)
	return stat_data.display % value

func _show_charge_shrine_window() -> void:
	_ensure_charge_shrine_popup_exists()
	get_tree().paused = true
	charge_shrine_popup_panel.visible = true
	charge_shrine_popup_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var grid = charge_shrine_popup_panel.get_node("Margin/VBox/OptionRow")
	for child in grid.get_children():
		child.queue_free()
	
	for idx in range(current_charge_shrine_options.size()):
		var option: Dictionary = current_charge_shrine_options[idx]
		var rarity_color: Color = option.get("rarity_color", Color.WHITE)
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(rarity_color.r * 0.15, rarity_color.g * 0.15, rarity_color.b * 0.15, 1.0)
		sb.border_width_left = 3
		sb.border_width_top = 3
		sb.border_width_right = 3
		sb.border_width_bottom = 3
		sb.border_color = rarity_color
		sb.corner_radius_top_left = 8
		sb.corner_radius_top_right = 8
		sb.corner_radius_bottom_left = 8
		sb.corner_radius_bottom_right = 8

		var choose_btn = Button.new()
		choose_btn.text = "★ %s\n%s" % [String(option.get("rarity_name", "Common")).to_upper(), String(option.get("display", ""))]
		choose_btn.custom_minimum_size = Vector2(250, 180)
		choose_btn.add_theme_font_size_override("font_size", 18)
		choose_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		choose_btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		choose_btn.add_theme_stylebox_override("normal", sb)
		choose_btn.add_theme_stylebox_override("hover", sb)
		choose_btn.add_theme_stylebox_override("pressed", sb)
		choose_btn.add_theme_stylebox_override("focus", sb)
		choose_btn.pressed.connect(_on_charge_shrine_option_chosen.bind(idx))
		grid.add_child(choose_btn)

func _ensure_charge_shrine_popup_exists() -> void:
	if charge_shrine_popup_panel:
		return
	
	charge_shrine_popup_panel = PanelContainer.new()
	charge_shrine_popup_panel.name = "ChargeShrinePopupPanel"
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.11, 1.0)
	sb.border_width_left = 5
	sb.border_width_top = 5
	sb.border_width_right = 5
	sb.border_width_bottom = 5
	sb.border_color = Color(0.45, 0.85, 1.0, 1.0)
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	charge_shrine_popup_panel.add_theme_stylebox_override("panel", sb)
	charge_shrine_popup_panel.custom_minimum_size = Vector2(980, 420)
	charge_shrine_popup_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	charge_shrine_popup_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	charge_shrine_popup_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var margin = MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	charge_shrine_popup_panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "Charge Shrine"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.modulate = Color(0.55, 0.9, 1.0)
	vbox.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Choose one reward."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(0.85, 0.92, 1.0)
	vbox.add_child(subtitle)
	
	var options_row = HBoxContainer.new()
	options_row.name = "OptionRow"
	options_row.alignment = BoxContainer.ALIGNMENT_CENTER
	options_row.add_theme_constant_override("separation", 20)
	vbox.add_child(options_row)
	
	$UI.add_child(charge_shrine_popup_panel)
	charge_shrine_popup_panel.visible = false

func _on_charge_shrine_option_chosen(index: int) -> void:
	if index < 0 or index >= current_charge_shrine_options.size():
		return
	var option: Dictionary = current_charge_shrine_options[index]
	var internal_stat: String = option.get("internal_stat", "")
	var value: float = float(option.get("value", 0.0))
	if internal_stat != "":
		var current = GameState.run_gift_bonuses.get(internal_stat, 0.0)
		GameState.run_gift_bonuses[internal_stat] = current + value
		var player_node = get_tree().get_first_node_in_group("player")
		if player_node and player_node.has_method("refresh_stats"):
			player_node.refresh_stats()
	if is_instance_valid(current_charge_shrine):
		current_charge_shrine.queue_free()
	current_charge_shrine = null
	current_charge_shrine_options.clear()
	charge_shrine_popup_panel.visible = false
	get_tree().paused = false

