class_name HQ extends Building
## Central base. Phase 4: dropoff for crystal and ice (footprint and kinds set in hq.tscn).

signal queue_changed(count: int, progress: float)

const WORKER_COST := {ResKind.CRYSTAL: 50}
const TRAIN_SECONDS := 8.0
const QUEUE_MAX := 5

var queue := 0

var _train_time := 0.0


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
