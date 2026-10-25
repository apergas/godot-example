extends SceneTree

var _failed := false


func _initialize() -> void:
	create_timer(20.0).timeout.connect(_on_timeout)
	await process_frame
	var gs = root.get_node("GameState")
	root.get_node("Nav").reset()
	gs.reset()
	var hud = load("res://scenes/hud.tscn").instantiate()
	root.add_child(hud)
	var world := Node2D.new()
	root.add_child(world)
	var hq = load("res://scenes/buildings/hq.tscn").instantiate()
	hq.position = Grid.footprint_origin(MapLayout.HQ_CELL, Vector2i(3, 3))
	world.add_child(hq)
	hq.set_process(false)
	await process_frame
	await process_frame

	var pop: Label = hud.get_node("%PopLabel")
	var panel: Control = hud.get_node("%HQPanel")
	var button: Button = hud.get_node("%TrainButton")
	var queue_label: Label = hud.get_node("%QueueLabel")
	var bar: ProgressBar = hud.get_node("%TrainBar")
	var status: Label = hud.get_node("%StatusLabel")

	_check("pop_text", pop.text == "pob 0/5", pop.text)
	_check("pop_not_red", not pop.has_theme_color_override("font_color"), "red at 0/5")
	_check("panel_hidden_at_start", not panel.visible, "visible")
	_check("button_text", button.text == "Robot (50 cristal)", button.text)

	var requests: Array = [0]
	hud.train_requested.connect(func() -> void: requests[0] += 1)

	hud.show_for_selection([hq])
	_check("panel_for_hq", panel.visible, "hidden")
	_check("queue_label_empty", queue_label.text == "Cola: 0/5", queue_label.text)

	button.pressed.emit()
	_check("button_emits", requests[0] == 1, str(requests[0]))

	var key := InputEventKey.new()
	key.keycode = KEY_Q
	key.pressed = true
	hud._unhandled_key_input(key)
	_check("q_emits", requests[0] == 2, str(requests[0]))

	hq.enqueue_worker()
	_check("queue_label_updates", queue_label.text == "Cola: 1/5", queue_label.text)
	_check("button_disabled_without_money", button.disabled, "enabled with 0 crystal")
	hq._process(hq.TRAIN_SECONDS * 0.25)
	_check("bar_updates", is_equal_approx(bar.value, 0.25), str(bar.value))
	_check("status_hidden_with_room", not status.visible, "visible")

	gs.add_population(5)
	_check("pop_full_text", pop.text == "pob 5/5", pop.text)
	_check("pop_full_red", pop.has_theme_color_override("font_color"), "not red")
	_check("status_when_blocked", status.visible and status.text == "Población máxima — construye habitáculos", status.text)

	var other := Node2D.new()
	world.add_child(other)
	hud.show_for_selection([other])
	_check("panel_hidden_for_other", not panel.visible, "visible")
	hud.show_for_selection([hq, other])
	_check("panel_hidden_for_many", not panel.visible, "visible")
	hud._unhandled_key_input(key)
	_check("q_ignored_when_hidden", requests[0] == 2, str(requests[0]))
	hud.show_for_selection([])
	_check("panel_hidden_for_empty", not panel.visible, "visible")
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
