extends Control

@onready var gems_label: Label = $VBox/Header/GemsLabel
@onready var grid: GridContainer = $VBox/Scroll/Grid
@onready var back_btn: Button = $VBox/Footer/Back
@onready var reset_btn: Button = $VBox/Footer/Reset

const UPGRADES = [
	{"id": "damage", "name": "Damage", "desc": "+1% Damage per level"},
	{"id": "atkspd", "name": "Attack Speed", "desc": "+1% Attack Speed per level"},
	{"id": "pickup_radius", "name": "Magnet", "desc": "+1 Magnet Radius per level"},
	{"id": "max_health", "name": "Max Health", "desc": "+1 Health per level"},
	{"id": "regen", "name": "Health Regen", "desc": "+0.1 HP/sec per level"},
	{"id": "crit", "name": "Crit Chance", "desc": "+1% Crit Chance per level"},
	{"id": "crit_damage", "name": "Crit Damage", "desc": "+10% Crit Multiplier per level"},
	{"id": "armor", "name": "Armor (Flat)", "desc": "+1 Flat damage reduction per level"},
	{"id": "armor_percent", "name": "Armor (%)", "desc": "+1% Total damage reduction per level"},
	{"id": "thorns", "name": "Thorns", "desc": "+1% Thorns damage reflected"},
	{"id": "spawn_rate", "name": "Spawn Rate", "desc": "+1% Enemy spawn rate"},
	{"id": "start_gold", "name": "Starting Gold", "desc": "+1 Gold per level"},
	{"id": "gold_drop", "name": "Gold Drop", "desc": "+1% Gold from enemies"},
	{"id": "gem_drop", "name": "Gem Drop", "desc": "+1% Gem drop chance"},
	{"id": "speed", "name": "Movement Speed", "desc": "+1% Speed per level"}
]

func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	reset_btn.pressed.connect(_on_reset_pressed)
	_refresh_ui()

func _exit_tree() -> void:
	if is_instance_valid(grid):
		for child in grid.get_children():
			child.queue_free()

func _refresh_ui() -> void:
	gems_label.text = "Gems: %d" % GameState.gems
	
	for child in grid.get_children():
		child.queue_free()
	
	for upg in UPGRADES:
		var level = GameState.get("perm_" + upg.id + "_level")
		var cost = GameState.get_perm_cost(level)
		
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
		desc.text = upg.desc
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.modulate = Color(0.8, 0.8, 0.9)
		vbox.add_child(desc)
		
		var btn = Button.new()
		if level >= 10:
			btn.text = "MAX LEVEL"
			btn.disabled = true
		else:
			btn.text = "Upgrade: %d Gems" % cost
			btn.disabled = GameState.gems < cost
		btn.pressed.connect(_buy_upgrade.bind(upg.id))
		vbox.add_child(btn)
		
		grid.add_child(panel)

func _buy_upgrade(id: String) -> void:
	if GameState.buy_perm_upgrade(id):
		_refresh_ui()

func _on_reset_pressed() -> void:
	GameState.reset_gems()
	_refresh_ui()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
