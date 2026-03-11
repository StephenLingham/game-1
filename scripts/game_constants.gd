class_name GameConstants extends RefCounted

# ==========================================
# CENTRAL GAME BALANCE TWEAKS
# Edit these variables to adjust gameplay!
# ==========================================

# --- PLAYER STATS ---
const PLAYER_SPEED: float = 300.0
const PLAYER_FIRE_RATE: float = 0.50
const PLAYER_MAX_HEALTH: int = 5
const PLAYER_BASE_DAMAGE: int = 1

# --- WAVES & SPAWN SETTINGS ---
const TOTAL_WAVES: int = 10
const WAVE_SECONDS: float = 30.0

# --- ARENA SETTINGS ---
const ARENA_WIDTH_MULTIPLIER: float = 1.1
const ARENA_HEIGHT_MULTIPLIER: float = 1.1

const WAVE_BASE_SPAWN_WAIT: float = 0.75
const WAVE_MIN_SPAWN_WAIT: float = 0.25
const WAVE_SPAWN_WAIT_DECREMENT: float = 0.05

# Enemy Probabilities (Should sum to 1.0)
const PROB_NORMAL_ENEMY: float = 0.70
const PROB_FAST_ENEMY: float = 0.20
const PROB_BIG_ENEMY: float = 0.10

# --- NORMAL ENEMY SETTINGS ---
const ENEMY_NORMAL_SPEED: float = 120.0
const ENEMY_NORMAL_HEALTH: int = 2
const ENEMY_NORMAL_DAMAGE: int = 1
const ENEMY_NORMAL_ATTACK_COOLDOWN: float = 0.5
const ENEMY_NORMAL_GOLD_MIN: int = 1
const ENEMY_NORMAL_GOLD_MAX: int = 3

# --- FAST ENEMY SETTINGS ---
const ENEMY_FAST_SPEED: float = 220.0
const ENEMY_FAST_HEALTH: int = 1
const ENEMY_FAST_DAMAGE: int = 1
const ENEMY_FAST_ATTACK_COOLDOWN: float = 0.5
const ENEMY_FAST_GOLD_MIN: int = 1
const ENEMY_FAST_GOLD_MAX: int = 3

# --- BIG ENEMY SETTINGS ---
const ENEMY_BIG_SPEED: float = 120.0
const ENEMY_BIG_HEALTH: int = 8
const ENEMY_BIG_DAMAGE: int = 2
const ENEMY_BIG_ATTACK_COOLDOWN: float = 0.5
const ENEMY_BIG_GOLD_MIN: int = 3
const ENEMY_BIG_GOLD_MAX: int = 6

# --- COLLECTION SETTINGS ---
const BASE_COLLECTION_RADIUS: float = 50.0
const COLLECTION_RADIUS_UPGRADE_AMOUNT: float = 25.0
const PERM_COLLECTION_RADIUS_INCREMENT: float = 10.0
const MAGNET_SPEED: float = 600.0

# --- ORB ABILITY SETTINGS ---
const ORB_BASE_ROTATE_SPEED: float = 2.5
const ORB_UPGRADE_ROTATE_SPEED: float = 4.5
const ORB_RADIUS: float = 75.0
const ORB_DAMAGE: int = 2
const ORB_MAX_LEVEL: int = 6
