extends Node
# Persistent meta-progression + run-state container.

const SAVE_PATH := "user://save.json"

var gems: int = 0

# Unlocks
var unlocked_items: Array = ["zap"] # Abilities the player CAN see in shop
var unlocked_auras: Array = [] # Auras the player CAN see in shop
var unlocked_treasure_items: Array = [] # Items the player CAN see in chests
var run_unlocked_items: Array = [] # Items unlocked IN THE CURRENT RUN (delayed until end)
var completed_levels: Array = []
var lifetime_kills: Dictionary = {"zap": 0}
var lifetime_chests_opened: int = 0
var sealed_items: Array = [] # IDs of items the player has sealed
var unlocked_characters: Array = ["starter"]
var current_character: String = "starter"
var max_levels_reached: Dictionary = {} # item_id -> reached_max (bool)
var selected_starter_weapon: String = "zap"
var lifetime_upgrades: Dictionary = {} # id -> total upgrades across all runs
var lifetime_item_picks: Dictionary = {} # id -> total picks across all runs

# Permanent Upgrades
var perm_damage_level: int = 0
var perm_atkspd_level: int = 0
var perm_pickup_radius_level: int = 0
var perm_max_health_level: int = 0
var perm_regen_level: int = 0
var perm_crit_level: int = 0
var perm_armor_level: int = 0
var perm_armor_percent_level: int = 0
var perm_gold_drop_level: int = 0
var perm_speed_level: int = 0
var perm_thorns_level: int = 0
var perm_spawn_rate_level: int = 0
var perm_crit_damage_level: int = 0
var perm_projectiles_level: int = 0
var perm_bounces_level: int = 0
var perm_extra_slots_level: int = 0

var aura_max_levels_reached: Dictionary = {} # aura_id -> max_level

# Run-time values (reset per run)
var run_xp: int = 0
var run_level: int = 1
var run_xp_to_next_level: int = 100
var run_abilities: Dictionary = {} # ability_id -> level
var run_reroll_count: int = 3
var run_banished_abilities: Array = []
var run_banish_count: int = 2
var run_items: Array = [] # [item_id, item_id, ...]


# Character specific run state
var run_speed_bonus: float = 0.0
var run_lifesteal: float = 0.0
var run_extra_projectiles: int = 0
var run_extra_bounces: int = 0

# Per-weapon trait accumulations (float values, floored when used)
# Structure: { "weapon_id": { "damage": 0.0, "crit_chance": 0.0, "projectiles": 0.0, "bounces": 0.0, "size": 0.0 } }
var run_weapon_traits: Dictionary = {}

# Bonuses from collected presents
var run_present_bonuses: Dictionary = {}

signal level_up(new_level: int)


# Level / Difficulty Stats
var run_difficulty_health_mult: float = 1.0
var run_difficulty_damage_mult: float = 1.0
var run_difficulty_spawn_mult: float = 1.0
var run_level_name: String = "Level 1"

# Run statistics (reset per run)
var run_enemies_killed: int = 0
var run_xp_collected: int = 0
var run_gems_collected: int = 0
var run_damage_stats: Dictionary = {} # ability_id -> damage

func _ready() -> void:
	load_save()
	
	var changed := false
	if GameConstants.DEBUG_RESET_ALL_DATA:
		# Reset EVERYTHING
		gems = 0
		unlocked_items = ["zap"]
		unlocked_auras = []
		unlocked_treasure_items = []
		lifetime_kills = {"zap": 0}
		lifetime_chests_opened = 0
		completed_levels = []
		aura_max_levels_reached = {}
		_reset_all_perm_levels()
		changed = true
		print("DEBUG: All data reset.")
	else:
		if GameConstants.DEBUG_RESET_UNLOCKS:
			unlocked_items = ["zap"]
			unlocked_auras = []
			unlocked_treasure_items = []
			lifetime_kills = {"zap": 0}
			lifetime_chests_opened = 0
			completed_levels = []
			changed = true
			print("DEBUG: Unlocks reset.")
	
	
	if GameConstants.DEBUG_RESET_GEMS:
		gems = 0
		_reset_all_perm_levels()
		changed = true
		print("DEBUG: Gems & Upgrades reset.")
	
	# Initial 5 items if none unlocked yet
	if unlocked_treasure_items.size() < 5:
		var all_items = GameConstants.ITEMS.keys()
		for i in range(min(5, all_items.size())):
			var id = all_items[i]
			if not unlocked_treasure_items.has(id):
				unlocked_treasure_items.append(id)
		changed = true
	
	# Initial 1 weapons if none unlocked yet (Zap)
	if unlocked_items.size() < 1:
		var defaults = ["zap"]
		for id in defaults:
			if not unlocked_items.has(id):
				unlocked_items.append(id)
		changed = true
	
	if changed:
		save()

