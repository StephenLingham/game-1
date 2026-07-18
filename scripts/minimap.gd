extends Control
# Circular Mini-map and Full Map Overlay with Fog of War

var cell_size: float = 120.0
var cols: int = 0
var rows: int = 0
var fog_grid: Array = []
var arena_rect: Rect2
var player: Node2D = null
var is_initialized: bool = false
var crystal_marker_texture: Texture2D = preload("res://assets/gem_icon.png")
const PANEL_BACKGROUND := preload("res://assets/ui/level_up/panel_background_wood.webp")

# Circular Minimap Properties
var minimap_radius: float = 80.0
var minimap_margin: float = 20.0
var minimap_scale: float = 80.0 / 1200.0 # 1200 world units map to 80 units in minimap

# Full Screen Map Properties
var full_map_size: Vector2 = Vector2(600, 600)
var is_tab_held: bool = false
var full_map_layout: HBoxContainer
var map_inventory_panel: RunInventoryPanel
var map_stats_panel: RunStatsPanel
var full_map_panel_style: StyleBoxTexture

func _ready() -> void:
	# Add to group or do general setups
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	full_map_panel_style = _create_map_panel_style()
	_build_full_map_layout()
	_try_auto_initialize()

func _build_full_map_layout() -> void:
	full_map_layout = HBoxContainer.new()
	full_map_layout.name = "FullMapThreeColumnLayout"
	full_map_layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	full_map_layout.offset_left = 20.0
	full_map_layout.offset_top = 20.0
	full_map_layout.offset_right = -20.0
	full_map_layout.offset_bottom = -20.0
	full_map_layout.alignment = BoxContainer.ALIGNMENT_CENTER
	full_map_layout.add_theme_constant_override("separation", 36)
	full_map_layout.visible = false
	add_child(full_map_layout)

	map_inventory_panel = RunInventoryPanel.new()
	map_inventory_panel.name = "RunInventoryPanel"
	var main_scene := get_tree().current_scene
	if main_scene and main_scene.has_method("get_run_ability_catalog"):
		map_inventory_panel.set_ability_catalog(main_scene.get_run_ability_catalog())
	full_map_layout.add_child(map_inventory_panel)
	map_inventory_panel.add_theme_stylebox_override("panel", full_map_panel_style)

	var map_space := Control.new()
	map_space.name = "MapSpace"
	map_space.custom_minimum_size = full_map_size
	map_space.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	full_map_layout.add_child(map_space)

	map_stats_panel = RunStatsPanel.new()
	map_stats_panel.name = "RunStatsPanel"
	full_map_layout.add_child(map_stats_panel)
	map_stats_panel.add_theme_stylebox_override("panel", full_map_panel_style)

func _create_map_panel_style() -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = PANEL_BACKGROUND
	style.texture_margin_left = 24.0
	style.texture_margin_top = 24.0
	style.texture_margin_right = 24.0
	style.texture_margin_bottom = 24.0
	style.content_margin_left = 22.0
	style.content_margin_top = 20.0
	style.content_margin_right = 22.0
	style.content_margin_bottom = 20.0
	return style

func initialize(rect: Rect2, p_node: Node2D) -> void:
	arena_rect = rect
	player = p_node
	
	cols = int(ceil(arena_rect.size.x / cell_size))
	rows = int(ceil(arena_rect.size.y / cell_size))
	
	fog_grid = []
	for x in range(cols):
		var col_arr = []
		for y in range(rows):
			col_arr.append(false) # Covered by fog initially
		fog_grid.append(col_arr)
		
	is_initialized = true

func _try_auto_initialize() -> void:
	var main_scene = get_tree().current_scene
	if not main_scene: return
	
	var floor_rect = main_scene.get_node_or_null("ArenaFloor") as TextureRect
	var p_node = main_scene.get_node_or_null("Player") as Node2D
	
	if floor_rect and p_node:
		var size = floor_rect.size
		if size.length() > 100: # Ensure arena has been resized/configured
			initialize(Rect2(floor_rect.position, size), p_node)

