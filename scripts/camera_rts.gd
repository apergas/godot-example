extends Camera2D
## RTS camera: WASD/arrows, screen-edge scroll, middle-button drag and wheel zoom,
## always kept inside Grid.map_rect_world(). The math lives in static functions.

const SPEED := 900.0
const EDGE_MARGIN := 20.0
const ZOOM_MIN := 0.5
const ZOOM_MAX := 2.0
const ZOOM_STEP := 1.1

@export var edge_scroll := true

var _dragging := false
var _mouse_inside := false


func _ready() -> void:
	var bounds := Grid.map_rect_world()
	limit_left = int(bounds.position.x)
	limit_top = int(bounds.position.y)
	limit_right = int(bounds.end.x)
	limit_bottom = int(bounds.end.y)
	get_window().mouse_exited.connect(_on_mouse_left)
	get_window().focus_exited.connect(_on_mouse_left)
	_clamp_to_map()


func _input(event: InputEvent) -> void:
	# Edge scrolling only starts once the mouse has actually moved inside the window.
	if event is InputEventMouseMotion:
		_mouse_inside = true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		match button.button_index:
			MOUSE_BUTTON_MIDDLE:
				_dragging = button.pressed
			MOUSE_BUTTON_WHEEL_UP:
				if button.pressed:
					_zoom_at(button.position, pow(ZOOM_STEP, _wheel_steps(button)))
			MOUSE_BUTTON_WHEEL_DOWN:
				if button.pressed:
					_zoom_at(button.position, pow(ZOOM_STEP, -_wheel_steps(button)))
	elif event is InputEventMouseMotion and _dragging:
		position -= (event as InputEventMouseMotion).relative / zoom.x
		_clamp_to_map()


func _process(delta: float) -> void:
	var direction := _key_direction()
	if edge_scroll and _mouse_inside:
		direction += edge_direction(get_viewport().get_mouse_position(), get_viewport_rect().size, EDGE_MARGIN)
	if direction != Vector2.ZERO:
		position += scroll_offset(direction, delta, zoom.x)
	_clamp_to_map()


## -1/0/1 per axis when the mouse is within `margin` px of a screen edge.
static func edge_direction(mouse: Vector2, view_size: Vector2, margin: float) -> Vector2:
	var direction := Vector2.ZERO
	if mouse.x < margin:
		direction.x = -1.0
	elif mouse.x >= view_size.x - margin:
		direction.x = 1.0
	if mouse.y < margin:
		direction.y = -1.0
	elif mouse.y >= view_size.y - margin:
		direction.y = 1.0
	return direction


## World movement for one frame; dividing by zoom keeps the on-screen speed constant.
static func scroll_offset(direction: Vector2, delta: float, cam_zoom: float) -> Vector2:
	if direction == Vector2.ZERO:
		return Vector2.ZERO
	return direction.normalized() * SPEED * delta / cam_zoom


static func clamp_zoom(value: float) -> float:
	return clampf(value, ZOOM_MIN, ZOOM_MAX)


## Keeps the visible rectangle inside `bounds`; centres an axis where the view is larger.
static func clamp_position(pos: Vector2, view_size: Vector2, cam_zoom: float, bounds: Rect2) -> Vector2:
	var half := view_size / (2.0 * cam_zoom)
	var low := bounds.position + half
	var high := bounds.end - half
	var center := bounds.get_center()
	var x: float = center.x if low.x > high.x else clampf(pos.x, low.x, high.x)
	var y: float = center.y if low.y > high.y else clampf(pos.y, low.y, high.y)
	return Vector2(x, y)


## Camera position after a zoom change that keeps the world point under `screen_point` fixed.
static func zoom_anchor_position(cam_pos: Vector2, screen_point: Vector2, view_size: Vector2,
		old_zoom: float, new_zoom: float) -> Vector2:
	var from_center := screen_point - view_size / 2.0
	var world_point := cam_pos + from_center / old_zoom
	return world_point - from_center / new_zoom


func _key_direction() -> Vector2:
	var direction := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0
	return direction


## Trackpads and browsers send fractional wheel steps in `factor`; 0 means "not reported".
func _wheel_steps(button: InputEventMouseButton) -> float:
	return clampf(button.factor, 0.1, 3.0) if button.factor > 0.0 else 1.0


func _zoom_at(screen_point: Vector2, factor: float) -> void:
	var old_zoom := zoom.x
	var new_zoom := clamp_zoom(old_zoom * factor)
	if is_equal_approx(new_zoom, old_zoom):
		return
	position = zoom_anchor_position(position, screen_point, get_viewport_rect().size, old_zoom, new_zoom)
	zoom = Vector2(new_zoom, new_zoom)
	_clamp_to_map()


func _clamp_to_map() -> void:
	position = clamp_position(position, get_viewport_rect().size, zoom.x, Grid.map_rect_world())


func _on_mouse_left() -> void:
	_mouse_inside = false
	_dragging = false