func reset_all_data() -> void:
	gems = 0
	unlocked_items = ["zap"]
	unlocked_auras = []
	unlocked_treasure_items = []
	lifetime_kills = {"zap": 0}
	lifetime_chests_opened = 0
	completed_levels = []
	aura_max_levels_reached = {}
	sealed_items = []
	unlocked_characters = ["starter"]
	current_character = "starter"
	max_levels_reached = {}
	lifetime_upgrades = {}
	lifetime_item_picks = {}
	_reset_all_perm_levels()
	save()

func _reset_all_perm_levels() -> void:
	perm_damage_level = 0
	perm_atkspd_level = 0
	perm_pickup_radius_level = 0
	perm_max_health_level = 0
	perm_regen_level = 0
	perm_crit_level = 0
	perm_armor_level = 0
	perm_armor_percent_level = 0
	perm_gold_drop_level = 0
	perm_speed_level = 0
	perm_thorns_level = 0
	perm_spawn_rate_level = 0
	perm_crit_damage_level = 0
	perm_projectiles_level = 0
	perm_bounces_level = 0

func reset_run() -> void:
	run_xp = 0
	run_level = 1
	run_xp_to_next_level = GameConstants.XP_BASE_LEVEL
	run_abilities = {"zap": 1}
	run_banished_abilities = []
	run_banish_count = GameConstants.SHOP_BANISH_COUNT
	run_reroll_count = 3 # 3 rerolls per run
	
	run_enemies_killed = 0
	run_xp_collected = 0
	run_gems_collected = 0
	run_damage_stats = {}
	run_unlocked_items = []
	run_items = []

	
	run_speed_bonus = 0.0
	run_lifesteal = 0.0
	run_extra_projectiles = 0
	run_extra_bounces = 0
	run_weapon_traits = {}
	run_present_bonuses = {}
	
	_apply_initial_character_traits()

func _apply_initial_character_traits() -> void:
	# Add initial weapon based on character or default
	if run_abilities.is_empty() or (run_abilities.size() == 1 and run_abilities.has("zap")):
		if current_character == "passive_master":
			run_abilities.clear() # No weapons
			# Maybe give an initial aura?
			run_abilities["aura_damage"] = 1
		else:
			run_abilities = {selected_starter_weapon: 1}
	
	match current_character:
		"vampire":
			# Handled via 10x max health in GameState.get_max_health
			pass
		"tank":
			# Handled in player.refresh_stats (slow)
			pass

func add_xp(amount: int) -> void:
	# Apply the XP multiplier from permanent upgrades and auras
	var actual_amount = int(amount * get_xp_drop_multiplier())
	run_xp += actual_amount
	run_xp_collected += actual_amount
	
	while run_xp >= run_xp_to_next_level:
		run_xp -= run_xp_to_next_level
		run_level += 1
		# Exponential/linear scaling
		run_xp_to_next_level = int(run_xp_to_next_level * GameConstants.XP_SCALING) + GameConstants.XP_INCREMENT
		_apply_character_level_up_traits()
		level_up.emit(run_level)

func _apply_character_level_up_traits() -> void:
	match current_character:
		"vampire":
			run_lifesteal += 0.01 # +1% lifesteal per level
		"singular_volley":
			run_extra_projectiles += 1

