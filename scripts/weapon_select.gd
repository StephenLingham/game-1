extends Control

@onready var grid: GridContainer = $VBox/Scroll/Grid
@onready var back_btn: Button = $VBox/Footer/Back

func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	_refresh_ui()

func _refresh_ui() -> void:
	for child in grid.get_children():
		child.queue_free()
	
	# We want to show all unlocked weapons
	# We can get names from Main.ALL_ABILITIES or hardcode a map here for simplicity
	# Since Main is a scene script, it's better to have a central data source.
	# GameState.unlocked_items contains the IDs.
	
	var weapons_data = {
		"zap": {"name": "Zap", "desc": "Basic lightning strike."},
		"arcane_missile": {"name": "Arcane Missile", "desc": "Homing arcane bolts."},
		"fireball": {"name": "Fireball", "desc": "Explosive fire damage."},
		"ice_shard": {"name": "Ice Shard", "desc": "Piercing ice shards."},
		"meteor": {"name": "Meteor", "desc": "High damage from above."},
		"frozen_orb": {"name": "Frozen Orb", "desc": "Slow moving, shoots ice shards."},
		"lightning_bolt": {"name": "Lightning Bolt", "desc": "Chain lightning damage."},
		"ice_bolt": {"name": "Ice Bolt", "desc": "Freezes enemies on hit."},
		"fire_bolt": {"name": "Fire Bolt", "desc": "Leaves a trail of fire."},
		"arcane_bolt": {"name": "Arcane Bolt", "desc": "Fast moving arcane energy."},
		"lightning_fork": {"name": "Lightning Fork", "desc": "Splits into multiple bolts."},
		"blizzard": {"name": "Blizzard", "desc": "Slows and damages in an area."},
		"arcane_orbs": {"name": "Arcane Orbs", "desc": "Orbiting arcane power."},
		"arcane_field": {"name": "Arcane Field", "desc": "Damages anything nearby."},
		"fire_trail": {"name": "Fire Trail", "desc": "Leaves burning ground behind."},
		"shotgun": {"name": "Shotgun", "desc": "Short range burst."},
		"sniper": {"name": "Sniper Gun", "desc": "Long range high damage."},
		"rocket": {"name": "Rocket Launcher", "desc": "Large area explosions."},
		"machine_gun": {"name": "Machine Gun", "desc": "Rapid fire bullets."},
		"orbs": {"name": "Energy Orbs", "desc": "Orbiting defense."},
		"spike_ball": {"name": "Spike Ball", "desc": "Bouncing spike ball."},
		"bouncing_disk": {"name": "Bouncing Disk", "desc": "Ricocheting disk."},
		"floor_spikes": {"name": "Floor Spikes", "desc": "Damages enemies on ground."},
		"turret": {"name": "Turret", "desc": "Stationary automated fire."},
		"ice_wave": {"name": "Ice Wave", "desc": "Freezes in a wide arc."}
	}
	
	var unlocked = GameState.unlocked_items
	
	for id in unlocked:
		var data = weapons_data.get(id, {"name": id.capitalize(), "desc": "A powerful weapon."})
		
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(300, 200)
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 10)
		panel.add_child(vbox)
		
		panel.add_theme_stylebox_override("panel", WoodUI.card_style())
		
		var title = Label.new()
		title.text = data.name
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 24)
		vbox.add_child(title)

		var icon_path := "res://assets/Weapons/Icons/%s.png" % id
		if ResourceLoader.exists(icon_path):
			var icon := TextureRect.new()
			icon.texture = load(icon_path) as Texture2D
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(82, 82)
			vbox.add_child(icon)
		
		var desc = Label.new()
		desc.text = data.desc
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.modulate = WoodUI.TEXT_MUTED
		vbox.add_child(desc)
		
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		panel.gui_input.connect(_on_card_gui_input.bind(id))
		
		grid.add_child(panel)

func _on_card_gui_input(event: InputEvent, id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_weapon_selected(id)

func _on_weapon_selected(id: String) -> void:
	GameState.selected_starter_weapon = id
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn")
