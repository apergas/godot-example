class_name HQ extends Building
## Central base: dropoff for crystal and ice, +5 population cap, and a worker training queue
## (footprint, kinds and cap bonus set in hq.tscn).

signal queue_changed(count: int, progress: float)
signal worker_spawned(worker: Node2D)

const NavScript := preload("res://scripts/nav.gd")
const WORKER_COST := {ResKind.CRYSTAL: 50}
const TRAIN_SECONDS := 8.0
const QUEUE_MAX := 5
const WORKER_SCENE := preload("res://scenes/worker.tscn")
const SPAWN_OFFSETS := [Vector2.ZERO, Vector2(24, 0), Vector2(-24, 0), Vector2(0, 20), Vector2(24, 20)]
const BAR_SIZE := Vector2(96, 8)
const BAR_COLOR := Color(0.3, 1.0, 0.4)
const BAR_BLOCKED_COLOR := Color(1.0, 0.35, 0.3)

var queue := 0

var _train_time := 0.0
var _spawned := 0


func enqueue_worker() -> bool:
	if not built or queue >= QUEUE_MAX:
		return false
	var gs := get_node_or_null("/root/GameState") as GameStateScript
	if gs == null or not gs.spend(WORKER_COST):
		return false
	queue += 1
	_emit_queue()
	return true


func train_progress() -> float:
	return clampf(_train_time / TRAIN_SECONDS, 0.0, 1.0)


func _emit_queue() -> void:
	queue_changed.emit(queue, train_progress())
	redraw_overlay()


func is_blocked() -> bool:
	return queue > 0 and not _has_room()


func _process(delta: float) -> void:
	if queue == 0:
		return
	if _has_room():
		_train_time = minf(_train_time + delta, TRAIN_SECONDS)
		if _train_time >= TRAIN_SECONDS:
			_train_time = 0.0
			queue -= 1
			_spawn_worker()
		_emit_queue()
	redraw_overlay()


func _has_room() -> bool:
	var gs := get_node_or_null("/root/GameState") as GameStateScript
	return gs != null and gs.has_room()


func _spawn_worker() -> void:
	var from := global_position + Vector2(0, 32)
	var nav := get_node_or_null("/root/Nav") as NavScript
	var spot: Vector2 = nav.approach_point(cell_rect(), from) if nav else from
	spot += SPAWN_OFFSETS[_spawned % SPAWN_OFFSETS.size()]
	_spawned += 1
	var parent: Node2D = get_parent()
	var worker: Node2D = WORKER_SCENE.instantiate()
	worker.position = parent.to_local(spot)
	parent.add_child(worker)
	worker_spawned.emit(worker)


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
