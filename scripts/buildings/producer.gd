class_name Producer extends Building
## Building with a paid production queue (HQ, Shipyard, ColonyModule): it pays when a unit is
## queued, trains one unit at a time and waits, timer paused, while _can_release() is false.

signal queue_changed(count: int, progress: float)

const BAR_SIZE := Vector2(96, 8)
const BAR_COLOR := Color(0.3, 1.0, 0.4)
const BAR_BLOCKED_COLOR := Color(1.0, 0.35, 0.3)

var queue := 0

var _train_time := 0.0


func unit_cost() -> Dictionary:
	return {}


func unit_seconds() -> float:
	return 1.0


func queue_max() -> int:
	return 1


func title() -> String:
	return ""


func unit_name() -> String:
	return ""


func blocked_text() -> String:
	return ""


func enqueue() -> bool:
	if not built or queue >= queue_max():
		return false
	var gs := get_node_or_null("/root/GameState") as GameStateScript
	if gs == null or not gs.spend(unit_cost()):
		return false
	queue += 1
	_emit_queue()
	return true


func train_progress() -> float:
	return clampf(_train_time / unit_seconds(), 0.0, 1.0)


func is_blocked() -> bool:
	return queue > 0 and not _can_release()


func _process(delta: float) -> void:
	if queue == 0:
		return
	if _can_release():
		_train_time = minf(_train_time + delta, unit_seconds())
		if _train_time >= unit_seconds():
			_train_time = 0.0
			queue -= 1
			_release_unit()
		_emit_queue()
	redraw_overlay()


## True when a finished unit could leave right now (population room, a free pad...).
func _can_release() -> bool:
	return true


func _release_unit() -> void:
	pass


func _emit_queue() -> void:
	queue_changed.emit(queue, train_progress())
	redraw_overlay()


func _draw_overlay() -> void:
	super()
	if queue == 0:
		return
	var bar := Rect2(Vector2(-BAR_SIZE.x * 0.5, _sprite_top() - BAR_SIZE.y - 6.0), BAR_SIZE)
	_overlay.draw_rect(bar, Color(0.0, 0.0, 0.0, 0.6))
	var fill := bar.grow(-1.0)
	fill.size.x *= train_progress()
	_overlay.draw_rect(fill, BAR_COLOR)
	if is_blocked():
		_overlay.draw_rect(bar, BAR_BLOCKED_COLOR, false, 2.0)


func _sprite_top() -> float:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null or sprite.texture == null:
		return -float(footprint.y * Grid.TILE) - 64.0
	return (sprite.transform * sprite.get_rect().position).y
