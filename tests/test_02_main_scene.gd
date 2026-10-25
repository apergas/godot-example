extends SceneTree

var _failed := false


func _initialize() -> void:
	var main: Node2D = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame

	var world := main.get_node_or_null("World") as Node2D
	_check("world_y_sorted", world != null and world.y_sort_enabled, "World missing or not y-sorted")
	var workers: Array = get_nodes_in_group("workers")
	_check("three_workers", workers.size() == 3, "found %d workers" % workers.size())
	var all_in_world := world != null
	for w in workers:
		if (w as Node).get_parent() != world:
			all_in_world = false
	_check("workers_in_world", all_in_world, "some worker is not a child of World")
	var selection := main.get_node_or_null("Selection") as Node2D
	_check("selection_node", selection != null and selection.z_index == 100 and selection.has_method("end_drag"), "Selection missing or misconfigured")
	_check("command_move_exists", main.has_method("command_move"), "main.gd has no command_move")
	if _failed:
		quit(1)
		return

	selection.select(workers)
	var target := Vector2(1200, 1400)
	main.command_move(target)
	var marker_script: GDScript = load("res://scripts/order_marker.gd")
	var markers := 0
	for child in main.get_children():
		if child.get_script() == marker_script:
			markers += 1
	_check("order_marker_spawned", markers == 1, "found %d markers" % markers)

	for i in 240:
		await physics_frame

	var formation: GDScript = load("res://scripts/formation.gd")
	var targets: Array = formation.targets(target, 3, 40.0)
	var reached := true
	for t in targets:
		var near := false
		for w in workers:
			if (w as Node2D).global_position.distance_to(t) <= 12.0:
				near = true
		if not near:
			reached = false
	_check("workers_reach_formation", reached, "some formation slot has no worker within 12 px")
	var min_dist := INF
	for a in workers.size():
		for b in range(a + 1, workers.size()):
			min_dist = minf(min_dist, (workers[a] as Node2D).global_position.distance_to((workers[b] as Node2D).global_position))
	_check("workers_do_not_overlap", min_dist >= 23.0, "closest pair at %.2f px" % min_dist)
	quit(1 if _failed else 0)


func _check(test_name: String, ok: bool, why: String) -> void:
	if ok:
		print("PASS ", test_name)
	else:
		print("FAIL ", test_name, ": ", why)
		_failed = true
