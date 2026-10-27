extends SceneTree

var _failed := false


func _initialize() -> void:
	create_timer(20.0).timeout.connect(_on_timeout)
	await process_frame
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.get_node("Nav").reset()
	root.get_node("GameState").reset()
	var world := Node2D.new()
	root.add_child(world)
	var hq = load("res://scenes/buildings/hq.tscn").instantiate()
	hq.position = Grid.footprint_origin(MapLayout.HQ_CELL, Vector2i(3, 3))
	world.add_child(hq)
	var worker = load("res://scenes/worker.tscn").instantiate()
	worker.position = Grid.cell_to_world(Vector2i(30, 30))
	world.add_child(worker)
	var sel := Selection.new()
	root.add_child(sel)
	await process_frame
	await process_frame

	var hq_point: Vector2 = hq.global_position + Vector2(0.0, -Grid.TILE * 1.5)
	var worker_point: Vector2 = worker.global_position + Vector2(0.0, -22.0)

	_click(sel, hq_point, false)
	_check("click_selects_building", sel.items == [hq] and hq.selected, str(sel.items))
	_check("overlay_exists", hq.get_node_or_null("Overlay") != null, "no Overlay child")

	_click(sel, worker_point, false)
	_check("click_worker_replaces", sel.items == [worker] and not hq.selected, str(sel.items))

	_click(sel, hq_point, true)
	_check("shift_click_building_alone", sel.items == [hq] and not worker.selected, str(sel.items))

	_click(sel, worker_point, true)
	_check("shift_click_worker_drops_building", sel.items == [worker] and not hq.selected, str(sel.items))

	var box_from: Vector2 = hq.global_position - Vector2(200.0, 400.0)
	var box_to: Vector2 = worker.global_position + Vector2(50.0, 50.0)
	sel.select([hq])
	sel.begin_drag(box_from)
	sel.update_drag(box_to)
	sel.end_drag(box_to, false)
	_check("box_only_workers", sel.items == [worker], str(sel.items))

	sel.select([hq])
	sel.begin_drag(box_from)
	sel.update_drag(box_to)
	sel.end_drag(box_to, true)
	_check("additive_box_drops_building", sel.items == [worker], str(sel.items))

	_click(sel, Grid.cell_to_world(Vector2i(50, 40)), false)
	_check("click_empty_clears", sel.items.is_empty(), str(sel.items))

	# Additive click on empty ground keeps the selection.
	sel.select([worker])
	_click(sel, Grid.cell_to_world(Vector2i(50, 40)), true)
	_check("additive_click_empty_keeps", sel.items == [worker], str(sel.items))

	# Freed nodes are filtered from the additive base.
	var extra = load("res://scenes/worker.tscn").instantiate()
	extra.position = Grid.cell_to_world(Vector2i(40, 30))
	world.add_child(extra)
	await process_frame
	sel.select([extra])
	extra.free()
	_click(sel, worker_point, true)
	_check("additive_filters_freed", sel.items == [worker], str(sel.items))

	_finish()


func _click(sel: Selection, p: Vector2, additive: bool) -> void:
	sel.begin_drag(p)
	sel.end_drag(p, additive)


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
