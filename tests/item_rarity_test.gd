extends Node
# Run in an isolated copy; this test acquires items and changes unlock state.
var failures: int = 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func frames(count: int = 3) -> void:
	for i in range(count):
		await get_tree().process_frame

func screenshot(filename: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://" + filename)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()

func _run() -> void:
	check(String(ProjectSettings.get_setting("application/config/name")).contains("Rarity Verification"), "Use an isolated verification project")
	if failures > 0:
		get_tree().quit(1)
		return
	reparent(get_tree().root)
	seed(41827)
	var ids: Array = GameConstants.ITEMS.keys()
	for id in ids:
		check(GameConstants.ITEMS[id].has("rarity"), "Missing rarity: " + id)
		check(ItemRarity.WEIGHTS.has(ItemRarity.tier(id)), "Invalid rarity: " + id)
	var representatives := ["quantum_socks", "pirate_rum", "atlas_eye", "volley_charm", "hex_nails"]
	var counts := {}
	for id in representatives:
		counts[id] = 0
	for i in range(30000):
		var result := ItemRarity.roll_options(representatives, 1)
		counts[result[0]] += 1
	for id in representatives:
		var observed := float(counts[id]) / 30000.0
		var expected := float(ItemRarity.WEIGHTS[ItemRarity.tier(id)]) / 179.0
		check(abs(observed - expected) < 0.015, "Wrong weight distribution: " + id)
	print("WEIGHT_DISTRIBUTION ", counts)
	for i in range(1000):
		var options := ItemRarity.roll_options(ids)
		check(options.size() == 3 and options[0] != options[1] and options[1] != options[2] and options[0] != options[2], "Duplicate/short chest")
	check(ItemRarity.roll_options([]).is_empty(), "Empty pool failed")
	check(ItemRarity.roll_options(["invalid", "quantum_socks", "quantum_socks"]) == ["quantum_socks"], "Invalid/duplicate filtering failed")
	GameState.unlocked_treasure_items = ["quantum_socks", "pirate_rum", "phoenix_idol", "ninja_wizard_cat", "invalid"]
	GameState.sealed_items = ["pirate_rum"]
	GameState.run_items = ["phoenix_idol", "ninja_wizard_cat"]
	check(GameState.roll_chest_options() == ["quantum_socks"], "Locked, sealed or unique exclusion failed")
	GameState.sealed_items.append("quantum_socks")
	check(GameState.roll_chest_options().is_empty(), "Fully excluded pool failed")
	GameState.sealed_items.clear()
	GameState.run_items.clear()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await frames()
	var main = get_tree().current_scene
	# Exercise an actual chest spawn/collection and item-button signal.
	GameState.unlocked_treasure_items = ["quantum_socks", "pirate_rum", "atlas_eye"]
	var chest = load("res://scenes/TreasureChest.tscn").instantiate()
	main.add_child(chest)
	chest._collect()
	await frames()
	check(not is_instance_valid(chest), "Collected chest was not freed")
	var grid = main.item_popup_panel.get_node("Margin/VBox/ItemGrid")
	var chosen: String = main.current_chest_options[0]
	grid.get_child(0).pressed.emit()
	check(GameState.has_run_item(chosen), "Item button did not acquire item")
	GameState.run_items.clear()
	# Render every actual item card, including long names/descriptions, and free
	# each prior batch through the real chest refresh path.
	for offset in range(0, ids.size(), 3):
		GameState.unlocked_treasure_items = ids.slice(offset, offset + 3)
		main.show_item_window()
		await frames()
		check(grid.get_child_count() == GameState.unlocked_treasure_items.size(), "Stale chest cards")
		for button in grid.get_children():
			check(button.get_global_rect().end.x <= get_viewport().get_visible_rect().size.x + 1, "Chest card exceeds viewport horizontally")
			check(button.get_global_rect().end.y <= get_viewport().get_visible_rect().size.y + 1, "Chest card exceeds viewport vertically")
		if offset == 0:
			await screenshot("chest-common.png")
		if offset == 39:
			await screenshot("chest-long-description.png")
		main._close_item_window()
	GameState.unlocked_treasure_items = ["atlas_eye", "volley_charm", "hex_nails"]
	main.show_item_window()
	await frames()
	await screenshot("chest-high-rarities.png")
	main._close_item_window()
	GameState.unlocked_treasure_items = []
	main.show_item_window()
	await frames()
	check(grid.get_child_count() == 1 and grid.get_child(0) is Label, "Empty chest message missing")
	main._on_item_chosen("skip")
	check(not get_tree().paused, "Skip left game paused")
	GameState.run_items = representatives.duplicate()
	main._toggle_pause()
	await frames()
	await screenshot("rarity-inventory.png")
	main._resume()
	get_tree().change_scene_to_file("res://scenes/Unlocks.tscn")
	await frames()
	GameState.unlocked_treasure_items = ids.duplicate()
	var unlocks = get_tree().current_scene
	unlocks._on_view_changed("items")
	await frames()
	check(unlocks.grid.get_child_count() == ids.size(), "Catalogue missing items")
	await screenshot("rarity-catalogue.png")
	unlocks._on_view_changed("weapons")
	await frames()
	unlocks._on_view_changed("items")
	await frames()
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
	await frames()
	check(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) == 0, "Orphan nodes remain after scene cleanup")
	print("RARITY_TEST_RESULT failures=", failures, " items=", ids.size(), " orphans=", Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	get_tree().quit(0 if failures == 0 else 1)
