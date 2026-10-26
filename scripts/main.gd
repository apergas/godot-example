extends Node2D

const FORMATION_SPACING := 40.0
const OrderMarker := preload("res://scripts/order_marker.gd")
const CRYSTAL_SCENE := preload("res://scenes/resources/crystal.tscn")
const ICE_SCENE := preload("res://scenes/resources/ice.tscn")
const HQ_SCENE := preload("res://scenes/buildings/hq.tscn")
const WORKER_SCENE := preload("res://scenes/worker.tscn")

@onready var _selection: Selection = $Selection
@onready var _hud: CanvasLayer = $HUD
@onready var _world: Node2D = $World
@onready var _placement: Placement = $Placement


func _ready() -> void:
	_hud.connect("train_requested", _on_train_requested)
	_selection.changed.connect(Callable(_hud, "show_for_selection"))
	_placement.world = _world
	_hud.connect("build_requested", Callable(_placement, "begin"))
	_placement.placed.connect(_on_building_placed)
	_spawn_resources()
	var hq := _spawn_hq()
	_spawn_workers()
	($Camera2D as Camera2D).position = hq.position + Vector2(0.0, -Grid.TILE * 1.5)


func _process(_delta: float) -> void:
	_update_hover()


func _unhandled_input(event: InputEvent) -> void:
	if _placement.active:
		return
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
				if _try_build_order(point):
					return
				command_move(point)


func command_move(point: Vector2) -> void:
	_order_workers(_selected_workers(), point)


func _order_workers(workers: Array, point: Vector2) -> void:
	if workers.is_empty():
		return
	var node := _resource_at(point)
	if node != null:
		for worker in workers:
			worker.gather(node)
		return
	var building := _building_at(point)
	if building != null:
		for worker in workers:
			if worker.carry_amount > 0 and building.accepts(worker.carry_kind):
				worker.return_cargo(building)
			else:
				worker.move_to(point)
		return
	# Closest robots take the inner slots, so the group does not cross over itself.
	workers.sort_custom(func(a: Node2D, b: Node2D) -> bool: return a.global_position.distance_squared_to(point) < b.global_position.distance_squared_to(point))
	var targets := Formation.targets(point, workers.size(), FORMATION_SPACING)
	for i in workers.size():
		workers[i].move_to(targets[i])
	_spawn_marker(targets[0])


func _on_train_requested() -> void:
	for item in _selection.items:
		if is_instance_valid(item) and item is HQ:
			item.enqueue_worker()


func _selected_workers() -> Array:
	var result: Array = []
	for item in _selection.items:
		if is_instance_valid(item) and item.is_in_group("workers"):
			result.append(item)
	return result


func _building_at(point: Vector2) -> Building:
	for node in get_tree().get_nodes_in_group("buildings"):
		var building := node as Building
		if building != null and building.contains_point(point):
			return building
	return null


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


func _spawn_hq() -> HQ:
	var hq := HQ_SCENE.instantiate() as HQ
	hq.position = Grid.footprint_origin(MapLayout.HQ_CELL, hq.footprint)
	_world.add_child(hq)
	return hq


func _on_building_placed(building: Building) -> void:
	for worker in _selected_workers():
		worker.build(building)


func _unfinished_building_at(point: Vector2) -> Building:
	for node in get_tree().get_nodes_in_group("buildings"):
		var building := node as Building
		if building != null and not building.built and building.contains_point(point):
			return building
	return null


func _try_build_order(point: Vector2) -> bool:
	var site := _unfinished_building_at(point)
	var builders := _selected_workers()
	if site == null or builders.is_empty():
		return false
	for worker in builders:
		worker.build(site)
	return true


func _spawn_workers() -> void:
	for i in MapLayout.START_WORKERS:
		var worker := WORKER_SCENE.instantiate() as Node2D
		var cell := Vector2i(MapLayout.HQ_CELL.x + i % 3, MapLayout.HQ_CELL.y + 3 + floori(i / 3.0))
		worker.position = Grid.cell_to_world(cell)
		_world.add_child(worker)