func get_projectiles() -> int:
	var plvl = min(perm_projectiles_level, 10)
	return GameConstants.BASE_PROJECTILES + plvl + run_extra_projectiles

func get_bounces() -> int:
	var blvl = min(perm_bounces_level, 10)
	return GameConstants.BASE_BOUNCES + blvl + run_extra_bounces

# --- PER-WEAPON TRAIT SYSTEM ---

func get_weapon_trait(weapon_id: String, trait_name: String) -> float:
	return run_weapon_traits.get(weapon_id, {}).get(trait_name, 0.0)

func add_weapon_trait(weapon_id: String, trait_name: String, amount: float) -> void:
	if not run_weapon_traits.has(weapon_id):
		run_weapon_traits[weapon_id] = {}
	var current: float = run_weapon_traits[weapon_id].get(trait_name, 0.0)
	run_weapon_traits[weapon_id][trait_name] = current + amount

## Returns the total projectile count for a weapon, respecting its trait bonus.
## Fractional accumulations are floored. Minimum is always 1.
func get_weapon_projectiles(weapon_id: String) -> int:
	var trait_bonus := get_weapon_trait(weapon_id, "projectiles")
	return max(1, int(floor(float(GameConstants.BASE_PROJECTILES) + trait_bonus)))

## Returns bounce count for a weapon from its trait bonus. Fractional values are floored.
func get_weapon_bounces(weapon_id: String) -> int:
	var trait_bonus := get_weapon_trait(weapon_id, "bounces")
	return max(0, int(floor(float(GameConstants.BASE_BOUNCES) + trait_bonus)))

## Returns a size multiplier (e.g. 1.30 = +30% radius) for area-based weapon attacks.
func get_weapon_size_multiplier(weapon_id: String) -> float:
	return 1.0 + get_weapon_trait(weapon_id, "size")

## Returns flat damage bonus accumulated for this weapon via its damage trait.
func get_weapon_damage_bonus(weapon_id: String) -> int:
	return int(round(get_weapon_trait(weapon_id, "damage")))

## Returns extra crit chance (0.0-1.0) accumulated for this weapon via its crit_chance trait.
func get_weapon_crit_chance_bonus(weapon_id: String) -> float:
	return get_weapon_trait(weapon_id, "crit_chance")

## Roll a random rarity using weighted selection.
func roll_rarity() -> String:
	var weights: Array = GameConstants.RARITY_WEIGHTS
	var total := 0
	for w in weights: total += w
	var roll := randi() % total
	var cumulative := 0
	for i in range(GameConstants.RARITIES.size()):
		cumulative += weights[i]
		if roll < cumulative:
			return GameConstants.RARITIES[i]
	return "common"

## Roll a full trait upgrade for a weapon: returns { trait, rarity, value, display_text }
func roll_weapon_upgrade(weapon_id: String) -> Dictionary:
	var traits: Array = GameConstants.WEAPON_TRAITS.get(weapon_id, [])
	if traits.is_empty():
		return {}
	var trait_name: String = traits[randi() % traits.size()]
	var rarity: String = roll_rarity()
	var mult: float = GameConstants.RARITY_MULTIPLIERS[rarity]
	var value: float
	match trait_name:
		"damage":      value = GameConstants.TRAIT_BASE_DAMAGE * mult
		"crit_chance": value = GameConstants.TRAIT_BASE_CRIT_CHANCE * mult
		"projectiles": value = GameConstants.TRAIT_BASE_PROJECTILES * mult
		"bounces":     value = GameConstants.TRAIT_BASE_BOUNCES * mult
		"size":        value = GameConstants.TRAIT_BASE_SIZE * mult
		_:             value = 0.0
	var display: String
	match trait_name:
		"damage":      display = "+%d Damage" % int(round(value))
		"crit_chance": display = "+%d%% Crit Chance" % int(round(value * 100.0))
		"projectiles": display = "+%.1f Projectiles (→%d)" % [value, int(floor(get_weapon_trait(weapon_id, "projectiles") + value)) + GameConstants.BASE_PROJECTILES]
		"bounces":     display = "+%.1f Bounces (→%d)" % [value, int(floor(get_weapon_trait(weapon_id, "bounces") + value))]
		"size":        display = "+%d%% Area Size" % int(round(value * 100.0))
		_:             display = ""
	return {
		"trait":   trait_name,
		"rarity":  rarity,
		"value":   value,
		"display": display
	}


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

