extends Camera2D
## RTS camera: WASD/arrows, screen-edge scroll, middle-button drag and wheel zoom,
## always kept inside Grid.map_rect_world(). The math lives in static functions.

const SPEED := 900.0
const EDGE_MARGIN := 20.0
const ZOOM_MIN := 0.5
const ZOOM_MAX := 2.0
const ZOOM_STEP := 1.1


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
