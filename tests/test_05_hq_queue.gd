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
	var counts: Array = []
	hq.queue_changed.connect(func(count: int, _progress: float) -> void: counts.append(count))

	_check("constants", hq.TRAIN_SECONDS == 8.0 and hq.QUEUE_MAX == 5 and hq.WORKER_COST == {ResKind.CRYSTAL: 50}, "unexpected constants")
	_check("starts_empty", hq.queue == 0, str(hq.queue))

	var ok: bool = hq.enqueue_worker()
	_check("enqueue_pays", ok and hq.queue == 1 and gs.stock[ResKind.CRYSTAL] == 0, "ok=%s queue=%d stock=%s" % [ok, hq.queue, gs.stock])
	_check("signal_on_enqueue", counts == [1], str(counts))

	ok = hq.enqueue_worker()
	_check("reject_without_money", not ok and hq.queue == 1 and gs.stock[ResKind.CRYSTAL] == 0, "ok=%s queue=%d" % [ok, hq.queue])
	_check("no_signal_on_reject", counts == [1], str(counts))

	gs.add(ResKind.CRYSTAL, 1000)
	for i in 4:
		hq.enqueue_worker()
	_check("fills_to_max", hq.queue == hq.QUEUE_MAX, str(hq.queue))
	_check("paid_each", gs.stock[ResKind.CRYSTAL] == 800, str(gs.stock))

	ok = hq.enqueue_worker()
	_check("reject_when_full", not ok and hq.queue == 5 and gs.stock[ResKind.CRYSTAL] == 800, "ok=%s queue=%d stock=%s" % [ok, hq.queue, gs.stock])
	_check("progress_zero_before_training", hq.train_progress() == 0.0, str(hq.train_progress()))
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
