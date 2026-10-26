extends SceneTree
## Victory screen shows "Misiones: N/T": 12/12 after a full win, a partial count, hidden without a tracker.

var _failed := false


func _initialize() -> void:
	create_timer(30.0).timeout.connect(_on_timeout)
	await process_frame
	var gs = root.get_node("GameState")
	gs.reset()

	# Full game: the tracker completes the final mission on victory; the screen reads it afterwards.
	var main := _make_main(true)
	var victory := main.get_node("Victory") as Victory
	var tracker := main.get_node("MissionTracker") as MissionTracker
	await process_frame
	gs.victory.emit()
	var guard := 0
	while victory.screen == null and guard < 600:
		await process_frame
		guard += 1
	_check("full_screen_shown", victory.screen != null, "no screen")
	if victory.screen != null:
		var label := victory.screen.get_node("%MissionsLabel") as Label
		_check("full_text", label.text == "Misiones: 12/12", label.text)
		_check("full_visible", label.visible, "hidden")
	main.queue_free()
	await process_frame

	# Partial count, guide hidden: the line still shows.
	gs.reset()
	main = _make_main(true)
	victory = main.get_node("Victory") as Victory
	tracker = main.get_node("MissionTracker") as MissionTracker
	await process_frame
	tracker.index = 5
	MissionPanel.guide_hidden = true
	victory._show_screen()
	var partial := victory.screen.get_node("%MissionsLabel") as Label
	_check("partial_text", partial.text == "Misiones: 5/12", partial.text)
	_check("partial_visible_with_guide_hidden", partial.visible, "hidden")
	MissionPanel.guide_hidden = false
	main.queue_free()
	await process_frame

	# No tracker: line hidden.
	main = _make_main(false)
	victory = main.get_node("Victory") as Victory
	victory._show_screen()
	_check("no_tracker_hidden", not (victory.screen.get_node("%MissionsLabel") as Label).visible, "visible")
	main.queue_free()
	await process_frame
	gs.reset()
	quit(1 if _failed else 0)


func _make_main(with_tracker: bool) -> Node:
	var main := Node.new()
	main.name = "Main"
	root.add_child(main)
	var victory := Victory.new()
	victory.name = "Victory"
	main.add_child(victory)
	if with_tracker:
		var tracker := MissionTracker.new()
		tracker.name = "MissionTracker"
		main.add_child(tracker)
	return main


func _check(test_name: String, ok: bool, why: String) -> void:
	if ok:
		print("PASS ", test_name)
	else:
		_failed = true
		print("FAIL ", test_name, ": ", why)


func _on_timeout() -> void:
	print("FAIL timeout: test did not finish (script error?)")
	quit(1)
