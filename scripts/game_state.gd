extends Node
# Simple persistent meta-progression + run-state container.

const SAVE_PATH := "user://save.json"

var gems: int = 0
var perm_damage_level: int = 0
var perm_atkspd_level: int = 0
var perm_pickup_radius_level: int = 0

# Run-time values (reset per run)
var run_gold: int = 0
var run_gun_level: int = 1
var run_magnet_level: int = 0
var run_orb_level: int = 0
var run_spike_ball_level: int = 0
var run_shotgun_level: int = 0
var run_sniper_level: int = 0
var run_rocket_level: int = 0

func _ready() -> void:
	load_save()

func reset_run() -> void:
	run_gold = 0
	run_gun_level = 1
	run_magnet_level = 0
	run_orb_level = 0
	run_spike_ball_level = 0
	run_shotgun_level = 0
	run_sniper_level = 0
	run_rocket_level = 0

func get_damage_multiplier() -> float:
	return 1.0 + 0.10 * float(perm_damage_level)

func get_atkspd_multiplier() -> float:
	return 1.0 + 0.10 * float(perm_atkspd_level)

func get_pickup_radius() -> float:
	var base := GameConstants.BASE_COLLECTION_RADIUS
	var perm := float(perm_pickup_radius_level) * GameConstants.PERM_COLLECTION_RADIUS_INCREMENT
	var run := float(run_magnet_level) * GameConstants.COLLECTION_RADIUS_UPGRADE_AMOUNT
	return base + perm + run

func get_gun_damage_bonus() -> int:
	return (run_gun_level - 1) * GameConstants.GUN_DAMAGE_PER_UPGRADE

func get_gun_atk_speed_mult() -> float:
	return 1.0 + float(run_gun_level - 1) * GameConstants.GUN_ATK_SPD_PER_UPGRADE

func get_orb_count() -> int:
	if run_orb_level >= 5: return 3
	if run_orb_level >= 3: return 2
	if run_orb_level >= 1: return 1
	return 0

func get_orb_speed() -> float:
	if run_orb_level >= 2: return GameConstants.ORB_UPGRADE_ROTATE_SPEED
	return GameConstants.ORB_BASE_ROTATE_SPEED

func get_shotgun_bullet_count() -> int:
	match run_shotgun_level:
		1: return 3
		2: return 5
		3: return 7
		4: return 9
	return 0

func get_sniper_cooldown() -> float:
	var cooldown = GameConstants.SNIPER_BASE_COOLDOWN - (run_sniper_level - 1) * GameConstants.SNIPER_COOLDOWN_REDUCTION_PER_LEVEL
	return max(0.5, cooldown)

func get_rocket_cooldown() -> float:
	var cooldown = GameConstants.ROCKET_BASE_COOLDOWN - (run_rocket_level - 1) * GameConstants.ROCKET_COOLDOWN_REDUCTION_PER_LEVEL
	return max(0.5, cooldown)

func get_rocket_blast_radius() -> float:
	return GameConstants.ROCKET_BASE_BLAST_RADIUS + (run_rocket_level - 1) * GameConstants.ROCKET_BLAST_RADIUS_PER_LEVEL

func award_gems(amount: int) -> void:
	gems += max(amount, 0)
	save()

func perm_damage_cost() -> int:
	return 10 + perm_damage_level * 10

func perm_atkspd_cost() -> int:
	return 10 + perm_atkspd_level * 10

func perm_pickup_radius_cost() -> int:
	return 10 + perm_pickup_radius_level * 10

func buy_perm_damage() -> bool:
	var cost := perm_damage_cost()
	if gems < cost:
		return false
	gems -= cost
	perm_damage_level += 1
	save()
	return true

func buy_perm_atkspd() -> bool:
	var cost := perm_atkspd_cost()
	if gems < cost:
		return false
	gems -= cost
	perm_atkspd_level += 1
	save()
	return true

func buy_perm_pickup_radius() -> bool:
	var cost := perm_pickup_radius_cost()
	if gems < cost:
		return false
	gems -= cost
	perm_pickup_radius_level += 1
	save()
	return true

func save() -> void:
	var data := {
		"gems": gems,
		"perm_damage_level": perm_damage_level,
		"perm_atkspd_level": perm_atkspd_level,
		"perm_pickup_radius_level": perm_pickup_radius_level
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var txt := f.get_as_text()
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	gems = int(parsed.get("gems", 0))
	perm_damage_level = int(parsed.get("perm_damage_level", 0))
	perm_atkspd_level = int(parsed.get("perm_atkspd_level", 0))
	perm_pickup_radius_level = int(parsed.get("perm_pickup_radius_level", 0))