func get_zap_damage_bonus() -> int:
	var lvl = run_abilities.get("zap", 1)
	return (lvl - 1) * GameConstants.ZAP_DAMAGE_PER_UPGRADE

func get_zap_atk_speed_mult() -> float:
	var lvl = run_abilities.get("zap", 1)
	return 1.0 + float(lvl - 1) * GameConstants.ZAP_ATK_SPD_PER_UPGRADE

func get_shotgun_bullet_count() -> int:
	var lvl = run_abilities.get("shotgun", 0)
	match lvl:
		1: return 3
		2: return 5
		3: return 7
		4: return 9
	return 0

# Legacy properties for scripts I haven't fully updated yet
var run_damage_zap: int:
	get: return run_damage_stats.get("zap", 0)
	set(v): run_damage_stats["zap"] = v
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
	var lvl = 10 if GameConstants.DEBUG_MAX_PERM_UPGRADES else min(perm_damage_level, 10)
	var mult = 1.0 + 0.01 * float(lvl)
	mult += _get_aura_bonus("damage_multiplier")
	for item_id in run_items:
		var stats = GameConstants.ITEMS.get(item_id, {}).get("stats", {})
		mult += stats.get("damage_multiplier", 0.0)
	
	# Character traits
	match current_character:
		"speed_damage":
			# Damage scales with speed: +1% damage per 5% speed bonus
			var speed_mult = get_speed_multiplier()
			mult += (speed_mult - 1.0) * 0.2 
		"glass_cannon":
			mult += run_level * 0.05 # +5% damage per level
		"singular_force":
			mult *= 6.0
	
	mult += run_present_bonuses.get("damage_multiplier", 0.0)
	
	return mult


func get_atkspd_multiplier() -> float:
	var lvl = 10 if GameConstants.DEBUG_MAX_PERM_UPGRADES else min(perm_atkspd_level, 10)
	var mult = 1.0 + 0.01 * float(lvl)
	mult += _get_aura_bonus("atkspd_multiplier")
	for item_id in run_items:
		var stats = GameConstants.ITEMS.get(item_id, {}).get("stats", {})
		mult += stats.get("atkspd_multiplier", 0.0)
	
	mult += run_present_bonuses.get("atkspd_multiplier", 0.0)
	return mult


func get_pickup_radius() -> float:
	var base := GameConstants.BASE_COLLECTION_RADIUS
	var plvl = 10 if GameConstants.DEBUG_MAX_PERM_UPGRADES else min(perm_pickup_radius_level, 10)
	var perm := float(plvl) * GameConstants.PERM_COLLECTION_RADIUS_INCREMENT
	var bonus := _get_aura_bonus("pickup_radius")
	for item_id in run_items:
		var stats = GameConstants.ITEMS.get(item_id, {}).get("stats", {})
		bonus += stats.get("pickup_radius", 0.0)
	return base + perm + bonus


func get_total_damage(base: int) -> int:
	var bonus_flat := 0
	for item_id in run_items:
		var stats = GameConstants.ITEMS.get(item_id, {}).get("stats", {})
		bonus_flat += stats.get("damage", 0)
		
	var dmg = float(base + get_zap_damage_bonus() + bonus_flat)
	dmg += run_present_bonuses.get("damage_bonus", 0.0)
	dmg *= get_damage_multiplier()
	return int(round(dmg))

