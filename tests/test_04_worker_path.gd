extends SceneTree

const NavScript := preload("res://scripts/nav.gd")
const WorkerScript := preload("res://scripts/worker.gd")

var _failed := false


func _initialize() -> void:
	await process_frame
	var nav := root.get_node("Nav") as NavScript
	nav.reset()
	var hq := (load("res://scenes/buildings/hq.tscn") as PackedScene).instantiate() as Building
	hq.position = Grid.footprint_origin(Vector2i(10, 21), hq.footprint)
	root.add_child(hq)
	var worker := (load("res://scenes/worker.tscn") as PackedScene).instantiate() as WorkerScript
	worker.position = Grid.cell_to_world(Vector2i(8, 22))
	worker.speed = 400.0
	root.add_child(worker)
	await physics_frame

	var target := Grid.cell_to_world(Vector2i(14, 22)) + Vector2(6.0, -10.0)
	worker.move_to(target)
	_check(worker.state == WorkerScript.State.MOVING, "move_sets_moving", str(worker.state))
	var entered_hq := false
	for frame in 600:
		await physics_frame
		if hq.cell_rect().has_point(Grid.world_to_cell(worker.global_position)):
			entered_hq = true
		if worker.state == WorkerScript.State.IDLE:
			break
	_check(worker.state == WorkerScript.State.IDLE, "move_finishes", str(worker.state))
	_check(worker.global_position.distance_to(target) <= 6.0, "move_reaches_target", str(worker.global_position))
	_check(not entered_hq, "move_avoids_hq", "worker stepped into the HQ footprint")

	worker.move_to(hq.global_position + Vector2(0.0, -96.0))
	for frame in 600:
		await physics_frame
		if worker.state == WorkerScript.State.IDLE:
			break
	var cell := Grid.world_to_cell(worker.global_position)
	_check(not hq.cell_rect().has_point(cell) and hq.cell_rect().grow(1).has_point(cell),
			"move_into_building_stops_next_to_it", str(cell))

	# Unreachable target (walled-in cell) must end in IDLE, not walk forever.
	nav.set_blocked(Rect2i(Vector2i(30, 10), Vector2i(3, 3)), true)
	nav.set_blocked(Rect2i(Vector2i(31, 11), Vector2i.ONE), false)
	worker.move_to(Grid.cell_to_world(Vector2i(31, 11)))
	for frame in 600:
		await physics_frame
		if worker.state == WorkerScript.State.IDLE:
			break
	_check(worker.state == WorkerScript.State.IDLE, "unreachable_target_goes_idle", str(worker.state))
	quit(1 if _failed else 0)


func _check(ok: bool, name: String, why: String) -> void:
	if ok:
		print("PASS ", name)
	else:
		print("FAIL ", name, ": ", why)
		_failed = true
