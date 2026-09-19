extends RefCounted
class_name RunCampaign

const AREA_SECONDS := 300.0
const RUN_SECONDS := 900.0
const NAMES := ["Mushroom Forest", "Crimson Citadel", "Obsidian Obelisk - The Darkest Darkness"]
const WAVE_ENEMIES := [
	[],
	["Cinderling", "AshGuard", "FlameDancer", "MagmaSentinel", "EmberArcher", "FurnaceRam", "ElderDrake", "LavaCrawler", "PyreTwin", "InfernoDragon"],
	["BlinkStalker", "GravityWisp", "ObsidianPhalanx", "DreadKnight", "VoidOracle", "RiftHound", "BansheeQueen", "NightMaw", "SoulReaper", "ObsidianDeath"],
]
const SUPPORT_ENEMIES := [[], ["CrimsonEscort"], ["VoidEscort"]]
const ENEMIES := [["Normal", "Fast", "Big"], WAVE_ENEMIES[1], WAVE_ENEMIES[2]]
const MINIBOSSES := [[], ["MagmaSentinel", "ElderDrake"], ["DreadKnight", "BansheeQueen"]]
const BOSSES := ["Boss", "InfernoDragon", "ObsidianDeath"]

# One signature type and encounter rule per wave. Entries are intentionally
# never reused by another wave in the same campaign.
const WAVE_MECHANICS := [
	[],
	[
		"one-hit cinderling rush",
		"alternating pincer columns",
		"clockwise spiral closing on the player",
		"90%-player-speed endurance miniboss",
		"a few widely spaced ranged marksmen",
		"charging wedge formations",
		"elder drake with staggered escort pairs",
		"four delayed walls, one from each direction",
		"mirrored melee pairs",
		"Inferno Dragon boss",
	],
	[
		"phasing ambush ring",
		"counter-clockwise gravity spiral",
		"marching rows with shifting safe lanes",
		"Dread Knight endurance duel",
		"a few slow-firing void marksmen",
		"four-corner rift-hound charges",
		"Banshee Queen ground-pulse duel",
		"rotating-wall enclosure with an escape gap",
		"alternating soul-reaper pincers",
		"Obsidian Death boss",
	],
]

static func is_boss(kind: String) -> bool:
	return kind in BOSSES

static func is_miniboss(kind: String) -> bool:
	return kind in MINIBOSSES[1] or kind in MINIBOSSES[2]

static func is_campaign_enemy(kind: String) -> bool:
	return kind in ENEMIES[1] or kind in ENEMIES[2] or kind in SUPPORT_ENEMIES[1] or kind in SUPPORT_ENEMIES[2] or is_miniboss(kind) or kind in ["InfernoDragon", "ObsidianDeath"]

static func wave_enemy(stage: int, wave: int) -> String:
	if stage < 1 or stage >= WAVE_ENEMIES.size() or wave < 1 or wave > WAVE_ENEMIES[stage].size():
		return ""
	return WAVE_ENEMIES[stage][wave - 1]

# Health, speed, contact damage, visual diameter, behavior, atlas cell, XP.
static func enemy_data(kind: String) -> Dictionary:
	var stats: Array = {
		"CrimsonEscort": [380, 105, 26, 72, "hunt", 1, 24],
		"Cinderling": [1, 440, 8, 48, "rush", 2, 2],
		"AshGuard": [520, 78, 30, 92, "bulwark", 1, 38],
		"FlameDancer": [260, 112, 22, 70, "spiral", 2, 25],
		# Base player speed is 300, so this endurance enemy pursues at 90%.
		"MagmaSentinel": [9000, 270, 42, 180, "relentless", 3, 260],
		"EmberArcher": [430, 58, 28, 76, "ranged", 0, 42],
		"FurnaceRam": [760, 82, 38, 104, "charge", 1, 55],
		"ElderDrake": [8500, 92, 48, 190, "charge", 4, 280],
		"LavaCrawler": [340, 96, 25, 72, "march", 2, 28],
		"PyreTwin": [620, 108, 34, 88, "orbit_melee", 0, 48],
		"Dragon": [240, 85, 24, 86, "breath", 0, 24],
		"FireGolem": [900, 42, 38, 110, "slam", 1, 60],
		"FireElemental": [180, 105, 22, 76, "orbit", 2, 22],
		"InfernoDragon": [45000, 52, 65, 290, "inferno", 5, 500],
		"VoidEscort": [420, 116, 30, 74, "phase", 0, 28],
		"BlinkStalker": [360, 128, 30, 76, "phase", 0, 34],
		"GravityWisp": [310, 118, 29, 68, "spiral_reverse", 1, 31],
		"ObsidianPhalanx": [850, 68, 42, 105, "bulwark", 2, 58],
		"DreadKnight": [13000, 118, 62, 180, "charge", 3, 380],
		"VoidOracle": [520, 52, 36, 80, "ranged", 1, 52],
		"RiftHound": [480, 145, 35, 82, "leap", 0, 42],
		"BansheeQueen": [11000, 90, 54, 185, "banshee", 4, 380],
		"NightMaw": [700, 105, 44, 98, "hunt", 2, 58],
		"SoulReaper": [1250, 82, 52, 112, "hunt", 2, 82],
		"Ghost": [420, 92, 32, 82, "phase", 0, 38],
		"VoidWisp": [280, 125, 28, 68, "orbit", 1, 30],
		"Reaper": [1100, 70, 48, 112, "charge", 2, 75],
		"ObsidianDeath": [65000, 57, 80, 310, "death", 5, 750],
	}[kind]
	return {"health": stats[0], "speed": stats[1], "damage": stats[2], "size": stats[3], "behavior": stats[4], "cell": stats[5], "xp": stats[6], "dark": kind in ENEMIES[2] or kind in MINIBOSSES[2] or kind in ["Ghost", "VoidWisp", "Reaper", "VoidEscort", "ObsidianDeath"]}