func _process(_delta: float) -> void:
	if not is_initialized or not is_instance_valid(player):
		_try_auto_initialize()
		return
		
	# Manage visibility during overlay panels (Shop, Pause, Game Over)
	var main_scene = get_tree().current_scene
	if main_scene:
		var shop = main_scene.get_node_or_null("UI/ShopPanel")
		var game_over = main_scene.get_node_or_null("UI/GameOverPanel")
		var pause = main_scene.get_node_or_null("UI/PausePanel")
		var item_window = main_scene.get_node_or_null("UI/ItemPopupPanel")
		
		var is_any_open = (shop and shop.visible) or (game_over and game_over.visible) or (pause and pause.visible) or (item_window and item_window.visible)
		if is_any_open:
			visible = false
			return
	visible = true

	# Check Tab key
	var tab_pressed = Input.is_key_pressed(KEY_TAB)
	if tab_pressed != is_tab_held:
		is_tab_held = tab_pressed
		full_map_layout.visible = is_tab_held
		if is_tab_held:
			map_inventory_panel.refresh_inventory()
			map_stats_panel.refresh_stats()
		queue_redraw()
		
	# Uncover fog around player
	var player_pos = player.global_position
	var local_pos = player_pos - arena_rect.position
	var p_col = int(local_pos.x / cell_size)
	var p_row = int(local_pos.y / cell_size)
	
	var reveal_cells := GameConstants.LARGE_MAP_FOG_REVEAL_CELLS + (10 if GameState.has_run_item("cartographers_lens") else 0)
	var reveal_radius := GameConstants.LARGE_MAP_FOG_REVEAL_RADIUS + (1000.0 if GameState.has_run_item("cartographers_lens") else 0.0)
	if GameState.has_run_item("atlas_eye"):
		for x in range(cols):
			for y in range(rows):
				fog_grid[x][y] = true
	else:
		for x in range(max(0, p_col - reveal_cells), min(cols, p_col + reveal_cells + 1)):
			for y in range(max(0, p_row - reveal_cells), min(rows, p_row + reveal_cells + 1)):
				var cell_center = arena_rect.position + Vector2(x + 0.5, y + 0.5) * cell_size
				if player_pos.distance_to(cell_center) < reveal_radius:
					fog_grid[x][y] = true
				
	queue_redraw()

func is_uncovered(world_pos: Vector2) -> bool:
	if GameState.has_run_item("atlas_eye"):
		return true
	if not GameConstants.ENABLE_LARGE_MAP_FOG_OF_WAR:
		return true
	if not is_initialized: return false
	var local_pos = world_pos - arena_rect.position
	var col = int(local_pos.x / cell_size)
	var row = int(local_pos.y / cell_size)
	if col >= 0 and col < cols and row >= 0 and row < rows:
		return fog_grid[col][row]
	return false

func _is_crystal_pickup(node: Object) -> bool:
	return is_instance_valid(node) and node.get("type") == 4

func _torch_color(torch: Object) -> Color:
	return Color(1.0, 0.24, 0.18, 1.0) if int(torch.get("torch_type")) == 1 else Color(0.2, 0.62, 1.0, 1.0)


func _draw() -> void:
	if not is_initialized or not is_instance_valid(player):
		return
		
	if is_tab_held:
		_draw_full_map()
	else:
		_draw_minimap()

