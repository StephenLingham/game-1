class_name RunStatsPanel
extends PanelContainer

var _values: Dictionary = {}

func _ready() -> void:
	custom_minimum_size = Vector2(248, 0)
	size_flags_horizontal = Control.SIZE_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_stylebox_override("panel", _panel_style())
	_build_ui()
	refresh_stats()

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.042, 0.068, 0.97)
	style.border_color = Color(0.28, 0.58, 0.72, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _build_ui() -> void:
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	add_child(content)
	var heading := HBoxContainer.new()
	content.add_child(heading)
	var title := Label.new()
	title.text = "STATS"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.58, 0.86, 1.0))
	heading.add_child(title)
	var level := Label.new()
	level.name = "RunLevel"
	level.add_theme_font_size_override("font_size", 14)
	level.add_theme_color_override("font_color", Color(1.0, 0.82, 0.34))
	heading.add_child(level)
	_values["run_level"] = level
	var rule := HSeparator.new()
	rule.modulate = Color(0.3, 0.6, 0.9, 0.45)
	content.add_child(rule)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 5)
	scroll.add_child(grid)
	var stats := [
		["health", "Health"], ["damage", "Damage"],
		["max_health", "Max Health"], ["attack_speed", "Attack Speed"],
		["regen", "Health Regen"], ["crit_chance", "Crit Chance"],
		["armor", "Armor"], ["crit_damage", "Crit Damage"],
		["damage_reduction", "Damage Reduction"], ["move_speed", "Move Speed"],
		["thorns", "Thorns"], ["collection_range", "Collection Range"],
		["luck", "Luck"], ["xp_gain", "XP Gain"],
		["projectiles", "Projectiles"], ["bounces", "Bounces"],
	]
	for stat in stats:
		_add_stat_row(grid, stat[0], stat[1])

func _add_stat_row(grid: GridContainer, key: String, display_name: String) -> void:
	var name_label := Label.new()
	name_label.text = display_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color(0.68, 0.74, 0.86))
	grid.add_child(name_label)
	var value_label := Label.new()
	value_label.text = "--"
	value_label.custom_minimum_size = Vector2(72, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 12)
	value_label.add_theme_color_override("font_color", Color.WHITE)
	grid.add_child(value_label)
	_values[key] = value_label

func refresh_stats() -> void:
	if not is_node_ready():
		return
	var player := get_tree().get_first_node_in_group("player")
	var current_health := GameState.get_max_health()
	if player and "health" in player:
		current_health = int(player.health)
	_set_value("run_level", "LEVEL %d" % GameState.run_level)
	_set_value("health", "%d / %d" % [current_health, GameState.get_max_health()])
	_set_value("damage", "%d  (x%.2f)" % [_current_damage(player), GameState.get_damage_multiplier()])
	_set_value("max_health", str(GameState.get_max_health()))
	_set_value("attack_speed", "+%.0f%%" % ((GameState.get_atkspd_multiplier() - 1.0) * 100.0))
	_set_value("regen", "%.1f / sec" % GameState.get_health_regen())
	_set_value("crit_chance", "%.1f%%" % (GameState.get_crit_chance() * 100.0))
	_set_value("armor", str(GameState.get_armor()))
	_set_value("crit_damage", "%.0f%%" % (GameState.get_crit_multiplier() * 100.0))
	_set_value("damage_reduction", "%.1f%%" % (GameState.get_armor_percent() * 100.0))
	_set_value("move_speed", "%.0f%%" % (GameState.get_speed_multiplier() * 100.0))
	_set_value("thorns", "%.1f%%" % (GameState.get_thorns_percentage() * 100.0))
	_set_value("collection_range", "%.0f px" % GameState.get_pickup_radius())
	_set_value("luck", "%.2fx" % GameState.get_luck())
	_set_value("xp_gain", "%.0f%%" % (GameState.get_xp_drop_multiplier() * 100.0))
	_set_value("projectiles", str(GameState.get_projectiles()))
	_set_value("bounces", str(GameState.get_bounces()))

func _current_damage(player: Node) -> int:
	if player and player.has_method("get_damage"):
		return int(player.get_damage())
	return GameState.get_total_damage(GameConstants.ZAP_BASE_DAMAGE + GameState.get_zap_damage_bonus())

func _set_value(key: String, value: String) -> void:
	var label: Label = _values.get(key)
	if label:
		label.text = value
