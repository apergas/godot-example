extends Node2D

const FORMATION_SPACING := 40.0
const OrderMarker := preload("res://scripts/order_marker.gd")
const CRYSTAL_SCENE := preload("res://scenes/resources/crystal.tscn")
const ICE_SCENE := preload("res://scenes/resources/ice.tscn")

@onready var _selection: Selection = $Selection
@onready var _hud: CanvasLayer = $HUD


func _ready() -> void:
	$Selection.changed.connect(Callable(_hud, "show_for_selection"))
	_spawn_resources()


func _process(_delta: float) -> void:
	_update_hover()


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


func _spawn_resources() -> void:
	for c in MapLayout.CRYSTAL_CELLS:
		_spawn_resource(CRYSTAL_SCENE, c)
	for c in MapLayout.ICE_CELLS:
		_spawn_resource(ICE_SCENE, c)


func _spawn_resource(scene: PackedScene, c: Vector2i) -> ResourceNode:
	var node := scene.instantiate() as ResourceNode
	# Set before add_child: ResourceNode computes its cell in _ready (World sits at the origin).
	node.position = Grid.cell_to_world(c) + Vector2(0, Grid.TILE / 2.0 - 4)
	$World.add_child(node)
	return node


func _update_hover() -> void:
	var res := _resource_at(get_global_mouse_position())
	if res == null:
		_hud.hide_hover()
		return
	_hud.show_hover("%s: %d" % [ResKind.NAMES[res.kind], res.amount], get_viewport().get_mouse_position())


func _resource_at(point: Vector2) -> ResourceNode:
	var best: ResourceNode = null
	for node in get_tree().get_nodes_in_group("resources"):
		var res := node as ResourceNode
		if res == null or res.is_queued_for_deletion() or not res.contains_point(point):
			continue
		if best == null or res.global_position.y > best.global_position.y:
			best = res
	return best
