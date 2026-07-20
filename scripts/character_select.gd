extends Control

@onready var grid: GridContainer = $VBox/Scroll/Grid
@onready var back_btn: Button = $VBox/Footer/Back

func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	
	# Start button should be disabled until a character is selected if we want, 
	# but we have a default "starter" selected usually.
	
	_refresh_ui()


func _refresh_ui() -> void:
	for child in grid.get_children():
		child.queue_free()
	
	var chars = GameConstants.CHARACTERS
	var chain = GameConstants.CHARACTER_UNLOCK_CHAIN
	
	for id in chain:
		var cdata = chars[id]
		var is_unlocked = GameState.unlocked_characters.has(id)
		
		var panel = PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var vbox = VBoxContainer.new()
		vbox.custom_minimum_size = Vector2(280, 220)
		panel.custom_minimum_size = Vector2(320, 250)
		panel.add_child(vbox)
		
		panel.add_theme_stylebox_override("panel", WoodUI.card_style(Color.WHITE if is_unlocked else Color(0.46, 0.43, 0.4, 0.92)))

		var title = Label.new()
		title.text = cdata.name
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 24)
		title.modulate = WoodUI.TEXT_PRIMARY if is_unlocked else WoodUI.TEXT_MUTED
		vbox.add_child(title)
		
		var status = Label.new()
		status.text = "" if is_unlocked else "LOCKED"
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status.modulate = Color.SPRING_GREEN if is_unlocked else Color.TOMATO
		status.add_theme_font_size_override("font_size", 16)
		vbox.add_child(status)
		
		var desc = Label.new()
		desc.text = cdata.desc if is_unlocked else "???"
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.modulate = WoodUI.TEXT_MUTED
		
		if is_unlocked and cdata.has("texture"):
			var tex_rect = TextureRect.new()
			tex_rect.texture = load(cdata.texture)
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.custom_minimum_size = Vector2(0, 120)
			vbox.add_child(tex_rect)
			
		vbox.add_child(desc)
		
		if is_unlocked:
			panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			panel.gui_input.connect(_on_card_gui_input.bind(id))
		else:
			# Show hint
			var idx = chain.find(id)
			if idx > 0:
				var prec_id = chain[idx-1]
				var prec_name = chars[prec_id].name
				var hint = Label.new()
				hint.text = "Win a run with\n%s" % prec_name
				hint.add_theme_font_size_override("font_size", 14)
				hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				hint.modulate = Color.GOLD
				vbox.add_child(hint)
		
		grid.add_child(panel)

func _on_card_gui_input(event: InputEvent, id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_character_selected(id)

func _on_character_selected(id: String) -> void:
	GameState.current_character = id
	GameState.save()
	if id == "passive_master":
		get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")
	else:
		_on_start_run_pressed()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")

func _on_start_run_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/WeaponSelect.tscn")
