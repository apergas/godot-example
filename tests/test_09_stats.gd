extends SceneTree
## GameState.stats: deliveries count, rewards do not, add_stat/set_stat, colonists/ships, reset.

var _failed := false


func _initialize() -> void:
	create_timer(20.0).timeout.connect(_on_timeout)
	await process_frame
	var gs: Node = root.get_node("GameState")
	gs.reset()
	var start := {"gathered_crystal": 0, "gathered_ice": 0, "workers_trained": 0, "colonists": 0, "ships": 0, "selected_worker": 0}
	_check("start_stats", gs.stats == start, str(gs.stats))
	var hits := [0]
	gs.stats_changed.connect(func() -> void: hits[0] += 1)

	gs.add(ResKind.CRYSTAL, 10, true)
	_check("delivery_adds_stock", gs.stock[ResKind.CRYSTAL] == 60, str(gs.stock))
	_check("delivery_counts_crystal", gs.stat("gathered_crystal") == 10 and hits[0] == 1, "%s hits=%d" % [gs.stats, hits[0]])
	gs.add(ResKind.ICE, 10, true)
	_check("delivery_counts_ice", gs.stat("gathered_ice") == 10 and gs.stat("gathered_crystal") == 10, str(gs.stats))

	gs.add(ResKind.CRYSTAL, 25)
	_check("reward_adds_stock", gs.stock[ResKind.CRYSTAL] == 85, str(gs.stock))
	_check("reward_not_counted", gs.stat("gathered_crystal") == 10 and hits[0] == 2, "%s hits=%d" % [gs.stats, hits[0]])
	_check("reward_not_in_gathered", gs.gathered[ResKind.CRYSTAL] == 10, str(gs.gathered))
	gs.add(ResKind.ICE, 0, true)
	_check("zero_delivery_silent", gs.stat("gathered_ice") == 10 and hits[0] == 2, "hits=%d" % hits[0])

	_check("missing_stat_is_zero", gs.stat("built_shipyard") == 0, str(gs.stat("built_shipyard")))
	gs.add_stat("built_habitat")
	_check("add_stat_default_one", gs.stat("built_habitat") == 1 and hits[0] == 3, "hits=%d" % hits[0])
	gs.add_stat("workers_trained", 2)
	_check("add_stat_n", gs.stat("workers_trained") == 2, str(gs.stats))

	gs.set_stat("selected_worker", 1)
	_check("set_stat", gs.stat("selected_worker") == 1 and hits[0] == 5, "hits=%d" % hits[0])
	gs.set_stat("selected_worker", 1)
	_check("set_stat_same_value_silent", hits[0] == 5, "hits=%d" % hits[0])

	gs.add_colonist(1)
	gs.add_ship(1)
	_check("colonist_and_ship_counted", gs.stat("colonists") == 1 and gs.stat("ships") == 1, str(gs.stats))

	gs.reset()
	_check("reset_clears_stats", gs.stats == start and not gs.stats.has("built_habitat"), str(gs.stats))
	_check("reset_emits_stats_changed", hits[0] >= 8, "hits=%d" % hits[0])
	_check("reset_keeps_start_stock", gs.stock[ResKind.CRYSTAL] == 50 and gs.stock[ResKind.ICE] == 0, str(gs.stock))
	gs.add_stat("built_hq")
	_check("start_stats_constant_untouched", not gs.START_STATS.has("built_hq"), str(gs.START_STATS))
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
