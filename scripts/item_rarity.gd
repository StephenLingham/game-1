class_name ItemRarity
extends RefCounted

# Per-item weights, not tier percentages: an individual stronger item is rarer
# even when unlocks/seals leave different numbers of items in each tier.
const WEIGHTS: Dictionary = {"common": 100.0, "uncommon": 50.0, "rare": 20.0, "epic": 7.0, "legendary": 2.0}

static func tier(item_id: String) -> String:
	return String(GameConstants.ITEMS.get(item_id, {}).get("rarity", "common"))

static func color(item_id: String) -> Color:
	return GameConstants.RARITY_COLORS[tier(item_id)]

static func label(item_id: String) -> String:
	return GameConstants.RARITY_NAMES[tier(item_id)]

static func roll_options(eligible: Array, count: int = 3) -> Array:
	var pool: Array = []
	for item_id in eligible:
		if GameConstants.ITEMS.has(item_id) and not pool.has(item_id):
			pool.append(item_id)
	var result: Array = []
	while result.size() < count and not pool.is_empty():
		var total := 0.0
		for item_id in pool:
			total += float(WEIGHTS[tier(item_id)])
		var roll := randf() * total
		var selected: int = pool.size() - 1
		for i in range(pool.size()):
			roll -= float(WEIGHTS[tier(pool[i])])
			if roll < 0.0:
				selected = i
				break
		result.append(pool[selected])
		pool.remove_at(selected)
	return result

static func card_style(accent: Color, highlighted: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.06, 0.09).lerp(accent, 0.16 if highlighted else 0.06)
	style.border_color = accent.lightened(0.2) if highlighted else accent
	style.set_border_width_all(3 if highlighted else 2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	return style
