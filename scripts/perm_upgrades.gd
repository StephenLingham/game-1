extends Control

@onready var crystals_label: Label = $VBox/Header/GemsLabel
@onready var grid: GridContainer = $VBox/Scroll/Grid
@onready var back_btn: Button = $VBox/Footer/Back
@onready var reset_btn: Button = $VBox/Footer/Reset

const UPGRADES = [
	{"id": "spawn_rate", "name": "Chaos", "desc": "+1% enemy spawn rate"},
	{"id": "gold_drop", "name": "Learning", "desc": "+1% XP gained"},
	{"id": "luck", "name": "Luck", "desc": "+1% luck"}
]

func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	reset_btn.pressed.connect(_on_reset_pressed)
	_refresh_ui()


func _refresh_ui() -> void:
	crystals_label.text = "Crystals: %d" % GameState.crystals
	
	for child in grid.get_children():
		child.queue_free()
	
	for upg in UPGRADES:
		var level = GameState.get("perm_" + upg.id + "_level")
		var cost = GameState.get_perm_cost(level)
		var next_level = min(level + 1, GameConstants.MAX_PERM_UPGRADE_LEVEL)
		
		var panel = PanelContainer.new()
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 12)
		vbox.custom_minimum_size = Vector2(280, 0)
		panel.add_child(vbox)
		
		var title = Label.new()
		title.text = upg.name + " (Lv. %d)" % level
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 22)
		vbox.add_child(title)
		
		var desc = Label.new()
		desc.text = "%s\nCurrent: %s   ->   Next: %s" % [
			upg.desc,
			_format_upgrade_bonus(upg.id, level),
			_format_upgrade_bonus(upg.id, next_level)
		]
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.modulate = WoodUI.TEXT_MUTED
		vbox.add_child(desc)
		
		var btn = Button.new()
		if level >= GameConstants.MAX_PERM_UPGRADE_LEVEL:
			btn.text = "MAX LEVEL"
			btn.disabled = true
		else:
			btn.text = "Upgrade: %d Crystals" % cost
			btn.disabled = GameState.crystals < cost
		btn.pressed.connect(_buy_upgrade.bind(upg.id))
		vbox.add_child(btn)
		
		grid.add_child(panel)

func _buy_upgrade(id: String) -> void:
	if GameState.buy_perm_upgrade(id):
		_refresh_ui()

func _format_upgrade_bonus(id: String, level: int) -> String:
	var clamped_level = min(level, GameConstants.MAX_PERM_UPGRADE_LEVEL)
	match id:
		"spawn_rate", "gold_drop", "luck":
			return "+%d%%" % clamped_level
		_:
			return str(clamped_level)

func _on_reset_pressed() -> void:
	GameState.reset_crystals()
	_refresh_ui()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
