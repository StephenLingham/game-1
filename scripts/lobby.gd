extends Control

@onready var lbl_gems: Label = $VBox/GemsLabel
@onready var btn_perm_dmg: Button = $VBox/PermDamage
@onready var btn_perm_spd: Button = $VBox/PermAtkSpd

func _ready() -> void:
	$VBox/Start.pressed.connect(_start)
	btn_perm_dmg.pressed.connect(_buy_perm_damage)
	btn_perm_spd.pressed.connect(_buy_perm_atkspd)
	_refresh()

func _refresh() -> void:
	lbl_gems.text = "Gems: %d" % GameState.gems
	btn_perm_dmg.text = "Permanent Damage (+10%%) - %d gems (lvl %d)" % [GameState.perm_damage_cost(), GameState.perm_damage_level]
	btn_perm_spd.text = "Permanent Attack Speed (+10%%) - %d gems (lvl %d)" % [GameState.perm_atkspd_cost(), GameState.perm_atkspd_level]

func _buy_perm_damage() -> void:
	if GameState.buy_perm_damage():
		_refresh()

func _buy_perm_atkspd() -> void:
	if GameState.buy_perm_atkspd():
		_refresh()

func _start() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

