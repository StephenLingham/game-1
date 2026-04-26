class_name GameConstants extends RefCounted

# ==========================================
# CENTRAL GAME BALANCE TWEAKS
# Edit these variables to adjust gameplay!
# ==========================================

const GAME_VERSION: String = "v0.13.0"

# --- PLAYER STATS ---
const PLAYER_SPEED: float = 300.0
const PLAYER_FIRE_RATE: float = 0.50
const PLAYER_MAX_HEALTH: int = 100
const PLAYER_BASE_DAMAGE: int = 50

# --- XP SETTINGS ---
const XP_BASE_LEVEL: int = 100
const XP_SCALING: float = 1.1 # Multiplier for next level
const XP_INCREMENT: int = 50 # Additive for next level

# --- PERMANENT UPGRADES ---
const PERM_LEVEL_COST: int = 1
const PERM_COST_INCREMENT: int = 0

# --- GUN ABILITY SETTINGS ---
const GUN_MAX_LEVEL: int = 4
const GUN_DAMAGE_PER_UPGRADE: int = 50
const GUN_ATK_SPD_PER_UPGRADE: float = 0.15

# --- WAVES & SPAWN SETTINGS ---
const TOTAL_WAVES: int = 10
const WAVE_SECONDS: float = 30.0

# --- ARENA SETTINGS ---
const ARENA_SIZE_MULTIPLIER: float = 2.0

const WAVE_BASE_SPAWN_WAIT: float = 0.75
const WAVE_MIN_SPAWN_WAIT: float = 0.25
const WAVE_SPAWN_WAIT_DECREMENT: float = 0.05

# Enemy Probabilities
const PROB_NORMAL_ENEMY: float = 0.50
const PROB_FAST_ENEMY: float = 0.20
const PROB_BIG_ENEMY: float = 0.10
const PROB_TANK_ENEMY: float = 0.20

# --- ENEMY SETTINGS ---
const ENEMY_NORMAL_SPRITE_SCALE: float = 0.09
const ENEMY_NORMAL_SPEED: float = 80.0
const ENEMY_NORMAL_HEALTH: int = 100
const ENEMY_NORMAL_DAMAGE: int = 20
const ENEMY_NORMAL_ATTACK_COOLDOWN: float = 1.0
const ENEMY_NORMAL_XP_MIN: int = 10
const ENEMY_NORMAL_XP_MAX: int = 15

const ENEMY_FAST_SPRITE_SCALE: float = 0.07
const ENEMY_FAST_SPEED: float = 160.0
const ENEMY_FAST_HEALTH: int = 50
const ENEMY_FAST_DAMAGE: int = 20
const ENEMY_FAST_ATTACK_COOLDOWN: float = 1.0
const ENEMY_FAST_XP_MIN: int = 8
const ENEMY_FAST_XP_MAX: int = 12

const ENEMY_BIG_SPRITE_SCALE: float = 0.15
const ENEMY_BIG_SPEED: float = 80.0
const ENEMY_BIG_HEALTH: int = 400
const ENEMY_BIG_DAMAGE: int = 40
const ENEMY_BIG_ATTACK_COOLDOWN: float = 1.5
const ENEMY_BIG_XP_MIN: int = 40
const ENEMY_BIG_XP_MAX: int = 60

const ENEMY_TANK_SPRITE_SCALE: float = 0.07
const ENEMY_TANK_SPEED: float = 90.0
const ENEMY_TANK_HEALTH: int = 50
const ENEMY_TANK_DAMAGE: int = 20
const ENEMY_TANK_ATTACK_COOLDOWN: float = 1.0
const ENEMY_TANK_XP_MIN: int = 10
const ENEMY_TANK_XP_MAX: int = 15

# --- COLLECTION SETTINGS ---
const BASE_COLLECTION_RADIUS: float = 50.0
const COLLECTION_RADIUS_UPGRADE_AMOUNT: float = 25.0
const MAGNET_MAX_LEVEL: int = 7
const MAGNET_BASE_COST: int = 15
const MAGNET_COST_INCREMENT: int = 10
const PERM_COLLECTION_RADIUS_INCREMENT: float = 1.0
const MAGNET_SPEED: float = 600.0

# --- ORB ABILITY SETTINGS ---
const ORB_BASE_ROTATE_SPEED: float = 2.5
const ORB_UPGRADE_ROTATE_SPEED: float = 4.5
const ORB_RADIUS: float = 100.0
const ORB_DAMAGE: int = 100
const ORB_MAX_LEVEL: int = 6

# --- SPIKE BALL ABILITY SETTINGS ---
const SPIKE_BALL_BASE_DAMAGE: int = 750
const SPIKE_BALL_BASE_DISTANCE: float = 500.0
const SPIKE_BALL_DISTANCE_PER_LEVEL: float = 200.0
const SPIKE_BALL_BASE_COOLDOWN: float = 2.5
const SPIKE_BALL_COOLDOWN_REDUCTION_PER_LEVEL: float = 0.4
const SPIKE_BALL_MAX_LEVEL: int = 5

