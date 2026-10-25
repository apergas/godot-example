extends SceneTree

var _failed := false


func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/worker.tscn")
	var probe: Node2D = scene.instantiate()
	if not probe.has_method("separation_push"):
		_check("separation_push_exists", false, "worker.gd has no separation_push")
		probe.free()
		quit(1)
		return
	probe.free()
	var worker_script: GDScript = load("res://scripts/worker.gd")

	var far: Vector2 = worker_script.separation_push(Vector2.ZERO, 1, PackedVector2Array([Vector2(30, 0)]), PackedInt64Array([2]), 24.0)
	_check("no_push_when_far", far == Vector2.ZERO, "got %s" % far)
	var half: Vector2 = worker_script.separation_push(Vector2.ZERO, 1, PackedVector2Array([Vector2(12, 0)]), PackedInt64Array([2]), 24.0)
	_check("half_overlap_push", half.is_equal_approx(Vector2(-0.5, 0)), "got %s" % half)
	var tie_high: Vector2 = worker_script.separation_push(Vector2.ZERO, 5, PackedVector2Array([Vector2.ZERO]), PackedInt64Array([3]), 24.0)
	var tie_low: Vector2 = worker_script.separation_push(Vector2.ZERO, 3, PackedVector2Array([Vector2.ZERO]), PackedInt64Array([5]), 24.0)
	_check("tie_splits_opposite", tie_high.is_equal_approx(Vector2.RIGHT) and tie_low.is_equal_approx(Vector2.LEFT), "got %s / %s" % [tie_high, tie_low])

	var spots: Array[Vector2] = [Vector2(500, 500), Vector2(500, 500), Vector2(510, 500), Vector2(900, 900)]
	var workers: Array = []
	for spot in spots:
		var w: Node2D = scene.instantiate()
		w.position = spot
		root.add_child(w)
		workers.append(w)
	await process_frame
	for i in 90:
		await physics_frame

	var min_dist := INF
	for a in 3:
		for b in range(a + 1, 3):
			min_dist = minf(min_dist, (workers[a] as Node2D).global_position.distance_to((workers[b] as Node2D).global_position))
	_check("overlapping_workers_separate", min_dist >= 23.0, "closest pair at %.2f px" % min_dist)
	var lone: Node2D = workers[3]
	_check("lone_worker_stays", lone.global_position.distance_to(Vector2(900, 900)) < 0.01, "lone worker drifted to %s" % lone.global_position)
	quit(1 if _failed else 0)


func _check(test_name: String, ok: bool, why: String) -> void:
	if ok:
		print("PASS ", test_name)
	else:
		print("FAIL ", test_name, ": ", why)
		_failed = true
