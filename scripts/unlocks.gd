extends Control

@onready var grid: GridContainer = $VBox/Scroll/Grid
@onready var back_btn: Button = $VBox/Footer/Back

const WEAPONS = {
	"zap": {"name": "Zap", "unlock": "Unlocked by default"},
	"arcane_missile": {"name": "Arcane Missile", "unlock": "Kill 50 enemies with Zap"},
	"fireball": {"name": "Fireball", "unlock": "Kill 50 enemies with Arcane Missile"},
	"ice_shard": {"name": "Ice Shard", "unlock": "Kill 50 enemies with Fireball"},
	"meteor": {"name": "Meteor", "unlock": "Kill 50 enemies with Ice Shard"},
	"frozen_orb": {"name": "Frozen Orb", "unlock": "Kill 50 enemies with Meteor"},
	"lightning_bolt": {"name": "Lightning Bolt", "unlock": "Kill 50 enemies with Frozen Orb"},
	"ice_bolt": {"name": "Ice Bolt", "unlock": "Kill 50 enemies with Lightning Bolt"},
	"fire_bolt": {"name": "Fire Bolt", "unlock": "Kill 50 enemies with Ice Bolt"},
	"arcane_bolt": {"name": "Arcane Bolt", "unlock": "Kill 50 enemies with Fire Bolt"},
	"lightning_fork": {"name": "Lightning Fork", "unlock": "Kill 50 enemies with Arcane Bolt"},
	"blizzard": {"name": "Blizzard", "unlock": "Kill 50 enemies with Lightning Fork"},
	"arcane_orbs": {"name": "Arcane Orbs", "unlock": "Kill 50 enemies with Blizzard"},
	"arcane_field": {"name": "Arcane Field", "unlock": "Kill 50 enemies with Arcane Orbs"},
	"fire_trail": {"name": "Fire Trail", "unlock": "Kill 50 enemies with Arcane Field"},
	"floor_spikes": {"name": "Floor Spikes", "unlock": "Kill 50 enemies with Fire Trail"},
	"ice_wave": {"name": "Ice Wave", "unlock": "Kill 50 enemies with Floor Spikes"},
	"spike_ball": {"name": "Spike Ball", "unlock": "Kill 50 enemies with Ice Wave"},
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
var aura_tab: Button
var item_tab: Button
var char_tab: Button
var slots_tab: Button

func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	
	# Tab buttons Setup
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	$VBox.add_child(hbox)
	$VBox.move_child(hbox, 1) # After Title
	
	weapon_tab = Button.new()
	weapon_tab.text = "Weapons"
	weapon_tab.custom_minimum_size = Vector2(180, 40)
	weapon_tab.pressed.connect(_on_view_changed.bind("weapons"))
	hbox.add_child(weapon_tab)
	
	aura_tab = Button.new()
	aura_tab.text = "Auras"
	aura_tab.custom_minimum_size = Vector2(180, 40)
	aura_tab.pressed.connect(_on_view_changed.bind("auras"))
	hbox.add_child(aura_tab)
	
	item_tab = Button.new()
	item_tab.text = "Items"
	item_tab.custom_minimum_size = Vector2(180, 40)
	item_tab.pressed.connect(_on_view_changed.bind("items"))
	hbox.add_child(item_tab)
	
	char_tab = Button.new()
	char_tab.text = "Characters"
	char_tab.custom_minimum_size = Vector2(180, 40)
	char_tab.pressed.connect(_on_view_changed.bind("characters"))
	hbox.add_child(char_tab)
	
	slots_tab = Button.new()
	slots_tab.text = "Slots"
	slots_tab.custom_minimum_size = Vector2(180, 40)
	slots_tab.pressed.connect(_on_view_changed.bind("slots"))
	hbox.add_child(slots_tab)
	
	_refresh_ui()

func _on_view_changed(view: String) -> void:
	current_view = view
	_refresh_ui()

func _refresh_ui() -> void:
	for child in grid.get_children():
		child.queue_free()
	
	# Update title
	$VBox/Header/Title.text = current_view.capitalize()
	
	# Update tab visual focus
	weapon_tab.modulate = Color.WHITE if current_view == "weapons" else Color(0.6, 0.6, 0.6)
	aura_tab.modulate = Color.WHITE if current_view == "auras" else Color(0.6, 0.6, 0.6)
	item_tab.modulate = Color.WHITE if current_view == "items" else Color(0.6, 0.6, 0.6)
	char_tab.modulate = Color.WHITE if current_view == "characters" else Color(0.6, 0.6, 0.6)
	slots_tab.modulate = Color.WHITE if current_view == "slots" else Color(0.6, 0.6, 0.6)
	
	match current_view:
		"weapons": _show_weapons()
		"auras": _show_auras()
		"items": _show_items()
		"characters": _show_characters()
		"slots": _show_slots()

func _show_weapons() -> void:
	for id in WEAPONS:
		var item = WEAPONS[id]
		var is_unlocked = GameState.is_item_unlocked(id)
		
		# Progress info
		var kills = GameState.lifetime_kills.get(id, 0)
		var needed = GameConstants.UNLOCK_KILLS_NEEDED
		
		var panel = PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
		
		if id != "zap" and not is_unlocked:
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
		
		# Sealing
		var total_upgrades = GameState.lifetime_upgrades.get(id, 0)
		if is_unlocked and total_upgrades >= 20:
			_add_seal_button(id, vbox, "weapons")
		elif is_unlocked:
			var prog = Label.new()
			prog.text = "Lifetime Upgrades: %d / 20" % total_upgrades
			prog.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			prog.modulate = Color(0.5, 0.5, 0.5)
			prog.add_theme_font_size_override("font_size", 12)
			vbox.add_child(prog)

func _show_items() -> void:
	var items = GameConstants.ITEMS
	var unlocked = GameState.unlocked_treasure_items
	

	var item_ids = items.keys()
	for i in range(item_ids.size()):
		var id = item_ids[i]
		var item_data = items[id]
		var is_unlocked = unlocked.has(id)
		
		var panel = PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 10)
		vbox.custom_minimum_size = Vector2(280, 0)
		panel.add_child(vbox)
		
		var title = Label.new()
		# Friendly names for all, including locked
		title.text = item_data.name 
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
			var chests_needed = (i - 4) * 5
			var current_chests = GameState.lifetime_chests_opened
			
			var lock_info = Label.new()
			lock_info.text = "Open %d chests to unlock (%d / %d)" % [chests_needed, current_chests, chests_needed]
			lock_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lock_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lock_info.modulate = Color(0.7, 0.7, 0.7)
			vbox.add_child(lock_info)
		grid.add_child(panel)
		
		# Sealing
		var picks = GameState.lifetime_item_picks.get(id, 0)
		if is_unlocked and picks >= 5:
			_add_seal_button(id, vbox, "items")
		elif is_unlocked:
			var prog = Label.new()
			prog.text = "Times Chosen: %d / 5" % picks
			prog.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			prog.modulate = Color(0.5, 0.5, 0.5)
			prog.add_theme_font_size_override("font_size", 12)
			vbox.add_child(prog)