# --- SHOTGUN ABILITY SETTINGS ---
const SHOTGUN_BASE_COOLDOWN: float = 1.0
const SHOTGUN_SPREAD_ANGLE: float = 45.0
const SHOTGUN_MAX_LEVEL: int = 4

# --- SNIPER ABILITY SETTINGS ---
const SNIPER_BASE_COOLDOWN: float = 2.0
const SNIPER_COOLDOWN_REDUCTION_PER_LEVEL: float = 0.4
const SNIPER_DAMAGE: int = 2000
const SNIPER_MAX_LEVEL: int = 5

# --- ROCKET LAUNCHER ABILITY SETTINGS ---
const ROCKET_BASE_COOLDOWN: float = 4.0
const ROCKET_COOLDOWN_REDUCTION_PER_LEVEL: float = 0.5
const ROCKET_BASE_BLAST_RADIUS: float = 150.0
const ROCKET_BLAST_RADIUS_PER_LEVEL: float = 30.0
const ROCKET_MAX_LEVEL: int = 5
const ROCKET_SPEED: float = 400.0
const ROCKET_TURN_SPEED: float = 5.0
const ROCKET_DAMAGE: int = 500
const ROCKET_TARGET_RADIUS: float = 600.0

# Bouncing Disk
const DISK_BASE_COOLDOWN: float = 3.0
const DISK_BASE_DAMAGE: int = 600
const DISK_MAX_LEVEL: int = 5
const DISK_SPEED: float = 500.0

# Turret
const TURRET_BASE_COOLDOWN: float = 8.0
const TURRET_COOLDOWN_REDUCTION: float = 1.0
const TURRET_MAX_LEVEL: int = 5
const TURRET_DAMAGE: int = 250
const TURRET_FIRE_RATE: float = 0.5

# Machine Gun
const MG_BASE_COOLDOWN: float = 0.15
const MG_DAMAGE: int = 50
const MG_MAX_LEVEL: int = 5

# Floor Spikes
const SPIKES_BASE_COOLDOWN: float = 2.0
const SPIKES_BASE_DAMAGE: int = 500
const SPIKES_MAX_LEVEL: int = 5

# Ice Wave
const ICE_BASE_COOLDOWN: float = 6.0
const ICE_BASE_RADIUS: float = 200.0
const ICE_RADIUS_INCREMENT: float = 100.0
const ICE_MAX_LEVEL: int = 5
const ICE_FREEZE_DURATION: float = 2.0

# --- AURA SETTINGS ---
const AURA_MAX_LEVEL: int = 5
const AURA_MAX_COUNT: int = 6

# Aura Stat Values (per level)
const AURA_DAMAGE_BOOST: float = 0.1 # +10%
const AURA_ATKSPD_BOOST: float = 0.1 # +10%
const AURA_PICKUP_BOOST: float = 5.0 # +5 collection radius
const AURA_HEALTH_BOOST: int = 10     # +10 max health
const AURA_REGEN_BOOST: float = 0.1   # +0.1 HP/sec
const AURA_CRIT_BOOST: float = 0.05   # +5% crit chance
const AURA_CRIT_DMG_BOOST: float = 0.1 # +0.1x crit multiplier
const AURA_ARMOR_BOOST: int = 3      # +3 flat armor
const AURA_ARMOR_PCT_BOOST: float = 0.05 # +5% armor
const AURA_THORNS_BOOST: float = 0.1 # +10% thorns
const AURA_SPAWN_BOOST: float = 0.1  # +10% spawn rate
const AURA_XP_BOOST: float = 0.1    # +10% XP drop
const AURA_SPEED_BOOST: float = 0.10  # +10% movement speed

# --- SHOP SETTINGS ---
const SHOP_OPTIONS_COUNT: int = 3
const SHOP_MAX_ABILITIES: int = 6
const SHOP_BANISH_COUNT: int = 3

# --- POWER-UP ITEM SETTINGS ---
const PICKUP_EXPLOSION_RADIUS_MULTIPLIER: float = 0.5
const PICKUP_EXPLOSION_EXPAND_TIME: float = 0.5
const PICKUP_EXPLOSION_DAMAGE: int = 2000
const POWERUP_SPAWN_INTERVAL_MIN: float = 4
const POWERUP_SPAWN_INTERVAL_MAX: float = 8
const POWERUP_SPEED_BOOST_MULTIPLIER: float = 1.6
const POWERUP_SPEED_BOOST_DURATION: float = 7.0
const POWERUP_ATK_SPEED_BOOST_MULTIPLIER: float = 10.0
const POWERUP_ATK_SPEED_BOOST_DURATION: float = 3.0
const POWERUP_GEM_AWARD_AMOUNT: int = 1
const POWERUP_ICON_SCALE: float = 0.07
const CHEST_SPAWN_INTERVAL_MIN: float = 10.0
const CHEST_SPAWN_INTERVAL_MAX: float = 15.0