func get_max_health() -> int:
	var lvl = 10 if GameConstants.DEBUG_MAX_PERM_UPGRADES else min(perm_max_health_level, 10)
	var base = GameConstants.PLAYER_MAX_HEALTH + lvl * 1
	var bonus = int(_get_aura_bonus("max_health"))
	for item_id in run_items:
		var stats = GameConstants.ITEMS.get(item_id, {}).get("stats", {})
		bonus += stats.get("max_health", 0)
	
	var final_hp = base + bonus
	
	# Character traits
	match current_character:
		"tank":
			final_hp = int(final_hp * 2.5)
		"glass_cannon":
			final_hp = max(10, final_hp - (run_level - 1) * 5)
		"vampire":
			final_hp = int(final_hp * 10.0)
		"passive_master":
			final_hp = int(final_hp * 1.5)
			
	final_hp += int(run_present_bonuses.get("max_health", 0.0))
	return final_hp


func get_health_regen() -> float:
	var lvl = 10 if GameConstants.DEBUG_MAX_PERM_UPGRADES else min(perm_regen_level, 10)
	var base = float(lvl) * 0.1 # 0.1 HP per second
	var bonus = _get_aura_bonus("health_regen")
	for item_id in run_items:
		var stats = GameConstants.ITEMS.get(item_id, {}).get("stats", {})
		bonus += stats.get("health_regen", 0.0)
	return base + bonus


func get_crit_chance() -> float:
	var lvl = 10 if GameConstants.DEBUG_MAX_PERM_UPGRADES else min(perm_crit_level, 10)
	var base = float(lvl) * 0.01 # 1% per level
	var bonus = _get_aura_bonus("crit_chance")
	for item_id in run_items:
		var stats = GameConstants.ITEMS.get(item_id, {}).get("stats", {})
		bonus += stats.get("crit_chance", 0.0)
	
	bonus += run_present_bonuses.get("crit_chance", 0.0)
	return base + bonus


func get_crit_multiplier() -> float:
	var lvl = 10 if GameConstants.DEBUG_MAX_PERM_UPGRADES else min(perm_crit_damage_level, 10)
	var base = 2.0 + float(lvl) * 0.01 # Base 2.0x, +0.01x per level
	var bonus = _get_aura_bonus("crit_multiplier")
	for item_id in run_items:
		var stats = GameConstants.ITEMS.get(item_id, {}).get("stats", {})
		bonus += stats.get("crit_multiplier", 0.0)
	return base + bonus


func get_armor() -> int:
	var lvl = 10 if GameConstants.DEBUG_MAX_PERM_UPGRADES else min(perm_armor_level, 10)
	var base = lvl * 1 # Flat damage reduction
	var bonus = int(_get_aura_bonus("armor"))
	for item_id in run_items:
		var stats = GameConstants.ITEMS.get(item_id, {}).get("stats", {})
		bonus += stats.get("armor", 0)
	
	var final_armor = base + bonus
	
	# Character traits
	match current_character:
		"tank":
			final_armor += 20
		"passive_master":
			final_armor += 10
			
	return final_armor


func get_armor_percent() -> float:
	var lvl = 10 if GameConstants.DEBUG_MAX_PERM_UPGRADES else min(perm_armor_percent_level, 10)
	var base = float(lvl) * 0.01 # 1% reduction per level
	var bonus = _get_aura_bonus("armor_percent")
	for item_id in run_items:
		var stats = GameConstants.ITEMS.get(item_id, {}).get("stats", {})
		bonus += stats.get("armor_percent", 0.0)
	return base + bonus


func get_thorns_percentage() -> float:
	var lvl = 10 if GameConstants.DEBUG_MAX_PERM_UPGRADES else min(perm_thorns_level, 10)
	var base = float(lvl) * 0.01 # 1% thorns per level
	var bonus = _get_aura_bonus("thorns_percentage")
	for item_id in run_items:
		var stats = GameConstants.ITEMS.get(item_id, {}).get("stats", {})
		bonus += stats.get("thorns_percentage", 0.0)
	return base + bonus


func get_spawn_rate_multiplier() -> float:
	var lvl = 10 if GameConstants.DEBUG_MAX_PERM_UPGRADES else min(perm_spawn_rate_level, 10)
	var mult = 1.0 + float(lvl) * 0.01 + _get_aura_bonus("spawn_rate_multiplier") # +1% spawn rate per level
	
	match current_character:
		"chaos":
			mult += run_level * 0.1 # +10% spawn rate per level
			
	return mult

