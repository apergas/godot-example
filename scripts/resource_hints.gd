class_name ResourceHints extends Node2D
## While a dropoff building is being placed, highlights the resource nodes it would serve.

const RADIUS_TILES := 6
const RING_RADIUS := 26.0
const COLORS := {ResKind.CRYSTAL: Color("38d8f0"), ResKind.ICE: Color("e8f6ff")}

var kinds: Array[int] = []
var center := Vector2.ZERO
var _time := 0.0


func show_for(scene: PackedScene) -> void:
	kinds.clear()
	var instance := scene.instantiate()
	if instance is Building:
		kinds.assign((instance as Building).accepts_kinds)
	instance.free()
	_time = 0.0
	queue_redraw()


func hide_hints() -> void:
	kinds.clear()
	queue_redraw()


func nodes_in_range(at: Vector2) -> Array[ResourceNode]:
	var found: Array[ResourceNode] = []
	if kinds.is_empty():
		return found
	var radius := RADIUS_TILES * Grid.TILE
	for node in get_tree().get_nodes_in_group("resources"):
		var res := node as ResourceNode
		if res != null and res.kind in kinds and res.global_position.distance_to(at) <= radius:
			found.append(res)
	return found


func _process(delta: float) -> void:
	if kinds.is_empty():
		return
	var placement := get_parent() as Placement
	if placement != null and not placement.active:
		hide_hints()
		return
	_time += delta
	center = Grid.cell_to_world(Grid.world_to_cell(get_global_mouse_position()))
	queue_redraw()


func _draw() -> void:
	if kinds.is_empty():
		return
	draw_arc(to_local(center), RADIUS_TILES * Grid.TILE, 0.0, TAU, 64, Color(1.0, 1.0, 1.0, 0.2), 2.0)
	var alpha := 0.55 + 0.45 * sin(_time * 6.0)
	for res in nodes_in_range(center):
		var color: Color = COLORS[res.kind]
		color.a = alpha
		# Flattened ring at the node's base, like the worker's selection ring.
		draw_set_transform(to_local(res.global_position), 0.0, Vector2(1.0, 0.4))
		draw_arc(Vector2.ZERO, RING_RADIUS, 0.0, TAU, 24, color, 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
