extends CharacterBody2D

signal player_died

var speed: float = GameConstants.PLAYER_SPEED
var fire_rate: float = GameConstants.PLAYER_FIRE_RATE
var max_health: int = GameConstants.PLAYER_MAX_HEALTH
var base_damage: int = GameConstants.PLAYER_BASE_DAMAGE

var health: int
var can_fire: bool = true
var fire_timer: float = 0.0

# Click / tap-to-move support
var _click_target: Vector2 = Vector2.ZERO
var _has_click_target: bool = false

@onready var muzzle: Marker2D = $Muzzle
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")

func _ready() -> void:
	health = max_health

func _physics_process(delta: float) -> void:
	# Movement
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")

	if input_dir.length() > 0.0:
		# Keyboard / controller input takes priority
		_has_click_target = false
		if input_dir.length() > 1.0:
			input_dir = input_dir.normalized()
		velocity = input_dir * speed
	elif _has_click_target:
		var to_target := _click_target - global_position
		if to_target.length() <= 4.0:
			_has_click_target = false
			velocity = Vector2.ZERO
		else:
			velocity = to_target.normalized() * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	
	# Find nearest enemy and aim at it
	var nearest_enemy := _get_nearest_enemy()
	
	if nearest_enemy:
		look_at(nearest_enemy.global_position)
	
	# Auto-fire
	if not can_fire:
		fire_timer -= delta
		if fire_timer <= 0.0:
			can_fire = true
	
	if can_fire and nearest_enemy:
		fire()

func get_damage() -> int:
	var dmg := float(base_damage + GameState.run_damage_bonus)
	dmg *= GameState.get_damage_multiplier()
	return int(round(dmg))

func _get_fire_interval() -> float:
	var atk_mult := GameState.get_atkspd_multiplier() * GameState.run_atkspd_mult
	var interval: float = fire_rate / max(atk_mult, 0.05)
	return max(interval, 0.02)

func _unhandled_input(event: InputEvent) -> void:
	# Tap / click-to-move for mobile & mouse
	if event is InputEventScreenTouch and event.pressed:
		_set_click_target(event.position)
	elif event is InputEventScreenDrag:
		_set_click_target(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_set_click_target(event.position)

func _set_click_target(screen_pos: Vector2) -> void:
	var world_pos := screen_pos
	var cam := get_viewport().get_camera_2d()
	if cam:
		world_pos = cam.screen_to_world(screen_pos)
	_click_target = world_pos
	_has_click_target = true

func _get_nearest_enemy() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var closest_dist := INF
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist := global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = enemy
	
	return closest

func fire() -> void:
	can_fire = false
	fire_timer = _get_fire_interval()
	
	var bullet := bullet_scene.instantiate() as Area2D
	bullet.global_position = muzzle.global_position
	bullet.rotation = rotation
	bullet.direction = Vector2.RIGHT.rotated(rotation)
	bullet.damage = get_damage()
	get_tree().current_scene.add_child(bullet)

func take_damage(amount: int = 1) -> void:
	health -= amount
	
	# Flash red
	sprite.modulate = Color(1, 0.3, 0.3)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
	
	if health <= 0:
		player_died.emit()