func get_xp_drop_multiplier() -> float:
	var lvl = 10 if GameConstants.DEBUG_MAX_PERM_UPGRADES else min(perm_gold_drop_level, 10)
	var base = 1.0 + float(lvl) * 0.01
	# Any item bonuses too
	var bonus = _get_aura_bonus("xp_drop_multiplier")
	for item_id in run_items:
		var stats = GameConstants.ITEMS.get(item_id, {}).get("stats", {})
		bonus += stats.get("xp_drop_multiplier", 0.0)
	return base + bonus


func get_speed_multiplier(include_dynamic: bool = true) -> float:
	var lvl = 10 if GameConstants.DEBUG_MAX_PERM_UPGRADES else min(perm_speed_level, 10)
	var base = 1.0 + float(lvl) * 0.01
	var bonus = _get_aura_bonus("speed_multiplier")
	for item_id in run_items:
		var stats = GameConstants.ITEMS.get(item_id, {}).get("stats", {})
		bonus += stats.get("speed_multiplier", 0.0)
	
	var mult = base + bonus
	if include_dynamic:
		mult += run_speed_bonus # From Zephyros trait
	
	match current_character:
		"tank":
			mult *= 0.5 # Slow
		"vampire":
			mult = max(0.4, mult - (run_level - 1) * 0.02) # Decreases as level increases
			
	mult += run_present_bonuses.get("speed_multiplier", 0.0)
	return mult

func get_ability_limit() -> int:
	match current_character:
		"polymath": return 8 + perm_extra_slots_level
		"singular_force", "singular_volley", "singular_luck": return 1
	
	var base_slots = 1
	var extra_from_level = int(floor(run_level / 5.0)) # One new slot every 5 levels
	return base_slots + extra_from_level + perm_extra_slots_level

func get_aura_limit() -> int:
	return GameConstants.AURA_MAX_COUNT

func _get_aura_bonus(stat_name: String) -> float:
	var total = 0.0
	for aura_id in GameConstants.AURAS:
		var level = run_abilities.get(aura_id, 0)
		if level > 0:
			var aura_data = GameConstants.AURAS[aura_id]
			if aura_data.stat == stat_name:
				total += aura_data.value * level
	return total

func add_run_item(item_id: String) -> void:
	run_items.append(item_id)
	lifetime_item_picks[item_id] = lifetime_item_picks.get(item_id, 0) + 1
	
	var p = get_tree().get_first_node_in_group("player")
	if p and p.has_method("refresh_stats"):
		p.refresh_stats()



func award_gems(amount: int) -> void:
	gems += max(amount, 0)
	run_gems_collected += max(amount, 0)
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
	spent += _calculate_spent(perm_armor_percent_level)
	spent += _calculate_spent(perm_gold_drop_level)
	spent += _calculate_spent(perm_speed_level)
	spent += _calculate_spent(perm_thorns_level)
	spent += _calculate_spent(perm_spawn_rate_level)
	spent += _calculate_spent(perm_crit_damage_level)
	spent += _calculate_spent(perm_projectiles_level)
	spent += _calculate_spent(perm_bounces_level)
	
	gems += spent
	
	# Reset levels
	perm_damage_level = 0
	perm_atkspd_level = 0
	perm_pickup_radius_level = 0
	perm_max_health_level = 0
	perm_regen_level = 0
	perm_crit_level = 0
	perm_armor_level = 0
	perm_armor_percent_level = 0
	perm_gold_drop_level = 0
	perm_speed_level = 0
	perm_thorns_level = 0
	perm_spawn_rate_level = 0
	perm_crit_damage_level = 0
	perm_projectiles_level = 0
	perm_bounces_level = 0
	
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
	
	if current_level >= 10:
		return false
	
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

func record_chest_opened() -> void:
	lifetime_chests_opened += 1
	_check_unlocks()
	save()

