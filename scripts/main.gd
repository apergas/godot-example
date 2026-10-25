extends Node2D

@onready var _worker: CharacterBody2D = $Worker


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	var point := get_global_mouse_position()
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			_worker.selected = _worker.contains_point(point)
		MOUSE_BUTTON_RIGHT:
			if _worker.selected:
				_worker.move_to(point)
