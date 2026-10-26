extends SceneTree
## MissionPanel: title, text and progress from the tracker, 3 s toast, hide/show remembered, final state.

var _failed := false


func _initialize() -> void:
	create_timer(20.0).timeout.connect(_on_timeout)
	await process_frame
	var gs: Node = root.get_node("GameState")
	gs.reset()
	var tracker = load("res://scripts/mission_tracker.gd").new()
	root.add_child(tracker)
	var scene := load("res://scenes/mission_panel.tscn") as PackedScene
	if scene == null:
		_check("panel_scene_exists", false, "scenes/mission_panel.tscn missing")
		quit(1)
		return
	var panel = scene.instantiate()
	root.add_child(panel)
	await process_frame
	panel.bind(tracker)

	var title: Label = panel.get_node("%Title")
	var text: Label = panel.get_node("%Text")
	var bar: ProgressBar = panel.get_node("%Bar")
	var count: Label = panel.get_node("%Count")
	var toast: Label = panel.get_node("%Toast")
	var toggle: Button = panel.get_node("%ToggleButton")
	var body: Control = panel.get_node("%Body")

	_check("title_first", title.text == "Misión 1/12", title.text)
	_check("text_first", text.text == Missions.LIST[0]["text"], text.text)
	_check("progress_first", count.text == "0/1" and bar.max_value == 1.0 and bar.value == 0.0, "%s %f/%f" % [count.text, bar.value, bar.max_value])
	_check("toast_hidden_at_start", not toast.visible, "visible")
	_check("guide_shown_at_start", body.visible and toggle.text == "Ocultar guía", toggle.text)

	gs.set_stat("selected_worker", 1)
	_check("title_second", title.text == "Misión 2/12" and text.text == Missions.LIST[1]["text"], title.text)
	_check("toast_without_reward", toast.visible and toast.text == "✔ Misión completada", toast.text)
	_check("progress_second", count.text == "0/50" and bar.max_value == 50.0, "%s %f" % [count.text, bar.max_value])

	gs.add(ResKind.CRYSTAL, 20, true)
	_check("progress_follows_stats", count.text == "20/50" and bar.value == 20.0, "%s %f" % [count.text, bar.value])
	gs.add(ResKind.CRYSTAL, 30, true)
	_check("toast_with_reward", toast.visible and toast.text == "✔ Misión completada: +25 cristal", toast.text)
	_check("title_third", title.text == "Misión 3/12", title.text)
	panel._process(2.0)
	_check("toast_still_visible_at_2s", toast.visible, "hidden too early")
	panel._process(1.1)
	_check("toast_hidden_after_3s", not toast.visible, "still visible")

	toggle.pressed.emit()
	_check("hide_guide", not body.visible and toggle.text == "Mostrar guía", toggle.text)
	gs.add_stat("workers_trained")
	_check("toast_visible_when_guide_hidden", toast.visible and toast.text == "✔ Misión completada: +25 cristal", toast.text)

	panel.queue_free()
	await process_frame
	var panel2 = scene.instantiate()
	root.add_child(panel2)
	await process_frame
	panel2.bind(tracker)
	var body2: Control = panel2.get_node("%Body")
	var toggle2: Button = panel2.get_node("%ToggleButton")
	_check("hidden_state_remembered", not body2.visible and toggle2.text == "Mostrar guía", toggle2.text)
	toggle2.pressed.emit()
	_check("show_guide", body2.visible and toggle2.text == "Ocultar guía", toggle2.text)

	var title2: Label = panel2.get_node("%Title")
	var count2: Label = panel2.get_node("%Count")
	var bar2: ProgressBar = panel2.get_node("%Bar")
	_check("rebound_shows_current", title2.text == "Misión 4/12", title2.text)
	gs.add(ResKind.ICE, 50, true)
	gs.add_stat("built_habitat")
	gs.add_stat("built_crystal_depot")
	var dummies: Array = []
	for i in 10:
		var w := Node2D.new()
		w.add_to_group("workers")
		root.add_child(w)
		dummies.append(w)
	tracker.evaluate()
	gs.add_stat("built_habitat", 2)
	gs.add_stat("built_shipyard")
	gs.add_stat("built_colony_module")
	_check("title_eleventh", title2.text == "Misión 11/12", title2.text)
	_check("multi_condition_text", count2.text == "Naves 0/1 · Colonos 0/1" and bar2.max_value == 2.0, "%s %f" % [count2.text, bar2.max_value])

	gs.victory.emit()
	_check("finished_title", title2.text == "¡Misión cumplida!", title2.text)
	_check("finished_bar_full", bar2.value == bar2.max_value and count2.text == "", "%f/%f '%s'" % [bar2.value, bar2.max_value, count2.text])

	for w in dummies:
		w.queue_free()
	panel2.queue_free()
	tracker.queue_free()
	await process_frame
	gs.reset()
	quit(1 if _failed else 0)


func _check(test_name: String, ok: bool, why: String) -> void:
	if ok:
		print("PASS ", test_name)
	else:
		_failed = true
		print("FAIL ", test_name, ": ", why)


func _on_timeout() -> void:
	print("FAIL timeout: test did not finish (script error?)")
	quit(1)