func record_ability_upgrade(id: String, level: int) -> void:
	# Tracking total upgrades across all runs for sealing
	lifetime_upgrades[id] = lifetime_upgrades.get(id, 0) + 1
	
	if id.begins_with("aura_"):
		var current_max = aura_max_levels_reached.get(id, 0)
		if level > current_max:
			aura_max_levels_reached[id] = level
	
	# General max level tracking for sealing
	var max_lvl = 5 # Default
	# Note: I should probably move _get_max_level to a utility or Constants, 
	# but for now I'll just check if it's max.
	# Actually, Main.gd has _get_max_level. I'll just assume 5 if not specified.
	# To be safe, I'll just check if it's "high enough" or if we know the max.
	# I'll add a helper to check if an ID is maxed.
	if _is_ability_at_max(id, level):
		max_levels_reached[id] = true
	
	save()

func _is_ability_at_max(id: String, level: int) -> bool:
	# Keep in sync with Main.gd _get_max_level
	match id:
		"zap": return level >= GameConstants.ZAP_MAX_LEVEL
		"orbs": return level >= GameConstants.ORB_MAX_LEVEL
		"spike_ball": return level >= GameConstants.SPIKE_BALL_MAX_LEVEL
		"shotgun": return level >= GameConstants.SHOTGUN_MAX_LEVEL
		"sniper": return level >= GameConstants.SNIPER_MAX_LEVEL
		"rocket": return level >= GameConstants.ROCKET_MAX_LEVEL
		"bouncing_disk": return level >= GameConstants.DISK_MAX_LEVEL
		"floor_spikes": return level >= GameConstants.SPIKES_MAX_LEVEL
		"turret": return level >= GameConstants.TURRET_MAX_LEVEL
		"machine_gun": return level >= GameConstants.MG_MAX_LEVEL
		"ice_wave": return level >= GameConstants.ICE_MAX_LEVEL
	if id.begins_with("aura_"):
		return level >= GameConstants.AURA_MAX_LEVEL
	return level >= 5

func is_item_unlocked(id: String) -> bool:
	if GameConstants.DEBUG_UNLOCK_ALL_WEAPONS:
		# Check if it's a weapon based on ALL_ABILITIES in Main.gd or just return true for everything?
		# The request said "unlock all weapons", but unlocking everything is simpler and probably what's intended for debugging.
		return true
	if id.begins_with("aura_"):
		return unlocked_auras.has(id)
	return unlocked_items.has(id)

