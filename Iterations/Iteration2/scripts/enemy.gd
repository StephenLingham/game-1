extends CharacterBody2D

@export var move_speed: float = 140.0
@export var max_health: int = 30
@export var contact_dps: float = 12.0
@export var gold_drop_min: int = 1
@export var gold_drop_max: int = 3

var health: int
var player: Node2D

func _ready() -> void:
	health = max_health
	player = get_tree().current_scene.get_node_or_null("Player")
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if player == null:
		return
	var dir := (player.global_position - global_position).normalized()
	velocity = dir * move_speed
	move_and_slide()

	# Simple contact damage
	if global_position.distance_to(player.global_position) < 18.0:
		player.apply_damage(int(round(contact_dps * delta)))

func apply_damage(amount: int) -> void:
	health = max(health - amount, 0)
	if health == 0:
		_drop_gold()
		queue_free()

func _drop_gold() -> void:
	var pickup := preload("res://scenes/GoldPickup.tscn").instantiate()
	pickup.global_position = global_position
	pickup.value = randi_range(gold_drop_min, gold_drop_max)
	get_tree().current_scene.get_node("PickupContainer").add_child(pickup)
