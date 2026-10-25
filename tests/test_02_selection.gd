extends SceneTree

var _failed := false


func _initialize() -> void:
	var selection_script: GDScript = load("res://scripts/selection.gd")
	if selection_script == null:
		_check("selection_script_exists", false, "res://scripts/selection.gd missing")
		quit(1)
		return
	var worker_scene: PackedScene = load("res://scenes/worker.tscn")
	var workers: Array = []
	for spot in [Vector2(100, 100), Vector2(200, 100), Vector2(300, 100)]:
		var w: Node2D = worker_scene.instantiate()
		w.position = spot
		root.add_child(w)
		workers.append(w)
	var back: Node2D = worker_scene.instantiate()
	back.position = Vector2(400, 100)
	root.add_child(back)
	var front: Node2D = worker_scene.instantiate()
	front.position = Vector2(400, 130)
	root.add_child(front)
	var sel: Node2D = selection_script.new()
	root.add_child(sel)
	var emitted: Array = []
	sel.changed.connect(func(new_items: Array) -> void: emitted.append(new_items.size()))
	await process_frame

	var rect: Rect2 = selection_script.drag_rect(Vector2(250, 150), Vector2(50, 50))
	_check("drag_rect_normalized", rect == Rect2(50, 50, 200, 100), "got %s" % rect)
	var inside: Array = selection_script.items_in_rect(rect, workers)
	_check("items_in_rect_feet", inside.size() == 2 and inside.has(workers[0]) and inside.has(workers[1]), "got %d items" % inside.size())
	var body_only: Array = selection_script.items_in_rect(Rect2(280, 60, 40, 25), workers)
	_check("items_in_rect_body", body_only.size() == 1 and body_only[0] == workers[2], "got %d items" % body_only.size())
	var picked: Node2D = selection_script.pick_at(Vector2(400, 95), [back, front])
	_check("pick_front_most", picked == front, "picked the wrong worker")
	var missed: Node2D = selection_script.pick_at(Vector2(700, 700), [back, front])
	_check("pick_nothing", missed == null, "picked something in empty space")

	sel.begin_drag(Vector2(50, 50))
	sel.update_drag(Vector2(150, 120))
	sel.end_drag(Vector2(250, 150), false)
	_check("box_selects", sel.items.size() == 2 and workers[0].selected and workers[1].selected and not workers[2].selected, "items %d" % sel.items.size())

	sel.begin_drag(Vector2(290, 60))
	sel.end_drag(Vector2(310, 110), true)
	_check("shift_box_adds", sel.items.size() == 3 and workers[2].selected, "items %d" % sel.items.size())

	sel.begin_drag(Vector2(200, 80))
	sel.end_drag(Vector2(201, 81), false)
	_check("click_selects_one", sel.items.size() == 1 and sel.items[0] == workers[1] and not workers[0].selected and workers[1].selected, "items %d" % sel.items.size())

	sel.begin_drag(Vector2(300, 80))
	sel.end_drag(Vector2(300, 80), true)
	_check("shift_click_adds", sel.items.size() == 2 and workers[1].selected and workers[2].selected, "items %d" % sel.items.size())

	sel.begin_drag(Vector2(600, 600))
	sel.end_drag(Vector2(601, 600), true)
	_check("shift_click_empty_keeps", sel.items.size() == 2, "items %d" % sel.items.size())

	sel.begin_drag(Vector2(600, 600))
	sel.end_drag(Vector2(601, 600), false)
	_check("click_empty_clears", sel.items.is_empty() and not workers[1].selected and not workers[2].selected, "items %d" % sel.items.size())

	sel.select([workers[0], workers[0]])
	_check("select_dedupes", sel.items.size() == 1 and workers[0].selected, "items %d" % sel.items.size())
	sel.clear()
	_check("clear", sel.items.is_empty() and not workers[0].selected, "items %d" % sel.items.size())
	_check("changed_emitted", emitted.size() == 8, "changed emitted %d times" % emitted.size())
	quit(1 if _failed else 0)


func _check(test_name: String, ok: bool, why: String) -> void:
	if ok:
		print("PASS ", test_name)
	else:
		print("FAIL ", test_name, ": ", why)
		_failed = true
