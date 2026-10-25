class_name Building extends StaticBody2D
## Base for every building: grid footprint, Nav blocking, dropoff role and picking.

signal completed

const SELECT_COLOR := Color(0.3, 1.0, 0.4)

@export var footprint := Vector2i(2, 2)
@export var accepts_kinds: Array[int] = []
@export var build_time := 10.0

var cell: Vector2i
var built := true
var build_progress := 0.0
var selected := false:
	set(value):
		selected = value
		queue_redraw()


func _ready() -> void:
	cell = Grid.footprint_cell(global_position, footprint)
	add_to_group("buildings")
	if not accepts_kinds.is_empty():
		add_to_group("dropoffs")
	_set_nav_blocked(true)


func _exit_tree() -> void:
	_set_nav_blocked(false)


func cell_rect() -> Rect2i:
	return Rect2i(cell, footprint)


func accepts(kind: int) -> bool:
	return built and kind in accepts_kinds


func contains_point(p: Vector2) -> bool:
	return _pick_rect().has_point(p)


func _set_nav_blocked(blocked: bool) -> void:
	var nav := get_node_or_null("/root/Nav")
	if nav:
		nav.set_blocked(cell_rect(), blocked)


## Footprint in world space, stretched up to the top of the sprite (the building's height).
func _pick_rect() -> Rect2:
	var size := Vector2(footprint * Grid.TILE)
	var rect := Rect2(global_position - Vector2(size.x / 2.0, size.y), size)
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		var top := global_position.y + sprite.position.y + sprite.offset.y * sprite.scale.y
		rect = rect.expand(Vector2(rect.position.x, top))
	return rect


func _draw() -> void:
	if not selected:
		return
	var size := Vector2(footprint * Grid.TILE)
	draw_rect(Rect2(Vector2(-size.x / 2.0, -size.y), size).grow(4.0), SELECT_COLOR, false, 2.0)