# --- GEM DROP SETTINGS ---
const GEM_DROP_TIMES: Array = [30.0, 90.0, 150.0, 210.0, 270.0]

# --- UNLOCKS ---
const UNLOCK_KILLS_NEEDED: int = 50
const DEBUG_UNLOCK_ALL_WEAPONS: bool = false
const DEBUG_MAX_PERM_UPGRADES: bool = false
const DEBUG_UNLOCK_ALL_LEVELS: bool = false
const DEBUG_RESET_UNLOCKS: bool = false
const DEBUG_RESET_GEMS: bool = false
const DEBUG_RESET_ALL_DATA: bool = false

# --- CHARACTERS ---
const CHARACTERS: Dictionary = {
	"starter": {
		"name": "Alaric the Apprentice",
		"desc": "A balanced wizard starting his journey.",
		"traits": []
	},
	"speed_damage": {
		"name": "Zephyros the Swift",
		"desc": "Damage scales with speed. Gains speed over time, but halved on hit.",
		"traits": ["speed_damage_scaling", "speed_gain_over_time"]
	},
	"tank": {
		"name": "Grogun the Titan",
		"desc": "Very slow but extremely durable.",
		"traits": ["high_armor_health", "slowness"]
	},
	"glass_cannon": {
		"name": "Mordred the Maleficent",
		"desc": "Max health decreases but damage increases on every level up.",
		"traits": ["damage_up_hp_down_on_level"]
	},
	"chaos": {
		"name": "Kaos the Herald",
		"desc": "Enemies spawn faster as he grows in power.",
		"traits": ["spawn_rate_on_level"]
	},
	"echo": {
		"name": "Mystra the Echo",
		"desc": "Has the rare ability to carry duplicate auras.",
		"traits": ["duplicate_auras"]
	},
	"polymath": {
		"name": "Octavius the Polymath",
		"desc": "Can master 8 abilities instead of 6.",
		"traits": ["extra_slots"]
	},
	"singular_force": {
		"name": "Solon the Singular",
		"desc": "Can only hold one ability, but it deals 6x damage.",
		"traits": ["single_ability_damage"]
	},
	"singular_volley": {
		"name": "Volos the Voluminous",
		"desc": "Only one ability, but it gains an extra projectile every level.",
		"traits": ["single_ability_projectiles"]
	},
	"singular_luck": {
		"name": "Fortuno the Favored",
		"desc": "Only one ability, but chests appear 5x as often.",
		"traits": ["single_ability_chests"]
	},
	"vampire": {
		"name": "Sanguis the Eternal",
		"desc": "Starts with massive health. Speed decreases but lifesteal increases as he levels.",
		"traits": ["high_hp_vampire"]
	},
	"passive_master": {
		"name": "Thornius the Reactive",
		"desc": "High thorns and regen. Can't use weapons, but masters auras.",
		"traits": ["no_weapons_auras_only"]
	}
}

const CHARACTER_UNLOCK_CHAIN: Array = [
	"starter", "speed_damage", "tank", "glass_cannon", "chaos", "echo", 
	"polymath", "singular_force", "singular_volley", "singular_luck", "vampire", "passive_master"
]

# --- CHARACTER SPECIFIC SETTINGS ---
# Zephyros
const ZEPHYROS_SPEED_GAIN_PER_SEC: float = 0.05
const ZEPHYROS_MAX_SPEED_BONUS: float = 2.0

# --- SEALING ---
const MIN_UNSEALED_COUNT: int = 6

