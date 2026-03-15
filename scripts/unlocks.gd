extends Control

@onready var grid: GridContainer = $VBox/Scroll/Grid
@onready var back_btn: Button = $VBox/Footer/Back

const ITEMS = {
	"handgun": {"name": "Handgun", "unlock": "Unlocked by default"},
	"shotgun": {"name": "Shotgun", "unlock": "Kill 100 enemies with Handgun"},
	"sniper": {"name": "Sniper", "unlock": "Kill 100 enemies with Shotgun"},
	"rocket": {"name": "Rocket Launcher", "unlock": "Kill 100 enemies with Sniper"},
	"machine_gun": {"name": "Machine Gun", "unlock": "Kill 100 enemies with Rocket"},
	"magnet": {"name": "Magnet", "unlock": "Unlocked by default"},
	"orbs": {"name": "Energy Orbs", "unlock": "Upgrade Magnet once in a run"},
	"ice_wave": {"name": "Ice Wave", "unlock": "Upgrade Orbs once in a run"},
	"floor_spikes": {"name": "Floor Spikes", "unlock": "Upgrade Ice Wave once in a run"},
	"turret": {"name": "Turret", "unlock": "Upgrade Floor Spikes once in a run"},
	"bouncing_disk": {"name": "Bouncing Disk", "unlock": "Temporary Secret (Check back later!)"}
}

func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	_refresh_ui()

func _refresh_ui() -> void:
	for child in grid.get_children():
		child.queue_free()
	
	for id in ITEMS:
		var item = ITEMS[id]
		var is_unlocked = GameState.unlocked_items.has(id)
		
		var panel = PanelContainer.new()
		var vbox = VBoxContainer.new()
		panel.add_child(vbox)
		
		var title = Label.new()
		title.text = item.name if is_unlocked else "???"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(title)
		
		var status = Label.new()
		status.text = "UNLOCKED" if is_unlocked else "LOCKED"
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status.modulate = Color.GREEN if is_unlocked else Color.RED
		vbox.add_child(status)
		
		var desc = Label.new()
		desc.text = item.unlock
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.modulate = Color(0.7, 0.7, 0.7)
		vbox.add_child(desc)
		
		grid.add_child(panel)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
