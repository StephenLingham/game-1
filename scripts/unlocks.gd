extends Control

@onready var grid: GridContainer = $VBox/Scroll/Grid
@onready var back_btn: Button = $VBox/Footer/Back

const ITEMS = {
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
	"magnet": {"name": "Magnet", "unlock": "Unlocked by default"}
}

func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	_refresh_ui()

func _refresh_ui() -> void:
	for child in grid.get_children():
		child.queue_free()
	
	for id in ITEMS:
		var item = ITEMS[id]
		var is_unlocked = GameState.is_item_unlocked(id)
		
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
		
		var desc = Label.new()
		desc.text = item.unlock
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.modulate = Color(0.8, 0.8, 0.9)
		vbox.add_child(desc)
		
		grid.add_child(panel)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
