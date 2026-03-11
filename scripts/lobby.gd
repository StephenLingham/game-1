extends Control

@onready var lbl_gems: Label = $VBox/GemsLabel
@onready var btn_perm_dmg: Button = $VBox/PermDamage
@onready var btn_perm_spd: Button = $VBox/PermAtkSpd
var btn_perm_radius: Button

func _ready() -> void:
	$VBox/Start.pressed.connect(_start)
	$VBox/Exit.pressed.connect(_exit_game)
	btn_perm_dmg.pressed.connect(_buy_perm_damage)
	btn_perm_spd.pressed.connect(_buy_perm_atkspd)
	
	# Add radius upgrade button if it doesn't exist
	if not has_node("VBox/PermRadius"):
		btn_perm_radius = Button.new()
		btn_perm_radius.name = "PermRadius"
		$VBox.add_child(btn_perm_radius)
		# Move it before the Start button
		$VBox.move_child(btn_perm_radius, $VBox/Start.get_index())
	else:
		btn_perm_radius = $VBox/PermRadius
		
	btn_perm_radius.pressed.connect(_buy_perm_radius)
	_refresh()

func _refresh() -> void:
	lbl_gems.text = "Gems: %d" % GameState.gems
	btn_perm_dmg.text = "Permanent Damage (+10%%) - %d gems (lvl %d)" % [GameState.perm_damage_cost(), GameState.perm_damage_level]
	btn_perm_spd.text = "Permanent Attack Speed (+10%%) - %d gems (lvl %d)" % [GameState.perm_atkspd_cost(), GameState.perm_atkspd_level]
	btn_perm_radius.text = "Permanent Pickup Radius (+%dpx) - %d gems (lvl %d)" % [GameConstants.PERM_COLLECTION_RADIUS_INCREMENT, GameState.perm_pickup_radius_cost(), GameState.perm_pickup_radius_level]

func _buy_perm_damage() -> void:
	if GameState.buy_perm_damage():
		_refresh()

func _buy_perm_atkspd() -> void:
	if GameState.buy_perm_atkspd():
		_refresh()

func _buy_perm_radius() -> void:
	if GameState.buy_perm_pickup_radius():
		_refresh()

func _start() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _exit_game() -> void:
	get_tree().quit()

