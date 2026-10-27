extends SceneTree
## Main has a MissionTracker bound to the HUD mission panel; selecting a robot completes mission 1;
## the panel sits below the top bar, inside the screen and clear of %GoalLabel.

var _failed := false


func _initialize() -> void:
	create_timer(20.0).timeout.connect(_on_timeout)
	await process_frame
	var gs: Node = root.get_node("GameState")
	root.get_node("Nav").reset()
	gs.reset()
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	await process_frame

	var tracker = main.get_node_or_null("MissionTracker")
	_check("tracker_in_main", tracker != null and tracker is MissionTracker, str(tracker))
	var hud = main.get_node("HUD")
	var panel = hud.get_node_or_null("%MissionPanel")
	_check("panel_in_hud", panel != null and panel is MissionPanel, str(panel))
	if tracker == null or panel == null:
		quit(1)
		return
	var title: Label = panel.get_node("%Title")
	_check("starts_at_mission_1", tracker.index == 0 and title.text == "Misión 1/12", "%d %s" % [tracker.index, title.text])
	_check("start_stats_clean", gs.stat("workers_trained") == 0 and gs.stat("built_hq") == 0 and gs.stat("gathered_crystal") == 0, str(gs.stats))

	var rect: Rect2 = panel.get_global_rect()
	var top: Control = hud.get_node("TopBar")
	_check("below_top_bar", rect.position.y >= top.get_global_rect().end.y, "%s vs %s" % [rect, top.get_global_rect()])
	var screen: Vector2 = panel.get_viewport_rect().size
	_check("inside_screen", rect.position.x >= 0.0 and rect.end.x <= screen.x, "%s in %s" % [rect, screen])
	var goal = hud.get_node_or_null("%GoalLabel")
	_check("clear_of_goal_label", goal == null or not rect.intersects(goal.get_global_rect()), str(goal.get_global_rect() if goal else null))

	var workers := get_nodes_in_group("workers")
	_check("has_workers", workers.size() > 0, str(workers.size()))
	if workers.size() > 0:
		main.get_node("Selection").select([workers[0]])
		_check("selecting_completes_mission_1", tracker.index == 1 and title.text == "Misión 2/12", "%d %s" % [tracker.index, title.text])
		var toast: Label = panel.get_node("%Toast")
		_check("toast_in_game", toast.visible and toast.text == "✔ Misión completada", toast.text)
	main.queue_free()
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
