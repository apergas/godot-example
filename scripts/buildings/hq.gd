class_name HQ extends Producer
## Central base: dropoff for crystal and ice, +5 population cap (hq.tscn) and trains robots.

signal worker_spawned(worker: Node2D)

const NavScript := preload("res://scripts/nav.gd")
const WORKER_COST := {ResKind.CRYSTAL: 50}
const TRAIN_SECONDS := 8.0
const QUEUE_MAX := 5
const WORKER_SCENE := preload("res://scenes/worker.tscn")
const SPAWN_OFFSETS := [Vector2.ZERO, Vector2(24, 0), Vector2(-24, 0), Vector2(0, 20), Vector2(24, 20)]

var _spawned := 0


func unit_cost() -> Dictionary:
	return WORKER_COST


func unit_seconds() -> float:
	return TRAIN_SECONDS


func queue_max() -> int:
	return QUEUE_MAX


func title() -> String:
	return "Base central"


func unit_name() -> String:
	return "Robot"


func blocked_text() -> String:
	return "Población máxima — construye habitáculos"


func enqueue_worker() -> bool:
	return enqueue()


func _can_release() -> bool:
	var gs := get_node_or_null("/root/GameState") as GameStateScript
	return gs != null and gs.has_room()


func _release_unit() -> void:
	_spawn_worker()


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
	var gs := get_node_or_null("/root/GameState") as GameStateScript
	if gs:
		gs.add_stat("workers_trained")