func _show_auras() -> void:
	var auras = GameConstants.AURAS
	var aura_ids = auras.keys()
	
	for i in range(aura_ids.size()):
		var id = aura_ids[i]
		var aura_data = auras[id]
		var is_unlocked = GameState.is_item_unlocked(id)
		
		var panel = PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 10)
		vbox.custom_minimum_size = Vector2(280, 0)
		panel.add_child(vbox)
		
		var title = Label.new()
		title.text = aura_data.name
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 22)
		vbox.add_child(title)
		
		var status = Label.new()
		status.text = "Unlocked" if is_unlocked else "Locked"
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status.modulate = Color.SPRING_GREEN if is_unlocked else Color.TOMATO
		status.add_theme_font_size_override("font_size", 18)
		vbox.add_child(status)
		
		var desc = Label.new()
		if is_unlocked:
			var val = aura_data.value
			if aura_data.desc != "":
				if aura_data.stat.ends_with("_multiplier") or aura_data.stat.ends_with("_percent") or aura_data.stat.ends_with("_chance") or aura_data.stat == "thorns_percentage" or aura_data.stat == "gem_drop_chance_bonus" or aura_data.stat == "spawn_rate_multiplier":
					desc.text = aura_data.desc % int(val * 100)
				else:
					desc.text = aura_data.desc % val
			else:
				desc.visible = false
		else:
			var precursor = _get_aura_precursor(id)
			if precursor != "":
				var prec_name = auras[precursor].name
				desc.text = "Upgrade %s %d times in total to unlock" % [prec_name, GameConstants.AURA_UNLOCK_UPGRADES_NEEDED]
			else:
				desc.text = "Kill 100 enemies with Zap to unlock"
				
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.modulate = Color(0.8, 0.8, 0.9)
		vbox.add_child(desc)
		
		if not is_unlocked:
			var precursor = _get_aura_precursor(id)
			if precursor != "":
				var upgrades = GameState.lifetime_upgrades.get(precursor, 0)
				var progress = Label.new()
				progress.text = "Total Upgrades Progress: %d / %d" % [upgrades, GameConstants.AURA_UNLOCK_UPGRADES_NEEDED]
				progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				progress.modulate = Color.CYAN
				vbox.add_child(progress)
		grid.add_child(panel)
		
		# Sealing
		var total_upgrades = GameState.lifetime_upgrades.get(id, 0)
		if is_unlocked and total_upgrades >= 5:
			_add_seal_button(id, vbox, "auras")
		elif is_unlocked:
			var prog = Label.new()
			prog.text = "Lifetime Upgrades: %d / 5" % total_upgrades
			prog.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			prog.modulate = Color(0.5, 0.5, 0.5)
			prog.add_theme_font_size_override("font_size", 12)
			vbox.add_child(prog)

