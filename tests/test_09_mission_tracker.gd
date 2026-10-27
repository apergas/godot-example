extends SceneTree
## MissionTracker: the 12 missions in order with their stat, rewards paid once and not counted as
## gathering, chaining, workers_alive, multi-condition progress and finishing on victory.

var _failed := false
var _gs: Node


func _initialize() -> void:
	create_timer(20.0).timeout.connect(_on_timeout)
	await process_frame
	_gs = root.get_node("GameState")
	await _test_full_run()
	await _test_victory_finishes()
	await _test_chain_on_start()
	_gs.reset()
	quit(1 if _failed else 0)


func _make_tracker() -> Node:
	var tracker = load("res://scripts/mission_tracker.gd").new()
	root.add_child(tracker)
	await process_frame
	return tracker


func _test_full_run() -> void:
	_gs.reset()
	var tracker = await _make_tracker()
	var changed: Array = []
	var completed: Array = []
	tracker.mission_changed.connect(func(i: int) -> void: changed.append(i))
	tracker.mission_completed.connect(func(i: int, r: Dictionary) -> void: completed.append([i, r]))

	_check("starts_at_first", tracker.index == 0 and tracker.current()["id"] == "select_worker", str(tracker.index))
	_check("first_progress", tracker.progress() == 0 and tracker.target() == 1 and tracker.progress_text() == "0/1", tracker.progress_text())

	_gs.set_stat("selected_worker", 1)
	_check("m1_selected_worker", tracker.index == 1 and changed == [1] and completed == [[0, {}]], "%d %s %s" % [tracker.index, changed, completed])
	_check("m1_no_reward", _gs.stock[ResKind.CRYSTAL] == 50 and _gs.stock[ResKind.ICE] == 0, str(_gs.stock))

	_gs.add(ResKind.CRYSTAL, 30, true)
	_check("m2_partial", tracker.index == 1 and tracker.progress() == 30 and tracker.progress_text() == "30/50", tracker.progress_text())
	_gs.add(ResKind.CRYSTAL, 20, true)
	_check("m2_gathered_crystal", tracker.index == 2, str(tracker.index))
	_check("m2_reward_paid", _gs.stock[ResKind.CRYSTAL] == 125, str(_gs.stock))
	_check("reward_not_counted_as_gathered", _gs.stat("gathered_crystal") == 50, str(_gs.stats))
	_gs.add_stat("unrelated_stat")
	_check("reward_paid_once", _gs.stock[ResKind.CRYSTAL] == 125 and tracker.index == 2, str(_gs.stock))

	_gs.add_stat("workers_trained")
	_check("m3_workers_trained", tracker.index == 3 and _gs.stock[ResKind.CRYSTAL] == 150, "%d %s" % [tracker.index, _gs.stock])

	_gs.add(ResKind.ICE, 100)
	_check("m4_ignores_non_delivery_ice", tracker.index == 3 and tracker.progress() == 0, "%d %d" % [tracker.index, tracker.progress()])
	_gs.add(ResKind.ICE, 50, true)
	_check("m4_gathered_ice", tracker.index == 4 and _gs.stock[ResKind.CRYSTAL] == 175 and _gs.stock[ResKind.ICE] == 150, "%d %s" % [tracker.index, _gs.stock])

	_gs.add_stat("built_habitat")
	_check("m5_built_habitat", tracker.index == 5 and _gs.stock[ResKind.ICE] == 200, "%d %s" % [tracker.index, _gs.stock])

	_check("m6_progress_text", tracker.progress_text() == "0/1", tracker.progress_text())
	_gs.add_stat("built_ice_depot")
	_check("m6_either_depot", tracker.index == 6 and _gs.stock[ResKind.CRYSTAL] == 225, "%d %s" % [tracker.index, _gs.stock])

	var dummies: Array = []
	for i in 9:
		var w := Node2D.new()
		w.add_to_group("workers")
		root.add_child(w)
		dummies.append(w)
	tracker.evaluate()
	_check("m7_nine_not_enough", tracker.index == 6 and tracker.progress_text() == "9/10", tracker.progress_text())
	var tenth := Node2D.new()
	tenth.add_to_group("workers")
	root.add_child(tenth)
	dummies.append(tenth)
	tracker.evaluate()
	_check("m7_workers_alive", tracker.index == 7 and _gs.stock[ResKind.CRYSTAL] == 325, "%d %s" % [tracker.index, _gs.stock])

	_check("m8_counts_first_habitat", tracker.progress_text() == "1/3", tracker.progress_text())
	_gs.add_stat("built_habitat")
	_check("m8_partial", tracker.index == 7 and tracker.progress_text() == "2/3", tracker.progress_text())
	_gs.add_stat("built_habitat")
	_check("m8_more_habitats", tracker.index == 8 and _gs.stock[ResKind.ICE] == 250, "%d %s" % [tracker.index, _gs.stock])

	_gs.add_stat("built_colony_module")
	_check("m10_waits_for_m9", tracker.index == 8, str(tracker.index))
	var before := completed.size()
	_gs.add_stat("built_shipyard")
	_check("m9_m10_chained", tracker.index == 10 and completed.size() == before + 2, "%d %d" % [tracker.index, completed.size()])
	_check("chain_rewards", _gs.stock[ResKind.ICE] == 350 and _gs.stock[ResKind.CRYSTAL] == 375, str(_gs.stock))
	_check("chain_signals", changed.slice(-2) == [9, 10], str(changed))

	_check("m11_two_conditions", tracker.target() == 2 and tracker.progress_text() == "Naves 0/1 · Colonos 0/1", tracker.progress_text())
	_gs.add_stat("ships")
	_check("m11_half", tracker.index == 10 and tracker.progress() == 1 and tracker.progress_text() == "Naves 1/1 · Colonos 0/1", tracker.progress_text())
	_gs.add_stat("colonists")
	_check("m11_done", tracker.index == 11 and _gs.stock[ResKind.CRYSTAL] == 475, "%d %s" % [tracker.index, _gs.stock])

	_check("m12_progress", tracker.target() == 24 and tracker.progress() == 2 and tracker.progress_text() == "Colonos 1/20 · Naves 1/4", tracker.progress_text())
	_gs.add_stat("colonists", 19)
	_check("m12_needs_both", tracker.index == 11, str(tracker.index))
	_gs.add_stat("ships", 3)
	_check("m12_done", tracker.index == 12 and tracker.is_finished() and tracker.current().is_empty(), str(tracker.index))
	_check("all_completed_once", completed.size() == 12 and changed.back() == 12, "%d %s" % [completed.size(), changed])
	_check("final_stock", _gs.stock[ResKind.CRYSTAL] == 475 and _gs.stock[ResKind.ICE] == 350, str(_gs.stock))
	_gs.add_stat("built_habitat")
	_check("nothing_after_finish", tracker.index == 12 and completed.size() == 12 and tracker.progress() == 0, str(tracker.index))

	for w in dummies:
		w.queue_free()
	tracker.queue_free()
	await process_frame


