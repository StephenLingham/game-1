class_name GameConstants extends RefCounted

# ==========================================
# CENTRAL GAME BALANCE TWEAKS
# Edit these variables to adjust gameplay!
# ==========================================

const GAME_VERSION: String = "v0.7.0"

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
const PERM_LEVEL_COST: int = 10
const PERM_COST_INCREMENT: int = 10

# --- GUN ABILITY SETTINGS ---
const GUN_MAX_LEVEL: int = 4
const GUN_BASE_COST: int = 15
const GUN_COST_INCREMENT: int = 10
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
const PROB_NORMAL_ENEMY: float = 0.70
const PROB_FAST_ENEMY: float = 0.20
const PROB_BIG_ENEMY: float = 0.10

# --- ENEMY SETTINGS ---
const ENEMY_NORMAL_SPEED: float = 80.0
const ENEMY_NORMAL_HEALTH: int = 100
const ENEMY_NORMAL_DAMAGE: int = 20
const ENEMY_NORMAL_ATTACK_COOLDOWN: float = 1.0
const ENEMY_NORMAL_XP_MIN: int = 10
const ENEMY_NORMAL_XP_MAX: int = 15

const ENEMY_FAST_SPEED: float = 160.0
const ENEMY_FAST_HEALTH: int = 50
const ENEMY_FAST_DAMAGE: int = 20
const ENEMY_FAST_ATTACK_COOLDOWN: float = 1.0
const ENEMY_FAST_XP_MIN: int = 8
const ENEMY_FAST_XP_MAX: int = 12

const ENEMY_BIG_SPEED: float = 80.0
const ENEMY_BIG_HEALTH: int = 400
const ENEMY_BIG_DAMAGE: int = 40
const ENEMY_BIG_ATTACK_COOLDOWN: float = 1.5
const ENEMY_BIG_XP_MIN: int = 40
const ENEMY_BIG_XP_MAX: int = 60

# --- COLLECTION SETTINGS ---
const BASE_COLLECTION_RADIUS: float = 50.0
const COLLECTION_RADIUS_UPGRADE_AMOUNT: float = 25.0
const MAGNET_MAX_LEVEL: int = 7
const MAGNET_BASE_COST: int = 15
const MAGNET_COST_INCREMENT: int = 10
const PERM_COLLECTION_RADIUS_INCREMENT: float = 10.0
const MAGNET_SPEED: float = 600.0

# --- ORB ABILITY SETTINGS ---
const ORB_BASE_ROTATE_SPEED: float = 2.5
const ORB_UPGRADE_ROTATE_SPEED: float = 4.5
const ORB_RADIUS: float = 100.0
const ORB_DAMAGE: int = 100
const ORB_MAX_LEVEL: int = 6
const ORB_BASE_COST: int = 10
const ORB_COST_INCREMENT_PER_LEVEL: int = 5

# --- SPIKE BALL ABILITY SETTINGS ---
const SPIKE_BALL_BASE_DAMAGE: int = 750
const SPIKE_BALL_BASE_DISTANCE: float = 500.0
const SPIKE_BALL_DISTANCE_PER_LEVEL: float = 200.0
const SPIKE_BALL_BASE_COOLDOWN: float = 2.5
const SPIKE_BALL_COOLDOWN_REDUCTION_PER_LEVEL: float = 0.4
const SPIKE_BALL_MAX_LEVEL: int = 5
const SPIKE_BALL_BASE_COST: int = 25
const SPIKE_BALL_COST_INCREMENT_PER_LEVEL: int = 15

# --- SHOTGUN ABILITY SETTINGS ---
const SHOTGUN_BASE_COOLDOWN: float = 1.0
const SHOTGUN_SPREAD_ANGLE: float = 45.0
const SHOTGUN_MAX_LEVEL: int = 4
const SHOTGUN_BASE_COST: int = 10
const SHOTGUN_COST_INCREMENT_PER_LEVEL: int = 10