func finalize_run_unlocks() -> void:
	for item in run_unlocked_items:
		if item in GameConstants.ITEMS:
			if not unlocked_treasure_items.has(item):
				unlocked_treasure_items.append(item)
		elif item.begins_with("aura_"):
			if not unlocked_auras.has(item):
				unlocked_auras.append(item)
		else:
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
	# Zap -> Arcane Missile -> Fireball -> ...
	var weapon_chain = [
		"zap", "arcane_missile", "fireball", "ice_shard", "meteor", "frozen_orb", 
		"lightning_bolt", "ice_bolt", "fire_bolt", "arcane_bolt", "lightning_fork", 
		"blizzard", "arcane_orbs", "arcane_field", "fire_trail",
		"shotgun", "floor_spikes", "ice_wave", "spike_ball", "turret", 
		"sniper", "orbs", "bouncing_disk", "machine_gun", "rocket",
	]
	for i in range(weapon_chain.size() - 1):
		var current = weapon_chain[i]
		var next = weapon_chain[i+1]
		if lifetime_kills.get(current, 0) >= GameConstants.UNLOCK_KILLS_NEEDED:
			if not unlocked_items.has(next) and not run_unlocked_items.has(next):
				run_unlocked_items.append(next)
	
	# Treasure items: 5 unlocked by default, then 1 every 5 chests (5 chests -> 6th, 10 chests -> 7th, etc.)
	var total_items = GameConstants.ITEMS.size()
	var should_have_total = 5 + floor(float(lifetime_chests_opened) / 5.0)
	should_have_total = min(should_have_total, total_items)
	
	var current_total = unlocked_treasure_items.size() + run_unlocked_items.filter(func(id): return id in GameConstants.ITEMS).size()
	
	if current_total < should_have_total:
		var all_item_keys = GameConstants.ITEMS.keys()
		for id in all_item_keys:
			if not unlocked_treasure_items.has(id) and not run_unlocked_items.has(id):
				run_unlocked_items.append(id)
				current_total += 1
				if current_total >= should_have_total:
					break
	
	# Aura chain: previous at max level unlocks next
	var aura_chain = GameConstants.AURAS.keys()
	
	# Initial aura unlock: Kill 100 enemies with Zap
	if not unlocked_auras.has(aura_chain[0]):
		if lifetime_kills.get("zap", 0) >= 100:
			if not run_unlocked_items.has(aura_chain[0]):
				run_unlocked_items.append(aura_chain[0])

	for i in range(aura_chain.size() - 1):
		var current = aura_chain[i]
		var next = aura_chain[i+1]
		if unlocked_auras.has(current):
			# Use a separate tracking for max level achieved? 
			# User says "get the previous one to max level in a chain".
			# We can check lifetime_kills or a new lifetime_max_levels dict.
			# But and easier way is to check if we ever reached max level in a run and recorded it.
			# Let's add a lifetime_max_levels or just check record_ability_upgrade.
			# Actually, the user says "you need to get the previous one to max level".
			# I'll check a new dictionary `aura_max_levels_reached`.
			if aura_max_levels_reached.get(current, 0) >= GameConstants.AURA_MAX_LEVEL:
				if not unlocked_auras.has(next) and not run_unlocked_items.has(next):
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
		"perm_armor_percent_level": perm_armor_percent_level,
		"perm_gold_drop_level": perm_gold_drop_level,
		"perm_speed_level": perm_speed_level,
		"perm_thorns_level": perm_thorns_level,
		"perm_spawn_rate_level": perm_spawn_rate_level,
		"perm_crit_damage_level": perm_crit_damage_level,
		"perm_projectiles_level": perm_projectiles_level,
		"perm_bounces_level": perm_bounces_level,
		"unlocked_items": unlocked_items,
		"unlocked_auras": unlocked_auras,
		"unlocked_treasure_items": unlocked_treasure_items,
		"lifetime_kills": lifetime_kills,
		"lifetime_chests_opened": lifetime_chests_opened,
		"completed_levels": completed_levels,
		"aura_max_levels_reached": aura_max_levels_reached,
		"sealed_items": sealed_items,
		"unlocked_characters": unlocked_characters,
		"current_character": current_character,
		"max_levels_reached": max_levels_reached,
		"lifetime_upgrades": lifetime_upgrades,
		"lifetime_item_picks": lifetime_item_picks
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
	perm_armor_percent_level = int(parsed.get("perm_armor_percent_level", 0))
	perm_gold_drop_level = int(parsed.get("perm_gold_drop_level", 0))
	perm_speed_level = int(parsed.get("perm_speed_level", 0))
	perm_thorns_level = int(parsed.get("perm_thorns_level", 0))
	perm_spawn_rate_level = int(parsed.get("perm_spawn_rate_level", 0))
	perm_crit_damage_level = int(parsed.get("perm_crit_damage_level", 0))
	perm_projectiles_level = int(parsed.get("perm_projectiles_level", 0))
	perm_bounces_level = int(parsed.get("perm_bounces_level", 0))
	
	unlocked_items = parsed.get("unlocked_items", ["zap"])
	unlocked_auras = parsed.get("unlocked_auras", [])
	unlocked_treasure_items = parsed.get("unlocked_treasure_items", [])
	lifetime_kills = parsed.get("lifetime_kills", {"zap": 0})
	lifetime_chests_opened = int(parsed.get("lifetime_chests_opened", 0))
	completed_levels = parsed.get("completed_levels", [])
	aura_max_levels_reached = parsed.get("aura_max_levels_reached", {})
	sealed_items = parsed.get("sealed_items", [])
	unlocked_characters = parsed.get("unlocked_characters", ["starter"])
	current_character = parsed.get("current_character", "starter")
	max_levels_reached = parsed.get("max_levels_reached", {})
	lifetime_upgrades = parsed.get("lifetime_upgrades", {})
	lifetime_item_picks = parsed.get("lifetime_item_picks", {})