func _get_aura_precursor(id: String) -> String:
	var aura_chain = GameConstants.AURAS.keys()
	var idx = aura_chain.find(id)
	if idx > 0:
		return aura_chain[idx-1]
	return ""

func _get_precursor(id: String) -> String:
	var weapon_chain = WEAPONS.keys()
	var idx = weapon_chain.find(id)
	if idx > 0:
		return weapon_chain[idx-1]
	return ""

func _show_characters() -> void:
	var chars = GameConstants.CHARACTERS
	var chain = GameConstants.CHARACTER_UNLOCK_CHAIN
	
	for id in chain:
		var cdata = chars[id]
		var is_unlocked = GameState.unlocked_characters.has(id)
		
		var panel = PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 10)
		vbox.custom_minimum_size = Vector2(280, 0)
		panel.add_child(vbox)
		
		var title = Label.new()
		title.text = cdata.name
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 22)
		vbox.add_child(title)
		
		var status = Label.new()
		status.text = "Unlocked" if is_unlocked else "Locked"
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status.modulate = Color.SPRING_GREEN if is_unlocked else Color.TOMATO
		vbox.add_child(status)
		
		var desc = Label.new()
		desc.text = cdata.desc if is_unlocked else "???"
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.modulate = Color(0.8, 0.8, 0.9)
		vbox.add_child(desc)
		
		if not is_unlocked:
			# Show precursor
			var idx = chain.find(id)
			if idx > 0:
				var prec_id = chain[idx-1]
				var prec_name = chars[prec_id].name
				var hint = Label.new()
				hint.text = "Unlock by winning a run with %s" % prec_name
				hint.add_theme_font_size_override("font_size", 12)
				hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				hint.modulate = Color.GOLD
				vbox.add_child(hint)
				
		grid.add_child(panel)

func _add_seal_button(id: String, container: Control, category: String) -> void:
	var btn = Button.new()
	var is_sealed = GameState.sealed_items.has(id)
	
	btn.text = "Unseal" if is_sealed else "Seal"
	btn.modulate = Color.ORANGE if is_sealed else Color.WHITE
	
	btn.pressed.connect(_on_seal_toggled.bind(id, category))
	container.add_child(btn)

func _on_seal_toggled(id: String, category: String) -> void:
	var is_sealed = GameState.sealed_items.has(id)
	
	if not is_sealed:
		# Enforce 6-left rule
		var total_count = 0
		var sealed_count = 0
		
		if category == "weapons":
			total_count = GameConstants.CHARACTER_UNLOCK_CHAIN.size() # Wait, no.
			# I need the count of all weapons in GameConstants
			# Actually, I'll just check against the list in the current view
			total_count = WEAPONS.size()
			for wid in WEAPONS:
				if GameState.sealed_items.has(wid): sealed_count += 1
		elif category == "items":
			total_count = GameConstants.ITEMS.size()
			for iid in GameConstants.ITEMS:
				if GameState.sealed_items.has(iid): sealed_count += 1
		elif category == "auras":
			total_count = GameConstants.AURAS.size()
			for aid in GameConstants.AURAS:
				if GameState.sealed_items.has(aid): sealed_count += 1
				
		if total_count - sealed_count <= GameConstants.MIN_UNSEALED_COUNT:
			# Show warning or just return
			return
			
		GameState.sealed_items.append(id)
	else:
		GameState.sealed_items.erase(id)
		
	GameState.save()
	_refresh_ui()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")