# --- SNIPER ABILITY SETTINGS ---
const SNIPER_BASE_COOLDOWN: float = 2.0
const SNIPER_COOLDOWN_REDUCTION_PER_LEVEL: float = 0.4
const SNIPER_MAX_LEVEL: int = 5
const SNIPER_BASE_COST: int = 10
const SNIPER_COST_INCREMENT_PER_LEVEL: int = 10

# --- ROCKET LAUNCHER ABILITY SETTINGS ---
const ROCKET_BASE_COOLDOWN: float = 4.0
const ROCKET_COOLDOWN_REDUCTION_PER_LEVEL: float = 0.5
const ROCKET_BASE_BLAST_RADIUS: float = 150.0
const ROCKET_BLAST_RADIUS_PER_LEVEL: float = 30.0
const ROCKET_MAX_LEVEL: int = 5
const ROCKET_BASE_COST: int = 20
const ROCKET_COST_INCREMENT_PER_LEVEL: int = 15
const ROCKET_SPEED: float = 400.0
const ROCKET_TURN_SPEED: float = 5.0
const ROCKET_DAMAGE: int = 500
const ROCKET_TARGET_RADIUS: float = 600.0

# Bouncing Disk
const DISK_BASE_COOLDOWN: float = 3.0
const DISK_BASE_DAMAGE: int = 600
const DISK_MAX_LEVEL: int = 5
const DISK_BASE_COST: int = 20
const DISK_COST_INCREMENT: int = 15
const DISK_SPEED: float = 500.0

# Turret
const TURRET_BASE_COOLDOWN: float = 8.0
const TURRET_COOLDOWN_REDUCTION: float = 1.0
const TURRET_MAX_LEVEL: int = 5
const TURRET_BASE_COST: int = 25
const TURRET_COST_INCREMENT: int = 20
const TURRET_DAMAGE: int = 250
const TURRET_FIRE_RATE: float = 0.5

# Machine Gun
const MG_BASE_COOLDOWN: float = 0.15
const MG_DAMAGE: int = 50
const MG_MAX_LEVEL: int = 5
const MG_BASE_COST: int = 20
const MG_COST_INCREMENT: int = 15

# Floor Spikes
const SPIKES_BASE_COOLDOWN: float = 2.0
const SPIKES_BASE_DAMAGE: int = 500
const SPIKES_MAX_LEVEL: int = 5
const SPIKES_BASE_COST: int = 15
const SPIKES_COST_INCREMENT: int = 10

# Ice Wave
const ICE_BASE_COOLDOWN: float = 6.0
const ICE_BASE_RADIUS: float = 200.0
const ICE_RADIUS_INCREMENT: float = 100.0
const ICE_MAX_LEVEL: int = 5
const ICE_BASE_COST: int = 15
const ICE_COST_INCREMENT: int = 10
const ICE_FREEZE_DURATION: float = 2.0

# --- SHOP SETTINGS ---
const SHOP_OPTIONS_COUNT: int = 3
const SHOP_MAX_ABILITIES: int = 6
const SHOP_REROLL_BASE_COST: int = 2
const SHOP_REROLL_INCREMENT: int = 2
const SHOP_BANISH_COUNT: int = 3

# --- POWER-UP ITEM SETTINGS ---
const POWERUP_SPAWN_INTERVAL_MIN: float = 4
const POWERUP_SPAWN_INTERVAL_MAX: float = 8
const POWERUP_SPEED_BOOST_MULTIPLIER: float = 1.6
const POWERUP_SPEED_BOOST_DURATION: float = 7.0
const POWERUP_ATK_SPEED_BOOST_MULTIPLIER: float = 10.0
const POWERUP_ATK_SPEED_BOOST_DURATION: float = 3.0
const POWERUP_GEM_AWARD_AMOUNT: int = 1
const POWERUP_ICON_SCALE: float = 0.07

