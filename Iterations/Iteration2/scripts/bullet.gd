extends Area2D

@export var speed: float = 650.0
var direction: Vector2 = Vector2.RIGHT
var damage: int = 10

@onready var life_timer: Timer = $LifeTimer

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	life_timer.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	global_position += direction.normalized() * speed * delta

func _hit(target: Node) -> void:
	if target.has_method("apply_damage"):
		target.apply_damage(damage)
	queue_free()

func _on_area_entered(a: Area2D) -> void:
	_hit(a)

func _on_body_entered(b: Node) -> void:
	_hit(b)
