class_name Building extends StaticBody2D
## Base for every building: grid footprint, Nav blocking, dropoff role and picking.

signal completed

const GameStateScript := preload("res://scripts/game_state.gd")
const SELECT_COLOR := Color(0.3, 1.0, 0.4)
const SCAFFOLD_FRAME := 1
const SCAFFOLD_ALPHA := 0.8
const BAR_HEIGHT := 8.0
const BAR_GAP := 6.0
const BAR_BACK := Color(0.08, 0.11, 0.16, 0.9)
const BAR_FILL := Color(1.0, 0.76, 0.35)

@export var footprint := Vector2i(2, 2)
@export var accepts_kinds: Array[int] = []
@export var build_time := 10.0
@export var pop_cap_bonus := 0
@export var cost: Dictionary = {}

var cell: Vector2i
var built := true
var build_progress := 0.0
var _pop_cap_applied := false
var selected := false:
	set(value):
		selected = value
		redraw_overlay()
var _overlay: Node2D
var _bar: Node2D


func _ready() -> void:
	_overlay = Node2D.new()
	_overlay.name = "Overlay"
	_overlay.z_index = 1
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	cell = Grid.footprint_cell(global_position, footprint)
	add_to_group("buildings")
	if not accepts_kinds.is_empty():
		add_to_group("dropoffs")
	_set_nav_blocked(true)
	completed.connect(_on_completed_pop_cap)
	_sync_pop_cap.call_deferred()
	_bar = _make_bar()
	if built:
		build_progress = 1.0
	_refresh_construction_view()


func _exit_tree() -> void:
	_set_pop_cap_applied(false)
	_set_nav_blocked(false)


func cell_rect() -> Rect2i:
	return Rect2i(cell, footprint)


func accepts(kind: int) -> bool:
	return built and kind in accepts_kinds


func contains_point(p: Vector2) -> bool:
	return _pick_rect().has_point(p)


func start_construction() -> void:
	built = false
	build_progress = 0.0
	if is_inside_tree():
		_set_pop_cap_applied(false)
		_refresh_construction_view()


func add_build_progress(seconds: float) -> void:
	if built or seconds <= 0.0:
		return
	build_progress = minf(build_progress + seconds / maxf(build_time, 0.01), 1.0)
	if build_progress < 1.0:
		if _bar:
			_bar.queue_redraw()
		return
	built = true
	_set_pop_cap_applied(true)
	_refresh_construction_view()
	completed.emit()


func _sync_pop_cap() -> void:
	if is_inside_tree():
		_set_pop_cap_applied(built)


func _on_completed_pop_cap() -> void:
	_set_pop_cap_applied(true)


func _set_pop_cap_applied(on: bool) -> void:
	if on == _pop_cap_applied or pop_cap_bonus == 0:
		return
	_pop_cap_applied = on
	var gs := get_node_or_null("/root/GameState") as GameStateScript
	if gs:
		gs.add_cap(pop_cap_bonus if on else -pop_cap_bonus)


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


func redraw_overlay() -> void:
	if _overlay != null:
		_overlay.queue_redraw()


func _draw_overlay() -> void:
	if not selected:
		return
	var size := Vector2(footprint * Grid.TILE)
	# Flattened ellipse around the footprint, like the worker's ring.
	_overlay.draw_set_transform(Vector2(0.0, -size.y * 0.5), 0.0, Vector2(1.0, 0.6))
	_overlay.draw_arc(Vector2.ZERO, size.x * 0.5 + 8.0, 0.0, TAU, 48, SELECT_COLOR, 2.0)
	_overlay.draw_set_transform(Vector2.ZERO)

func _refresh_construction_view() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		var scaffold := not built and sprite.hframes > SCAFFOLD_FRAME
		sprite.frame = SCAFFOLD_FRAME if scaffold else 0
		sprite.modulate.a = 1.0 if built else SCAFFOLD_ALPHA
	if _bar:
		_bar.visible = not built
		_bar.queue_redraw()


func _make_bar() -> Node2D:
	var bar := Node2D.new()
	bar.name = "BuildBar"
	bar.z_index = 50
	bar.position = Vector2(0.0, _top_y() - BAR_GAP - BAR_HEIGHT)
	bar.visible = false
	bar.draw.connect(_draw_bar.bind(bar))
	add_child(bar)
	return bar


func _draw_bar(bar: Node2D) -> void:
	var width := footprint.x * Grid.TILE * 0.7
	var back := Rect2(-width / 2.0, 0.0, width, BAR_HEIGHT)
	bar.draw_rect(back.grow(1.0), BAR_BACK)
	bar.draw_rect(Rect2(back.position, Vector2(width * build_progress, BAR_HEIGHT)), BAR_FILL)


## Local y of the top edge of the sprite (the bar floats above it).
func _top_y() -> float:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite and sprite.texture:
		return (sprite.transform * sprite.get_rect()).position.y
	return -footprint.y * Grid.TILE
