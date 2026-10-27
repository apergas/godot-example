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
	var scene: PackedScene = load("res://scenes/buildings/hq.tscn")

	var hq = scene.instantiate()
	_check("hq_bonus_is_5", hq.pop_cap_bonus == 5, str(hq.pop_cap_bonus))
	hq.position = Grid.footprint_origin(MapLayout.HQ_CELL, Vector2i(3, 3))
	world.add_child(hq)
	await process_frame
	await process_frame
	_check("built_adds_cap", gs.population_cap == 5, str(gs.population_cap))

	hq.queue_free()
	await process_frame
	await process_frame
	_check("exit_removes_cap", gs.population_cap == 0, str(gs.population_cap))

	var site = scene.instantiate()
	site.built = false
	site.position = Grid.footprint_origin(Vector2i(20, 30), Vector2i(3, 3))
	world.add_child(site)
	await process_frame
	await process_frame
	_check("unbuilt_no_cap", gs.population_cap == 0, str(gs.population_cap))
	site.built = true
	site.completed.emit()
	_check("completed_adds_cap", gs.population_cap == 5, str(gs.population_cap))
	site.completed.emit()
	_check("completed_twice_no_double", gs.population_cap == 5, str(gs.population_cap))

	var late = scene.instantiate()
	late.position = Grid.footprint_origin(Vector2i(40, 30), Vector2i(3, 3))
	world.add_child(late)
	late.built = false
	await process_frame
	await process_frame
	_check("unbuilt_same_frame_no_cap", gs.population_cap == 5, str(gs.population_cap))
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
