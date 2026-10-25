extends Node2D

const FORMATION_SPACING := 40.0
const OrderMarker := preload("res://scripts/order_marker.gd")

@onready var _selection: Selection = $Selection


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_selection.update_drag(get_global_mouse_position())
		return
	if not (event is InputEventMouseButton):
		return
	var button := event as InputEventMouseButton
	var point := get_global_mouse_position()
	match button.button_index:
		MOUSE_BUTTON_LEFT:
			if button.pressed:
				_selection.begin_drag(point)
			else:
				_selection.end_drag(point, button.shift_pressed)
		MOUSE_BUTTON_RIGHT:
			if button.pressed:
				command_move(point)


func command_move(point: Vector2) -> void:
	var workers: Array = []
	for item in _selection.items:
		if is_instance_valid(item) and item.is_in_group("workers"):
			workers.append(item)
	if workers.is_empty():
		return
	# Closest robots take the inner slots, so the group does not cross over itself.
	workers.sort_custom(func(a: Node2D, b: Node2D) -> bool: return a.global_position.distance_squared_to(point) < b.global_position.distance_squared_to(point))
	var targets := Formation.targets(point, workers.size(), FORMATION_SPACING)
	for i in workers.size():
		workers[i].move_to(targets[i])
	_spawn_marker(targets[0])


func _spawn_marker(point: Vector2) -> void:
	var marker: Node2D = OrderMarker.new()
	marker.position = point
	marker.z_index = -5
	add_child(marker)
