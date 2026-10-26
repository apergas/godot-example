extends SceneTree

var _failed := false


func _initialize() -> void:
	create_timer(20.0).timeout.connect(_on_timeout)
	await process_frame
	var gs = root.get_node("GameState")
	root.get_node("Nav").reset()
	gs.reset()
	var world := Node2D.new()
	root.add_child(world)
	var hq = load("res://scenes/buildings/hq.tscn").instantiate()
	hq.position = Grid.footprint_origin(MapLayout.HQ_CELL, Vector2i(3, 3))
	world.add_child(hq)
	await process_frame
	await process_frame
	hq.set_process(false)
	var spawned: Array = []
	hq.worker_spawned.connect(func(w: Node2D) -> void: spawned.append(w))
	gs.add(ResKind.CRYSTAL, 50)
	hq.enqueue_worker()
	hq.enqueue_worker()
	_check("two_queued", hq.queue == 2 and gs.population_cap == 5, "queue=%d cap=%d" % [hq.queue, gs.population_cap])

	hq._process(hq.TRAIN_SECONDS * 0.5)
	_check("half_progress", is_equal_approx(hq.train_progress(), 0.5) and spawned.is_empty(), "progress=%f spawned=%d" % [hq.train_progress(), spawned.size()])

	hq._process(hq.TRAIN_SECONDS * 0.5 + 0.01)
	_check("worker_spawned", spawned.size() == 1 and hq.queue == 1, "spawned=%d queue=%d" % [spawned.size(), hq.queue])
	_check("population_up", gs.population == 1, str(gs.population))
	_check("progress_reset", hq.train_progress() == 0.0, str(hq.train_progress()))
	if spawned.size() == 1:
		var w = spawned[0]
		_check("spawn_in_world", w.get_parent() == world and w.is_in_group("workers"), str(w.get_parent()))
		_check("spawn_near_hq", w.global_position.distance_to(hq.global_position) < Grid.TILE * 4.0, str(w.global_position))
		_check("spawn_outside_footprint", not hq.cell_rect().has_point(Grid.world_to_cell(w.global_position)), str(Grid.world_to_cell(w.global_position)))
		_check("spawn_idle", w.state == 0, str(w.state))

	gs.add_population(4)
	_check("full_population", not gs.has_room(), "%d/%d" % [gs.population, gs.population_cap])
	for i in 5:
		hq._process(hq.TRAIN_SECONDS)
	_check("blocked_no_spawn", spawned.size() == 1 and hq.queue == 1, "spawned=%d queue=%d" % [spawned.size(), hq.queue])
	_check("blocked_flag", hq.is_blocked(), "is_blocked() false")
	_check("blocked_paused", hq.train_progress() == 0.0, str(hq.train_progress()))

	gs.add_cap(5)
	_check("unblocked_flag", not hq.is_blocked(), "is_blocked() true")
	hq._process(hq.TRAIN_SECONDS)
	_check("resumes_after_cap", spawned.size() == 2 and hq.queue == 0 and gs.population == 6, "spawned=%d queue=%d pop=%d" % [spawned.size(), hq.queue, gs.population])
	_check("second_spawn_offset", spawned.size() == 2 and spawned[0].global_position != spawned[1].global_position, "same spot")

	hq._process(hq.TRAIN_SECONDS)
	_check("idle_when_empty", spawned.size() == 2 and not hq.is_blocked(), str(spawned.size()))
	_finish()


func _check(test_name: String, ok: bool, why: String) -> void:
	if ok:
		print("PASS ", test_name)
	else:
		print("FAIL ", test_name, ": ", why)
		_failed = true


func _finish() -> void:
	quit(1 if _failed else 0)


func _on_timeout() -> void:
	print("FAIL timeout: test did not finish (script error?)")
	quit(1)
