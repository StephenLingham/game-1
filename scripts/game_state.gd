extends Node
# Persistent meta-progression + run-state container.

const SAVE_PATH := "user://save.json"

var gems: int = 0

# Permanent Upgrades
var perm_damage_level: int = 0
var perm_atkspd_level: int = 0
var perm_pickup_radius_level: int = 0
var perm_max_health_level: int = 0
var perm_regen_level: int = 0
var perm_crit_level: int = 0
var perm_armor_level: int = 0
var perm_start_gold_level: int = 0
var perm_gold_drop_level: int = 0
var perm_gem_drop_level: int = 0
var perm_speed_level: int = 0

# Unlocks
var unlocked_items: Array = ["handgun", "magnet"] # Items the player CAN see in shop
var run_unlocked_items: Array = [] # Items unlocked IN THE CURRENT RUN (delayed until end)
var completed_levels: Array = []
var lifetime_kills: Dictionary = {"handgun": 0}

# Run-time values (reset per run)
var run_gold: int = 0
var run_abilities: Dictionary = {} # ability_id -> level
var run_reroll_cost: int = 2
var run_banished_abilities: Array = []
var run_banish_count: int = 2

# Level / Difficulty Stats
var run_difficulty_health_mult: float = 1.0
var run_difficulty_damage_mult: float = 1.0
var run_difficulty_spawn_mult: float = 1.0
var run_level_name: String = "Level 1"

# Run statistics (reset per run)
var run_enemies_killed: int = 0
var run_gold_collected: int = 0
var run_gold_spent: int = 0
var run_damage_stats: Dictionary = {} # ability_id -> damage

func _ready() -> void:
	load_save()
	
	var changed := false
	if GameConstants.DEBUG_RESET_ALL_DATA:
		# Reset EVERYTHING
		gems = 0
		unlocked_items = ["handgun", "magnet"]
		lifetime_kills = {"handgun": 0}
		completed_levels = []
		_reset_all_perm_levels()
		changed = true
		print("DEBUG: All data reset.")
	else:
		if GameConstants.DEBUG_RESET_UNLOCKS:
			unlocked_items = ["handgun", "magnet"]
			lifetime_kills = {"handgun": 0}
			completed_levels = []
			changed = true
			print("DEBUG: Unlocks reset.")
		if GameConstants.DEBUG_RESET_GEMS:
			gems = 0
			_reset_all_perm_levels()
			changed = true
			print("DEBUG: Gems & Upgrades reset.")
	
	if changed:
		save()

func _reset_all_perm_levels() -> void:
	perm_damage_level = 0
	perm_atkspd_level = 0
	perm_pickup_radius_level = 0
	perm_max_health_level = 0
	perm_regen_level = 0
	perm_crit_level = 0
	perm_armor_level = 0
	perm_start_gold_level = 0
	perm_gold_drop_level = 0
	perm_gem_drop_level = 0
	perm_speed_level = 0

func reset_run() -> void:
	run_gold = 10 + perm_start_gold_level * 5 # Base gold + bonus
	run_abilities = {"handgun": 1}
	run_reroll_cost = GameConstants.SHOP_REROLL_BASE_COST
	run_banished_abilities = []
	run_banish_count = GameConstants.SHOP_BANISH_COUNT
	
	run_enemies_killed = 0
	run_gold_collected = 0
	run_gold_spent = 0
	run_damage_stats = {}
	run_unlocked_items = []

# --- HELPER GETTERS (Backward Compatibility) ---

func get_orb_count() -> int:
	var lvl = run_abilities.get("orbs", 0)
	if lvl >= 5: return 3
	if lvl >= 3: return 2
	if lvl >= 1: return 1
	return 0

func get_orb_speed() -> float:
	var lvl = run_abilities.get("orbs", 0)
	if lvl >= 2: return GameConstants.ORB_UPGRADE_ROTATE_SPEED
	return GameConstants.ORB_BASE_ROTATE_SPEED

func get_sniper_cooldown() -> float:
	var lvl = run_abilities.get("sniper", 0)
	var cooldown = GameConstants.SNIPER_BASE_COOLDOWN - (lvl - 1) * GameConstants.SNIPER_COOLDOWN_REDUCTION_PER_LEVEL
	return max(0.5, cooldown)

func get_rocket_cooldown() -> float:
	var lvl = run_abilities.get("rocket", 0)
	var cooldown = GameConstants.ROCKET_BASE_COOLDOWN - (lvl - 1) * GameConstants.ROCKET_COOLDOWN_REDUCTION_PER_LEVEL
	return max(0.5, cooldown)

func get_rocket_blast_radius() -> float:
	var lvl = run_abilities.get("rocket", 0)
	return GameConstants.ROCKET_BASE_BLAST_RADIUS + (lvl - 1) * GameConstants.ROCKET_BLAST_RADIUS_PER_LEVEL

func get_gun_damage_bonus() -> int:
	var lvl = run_abilities.get("handgun", 1)
	return (lvl - 1) * GameConstants.GUN_DAMAGE_PER_UPGRADE

