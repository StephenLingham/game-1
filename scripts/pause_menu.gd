class_name PauseMenu
extends Panel

signal escape_requested

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		escape_requested.emit()
		get_viewport().set_input_as_handled()

