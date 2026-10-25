class_name Selection
extends Node2D

signal changed(items: Array)

const CLICK_THRESHOLD := 6.0
# Selectable units have their origin at the feet; the body is drawn above it.
const BODY_OFFSET := Vector2(0.0, -22.0)
const FILL_COLOR := Color(0.3, 1.0, 0.4, 0.15)
const BORDER_COLOR := Color(0.3, 1.0, 0.4, 0.9)
const BORDER_WIDTH := 2.0

var items: Array = []

var _dragging := false
var _start := Vector2.ZERO
var _end := Vector2.ZERO


func select(new_items: Array) -> void:
	for item in items:
		if is_instance_valid(item):
			item.selected = false
	var unique: Array = []
	for item in new_items:
		if is_instance_valid(item) and not unique.has(item):
			unique.append(item)
	items = unique
	for item in items:
		item.selected = true
	changed.emit(items)


func clear() -> void:
	select([])


func begin_drag(p: Vector2) -> void:
	_dragging = true
	_start = p
	_end = p
	queue_redraw()


func update_drag(p: Vector2) -> void:
	if not _dragging:
		return
	_end = p
	queue_redraw()


func end_drag(p: Vector2, additive: bool) -> void:
	if not _dragging:
		return
	_dragging = false
	_end = p
	queue_redraw()
	var rect := drag_rect(_start, _end)
	var found: Array = []
	if _is_click(rect):
		var candidates: Array = get_tree().get_nodes_in_group("workers") + get_tree().get_nodes_in_group("buildings")
		var hit := pick_at(p, candidates)
		if hit != null and hit.is_in_group("buildings"):
			select([hit])
			return
		if hit != null:
			found = [hit]
	else:
		found = items_in_rect(rect, get_tree().get_nodes_in_group("workers"))
	if additive:
		select(_workers_only(items) + found)
	else:
		select(found)


static func drag_rect(a: Vector2, b: Vector2) -> Rect2:
	return Rect2(a, b - a).abs()


static func items_in_rect(rect: Rect2, nodes: Array) -> Array:
	var result: Array = []
	for node in nodes:
		if not (node is Node2D):
			continue
		var feet: Vector2 = (node as Node2D).global_position
		if rect.has_point(feet) or rect.has_point(feet + BODY_OFFSET):
			result.append(node)
	return result


static func pick_at(p: Vector2, nodes: Array) -> Node2D:
	var best: Node2D = null
	for node in nodes:
		if not (node is Node2D) or not node.has_method("contains_point"):
			continue
		if not node.contains_point(p):
			continue
		if best == null or (node as Node2D).global_position.y > best.global_position.y:
			best = node
	return best


static func _workers_only(nodes: Array) -> Array:
	var result: Array = []
	for node in nodes:
		if is_instance_valid(node) and node.is_in_group("workers"):
			result.append(node)
	return result


func _is_click(rect: Rect2) -> bool:
	return rect.size.x < CLICK_THRESHOLD and rect.size.y < CLICK_THRESHOLD


func _draw() -> void:
	if not _dragging:
		return
	var rect := drag_rect(_start, _end)
	if _is_click(rect):
		return
	draw_rect(rect, FILL_COLOR, true)
	draw_rect(rect, BORDER_COLOR, false, BORDER_WIDTH)