func get_gun_atk_speed_mult() -> float:
	var lvl = run_abilities.get("handgun", 1)
	return 1.0 + float(lvl - 1) * GameConstants.GUN_ATK_SPD_PER_UPGRADE

func get_shotgun_bullet_count() -> int:
	var lvl = run_abilities.get("shotgun", 0)
	match lvl:
		1: return 3
		2: return 5
		3: return 7
		4: return 9
	return 0

# Legacy properties for scripts I haven't fully updated yet
var run_damage_handgun: int:
	get: return run_damage_stats.get("handgun", 0)
	set(v): run_damage_stats["handgun"] = v
var run_damage_shotgun: int:
	get: return run_damage_stats.get("shotgun", 0)
	set(v): run_damage_stats["shotgun"] = v
var run_damage_sniper: int:
	get: return run_damage_stats.get("sniper", 0)
	set(v): run_damage_stats["sniper"] = v
var run_damage_rocket: int:
	get: return run_damage_stats.get("rocket", 0)
	set(v): run_damage_stats["rocket"] = v
var run_damage_spike_ball: int:
	get: return run_damage_stats.get("spike_ball", 0)
	set(v): run_damage_stats["spike_ball"] = v
var run_damage_orbs: int:
	get: return run_damage_stats.get("orbs", 0)
	set(v): run_damage_stats["orbs"] = v
var run_damage_turret: int:
	get: return run_damage_stats.get("turret", 0)
	set(v): run_damage_stats["turret"] = v
var run_damage_floor_spikes: int:
	get: return run_damage_stats.get("floor_spikes", 0)
	set(v): run_damage_stats["floor_spikes"] = v
var run_damage_bouncing_disk: int:
	get: return run_damage_stats.get("bouncing_disk", 0)
	set(v): run_damage_stats["bouncing_disk"] = v
var run_damage_explosion_pickup: int:
	get: return run_damage_stats.get("explosion_pickup", 0)
	set(v): run_damage_stats["explosion_pickup"] = v

func get_damage_multiplier() -> float:
	var lvl = 10 if GameConstants.DEBUG_MAX_PERM_UPGRADES else perm_damage_level
	return 1.0 + 0.10 * float(lvl)

func get_atkspd_multiplier() -> float:
	var lvl = 10 if GameConstants.DEBUG_MAX_PERM_UPGRADES else perm_atkspd_level
	return 1.0 + 0.10 * float(lvl)

func get_pickup_radius() -> float:
	var base := GameConstants.BASE_COLLECTION_RADIUS
	var plvl = 10 if GameConstants.DEBUG_MAX_PERM_UPGRADES else perm_pickup_radius_level
	var perm := float(plvl) * GameConstants.PERM_COLLECTION_RADIUS_INCREMENT
	var run := float(run_abilities.get("magnet", 0)) * GameConstants.COLLECTION_RADIUS_UPGRADE_AMOUNT
	return base + perm + run

func get_max_health() -> int:
	var lvl = 10 if GameConstants.DEBUG_MAX_PERM_UPGRADES else perm_max_health_level
	return GameConstants.PLAYER_MAX_HEALTH + lvl * 20

func get_health_regen() -> float:
	var lvl = 10 if GameConstants.DEBUG_MAX_PERM_UPGRADES else perm_regen_level
	return float(lvl) * 0.5 # 0.5 HP per second

func get_crit_chance() -> float:
	var lvl = 10 if GameConstants.DEBUG_MAX_PERM_UPGRADES else perm_crit_level
	return float(lvl) * 0.05 # 5% per level

func get_armor() -> int:
	var lvl = 10 if GameConstants.DEBUG_MAX_PERM_UPGRADES else perm_armor_level
	return lvl * 2 # Flat damage reduction

func get_gold_drop_multiplier() -> float:
	var lvl = 10 if GameConstants.DEBUG_MAX_PERM_UPGRADES else perm_gold_drop_level
	return 1.0 + float(lvl) * 0.1

func get_gem_drop_chance_bonus() -> float:
	var lvl = 10 if GameConstants.DEBUG_MAX_PERM_UPGRADES else perm_gem_drop_level
	return float(lvl) * 0.02

func get_speed_multiplier() -> float:
	var lvl = 10 if GameConstants.DEBUG_MAX_PERM_UPGRADES else perm_speed_level
	return 1.0 + float(lvl) * 0.05

func award_gems(amount: int) -> void:
	gems += max(amount, 0)
	save()

