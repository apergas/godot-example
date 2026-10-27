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
	var scene: PackedScene = load("res://scenes/worker.tscn")

	var a = scene.instantiate()
	a.position = Grid.cell_to_world(Vector2i(30, 30))
	world.add_child(a)
	_check("enter_adds_one", gs.population == 1, str(gs.population))

	var b = scene.instantiate()
	b.position = Grid.cell_to_world(Vector2i(32, 30))
	world.add_child(b)
	_check("second_adds_one", gs.population == 2, str(gs.population))

	a.queue_free()
	await process_frame
	await process_frame
	_check("free_removes_one", gs.population == 1, str(gs.population))

	world.remove_child(b)
	_check("remove_child_removes_one", gs.population == 0, str(gs.population))
	world.add_child(b)
	_check("re_add_adds_one", gs.population == 1, str(gs.population))
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
