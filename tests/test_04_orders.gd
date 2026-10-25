extends SceneTree

const WorkerScript := preload("res://scripts/worker.gd")

var _failed := false


func _initialize() -> void:
	await process_frame
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame

	var hq: Building = null
	for b in get_nodes_in_group("buildings"):
		if b is HQ:
			hq = b
	var crystal: ResourceNode = null
	for n in get_nodes_in_group("resources"):
		var res := n as ResourceNode
		if res.kind == ResKind.CRYSTAL and (crystal == null
				or res.global_position.distance_to(hq.global_position)
				< crystal.global_position.distance_to(hq.global_position)):
			crystal = res
	var workers := get_nodes_in_group("workers")

	var on_crystal := crystal.global_position + Vector2(0.0, -16.0)
	_check(main.call("_resource_at", on_crystal) == crystal, "resource_at", "crystal not picked")
	var on_hq := hq.global_position + Vector2(0.0, -96.0)
	_check(main.call("_building_at", on_hq) == hq, "building_at", "HQ not picked")

	main.call("_order_workers", workers, on_crystal)
	var all_gather := true
	for w in workers:
		var worker := w as WorkerScript
		if worker.state != WorkerScript.State.TO_RESOURCE or worker._gather_node != crystal:
			all_gather = false
	_check(all_gather, "right_click_resource_gathers", "a worker is not heading to the crystal")

	var loaded := workers[0] as WorkerScript
	loaded.carry_kind = ResKind.CRYSTAL
	loaded.carry_amount = 5
	main.call("_order_workers", [loaded], on_hq)
	_check(loaded.state == WorkerScript.State.TO_DROPOFF and loaded._dropoff == hq,
			"right_click_hq_with_cargo_returns", str(loaded.state))

	var empty := workers[1] as WorkerScript
	main.call("_order_workers", [empty], on_hq)
	_check(empty.state == WorkerScript.State.MOVING, "right_click_hq_empty_moves", str(empty.state))

	var ground := hq.global_position + Vector2(-400.0, 200.0)
	main.call("_order_workers", workers, ground)
	var all_move := true
	for w in workers:
		if (w as WorkerScript).state != WorkerScript.State.MOVING:
			all_move = false
	_check(all_move, "right_click_ground_moves", "a worker did not get a move order")
	quit(1 if _failed else 0)


func _check(ok: bool, name: String, why: String) -> void:
	if ok:
		print("PASS ", name)
	else:
		print("FAIL ", name, ": ", why)
		_failed = true