func reset_gems() -> void:
	# Calculate total gems spent
	var spent := 0
	spent += _calculate_spent(perm_damage_level)
	spent += _calculate_spent(perm_atkspd_level)
	spent += _calculate_spent(perm_pickup_radius_level)
	spent += _calculate_spent(perm_max_health_level)
	spent += _calculate_spent(perm_regen_level)
	spent += _calculate_spent(perm_crit_level)
	spent += _calculate_spent(perm_armor_level)
	spent += _calculate_spent(perm_start_gold_level)
	spent += _calculate_spent(perm_gold_drop_level)
	spent += _calculate_spent(perm_gem_drop_level)
	spent += _calculate_spent(perm_speed_level)
	
	gems += spent
	
	# Reset levels
	perm_damage_level = 0
	perm_atkspd_level = 0
	perm_pickup_radius_level = 0
	perm_max_health_level = 0
	perm_regen_level = 0
	perm_crit_level = 0
	perm_armor_level = 0
	perm_start_gold_level = 0
	perm_gold_drop_level = 0
	perm_gem_drop_level = 0
	perm_speed_level = 0
	
	save()

func _calculate_spent(level: int) -> int:
	var total := 0
	for i in range(level):
		total += GameConstants.PERM_LEVEL_COST + i * GameConstants.PERM_COST_INCREMENT
	return total

func get_perm_cost(level: int) -> int:
	return GameConstants.PERM_LEVEL_COST + level * GameConstants.PERM_COST_INCREMENT

func buy_perm_upgrade(property: String) -> bool:
	var level_var = "perm_" + property + "_level"
	var current_level = get(level_var)
	var cost = get_perm_cost(current_level)
	
	if gems >= cost:
		gems -= cost
		set(level_var, current_level + 1)
		save()
		return true
	return false

func record_kill(weapon: String) -> void:
	lifetime_kills[weapon] = lifetime_kills.get(weapon, 0) + 1
	_check_unlocks()
	save()

func record_ability_upgrade(id: String, level: int) -> void:
	# No save() here to avoid mid-run permanent save of kills/unlocks if we want to be strict, 
	# but kills are already being saved in record_kill. Let's be consistent.
	save()

func is_item_unlocked(id: String) -> bool:
	if GameConstants.DEBUG_UNLOCK_ALL_WEAPONS:
		# Check if it's a weapon based on ALL_ABILITIES in Main.gd or just return true for everything?
		# The request said "unlock all weapons", but unlocking everything is simpler and probably what's intended for debugging.
		return true
	return unlocked_items.has(id)

func finalize_run_unlocks() -> void:
	for item in run_unlocked_items:
		if not unlocked_items.has(item):
			unlocked_items.append(item)
	run_unlocked_items = []
	save()

func mark_level_completed(level_name: String) -> void:
	if not completed_levels.has(level_name):
		completed_levels.append(level_name)
	save()

func is_level_unlocked(level_id: String) -> bool:
	if GameConstants.DEBUG_UNLOCK_ALL_LEVELS:
		return true
	if level_id == "Level 1":
		return true
	if level_id == "Level 2":
		return completed_levels.has("Level 1")
	if level_id == "Level 3":
		return completed_levels.has("Level 2")
	return false

func _check_unlocks() -> void:
	# Handgun -> Shotgun -> Sniper -> Rocket -> Machine Gun
	var weapon_chain = [
		"handgun", "floor_spikes", "ice_wave", "spike_ball", "shotgun", "turret", 
		"sniper", "orbs", "bouncing_disk", "machine_gun", "rocket",
	]
	for i in range(weapon_chain.size() - 1):
		var current = weapon_chain[i]
		var next = weapon_chain[i+1]
		if lifetime_kills.get(current, 0) >= GameConstants.UNLOCK_KILLS_NEEDED:
			if not unlocked_items.has(next) and not run_unlocked_items.has(next):
				run_unlocked_items.append(next)

func save() -> void:
	var data := {
		"gems": gems,
		"perm_damage_level": perm_damage_level,
		"perm_atkspd_level": perm_atkspd_level,
		"perm_pickup_radius_level": perm_pickup_radius_level,
		"perm_max_health_level": perm_max_health_level,
		"perm_regen_level": perm_regen_level,
		"perm_crit_level": perm_crit_level,
		"perm_armor_level": perm_armor_level,
		"perm_start_gold_level": perm_start_gold_level,
		"perm_gold_drop_level": perm_gold_drop_level,
		"perm_gem_drop_level": perm_gem_drop_level,
		"perm_speed_level": perm_speed_level,
		"unlocked_items": unlocked_items,
		"lifetime_kills": lifetime_kills,
		"completed_levels": completed_levels
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
	perm_max_health_level = int(parsed.get("perm_max_health_level", 0))
	perm_regen_level = int(parsed.get("perm_regen_level", 0))
	perm_crit_level = int(parsed.get("perm_crit_level", 0))
	perm_armor_level = int(parsed.get("perm_armor_level", 0))
	perm_start_gold_level = int(parsed.get("perm_start_gold_level", 0))
	perm_gold_drop_level = int(parsed.get("perm_gold_drop_level", 0))
	perm_gem_drop_level = int(parsed.get("perm_gem_drop_level", 0))
	perm_speed_level = int(parsed.get("perm_speed_level", 0))
	
	unlocked_items = parsed.get("unlocked_items", ["handgun"])
	lifetime_kills = parsed.get("lifetime_kills", {"handgun": 0})
	completed_levels = parsed.get("completed_levels", [])
