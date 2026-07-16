class_name RunInventoryPanel
extends PanelContainer

const PLACEHOLDER_ICON := "res://assets/ui/question_mark.svg"
const WEAPON_ICON_PATHS := {
	"zap": "res://assets/Weapons/zap_projectile.png",
	"arcane_missile": "res://assets/Weapons/arcane_missile_projectile.png",
	"fireball": "res://assets/Weapons/fireball_projectile.png",
	"lightning_bolt": "res://assets/Weapons/lightning_bolt_projectile.png",
	"ice_bolt": "res://assets/Weapons/ice_bolt_projectile.png",
	"fire_bolt": "res://assets/Weapons/fire_bolt_projectile.png",
	"arcane_bolt": "res://assets/Weapons/arcane_bolt_projectile.png",
}

var _ability_names: Dictionary = {}
var _list: VBoxContainer

func _ready() -> void:
	custom_minimum_size = Vector2(238, 0)
	size_flags_horizontal = Control.SIZE_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_stylebox_override("panel", _panel_style())
	_build_ui()
	refresh_inventory()

func set_ability_catalog(abilities: Array) -> void:
	_ability_names.clear()
	for ability in abilities:
		_ability_names[String(ability.get("id", ""))] = String(ability.get("name", "Unknown"))
	if is_node_ready():
		refresh_inventory()

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.042, 0.068, 0.97)
	style.border_color = Color(0.28, 0.58, 0.52, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	var title := Label.new()
	title.text = "INVENTORY"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.62, 0.95, 0.82))
	root.add_child(title)
	var rule := HSeparator.new()
	rule.modulate = Color(0.3, 0.75, 0.64, 0.55)
	root.add_child(rule)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 7)
	scroll.add_child(_list)

func refresh_inventory() -> void:
	if not is_node_ready() or not is_instance_valid(_list):
		return
	for child in _list.get_children():
		child.queue_free()
	var weapons: Array = []
	var auras: Array = []
	var ability_ids: Array = GameState.run_abilities.keys()
	ability_ids.sort()
	for ability_id in ability_ids:
		var entry := {"id": String(ability_id), "name": _ability_name(String(ability_id)), "level": int(GameState.run_abilities[ability_id])}
		if String(ability_id).begins_with("aura_"):
			auras.append(entry)
		else:
			weapons.append(entry)
	var item_counts: Dictionary = {}
	for item_id in GameState.run_items:
		var key := String(item_id)
		item_counts[key] = int(item_counts.get(key, 0)) + 1
	var items: Array = []
	var item_ids: Array = item_counts.keys()
	item_ids.sort()
	for item_id in item_ids:
		var data: Dictionary = GameConstants.ITEMS.get(item_id, {})
		items.append({"id": String(item_id), "name": String(data.get("name", _humanize(String(item_id)))), "count": int(item_counts[item_id])})
	_add_category("WEAPONS", weapons, "weapon")
	_add_category("AURAS", auras, "aura")
	_add_category("ITEMS", items, "item")

func _add_category(title_text: String, entries: Array, kind: String) -> void:
	var title := Label.new()
	title.text = "%s  %d" % [title_text, entries.size()]
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", _category_color(kind))
	_list.add_child(title)
	if entries.is_empty():
		var empty := Label.new()
		empty.text = "  None held"
		empty.add_theme_font_size_override("font_size", 12)
		empty.add_theme_color_override("font_color", Color(0.46, 0.52, 0.61))
		_list.add_child(empty)
		return
	for entry in entries:
		_list.add_child(_make_entry(entry, kind))

func _make_entry(entry: Dictionary, kind: String) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _entry_style(_category_color(kind)))
	panel.tooltip_text = String(entry.get("name", "Unknown"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	row.add_child(_make_icon(String(entry.get("id", "")), kind))
	var name_label := Label.new()
	name_label.text = String(entry.get("name", "Unknown"))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.94, 1.0))
	row.add_child(name_label)
	var value := Label.new()
	value.text = "Lv %d" % int(entry.level) if entry.has("level") else "x%d" % int(entry.get("count", 1))
	value.add_theme_font_size_override("font_size", 11)
	value.add_theme_color_override("font_color", _category_color(kind).lightened(0.2))
	row.add_child(value)
	return panel

func _make_icon(id: String, kind: String) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = load(_icon_path(id, kind)) as Texture2D
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(34, 34)
	return icon

func _icon_path(id: String, kind: String) -> String:
	var candidates: Array[String] = []
	if kind == "weapon" and WEAPON_ICON_PATHS.has(id):
		candidates.append(String(WEAPON_ICON_PATHS[id]))
	if kind == "weapon":
		candidates.append("res://assets/Weapons/%s.png" % id)
	elif kind == "aura":
		candidates.append("res://assets/Auras/%s.png" % id)
	else:
		candidates.append("res://assets/Items/%s.png" % id)
	for candidate in candidates:
		if ResourceLoader.exists(candidate):
			return candidate
	return PLACEHOLDER_ICON

func _entry_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.075, 0.11, 0.94)
	style.border_color = Color(accent, 0.38)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 6
	style.content_margin_right = 7
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style

func _category_color(kind: String) -> Color:
	match kind:
		"weapon": return Color(0.35, 0.8, 1.0)
		"aura": return Color(0.92, 0.48, 1.0)
		_: return Color(0.98, 0.76, 0.32)

func _ability_name(id: String) -> String:
	if id.begins_with("aura_"):
		var aura: Dictionary = GameConstants.AURAS.get(id, {})
		if not aura.is_empty():
			return String(aura.get("name", _humanize(id)))
	return String(_ability_names.get(id, _humanize(id)))

func _humanize(id: String) -> String:
	return id.replace("_", " ").capitalize()

