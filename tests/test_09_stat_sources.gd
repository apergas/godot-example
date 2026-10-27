extends SceneTree
## Stats come from real sources: building completion, HQ training, worker selection, deliveries.

var _failed := false


func _initialize() -> void:
	create_timer(20.0).timeout.connect(_on_timeout)
	await process_frame
	var gs: Node = root.get_node("GameState")
	root.get_node("Nav").reset()
	gs.reset()
	var world := Node2D.new()
	root.add_child(world)

	var hq = load("res://scenes/buildings/hq.tscn").instantiate()
	hq.position = Grid.footprint_origin(MapLayout.HQ_CELL, Vector2i(3, 3))
	world.add_child(hq)
	hq.set_process(false)
	var habitat = load("res://scenes/buildings/habitat.tscn").instantiate()
	habitat.position = Grid.footprint_origin(Vector2i(20, 10), habitat.footprint)
	habitat.start_construction()
	world.add_child(habitat)
	await process_frame
	await process_frame

	_check("prebuilt_hq_not_counted", gs.stat("built_hq") == 0, str(gs.stats))
	_check("habitat_kind_id", habitat.kind_id == "habitat", habitat.kind_id)
	habitat.add_build_progress(habitat.build_time * 0.5)
	_check("half_built_not_counted", gs.stat("built_habitat") == 0, str(gs.stats))
	habitat.add_build_progress(habitat.build_time)
	_check("built_habitat_counted", habitat.built and gs.stat("built_habitat") == 1, str(gs.stats))
	habitat.add_build_progress(5.0)
	_check("built_counted_once", gs.stat("built_habitat") == 1, str(gs.stats))

	var plain := Building.new()
	plain.position = Grid.footprint_origin(Vector2i(30, 10), plain.footprint)
	plain.start_construction()
	world.add_child(plain)
	plain.add_build_progress(plain.build_time + 1.0)
	_check("empty_kind_id_not_counted", not gs.stats.has("built_") and plain.built, str(gs.stats))

	var spawned: Array = []
	hq.worker_spawned.connect(func(w: Node2D) -> void: spawned.append(w))
	gs.add(ResKind.CRYSTAL, 50)
	hq.enqueue_worker()
	hq._process(hq.TRAIN_SECONDS + 0.01)
	_check("workers_trained_counted", spawned.size() == 1 and gs.stat("workers_trained") == 1, "spawned=%d %s" % [spawned.size(), gs.stats])

	var sel = load("res://scripts/selection.gd").new()
	root.add_child(sel)
	sel.select([hq])
	_check("building_selection_not_counted", gs.stat("selected_worker") == 0, str(gs.stats))
	if spawned.size() == 1:
		var worker = spawned[0]
		sel.select([worker])
		_check("worker_selection_counted", gs.stat("selected_worker") == 1, str(gs.stats))
		sel.clear()
		_check("selected_stays_after_clear", gs.stat("selected_worker") == 1, str(gs.stats))

		var ice_before: int = gs.stock[ResKind.ICE]
		worker.carry_kind = ResKind.ICE
		worker.carry_amount = 10
		worker._deliver()
		_check("delivery_adds_stock", gs.stock[ResKind.ICE] == ice_before + 10, str(gs.stock))
		_check("delivery_counted", gs.stat("gathered_ice") == 10, str(gs.stats))
		_check("spending_not_counted", gs.stat("gathered_crystal") == 0, str(gs.stats))
	world.queue_free()
	sel.queue_free()
	await process_frame
	quit(1 if _failed else 0)


func _check(test_name: String, ok: bool, why: String) -> void:
	if ok:
		print("PASS ", test_name)
	else:
		_failed = true
		print("FAIL ", test_name, ": ", why)


func _on_timeout() -> void:
	print("FAIL timeout: test did not finish (script error?)")
	quit(1)