# --- ITEMS ---
const ITEMS: Dictionary = {
	"nuclear_giraffe": {
		"name": "Nuclear Giraffe",
		"stats": {"crit_multiplier": 0.1}
	},
	"wholemeal_sandwich": {
		"name": "Wholemeal Sandwich",
		"stats": {"max_health": 10}
	},
	"banana_peel": {
		"name": "Slippery Banana Peel Dispenser",
		"stats": {"speed_multiplier": 0.1}
	},
	"meatloaf": {
		"name": "Grandma’s Hearty Meatloaf",
		"stats": {"health_regen": 0.1}
	},
	"quantum_socks": {
		"name": "Quantum Socks",
		"stats": {"pickup_radius": 5.0}
	},
	"pirate_rum": {
		"name": "Drunken Pirate’s Bottomless Rum",
		"stats": {"damage_multiplier": 0.1}
	},
	"friendly_spoon": {
		"name": "Friendly Spoon",
		"stats": {"armor": 5}
	},
	"bouncy_armor": {
		"name": "Inflatable Bouncy Castle Armor",
		"stats": {"armor_percent": 0.1}
	},
	"coffee_thermos": {
		"name": "Bottomless Coffee Thermos",
		"stats": {"atkspd_multiplier": 0.1}
	},
	"pet_rock": {
		"name": "Loyal Pet Rock",
		"stats": {"thorns_percentage": 0.1}
	},
	"disco_ball": {
		"name": "Laser Disco Ball",
		"stats": {"crit_chance": 0.1}
	},
	"clown_horn": {
		"name": "The Over-Enthusiastic Megaphone",
		"stats": {"damage_multiplier": 0.1}
	},
	"hamster_wheel": {
		"name": "Unstable Hamster Wheel",
		"stats": {"speed_multiplier": 0.1}
	},
	"toaster": {
		"name": "Fiery Toaster Attachment",
		"stats": {"damage_multiplier": 0.1}
	},
	"boomerang": {
		"name": "Sentient Boomerang",
		"stats": {"crit_multiplier": 0.1}
	},
	"lunchbox": {
		"name": "Lunchbox of Plenty",
		"stats": {"max_health": 10}
	},
	"eight_ball": {
		"name": "Magic 8-Ball of Chaos",
		"stats": {"crit_chance": 0.1}
	},
	"squirrel_launcher": {
		"name": "Hyperactive Squirrel Acorn Launcher",
		"stats": {"atkspd_multiplier": 0.1}
	},
	"springy_shoes": {
		"name": "Springy Shoes",
		"stats": {"speed_multiplier": 0.1}
	},
	"pinata_buddy": {
		"name": "Sentient Piñata Buddy",
		"stats": {"xp_drop_multiplier": 0.1}
	},
	"cosmic_sausage": {
		"name": "Cosmic Sausage",
		"stats": {"damage": 5}
	}
}

const AURAS: Dictionary = {
	"aura_damage": {
		"name": "Power Aura",
		"stat": "damage_multiplier",
		"value": AURA_DAMAGE_BOOST,
		"desc": "Increases overall damage bonus by %d%% per level."
	},
	"aura_atkspd": {
		"name": "Swiftness Aura",
		"stat": "atkspd_multiplier",
		"value": AURA_ATKSPD_BOOST,
		"desc": "Increases attack speed by %d%% per level."
	},
	"aura_pickup_radius": {
		"name": "Magnet Aura",
		"stat": "pickup_radius",
		"value": AURA_PICKUP_BOOST,
		"desc": "Increases collection radius by %d per level."
	},
	"aura_max_health": {
		"name": "Vitality Aura",
		"stat": "max_health",
		"value": AURA_HEALTH_BOOST,
		"desc": "Increases max health by %d per level."
	},
	"aura_regen": {
		"name": "Recovery Aura",
		"stat": "health_regen",
		"value": AURA_REGEN_BOOST,
		"desc": "Increases health regeneration by %.1f HP/sec per level."
	},
	"aura_crit": {
		"name": "Precision Aura",
		"stat": "crit_chance",
		"value": AURA_CRIT_BOOST,
		"desc": "Increases critical hit chance by %d%% per level."
	},
	"aura_crit_damage": {
		"name": "Ferocity Aura",
		"stat": "crit_multiplier",
		"value": AURA_CRIT_DMG_BOOST,
		"desc": "Increases critical damage multiplier by %.2fx per level."
	},
	"aura_armor": {
		"name": "Sentinel Aura",
		"stat": "armor",
		"value": AURA_ARMOR_BOOST,
		"desc": "Increases flat armor reduction by %d per level."
	},
	"aura_armor_percent": {
		"name": "Guardian Aura",
		"stat": "armor_percent",
		"value": AURA_ARMOR_PCT_BOOST,
		"desc": "Increases percentage damage reduction by %d%% per level."
	},
	"aura_thorns": {
		"name": "Spike Aura",
		"stat": "thorns_percentage",
		"value": AURA_THORNS_BOOST,
		"desc": "Reflects %d%% of incoming damage back to attackers per level."
	},
	"aura_speed": {
		"name": "Haste Aura",
		"stat": "speed_multiplier",
		"value": AURA_SPEED_BOOST,
		"desc": "Increases movement speed by %d%% per level."
	},
	"aura_xp_drop": {
		"name": "Learning Aura",
		"stat": "xp_drop_multiplier",
		"value": AURA_XP_BOOST,
		"desc": "Increases XP gained from drops by %d%% per level."
	},
	"aura_spawn_rate": {
		"name": "Chaos Aura",
		"stat": "spawn_rate_multiplier",
		"value": AURA_SPAWN_BOOST,
		"desc": "Increases enemy spawn rate by %d%% per level (more XP!)."
	}
}