func _draw_minimap() -> void:
	# Top right circular coordinates
	var screen_size = get_viewport_rect().size
	var mm_center = Vector2(screen_size.x - minimap_radius - minimap_margin, minimap_radius + minimap_margin)
	
	# Background
	draw_circle(mm_center, minimap_radius, Color(0.08, 0.08, 0.1, 0.75))
	
	var player_pos = player.global_position
	
	# Draw collectibles
	# 1. Gifts (Magenta)
	for g in get_tree().get_nodes_in_group("gifts"):
		if is_instance_valid(g):
			var pos = mm_center + (g.global_position - player_pos) * minimap_scale
			if pos.distance_to(mm_center) <= minimap_radius: # Fog of war does not apply to circular minimap
				draw_circle(pos, 3.5, Color(0.9, 0.0, 0.9, 1.0)) # Bright purple/magenta
				draw_circle(pos, 5.0, Color(0.9, 0.0, 0.9, 0.3)) # Outer glow

	# 1b. Charge Shrines (Blue)
	for s in get_tree().get_nodes_in_group("shrines"):
		if is_instance_valid(s):
			var pos = mm_center + (s.global_position - player_pos) * minimap_scale
			if pos.distance_to(mm_center) <= minimap_radius:
				draw_circle(pos, 4.0, Color(0.4, 0.85, 1.0, 1.0))
				draw_circle(pos, 6.5, Color(0.4, 0.85, 1.0, 0.28))
				
	# 1c. Torches (Blue XP / Red Spawn Rate)
	for torch in get_tree().get_nodes_in_group("torches"):
		if is_instance_valid(torch):
			var pos = mm_center + (torch.global_position - player_pos) * minimap_scale
			if pos.distance_to(mm_center) <= minimap_radius:
				var color := _torch_color(torch)
				draw_circle(pos, 3.25, Color.WHITE)
				draw_circle(pos, 2.25, color)
				draw_circle(pos, 6.0, Color(color.r, color.g, color.b, 0.28))

	# 2. Chests (Gold)
	for c in get_tree().get_nodes_in_group("chests"):
		if is_instance_valid(c):
			var pos = mm_center + (c.global_position - player_pos) * minimap_scale
			if pos.distance_to(mm_center) <= minimap_radius: # Fog of war does not apply to circular minimap
				draw_circle(pos, 3.5, Color(1.0, 0.75, 0.0, 1.0)) # Bright gold/yellow
				draw_circle(pos, 5.0, Color(1.0, 0.75, 0.0, 0.3))
				
	# 3. Powerups / Crystals (Cyan / Red)
	for p in get_tree().get_nodes_in_group("powerups"):
		if is_instance_valid(p):
			var pos = mm_center + (p.global_position - player_pos) * minimap_scale
			var is_crystal = _is_crystal_pickup(p)
			if is_crystal:
				if pos.distance_to(mm_center) <= minimap_radius:
					var crystal_size := Vector2(14.0, 14.0)
					var crystal_rect := Rect2(pos - crystal_size / 2.0, crystal_size)
					draw_texture_rect(crystal_marker_texture, crystal_rect, false)
			else:
				if pos.distance_to(mm_center) <= minimap_radius: # Fog of war does not apply to circular minimap
					draw_circle(pos, 3.5, Color(0.0, 0.85, 1.0, 1.0)) # Electric cyan
					draw_circle(pos, 5.0, Color(0.0, 0.85, 1.0, 0.3))

	# Draw player in center
	var p_pulse = 3.5 + sin(Time.get_ticks_msec() / 150.0) * 0.7
	draw_circle(mm_center, p_pulse, Color(0.2, 1.0, 0.2, 1.0)) # Glowing green player dot
	draw_circle(mm_center, p_pulse + 2.0, Color(0.2, 1.0, 0.2, 0.3))
	
	# Circular Border
	draw_circle_arc(mm_center, minimap_radius, Color(0.4, 0.8, 1.0, 1.0), 3.0)