func _show_slots() -> void:
	# Show Weapon slots progress
	var weapon_panel = PanelContainer.new()
	weapon_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var wvbox = VBoxContainer.new()
	wvbox.add_theme_constant_override("separation", 15)
	wvbox.custom_minimum_size = Vector2(320, 240)
	weapon_panel.add_child(wvbox)
	
	var wtitle = Label.new()
	wtitle.text = "Weapon Slots"
	wtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wtitle.add_theme_font_size_override("font_size", 24)
	wtitle.modulate = Color.CYAN
	wvbox.add_child(wtitle)
	
	var w_unlocked_count = GameState.unlocked_items.size()
	var current_w_slots = 1 + int(floor(w_unlocked_count / 4.0))
	current_w_slots = min(4, current_w_slots)
	
	var w_slots_lbl = Label.new()
	w_slots_lbl.text = "Active Weapon Slots: %d / 4" % current_w_slots
	w_slots_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	w_slots_lbl.add_theme_font_size_override("font_size", 20)
	wvbox.add_child(w_slots_lbl)
	
	var w_prog_lbl = Label.new()
	w_prog_lbl.text = "Weapons Unlocked: %d" % w_unlocked_count
	w_prog_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	w_prog_lbl.add_theme_font_size_override("font_size", 16)
	wvbox.add_child(w_prog_lbl)
	
	# Breakdown / milestones
	var w_breakdown = Label.new()
	w_breakdown.text = "Milestones:\n• 1 Slot: Unlocked by default %s\n• 2 Slots: Unlock 4 weapons %s\n• 3 Slots: Unlock 8 weapons %s\n• 4 Slots: Unlock 12 weapons %s" % [
		"✓",
		"✓" if w_unlocked_count >= 4 else "(Locked)",
		"✓" if w_unlocked_count >= 8 else "(Locked)",
		"✓" if w_unlocked_count >= 12 else "(Locked)"
	]
	w_breakdown.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	w_breakdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	w_breakdown.modulate = Color(0.8, 0.9, 0.9)
	wvbox.add_child(w_breakdown)
	
	grid.add_child(weapon_panel)

	# Show Aura slots progress
	var aura_panel = PanelContainer.new()
	aura_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var avbox = VBoxContainer.new()
	avbox.add_theme_constant_override("separation", 15)
	avbox.custom_minimum_size = Vector2(320, 240)
	aura_panel.add_child(avbox)
	
	var atitle = Label.new()
	atitle.text = "Aura Slots"
	atitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	atitle.add_theme_font_size_override("font_size", 24)
	atitle.modulate = Color.MAGENTA
	avbox.add_child(atitle)
	
	var a_unlocked_count = GameState.unlocked_auras.size()
	var current_a_slots = 1 + int(floor(a_unlocked_count / 3.0))
	current_a_slots = min(4, current_a_slots)
	
	var a_slots_lbl = Label.new()
	a_slots_lbl.text = "Active Aura Slots: %d / 4" % current_a_slots
	a_slots_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	a_slots_lbl.add_theme_font_size_override("font_size", 20)
	avbox.add_child(a_slots_lbl)
	
	var a_prog_lbl = Label.new()
	a_prog_lbl.text = "Auras Unlocked: %d" % a_unlocked_count
	a_prog_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	a_prog_lbl.add_theme_font_size_override("font_size", 16)
	avbox.add_child(a_prog_lbl)
	
	# Breakdown / milestones
	var a_breakdown = Label.new()
	a_breakdown.text = "Milestones:\n• 1 Slot: Unlocked by default %s\n• 2 Slots: Unlock 3 auras %s\n• 3 Slots: Unlock 6 auras %s\n• 4 Slots: Unlock 9 auras %s" % [
		"✓",
		"✓" if a_unlocked_count >= 3 else "(Locked)",
		"✓" if a_unlocked_count >= 6 else "(Locked)",
		"✓" if a_unlocked_count >= 9 else "(Locked)"
	]
	a_breakdown.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	a_breakdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	a_breakdown.modulate = Color(0.9, 0.8, 0.9)
	avbox.add_child(a_breakdown)
	
	grid.add_child(aura_panel)