# --- UNLOCKS ---
const UNLOCK_KILLS_NEEDED: int = 50
const DEBUG_UNLOCK_ALL_WEAPONS: bool = false
const DEBUG_MAX_PERM_UPGRADES: bool = false
const DEBUG_UNLOCK_ALL_LEVELS: bool = false
const DEBUG_RESET_UNLOCKS: bool = false
const DEBUG_RESET_GEMS: bool = false
const DEBUG_RESET_ALL_DATA: bool = false

# --- ITEMS ---
const ITEMS: Dictionary = {
	"nuclear_giraffe": {
		"name": "Nuclear Giraffe",
		"stats": {"crit_multiplier": 1.0, "crit_chance": 0.05}
	},
	"wholemeal_sandwich": {
		"name": "Wholemeal Sandwich",
		"stats": {"atkspd_multiplier": 0.3, "armor": 10}
	},
	"banana_peel": {
		"name": "Slippery Banana Peel Dispenser",
		"stats": {"speed_multiplier": 0.2, "armor_percent": 0.1}
	},
	"meatloaf": {
		"name": "Grandma’s Hearty Meatloaf",
		"stats": {"max_health": 50, "health_regen": 1.0}
	},
	"quantum_socks": {
		"name": "Quantum Socks",
		"stats": {"pickup_radius": 50.0, "speed_multiplier": 0.1}
	},
	"pirate_rum": {
		"name": "Drunken Pirate’s Bottomless Rum",
		"stats": {"damage_multiplier": 0.5, "speed_multiplier": 0.2}
	},
	"friendly_spoon": {
		"name": "Friendly Spoon",
		"stats": {"armor": 20, "atkspd_multiplier": 0.1}
	},
	"bouncy_armor": {
		"name": "Inflatable Bouncy Castle Armor",
		"stats": {"armor": 10, "armor_percent": 0.2, "damage_multiplier": 0.15}
	},
	"coffee_thermos": {
		"name": "Bottomless Coffee Thermos",
		"stats": {"atkspd_multiplier": 0.25, "speed_multiplier": 0.15}
	},
	"pet_rock": {
		"name": "Loyal Pet Rock",
		"stats": {"armor": 15, "thorns_percentage": 0.25}
	},
	"disco_ball": {
		"name": "Laser Disco Ball",
		"stats": {"crit_chance": 0.15, "pickup_radius": 30.0}
	},
	"clown_horn": {
		"name": "The Over-Enthusiastic Megaphone",
		"stats": {"damage_multiplier": 0.3, "atkspd_multiplier": 0.2}
	},
	"hamster_wheel": {
		"name": "Unstable Hamster Wheel",
		"stats": {"speed_multiplier": 0.5, "max_health": 30}
	},
	"toaster": {
		"name": "Fiery Toaster Attachment",
		"stats": {"damage_multiplier": 0.4, "thorns_percentage": 0.3}
	},
	"boomerang": {
		"name": "Sentient Boomerang",
		"stats": {"crit_chance": 0.1, "crit_multiplier": 0.5}
	},
	"lunchbox": {
		"name": "Lunchbox of Plenty",
		"stats": {"thorns_percentage": 0.5, "armor": 5}
	},
	"eight_ball": {
		"name": "Magic 8-Ball of Chaos",
		"stats": {"damage_multiplier": 0.2, "crit_multiplier": 0.3, "crit_chance": 0.05}
	},
	"squirrel_launcher": {
		"name": "Hyperactive Squirrel Acorn Launcher",
		"stats": {"atkspd_multiplier": 0.6, "damage_multiplier": 0.25}
	},
	"springy_shoes": {
		"name": "Springy Shoes",
		"stats": {"health_regen": 3.0, "speed_multiplier": 0.15}
	},
	"pinata_buddy": {
		"name": "Sentient Piñata Buddy",
		"stats": {"xp_drop_multiplier": 0.5, "gem_drop_chance_bonus": 0.05}
	},
	"cosmic_sausage": {
		"name": "Cosmic Sausage",
		"stats": {"max_health": -5, "damage": 5}
	}
}
