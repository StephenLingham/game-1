extends Control

@onready var grid: GridContainer = $VBox/Scroll/Grid
@onready var back_btn: Button = $VBox/Footer/Back

const WEAPONS = {
	"handgun": {"name": "Handgun", "unlock": "Unlocked by default"},
	"floor_spikes": {"name": "Floor Spikes", "unlock": "Kill 50 enemies with Handgun"},
	"ice_wave": {"name": "Ice Wave", "unlock": "Kill 50 enemies with Floor Spikes"},
	"spike_ball": {"name": "Spike Ball", "unlock": "Freeze 50 enemies with Ice Wave"},
	"shotgun": {"name": "Shotgun", "unlock": "Kill 50 enemies with Spike Ball"},
	"turret": {"name": "Turret", "unlock": "Kill 50 enemies with Shotgun"},
	"sniper": {"name": "Sniper Gun", "unlock": "Kill 50 enemies with Turret"},
	"orbs": {"name": "Energy Orbs", "unlock": "Kill 50 enemies with Sniper Gun"},
	"bouncing_disk": {"name": "Bouncing Disk", "unlock": "Kill 50 enemies with Energy Orbs"},
	"machine_gun": {"name": "Machine Gun", "unlock": "Kill 50 enemies with Bouncing Disk"},
	"rocket": {"name": "Rocket Launcher", "unlock": "Kill 50 enemies with Machine Gun"},
}

var current_view: String = "weapons"
var weapon_tab: Button
var item_tab: Button

func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	
	# Tab buttons Setup
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	$VBox.add_child(hbox)
	$VBox.move_child(hbox, 1) # After Title
	
	weapon_tab = Button.new()
	weapon_tab.text = "Weapons"
	weapon_tab.custom_minimum_size = Vector2(250, 40)
	weapon_tab.pressed.connect(_on_view_changed.bind("weapons"))
	hbox.add_child(weapon_tab)
	
	item_tab = Button.new()
	item_tab.text = "Items"
	item_tab.custom_minimum_size = Vector2(250, 40)
	item_tab.pressed.connect(_on_view_changed.bind("items"))
	hbox.add_child(item_tab)
	
	_refresh_ui()

func _on_view_changed(view: String) -> void:
	current_view = view
	_refresh_ui()

func _refresh_ui() -> void:
	for child in grid.get_children():
		child.queue_free()
	
	# Update title
	$VBox/Header/Title.text = "Weapons" if current_view == "weapons" else "Items"
	
	# Update tab visual focus
	weapon_tab.modulate = Color.WHITE if current_view == "weapons" else Color(0.6, 0.6, 0.6)
	item_tab.modulate = Color.WHITE if current_view == "items" else Color(0.6, 0.6, 0.6)
	
	if current_view == "weapons":
		_show_weapons()
	else:
		_show_items()

func _show_weapons() -> void:
	for id in WEAPONS:
		var item = WEAPONS[id]
		var is_unlocked = GameState.is_item_unlocked(id)
		
		# Progress info
		var kills = GameState.lifetime_kills.get(id, 0)
		var needed = GameConstants.UNLOCK_KILLS_NEEDED
		
		var panel = PanelContainer.new()
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 10)
		vbox.custom_minimum_size = Vector2(280, 0)
		panel.add_child(vbox)
		
		var title = Label.new()
		title.text = item.name
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 22)
		vbox.add_child(title)
		
		var status = Label.new()
		status.text = "Unlocked" if is_unlocked else "Locked"
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status.modulate = Color.SPRING_GREEN if is_unlocked else Color.TOMATO
		status.add_theme_font_size_override("font_size", 18)
		vbox.add_child(status)
		
		if id != "handgun" and not is_unlocked:
			# Find the precursor to show its kills
			var precursor = _get_precursor(id)
			if precursor != "":
				var pkills = GameState.lifetime_kills.get(precursor, 0)
				var progress = Label.new()
				progress.text = "Progress: %d / %d" % [pkills, needed]
				progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				progress.modulate = Color.CYAN
				vbox.add_child(progress)

		var desc = Label.new()
		desc.text = item.unlock
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.modulate = Color(0.8, 0.8, 0.9)
		vbox.add_child(desc)
		
		grid.add_child(panel)

func _show_items() -> void:
	var items = GameConstants.ITEMS
	var unlocked = GameState.unlocked_treasure_items
	
	# Show overall progress header
	var progress_panel = PanelContainer.new()
	var progress_vbox = VBoxContainer.new()
	progress_panel.add_child(progress_vbox)
	
	var chests = GameState.lifetime_chests_opened
	var next_goal = (floor(chests / 5.0) + 1) * 5
	if unlocked.size() >= items.size():
		next_goal = -1 # All unlocked
		
	var progress_lbl = Label.new()
	progress_lbl.text = "Total Chests Opened: %d" % chests
	if next_goal != -1:
		progress_lbl.text += "\nNext Item Unlock at %d Chests (Progress: %d/5)" % [next_goal, chests % 5]
	else:
		progress_lbl.text += "\nAll Items Unlocked!"
	
	progress_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_lbl.modulate = Color.GOLD
	progress_vbox.add_child(progress_lbl)
	
	grid.add_child(progress_panel)
	# Pad the row if needed, but GridContainer handles it
	
	for id in items:
		var item_data = items[id]
		var is_unlocked = unlocked.has(id)
		
		var panel = PanelContainer.new()
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 10)
		vbox.custom_minimum_size = Vector2(280, 0)
		panel.add_child(vbox)
		
		var title = Label.new()
		title.text = item_data.name if is_unlocked else "???"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 22)
		vbox.add_child(title)
		
		var status = Label.new()
		status.text = "Unlocked" if is_unlocked else "Locked"
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status.modulate = Color.SPRING_GREEN if is_unlocked else Color.TOMATO
		status.add_theme_font_size_override("font_size", 18)
		vbox.add_child(status)
		
		if is_unlocked:
			var stats_lbl = Label.new()
			var stats_text = ""
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
					human_name = "Attack Speed"
					
				stats_text += "%s%s%s %s\n" % [sign_str, str(val), percent, human_name]
			
			stats_lbl.text = stats_text
			stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			stats_lbl.modulate = Color.LIGHT_BLUE
			stats_lbl.add_theme_font_size_override("font_size", 14)
			vbox.add_child(stats_lbl)
		else:
			var lock_info = Label.new()
			lock_info.text = "Open more treasure chests to unlock this item"
			lock_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lock_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lock_info.modulate = Color(0.5, 0.5, 0.5)
			vbox.add_child(lock_info)
		
		grid.add_child(panel)

func _get_precursor(id: String) -> String:
	var weapon_chain = [
		"handgun", "floor_spikes", "ice_wave", "spike_ball", "shotgun", "turret", 
		"sniper", "orbs", "bouncing_disk", "machine_gun", "rocket",
	]
	var idx = weapon_chain.find(id)
	if idx > 0:
		return weapon_chain[idx-1]
	return ""

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
