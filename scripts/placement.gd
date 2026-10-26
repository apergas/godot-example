class_name Placement
extends Node2D

signal placed(building: Building)

const NavScript := preload("res://scripts/nav.gd")
const GameStateScript := preload("res://scripts/game_state.gd")

const VALID_FILL := Color(0.3, 1.0, 0.4, 0.3)
const INVALID_FILL := Color(1.0, 0.25, 0.2, 0.3)
const GHOST_VALID := Color(1.0, 1.0, 1.0, 0.6)
const GHOST_INVALID := Color(1.0, 0.45, 0.45, 0.6)

var active := false
var world: Node2D
var footprint := Vector2i.ONE
var cost: Dictionary = {}
var ghost_cell := Vector2i.ZERO
var ghost_valid := false

var _scene: PackedScene
var _ghost: Sprite2D
var _ghost_offset := Vector2.ZERO
var _swallow_release := false


func begin(scene: PackedScene) -> void:
	cancel()
	var node := scene.instantiate()
	var proto := node as Building
	if proto == null:
		node.free()
		return
	_scene = scene
	footprint = proto.footprint
	cost = proto.cost.duplicate()
	_ghost = _make_ghost(proto)
	proto.free()
	active = true
	update_cursor(get_global_mouse_position())


func cancel() -> void:
	active = false
	_scene = null
	if _ghost:
		_ghost.queue_free()
		_ghost = null
	queue_redraw()


func cell_under(point: Vector2) -> Vector2i:
	var corner := point - Vector2(footprint) * Grid.TILE / 2.0
	return Vector2i((corner / Grid.TILE).round())


func is_valid_at(cell: Vector2i) -> bool:
	var rect := Rect2i(cell, footprint)
	if not (Grid.in_map(rect.position) and Grid.in_map(rect.end - Vector2i.ONE)):
		return false
	var nav := _nav()
	var gs := _game_state()
	if nav == null or gs == null:
		return false
	return nav.is_area_free(rect) and gs.can_afford(cost)


func update_cursor(point: Vector2) -> void:
	ghost_cell = cell_under(point)
	ghost_valid = is_valid_at(ghost_cell)
	if _ghost:
		_ghost.position = Grid.footprint_origin(ghost_cell, footprint) + _ghost_offset
		_ghost.modulate = GHOST_VALID if ghost_valid else GHOST_INVALID
	queue_redraw()


func confirm_at(cell: Vector2i, keep_active := false) -> Building:
	if not active or world == null or not is_valid_at(cell):
		return null
	if not _game_state().spend(cost):
		return null
	var building := _scene.instantiate() as Building
	building.position = world.to_local(Grid.footprint_origin(cell, footprint))
	world.add_child(building)
	building.start_construction()
	_evict_units(building.cell_rect())
	if not keep_active:
		cancel()
	placed.emit(building)
	return building


func _process(_delta: float) -> void:
	if active:
		update_cursor(get_global_mouse_position())


func _draw() -> void:
	if not active:
		return
	var area := Rect2(Vector2(ghost_cell) * Grid.TILE, Vector2(footprint) * Grid.TILE)
	var fill := VALID_FILL if ghost_valid else INVALID_FILL
	draw_rect(area, fill)
	draw_rect(area, Color(fill, 0.9), false, 2.0)


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb:
		if not mb.pressed:
			if _swallow_release and mb.button_index == MOUSE_BUTTON_LEFT:
				_swallow_release = false
				get_viewport().set_input_as_handled()
			return
		if not active:
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			update_cursor(get_global_mouse_position())
			confirm_at(ghost_cell, mb.shift_pressed)
			_swallow_release = true
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			cancel()
			get_viewport().set_input_as_handled()
		return
	var key := event as InputEventKey
	if active and key and key.pressed and key.keycode == KEY_ESCAPE:
		cancel()
		get_viewport().set_input_as_handled()


func _make_ghost(proto: Building) -> Sprite2D:
	var ghost := Sprite2D.new()
	ghost.name = "Ghost"
	var source := proto.get_node_or_null("Sprite2D") as Sprite2D
	if source:
		ghost.texture = source.texture
		ghost.hframes = source.hframes
		ghost.vframes = source.vframes
		ghost.frame = 0
		ghost.centered = source.centered
		ghost.offset = source.offset
		ghost.scale = source.scale
		_ghost_offset = source.position
	else:
		_ghost_offset = Vector2.ZERO
	add_child(ghost)
	return ghost


## Robots standing on the new footprint walk to the nearest free cell around it.
func _evict_units(rect: Rect2i) -> void:
	var area := Rect2(Vector2(rect.position) * Grid.TILE, Vector2(rect.size) * Grid.TILE)
	var nav := _nav()
	for node in get_tree().get_nodes_in_group("workers"):
		var unit := node as Node2D
		if unit and area.has_point(unit.global_position):
			unit.call("move_to", nav.approach_point(rect, unit.global_position))


func _nav() -> NavScript:
	return get_node_or_null("/root/Nav") as NavScript


func _game_state() -> GameStateScript:
	return get_node_or_null("/root/GameState") as GameStateScript
