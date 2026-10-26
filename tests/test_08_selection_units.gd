extends SceneTree
## tests/test_08_selection_units.gd — run: tools\godot.cmd --headless --path . --script res://tests/test_08_selection_units.gd

var _failed := false


func _initialize() -> void:
	create_timer(20.0).timeout.connect(_on_timeout)
	await process_frame
	var nav = root.get_node("Nav")
	nav.reset()
	root.get_node("GameState").reset()
	var world := Node2D.new()
	root.add_child(world)
	var hq = load("res://scenes/buildings/hq.tscn").instantiate()
	hq.position = Grid.footprint_origin(MapLayout.HQ_CELL, Vector2i(3, 3))
	world.add_child(hq)
	var worker = load("res://scenes/worker.tscn").instantiate()
	worker.position = Grid.cell_to_world(Vector2i(30, 30))
	world.add_child(worker)
	var colonist = load("res://scenes/colonist.tscn").instantiate()
	colonist.position = Grid.cell_to_world(Vector2i(32, 30))
	world.add_child(colonist)
	var rect := Rect2i(36, 29, 2, 2)
	nav.set_blocked(rect, true)
	var ship = load("res://scenes/rescue_ship.tscn").instantiate()
	ship.platform_rect = rect
	ship.position = Shipyard.platform_center(rect)
	world.add_child(ship)
	var sel := Selection.new()
	root.add_child(sel)
	await process_frame
	await process_frame
	colonist.set_physics_process(false)

	var box_from := Vector2(29 * Grid.TILE, 28 * Grid.TILE)
	var box_to := Vector2(40 * Grid.TILE, 31 * Grid.TILE + 40)
	sel.begin_drag(box_from)
	sel.update_drag(box_to)
	sel.end_drag(box_to, false)
	_check("box_takes_worker_and_colonist", sel.items.size() == 2 and sel.items.has(worker) and sel.items.has(colonist), str(sel.items))
	_check("box_skips_ship", not sel.items.has(ship) and not ship.selected, str(sel.items))
	_check("colonist_selected_flag", colonist.selected, "colonist.selected false")

	var ship_point: Vector2 = ship.global_position + Vector2(0, -80)
	var colonist_point: Vector2 = colonist.global_position + Vector2(0, -22)
	_click(sel, ship_point, false)
	_check("click_selects_ship_alone", sel.items == [ship] and ship.selected and not colonist.selected, str(sel.items))
	_click(sel, colonist_point, true)
	_check("shift_click_unit_drops_ship", sel.items == [colonist] and not ship.selected, str(sel.items))
	_click(sel, worker.global_position + Vector2(0, -22), true)
	_check("shift_click_mixes_units", sel.items.size() == 2 and sel.items.has(worker) and sel.items.has(colonist), str(sel.items))
	_click(sel, colonist_point, false)
	_check("click_selects_colonist", sel.items == [colonist], str(sel.items))
	_click(sel, hq.global_position + Vector2(0, -96), false)
	_check("click_building_still_alone", sel.items == [hq], str(sel.items))
	sel.begin_drag(Vector2.ZERO)
	sel.clear()
	_check("clear_ends_drag", not sel._dragging, "drag survived clear")
	quit(1 if _failed else 0)


func _click(sel: Selection, p: Vector2, additive: bool) -> void:
	sel.begin_drag(p)
	sel.end_drag(p, additive)


func _check(test_name: String, ok: bool, why: String) -> void:
	if ok:
		print("PASS ", test_name)
	else:
		print("FAIL ", test_name, ": ", why)
		_failed = true


func _on_timeout() -> void:
	print("FAIL timeout: test did not finish (script error?)")
	quit(1)
