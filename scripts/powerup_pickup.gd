extends Area2D

enum Type { MAGNET, SPEED, HEAL, ROCKET, CRYSTAL, ATK_SPEED }

@export var type: Type = Type.MAGNET

var _tex_magnet = preload("res://assets/powerup_magnet_2.png")
var _tex_speed = preload("res://assets/powerup_speed_2.png")
var _tex_heal = preload("res://assets/powerup_heal_2.png")
var _tex_explosion = preload("res://assets/powerup_explosion_2.png")
var _tex_crystal = preload("res://assets/gem_icon.png")
var _tex_atk_speed = preload("res://assets/powerup_atkspeed.png")

func _ready() -> void:
	add_to_group("powerups")
	body_entered.connect(_on_body_entered)
	
	# Visual setup based on type
	var sprite = $Sprite2D
	if sprite:
		var tex: Texture2D = null
		match type:
			Type.MAGNET: tex = _tex_magnet
			Type.SPEED: tex = _tex_speed
			Type.HEAL: tex = _tex_heal
			Type.ROCKET: tex = _tex_explosion
			Type.CRYSTAL: tex = _tex_crystal
			Type.ATK_SPEED: tex = _tex_atk_speed
		
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


func _process(delta: float) -> void:
	if type != Type.CRYSTAL or not GameState.has_run_item("crystal_magnet"):
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var direction: Vector2 = (player.global_position - global_position).normalized()
	global_position += direction * GameConstants.MAGNET_SPEED * delta
	if global_position.distance_to(player.global_position) < 18.0:
		collect(player)

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
			if player.health < player.max_health:
				player.heal_full()
			else:
				return # Prevent collection
		Type.ROCKET:
			player.trigger_rocket_blast()
		Type.CRYSTAL:
			GameState.award_crystals(GameConstants.POWERUP_CRYSTAL_AWARD_AMOUNT)
		Type.ATK_SPEED:
			if player.has_method("apply_atk_speed_boost"):
				player.apply_atk_speed_boost(GameConstants.POWERUP_ATK_SPEED_BOOST_MULTIPLIER, GameConstants.POWERUP_ATK_SPEED_BOOST_DURATION)
			
	queue_free()

func _apply_magnet(player: Node) -> void:
	var xp_drops = get_tree().get_nodes_in_group("xp_drops")
	for xp in xp_drops:
		if is_instance_valid(xp):
			if "is_magnetized" in xp:
				xp.is_magnetized = true
				xp.player = player

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
		Type.CRYSTAL: particles.color = Color(0.8, 0, 1)
		Type.ATK_SPEED: particles.color = Color(1, 0, 0)
		
	get_tree().current_scene.add_child(particles)
	get_tree().create_timer(1.0).timeout.connect(particles.queue_free)
