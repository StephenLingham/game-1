extends Node
var failures := 0
var main: Node
var wc: Node

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

func fresh_run(reset_clock: bool = true) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await frames()
	main = get_tree().current_scene
	wc = main.wave_controller
	wc.set_process(false)
	wc.spawn_timer.stop()
	main.player.set_physics_process(false)
	main.player.health = 57
	if reset_clock:
		GameState.run_elapsed_seconds = 0.0
	# Avoid upgrade popups while verifying boss deaths and their XP drops.
	GameState.run_xp_to_next_level = 10000000

func clear_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	for hazard in get_tree().get_nodes_in_group("enemy_hazards"):
		hazard.queue_free()
	await frames()

func _run() -> void:
	check(String(ProjectSettings.get_setting("application/config/name")).contains("Campaign Verification"), "Use an isolated test project")
	if failures:
		get_tree().quit(1)
		return
	reparent(get_tree().root)
	seed(9371)
	if GameConstants.DEBUG_STARTING_STAGE > 1:
		await verify_debug_start()
		return
	await fresh_run()
	check(wc.stage == 0 and wc.wave == 1, "Run must begin in Mushroom Forest")
	check(wc._choose_spawn_data_for_wave().scene == wc.enemy_tree_scene, "Forest first wave changed")
	check(GameConstants.ENEMY_BOSS_HEALTH == 30000, "Fox health changed")
	for area in [1, 2]:
		var wave_types: Array = RunCampaign.WAVE_ENEMIES[area]
		var unique_types := {}
		for kind in wave_types:
			unique_types[kind] = true
		check(wave_types.size() == 10 and unique_types.size() == 10, "Every late-campaign wave needs an exclusive enemy type")
		check(RunCampaign.WAVE_MECHANICS[area].size() == 10, "Every late-campaign wave needs a mechanic")
		var projectile_waves := wave_types.filter(func(kind): return RunCampaign.enemy_data(kind).behavior in ["ranged", "breath", "orbit", "inferno", "death"])
		check(projectile_waves.size() == 2, "Projectile enemies must be limited to one marksman wave and the boss")
	check(RunCampaign.enemy_data("Cinderling").health == 1 and RunCampaign.enemy_data("Cinderling").speed > GameConstants.PLAYER_SPEED, "Cinderling rush balance changed")
	check(is_equal_approx(float(RunCampaign.enemy_data("MagmaSentinel").speed), GameConstants.PLAYER_SPEED * 0.9), "Endurance miniboss must move at 90% player speed")
	await clear_enemies()
	wc.stage = 1
	wc.wave = 1
	wc._wave_spawn_step = 0
	wc._spawn_campaign_tick()
	var rushers := get_tree().get_nodes_in_group("enemies").filter(func(e): return e.enemy_type == "Cinderling")
	check(rushers.size() == 4 and rushers.all(func(e): return e.health == 1), "Rapid rush tick must spawn four one-health Cinderlings")
	await clear_enemies()
	wc.wave = 8
	wc._wave_spawn_step = 0
	for i in range(5):
		wc._spawn_campaign_tick()
	var wall_enemies := get_tree().get_nodes_in_group("enemies").filter(func(e): return e.enemy_type == "LavaCrawler")
	check(wall_enemies.size() == 32, "Four delayed wall steps must spawn exactly four eight-enemy walls")
	await clear_enemies()
	# Render all new assets and exercise attacks/status effects at all difficulties.
	for difficulty in [[1.0, 1.0, 1.0], [2.0, 1.5, 1.3], [4.0, 3.0, 1.8]]:
		GameState.run_difficulty_health_mult = difficulty[0]
		GameState.run_difficulty_damage_mult = difficulty[1]
		GameState.run_difficulty_spawn_mult = difficulty[2]
		for area in [1, 2]:
			wc.stage = area
			wc.wave = 0
			wc._next_wave()
			var base_wait := 0.42 if area == 1 else 2.8
			check(is_equal_approx(wc.spawn_timer.wait_time, base_wait / difficulty[2] / GameState.get_spawn_rate_multiplier()), "Spawn difficulty scaling failed")
			wc.spawn_timer.stop()
			main.transition_to_area(area)
			await frames()
			var kinds: Array = RunCampaign.WAVE_ENEMIES[area] + RunCampaign.SUPPORT_ENEMIES[area]
			var spawned: Array = []
			for i in range(kinds.size()):
				var kind: String = kinds[i]
				var pos: Vector2 = main.player.global_position + Vector2((i % 3 - 1) * 300, -130 if i < 3 else 185)
				var e = wc._spawn_enemy({"scene": wc.campaign_enemy_scene, "type": kind}, pos, true)
				e.set_physics_process(false)
				spawned.append(e)
				var data := RunCampaign.enemy_data(kind)
				var expected_health := 1 if kind == "Cinderling" else int(data.health * difficulty[0])
				check(e.health == expected_health, "Health scaling: " + kind)
				check(e.damage == int(data.damage * difficulty[1]), "Damage scaling: " + kind)
				check(e.sprite.texture is AtlasTexture, "Imported atlas missing: " + kind)
				e.ability_time = 0
				e._modify_movement(Vector2.RIGHT * e.speed, 0.1)
				var casts_ability: bool = data.behavior in ["breath", "slam", "orbit", "ranged", "charge", "banshee", "inferno", "death"]
				check(e.attacks_cast == (1 if casts_ability else 0), "Ability policy failed: " + kind)
				e.freeze(1.0)
				check(e._modify_movement(Vector2.RIGHT * e.speed, 0.1) == Vector2.ZERO, "Freeze failed: " + kind)
				e._freeze_timer = 0.0
				e.apply_slow(0.5, 1.0)
				e.apply_burn(2.0, 1.0)
				var old_health: int = e.health
				e._physics_process(0.5)
				check(e.health < old_health, "Burn failed: " + kind)
			if difficulty[0] == 1.0:
				for hazard in get_tree().get_nodes_in_group("enemy_hazards"):
					hazard.set_physics_process(false)
				wc.stage = area
				wc.wave = 4
				GameState.run_elapsed_seconds = float(area) * 300.0 + 90.0
				await get_tree().create_timer(1.2).timeout
				main.on_wave_started(4)
				main.on_wave_time(30)
				await screenshot("campaign-area-%d.png" % area)
			await clear_enemies()
	# Explicitly verify the new attacks cause damage and expire.
	var attack = load("res://scripts/enemy_hazard.gd").new()
	attack.position = main.player.global_position
	attack.warning = 0.1
	attack.lifetime = 0.2
	attack.damage = 1
	main.add_child(attack)
	var hp_before: int = main.player.health
	attack._physics_process(0.05)
	check(main.player.health == hp_before, "Warning dealt damage too early")
	attack._physics_process(0.1)
	check(main.player.health < hp_before, "Active hazard did not damage player")
	attack._physics_process(0.3)
	await frames()
	check(not is_instance_valid(attack), "Expired hazard leaked")
	GameState.run_difficulty_health_mult = 1.0
	GameState.run_difficulty_damage_mult = 1.0
	GameState.run_difficulty_spawn_mult = 1.0
	await fresh_run()
	var original_player = main.player
	GameState.run_abilities = {"zap": 3, "fireball": 2}
	GameState.run_items = ["giant_slayer"]
	GameState.run_level = 8
	var abilities := GameState.run_abilities.duplicate()
	# Advance all thirty real wave boundaries, leaving boss fights and portal
	# entry in the same active-play time budget.
	for area in range(3):
		if area > 0:
			check(wc.wave == 0, "Early portal skipped the arrival interval")
			var start := float(area) * 300.0
			wc.advance_time(start - GameState.run_elapsed_seconds)
		check(wc.stage == area and wc.wave == 1, "Wrong stage boundary")
		for wave_number in range(1, 11):
			check(wc.wave == wave_number, "Wave schedule mismatch")
			if area > 0:
				var signature := RunCampaign.wave_enemy(area, wave_number)
				var data: Dictionary = wc._choose_spawn_data_for_wave()
				check(data.type == signature, "Wrong signature enemy for wave: " + signature)
				check(get_tree().get_nodes_in_group("enemies").any(func(e): return e.enemy_type == signature), "Signature enemy did not appear: " + signature)
				if wave_number in [4, 7]:
					var expected: String = RunCampaign.MINIBOSSES[area][0 if wave_number == 4 else 1]
					check(get_tree().get_nodes_in_group("enemies").any(func(e): return e.enemy_type == expected), "Missing miniboss " + expected)
			wc.spawn_timer.stop()
			if wave_number < 10:
				await clear_enemies()
				wc.advance_time(30.0)
		var bosses := get_tree().get_nodes_in_group("enemies").filter(func(e): return RunCampaign.is_boss(e.enemy_type))
		check(bosses.size() == 1, "Expected exactly one area boss")
		if bosses.is_empty():
			get_tree().quit(1)
			return
		var boss = bosses[0]
		check(boss.enemy_type == RunCampaign.BOSSES[area], "Wrong boss")
		check(main.player._is_boss(boss), "Boss damage bonus does not recognize boss")
		# Kill through the normal damage path so rewards, signals, and disposal run.
		boss.take_damage(boss.health, "test")
		await frames()
		check(wc.bosses_defeated == area + 1, "Boss count is wrong")
		check(not main.game_over_panel.visible, "Boss ended the run early")
		if area < 2:
			var portals := get_tree().get_nodes_in_group("stage_portals")
			check(portals.size() == 1, "Boss must create one portal")
			if area == 0:
				await screenshot("campaign-portal.png")
			if portals.is_empty():
				get_tree().quit(1)
				return
			var health_before: int = main.player.health
			main.player.global_position = portals[0].global_position
			portals[0]._physics_process(0.7)
			await frames(5)
			check(wc.stage == area + 1, "Walking into portal did not change area")
			check(main.player == original_player and main.player.health == health_before, "Portal changed player or health")
			check(GameState.run_abilities == abilities and GameState.run_level == 8 and GameState.run_items == ["giant_slayer"], "Portal lost upgrades")
			check(get_tree().get_nodes_in_group("enemies").is_empty(), "Enemies survived portal")
			check(get_tree().get_nodes_in_group("enemy_hazards").is_empty(), "Hostile attacks survived portal")
			check(get_tree().get_nodes_in_group("stage_portals").is_empty(), "Portal was not freed")
		else:
			wc.advance_time(29.99)
			check(not main.game_over_panel.visible, "Victory occurred before 15:00")
			wc.advance_time(0.1)
			await frames()
			check(GameState.run_elapsed_seconds == 900.0, "Run did not stop exactly at 15:00")
			check(main.game_over_panel.visible and wc.bosses_defeated == 3 and wc.completed_waves == 30, "Campaign victory failed")
			await screenshot("campaign-victory.png")
	# A live boss or ignored portal must not allow advancing beyond five minutes.
	for kill_boss in [false, true]:
		await fresh_run()
		wc.wave = 9
		wc._next_wave()
		wc.spawn_timer.stop()
		if kill_boss:
			for boss in get_tree().get_nodes_in_group("enemies"):
				boss.take_damage(boss.health, "test")
			await frames()
		wc.advance_time(300.0)
		await frames()
		check(wc.finished and main.game_over_panel.visible and not wc.failure_reason.is_empty(), "Area deadline did not fail")
		check(wc.stage == 0 and GameState.run_elapsed_seconds == 300.0, "Deadline advanced without entering portal")
	# Restart, leave during active hazards, then verify scene ownership/cleanup.
	await fresh_run()
	main.transition_to_area(2)
	wc.stage = 2
	wc._spawn_enemy({"scene": wc.campaign_enemy_scene, "type": "ObsidianDeath"}, main.player.global_position + Vector2(300, 0), true)
	await frames(120)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
	await frames(8)
	check(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) == 0, "Orphan nodes after scene cleanup")
	print("CAMPAIGN_TEST_RESULT failures=", failures, " waves=30 bosses=3 minibosses=4 difficulties=3 duration=900 orphans=", Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	get_tree().quit(0 if failures == 0 else 1)

func verify_debug_start() -> void:
	await fresh_run(false)
	var expected_stage := clampi(GameConstants.DEBUG_STARTING_STAGE, 1, 3) - 1
	var expected_wave := clampi(GameConstants.DEBUG_STARTING_WAVE, 1, 10)
	var expected_clock := float(expected_stage * 300 + (expected_wave - 1) * 30)
	check(wc.stage == expected_stage and wc.wave == expected_wave, "Debug stage/wave not applied")
	check(absf(GameState.run_elapsed_seconds - expected_clock) < 1.0, "Debug clock has wrong offset")
	check(wc.bosses_defeated == expected_stage, "Skipped bosses not seeded")
	check(wc.completed_waves == expected_stage * 10 + expected_wave - 1, "Skipped waves not seeded")
	var floor_texture: Texture2D = main.get_node("ArenaFloor").texture
	var expected_texture := "volcanic-rock.png" if expected_stage == 1 else "starfield.png"
	check(floor_texture.resource_path.ends_with(expected_texture), "Wrong debug arena")
	check(wc.spawning, "Debug entry is waiting instead of spawning")
	var data: Dictionary = wc._choose_spawn_data_for_wave()
	check(data.type in RunCampaign.ENEMIES[expected_stage], "Wrong debug enemy roster")
	wc._spawn_enemy(data, main.player.global_position + Vector2(300, 0))
	# Advance to and defeat each remaining boss through the regular damage path.
	for area in range(expected_stage, 3):
		var boss_time := float(area * 300 + 270)
		wc.advance_time(maxf(0.0, boss_time - GameState.run_elapsed_seconds))
		wc.spawn_timer.stop()
		var bosses := get_tree().get_nodes_in_group("enemies").filter(func(e): return RunCampaign.is_boss(e.enemy_type))
		check(bosses.size() == 1, "Debug boss missing or duplicated")
		if bosses.is_empty():
			get_tree().quit(1)
			return
		bosses[0].take_damage(bosses[0].health, "test")
		await frames()
		if area < 2:
			var portals := get_tree().get_nodes_in_group("stage_portals")
			check(portals.size() == 1, "Debug boss did not create portal")
			main.player.global_position = portals[0].global_position
			portals[0]._physics_process(0.7)
			await frames(5)
			check(wc.stage == area + 1, "Debug portal progression failed")
		else:
			wc.advance_time(900.0 - GameState.run_elapsed_seconds)
			await frames()
			check(main.game_over_panel.visible and wc.bosses_defeated == 3 and wc.completed_waves == 30, "Debug start cannot finish campaign")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
	await frames(8)
	check(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) == 0, "Debug entry leaked nodes")
	print("DEBUG_START_TEST_RESULT failures=", failures, " stage=", expected_stage + 1, " wave=", expected_wave, " orphans=", Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	get_tree().quit(0 if failures == 0 else 1)
