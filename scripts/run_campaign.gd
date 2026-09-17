extends RefCounted
class_name RunCampaign

const AREA_SECONDS := 300.0
const RUN_SECONDS := 900.0
const NAMES := ["Mushroom Forest", "Crimson Citadel", "Obsidian Obelisk - The Darkest Darkness"]
const ENEMIES := [["Normal", "Fast", "Big"], ["Dragon", "FireGolem", "FireElemental"], ["Ghost", "VoidWisp", "Reaper"]]
const MINIBOSSES := [[], ["MagmaSentinel", "ElderDrake"], ["DreadKnight", "BansheeQueen"]]
const BOSSES := ["Boss", "InfernoDragon", "ObsidianDeath"]

static func is_boss(kind: String) -> bool:
	return kind in BOSSES

static func is_miniboss(kind: String) -> bool:
	return kind in MINIBOSSES[1] or kind in MINIBOSSES[2]

static func is_campaign_enemy(kind: String) -> bool:
	return kind in ENEMIES[1] or kind in ENEMIES[2] or is_miniboss(kind) or kind in ["InfernoDragon", "ObsidianDeath"]

# Health, speed, contact damage, visual diameter, behavior, atlas cell, XP.
static func enemy_data(kind: String) -> Dictionary:
	var stats: Array = {
		"Dragon": [240, 85, 24, 86, "breath", 0, 24],
		"FireGolem": [900, 42, 38, 110, "slam", 1, 60],
		"FireElemental": [180, 105, 22, 76, "orbit", 2, 22],
		"MagmaSentinel": [6500, 38, 48, 180, "slam", 3, 220],
		"ElderDrake": [8000, 72, 45, 190, "breath", 4, 260],
		"InfernoDragon": [45000, 52, 65, 290, "inferno", 5, 500],
		"Ghost": [420, 92, 32, 82, "phase", 0, 38],
		"VoidWisp": [280, 125, 28, 68, "orbit", 1, 30],
		"Reaper": [1100, 70, 48, 112, "charge", 2, 75],
		"DreadKnight": [12000, 62, 62, 180, "charge", 3, 350],
		"BansheeQueen": [10000, 65, 52, 185, "banshee", 4, 350],
		"ObsidianDeath": [65000, 57, 80, 310, "death", 5, 750],
	}[kind]
	return {"health": stats[0], "speed": stats[1], "damage": stats[2], "size": stats[3], "behavior": stats[4], "cell": stats[5], "xp": stats[6], "dark": kind in ENEMIES[2] or kind in MINIBOSSES[2] or kind == "ObsidianDeath"}