func _draw_full_map() -> void:
	var screen_size = get_viewport_rect().size
	var fm_rect = Rect2((screen_size - full_map_size) / 2.0, full_map_size)
	
	# Map background panel
	draw_style_box(full_map_panel_style, fm_rect.grow(10.0))
	draw_rect(fm_rect, Color(0.035, 0.055, 0.052, 1.0))
	
	# Scale calculations keeping aspect ratio
	var fm_scale = min(full_map_size.x / arena_rect.size.x, full_map_size.y / arena_rect.size.y)
	var bounds_rect = Rect2(
		fm_rect.position + (fm_rect.size - arena_rect.size * fm_scale) / 2.0,
		arena_rect.size * fm_scale
	)
	
	# Draw active floor boundary
	draw_rect(bounds_rect, Color(0.12, 0.12, 0.15, 1.0))
	
	# Draw Fog of War
	if GameConstants.ENABLE_LARGE_MAP_FOG_OF_WAR:
		for x in range(cols):
			for y in range(rows):
				if not fog_grid[x][y]:
					var mapped_cell_pos = bounds_rect.position + Vector2(x, y) * cell_size * fm_scale
					var mapped_cell_size = Vector2(cell_size, cell_size) * fm_scale
					# Draw dark gray fog overlay
					draw_rect(Rect2(mapped_cell_pos, mapped_cell_size), Color(0.03, 0.03, 0.05, 0.95))
				
	# Subtle grid borders
	draw_rect(bounds_rect, Color(0.2, 0.4, 0.5, 0.4), false, 1.5)
	
	var player_pos = player.global_position
	
	# Draw collectibles if uncovered
	# 1. Gifts (Magenta)
	for g in get_tree().get_nodes_in_group("gifts"):
		if is_instance_valid(g) and (is_uncovered(g.global_position) or (GameState.has_run_item("legendfinder_compass") and String(g.get("rarity")) == "legendary")):
			var local_offset = g.global_position - arena_rect.position
			var pos = bounds_rect.position + local_offset * fm_scale
			var color := Color(0.9, 0.0, 0.9, 1.0)
			if String(g.get("rarity")) == "legendary":
				color = Color(1.0, 0.85, 0.2, 1.0)
			draw_circle(pos, 4.5, color)
			draw_circle(pos, 6.0, Color(color.r, color.g, color.b, 0.3))

	# 1b. Charge Shrines (Blue)
	for s in get_tree().get_nodes_in_group("shrines"):
		if is_instance_valid(s) and is_uncovered(s.global_position):
			var local_offset = s.global_position - arena_rect.position
			var pos = bounds_rect.position + local_offset * fm_scale
			draw_circle(pos, 5.0, Color(0.4, 0.85, 1.0, 1.0))
			draw_circle(pos, 7.0, Color(0.4, 0.85, 1.0, 0.28))
			
	# 1c. Torches (Blue XP / Red Spawn Rate)
	for torch in get_tree().get_nodes_in_group("torches"):
		if is_instance_valid(torch) and is_uncovered(torch.global_position):
			var local_offset = torch.global_position - arena_rect.position
			var pos = bounds_rect.position + local_offset * fm_scale
			var color := _torch_color(torch)
			draw_circle(pos, 4.0, Color.WHITE)
			draw_circle(pos, 2.75, color)
			draw_circle(pos, 7.0, Color(color.r, color.g, color.b, 0.28))

	for c in get_tree().get_nodes_in_group("chests"):
	# 2. Chests (Gold)
		if is_instance_valid(c) and is_uncovered(c.global_position):
			var local_offset = c.global_position - arena_rect.position
			var pos = bounds_rect.position + local_offset * fm_scale
			draw_circle(pos, 4.5, Color(1.0, 0.75, 0.0, 1.0))
			draw_circle(pos, 6.0, Color(1.0, 0.75, 0.0, 0.3))
			
	# 3. Powerups / Crystals (Cyan / Red)
	for p in get_tree().get_nodes_in_group("powerups"):
		if is_instance_valid(p):
			var is_crystal = _is_crystal_pickup(p)
			if is_crystal:
				if is_uncovered(p.global_position) or GameState.has_run_item("crystal_tracker"):

					var local_offset = p.global_position - arena_rect.position
					var pos = bounds_rect.position + local_offset * fm_scale
					var crystal_size := Vector2(18.0, 18.0)
					var crystal_rect := Rect2(pos - crystal_size / 2.0, crystal_size)
					draw_texture_rect(crystal_marker_texture, crystal_rect, false)
			elif is_uncovered(p.global_position):
				var local_offset = p.global_position - arena_rect.position
				var pos = bounds_rect.position + local_offset * fm_scale
				draw_circle(pos, 4.5, Color(0.0, 0.85, 1.0, 1.0))
				draw_circle(pos, 6.0, Color(0.0, 0.85, 1.0, 0.3))

	# Draw player pulsing green dot
	var local_offset = player_pos - arena_rect.position
	var p_pos = bounds_rect.position + local_offset * fm_scale
	var p_pulse = 5.0 + sin(Time.get_ticks_msec() / 150.0) * 1.5
	draw_circle(p_pos, p_pulse, Color(0.2, 1.0, 0.2, 1.0))
	draw_circle(p_pos, p_pulse + 3.0, Color(0.2, 1.0, 0.2, 0.3))

# Helper to draw circular stroke/arc in Godot
func draw_circle_arc(center: Vector2, radius: float, color: Color, width: float = 1.0) -> void:
	var points_to_draw = 64
	var points = PackedVector2Array()
	for i in range(points_to_draw + 1):
		var angle = i * TAU / points_to_draw
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	for i in range(points_to_draw):
		draw_line(points[i], points[i + 1], color, width)
