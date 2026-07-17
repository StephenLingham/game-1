extends Node2D

@export var ability_id: String = "orbs"
@export var damage_source: String = "orbs"
@export var base_damage: int = GameConstants.ORB_DAMAGE

var orb_scene := preload("res://scenes/orb.tscn")
var orbs: Array[Node2D] = []
var rotation_angle: float = 0.0

func _process(delta: float) -> void:
	# Keep the controller locked to world rotation so orbs don't spin with the player
	global_rotation = 0.0
	
	var target_count = _get_orb_count()
	
	# Update orb count if needed
	if orbs.size() != target_count:
		_refresh_orbs(target_count)
	
	if target_count == 0:
		return
		
	var current_damage = base_damage + GameState.get_weapon_damage_bonus(damage_source)
	for orb in orbs:
		if is_instance_valid(orb) and "damage" in orb:
			orb.damage = current_damage
	
	# Rotate
	rotation_angle += _get_orb_speed() * delta
	if rotation_angle > TAU:
		rotation_angle -= TAU
		
	# Position orbs
	for i in range(orbs.size()):
		var angle = rotation_angle + (i * TAU / float(max(1, orbs.size())))
		orbs[i].position = Vector2.RIGHT.rotated(angle) * GameConstants.ORB_RADIUS

func _get_orb_count() -> int:
	# For weapon-based orb controllers (like arcane_orbs) prefer per-weapon trait projectiles
	# but only if the player currently has the arcane_orbs ability unlocked for this run.
	if damage_source == "arcane_orbs":
		if GameState.run_abilities.get("arcane_orbs", 0) > 0:
			return GameState.get_weapon_projectiles("arcane_orbs")
		return 0

	# Legacy behavior: orb count based on ability level
	var lvl = GameState.run_abilities.get(ability_id, 0)
	if lvl >= 5:
		return 3
	if lvl >= 3:
		return 2
	if lvl >= 1:
		return 1
	return 0

func _get_orb_speed() -> float:
	var lvl = GameState.run_abilities.get(ability_id, 0)
	var attack_speed_mult := GameState.get_atkspd_multiplier()
	var player := get_tree().get_first_node_in_group("player")
	if player and "_atk_speed_boost_multiplier" in player:
		attack_speed_mult *= player._atk_speed_boost_multiplier
	if lvl >= 2:
		return GameConstants.ORB_UPGRADE_ROTATE_SPEED * attack_speed_mult
	return GameConstants.ORB_BASE_ROTATE_SPEED * attack_speed_mult

func _refresh_orbs(count: int) -> void:
	# Clear old
	for o in orbs:
		if is_instance_valid(o):
			o.queue_free()
	orbs.clear()
	
	# Spawn new
	for i in range(count):
		var orb = orb_scene.instantiate()
		if "weapon_source" in orb:
			orb.weapon_source = damage_source
		if "damage" in orb:
			orb.damage = base_damage + GameState.get_weapon_damage_bonus(damage_source)
		if damage_source == "arcane_orbs":
			orb.modulate = Color(0.75, 0.45, 1.0)
		else:
			orb.modulate = Color(0.0, 0.8, 1.0)
		add_child(orb)
		orbs.append(orb)
