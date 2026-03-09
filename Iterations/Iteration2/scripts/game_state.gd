extends Node
# Simple persistent meta-progression + run-state container.

const SAVE_PATH := "user://save.json"

var gems: int = 0
var perm_damage_level: int = 0
var perm_atkspd_level: int = 0

# Run-time values (reset per run)
var run_gold: int = 0
var run_damage_bonus: int = 0          # flat bonus (shop)
var run_atkspd_mult: float = 1.0       # multiplicative (shop)

func _ready() -> void:
	load_save()

func reset_run() -> void:
	run_gold = 0
	run_damage_bonus = 0
	run_atkspd_mult = 1.0

func get_damage_multiplier() -> float:
	return 1.0 + 0.10 * float(perm_damage_level)

func get_atkspd_multiplier() -> float:
	return 1.0 + 0.10 * float(perm_atkspd_level)

func award_gems(amount: int) -> void:
	gems += max(amount, 0)
	save()

func perm_damage_cost() -> int:
	return 10 + perm_damage_level * 10

func perm_atkspd_cost() -> int:
	return 10 + perm_atkspd_level * 10

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

func save() -> void:
	var data := {
		"gems": gems,
		"perm_damage_level": perm_damage_level,
		"perm_atkspd_level": perm_atkspd_level
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
	var parsed := JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	gems = int(parsed.get("gems", 0))
	perm_damage_level = int(parsed.get("perm_damage_level", 0))
	perm_atkspd_level = int(parsed.get("perm_atkspd_level", 0))
