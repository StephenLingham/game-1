extends Area2D

enum Type { MAGNET, SPEED, HEAL, ROCKET, GEM }

@export var type: Type = Type.MAGNET

func _ready() -> void:
	add_to_group("powerups")
	body_entered.connect(_on_body_entered)
	
	# Visual setup based on type
	var sprite = $Sprite2D
	if sprite:
		var tex_path := ""
		match type:
			Type.MAGNET: tex_path = "res://assets/powerup_magnet_2.png"
			Type.SPEED: tex_path = "res://assets/powerup_speed_2.png"
			Type.HEAL: tex_path = "res://assets/powerup_heal_2.png"
			Type.ROCKET: tex_path = "res://assets/powerup_explosion_2.png"
			Type.GEM: tex_path = "res://assets/gem_icon.png"
		
		if ResourceLoader.exists(tex_path):
			var tex = load(tex_path)
			if tex:
				sprite.texture = tex
		
		# Reset spritesheet logic
		sprite.hframes = 1
		sprite.frame = 0
		# Adjust scale for high-res icons
		var s = GameConstants.POWERUP_ICON_SCALE
		sprite.scale = Vector2(s, s)
		
	# Float animation
	var tween = create_tween().set_loops()
	tween.tween_property($Sprite2D, "position:y", -5.0, 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property($Sprite2D, "position:y", 5.0, 1.0).set_trans(Tween.TRANS_SINE)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		collect(body)

func collect(player: Node) -> void:
	match type:
		Type.MAGNET:
			_apply_magnet(player)
		Type.SPEED:
			player.apply_speed_boost(GameConstants.POWERUP_SPEED_BOOST_MULTIPLIER, GameConstants.POWERUP_SPEED_BOOST_DURATION)
		Type.HEAL:
			player.heal_full()
		Type.ROCKET:
			player.trigger_rocket_blast()
		Type.GEM:
			GameState.award_gems(GameConstants.POWERUP_GEM_AWARD_AMOUNT)
			
	# Spawn some particles or effect
	_spawn_collect_effect()
	queue_free()

func _apply_magnet(player: Node) -> void:
	var gold_pickups = get_tree().get_nodes_in_group("gold_pickups")
	for gold in gold_pickups:
		if is_instance_valid(gold) and gold.has_method("collect"):
			# In gold_pickup.gd, magnetizing is done by setting is_magnetized = true
			if "is_magnetized" in gold:
				gold.is_magnetized = true
				gold.player = player

func _spawn_collect_effect() -> void:
	var particles = CPUParticles2D.new()
	particles.global_position = global_position
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.amount = 15
	particles.lifetime = 0.6
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 100.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	
	match type:
		Type.MAGNET: particles.color = Color(1, 0.9, 0)
		Type.SPEED: particles.color = Color(0, 1, 1)
		Type.HEAL: particles.color = Color(0, 1, 0)
		Type.ROCKET: particles.color = Color(1, 0.2, 0)
		Type.GEM: particles.color = Color(0.8, 0, 1)
		
	get_tree().current_scene.add_child(particles)
	get_tree().create_timer(1.0).timeout.connect(particles.queue_free)
