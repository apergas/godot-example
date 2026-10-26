extends SceneTree

var _failed := false


func _initialize() -> void:
	create_timer(20.0).timeout.connect(_on_timeout)
	await process_frame
	var gs = root.get_node("GameState")
	root.get_node("Nav").reset()
	gs.reset()
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	await process_frame

	_check("start_population", gs.population == MapLayout.START_WORKERS and gs.population == 3, str(gs.population))
	_check("start_cap", gs.population_cap == 5, str(gs.population_cap))
	var hud = main.get_node("HUD")
	var pop: Label = hud.get_node("%PopLabel")
	_check("hud_shows_3_of_5", pop.text == "pob 3/5", pop.text)

	var hq = null
	for b in get_nodes_in_group("buildings"):
		if b is HQ:
			hq = b
	_check("hq_exists", hq != null, "no HQ in group buildings")
	var sel = main.get_node("Selection")
	var panel: Control = hud.get_node("%HQPanel")
	_check("panel_hidden_at_start", not panel.visible, "visible")
	if hq != null:
		sel.select([hq])
		_check("panel_follows_selection", panel.visible, "hidden after selecting HQ")
		var before: int = hq.queue
		hud.train_requested.emit()
		_check("train_request_enqueues", hq.queue == before + 1, "queue=%d" % hq.queue)
		sel.clear()
		_check("panel_hides_on_clear", not panel.visible, "visible after clear")
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
