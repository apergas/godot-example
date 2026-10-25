extends SceneTree

var _failed := false


func _initialize() -> void:
	await process_frame
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame
	var world := main.get_node("World")

	var hqs: Array = []
	for b in get_nodes_in_group("buildings"):
		if b is HQ:
			hqs.append(b)
	_check(hqs.size() == 1, "one_hq", "found %d" % hqs.size())
	if hqs.size() == 1:
		var hq := hqs[0] as HQ
		_check(hq.cell == MapLayout.HQ_CELL, "hq_at_layout_cell", str(hq.cell))
		_check(hq.get_parent() == world, "hq_in_world", str(hq.get_parent()))
		var workers := get_nodes_in_group("workers")
		_check(workers.size() == MapLayout.START_WORKERS, "start_workers", "found %d" % workers.size())
		var near := true
		for w in workers:
			var c := Grid.world_to_cell((w as Node2D).global_position)
			if hq.cell_rect().has_point(c) or not hq.cell_rect().grow(2).has_point(c) or w.get_parent() != world:
				near = false
		_check(near, "workers_next_to_hq", "a worker is inside, far from the HQ or outside World")

	var forbidden := Rect2i(MapLayout.HQ_CELL, Vector2i(3, 3)).grow(2)
	var clear := true
	for c in MapLayout.CRYSTAL_CELLS + MapLayout.ICE_CELLS:
		if forbidden.has_point(c):
			clear = false
	_check(clear, "no_resources_near_hq", "a resource cell is within 2 tiles of the HQ footprint")
	quit(1 if _failed else 0)


func _check(ok: bool, name: String, why: String) -> void:
	if ok:
		print("PASS ", name)
	else:
		print("FAIL ", name, ": ", why)
		_failed = true