func _test_victory_finishes() -> void:
	_gs.reset()
	var tracker = await _make_tracker()
	var changed: Array = []
	tracker.mission_changed.connect(func(i: int) -> void: changed.append(i))
	_gs.victory.emit()
	_check("victory_finishes", tracker.is_finished() and changed == [Missions.LIST.size()], "%d %s" % [tracker.index, changed])
	_check("victory_pays_nothing", _gs.stock[ResKind.CRYSTAL] == 50 and _gs.stock[ResKind.ICE] == 0, str(_gs.stock))
	_gs.victory.emit()
	_check("victory_twice_ignored", changed.size() == 1, str(changed))
	tracker.queue_free()
	await process_frame


func _test_chain_on_start() -> void:
	_gs.reset()
	_gs.set_stat("selected_worker", 1)
	_gs.add(ResKind.CRYSTAL, 60, true)
	_gs.add_stat("workers_trained")
	var tracker = await _make_tracker()
	_check("chains_on_ready", tracker.index == 3, str(tracker.index))
	_check("chain_on_ready_rewards", _gs.stock[ResKind.CRYSTAL] == 160, str(_gs.stock))
	tracker.queue_free()
	await process_frame


func _check(test_name: String, ok: bool, why: String) -> void:
	if ok:
		print("PASS ", test_name)
	else:
		_failed = true
		print("FAIL ", test_name, ": ", why)


func _on_timeout() -> void:
	print("FAIL timeout: test did not finish (script error?)")
	quit(1)
