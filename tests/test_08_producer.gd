extends SceneTree
## tests/test_08_producer.gd — run: tools\godot.cmd --headless --path . --script res://tests/test_08_producer.gd

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

	_check("hq_is_producer", hq is Producer, "HQ does not extend Producer")
	_check("hq_unit_cost", hq.unit_cost() == HQ.WORKER_COST, str(hq.unit_cost()))
	_check("hq_unit_seconds_and_queue", hq.unit_seconds() == HQ.TRAIN_SECONDS and hq.queue_max() == HQ.QUEUE_MAX, "%f %d" % [hq.unit_seconds(), hq.queue_max()])
	_check("hq_texts", hq.title() == "Base central" and hq.unit_name() == "Robot", "%s %s" % [hq.title(), hq.unit_name()])

	gs.add(ResKind.CRYSTAL, 100)
	_check("enqueue_generic", hq.enqueue() and hq.queue == 1, str(hq.queue))
	_check("enqueue_worker_alias", hq.enqueue_worker() and hq.queue == 2, str(hq.queue))
	var spawned: Array = []
	hq.worker_spawned.connect(func(w: Node2D) -> void: spawned.append(w))
	hq._process(HQ.TRAIN_SECONDS + 0.01)
	_check("spawns_through_release_unit", spawned.size() == 1 and hq.queue == 1, "spawned=%d queue=%d" % [spawned.size(), hq.queue])
	world.queue_free()
	quit(1 if _failed else 0)


func _check(test_name: String, ok: bool, why: String) -> void:
	if ok:
		print("PASS ", test_name)
	else:
		print("FAIL ", test_name, ": ", why)
		_failed = true


func _on_timeout() -> void:
	print("FAIL timeout: test did not finish (script error?)")
	quit(1)
