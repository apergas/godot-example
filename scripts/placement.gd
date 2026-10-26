class_name Placement
extends Node2D

signal placed(building: Building)

const NavScript := preload("res://scripts/nav.gd")
const GameStateScript := preload("res://scripts/game_state.gd")

var active := false
var world: Node2D
var footprint := Vector2i.ONE
var cost: Dictionary = {}

var _scene: PackedScene


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
	proto.free()
	active = true


func cancel() -> void:
	active = false
	_scene = null


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
