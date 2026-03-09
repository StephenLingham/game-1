extends Area2D

var value: int = 1

func _ready() -> void:
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		collect(body)

func collect(_player: Node) -> void:
	GameState.run_gold += value
	queue_free()
