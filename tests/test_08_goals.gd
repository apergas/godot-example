extends SceneTree
## tests/test_08_goals.gd — run: tools\godot.cmd --headless --path . --script res://tests/test_08_goals.gd

var _failed := false


func _initialize() -> void:
	create_timer(20.0).timeout.connect(_on_timeout)
	await process_frame
	var gs = root.get_node("GameState")
	gs.reset()
	_check("max_cap_60", gs.MAX_CAP == 60, str(gs.MAX_CAP))
	gs.add_cap(100)
	_check("cap_clamped_to_60", gs.population_cap == 60, str(gs.population_cap))
	_check("goal_constants", gs.GOAL_COLONISTS == 20 and gs.GOAL_SHIPS == 4, "%d/%d" % [gs.GOAL_COLONISTS, gs.GOAL_SHIPS])
	_check("goals_start_at_constants", gs.goal_colonists == 20 and gs.goal_ships == 4, "%d/%d" % [gs.goal_colonists, gs.goal_ships])
	_check("counters_start_at_zero", gs.colonists == 0 and gs.ships == 0 and not gs.victory_reached, "%d/%d" % [gs.colonists, gs.ships])

	var goals: Array = []
	var wins: Array = [0]
	gs.goal_changed.connect(func(c: int, s: int) -> void: goals.append([c, s]))
	gs.victory.connect(func() -> void: wins[0] += 1)

	gs.goal_colonists = 2
	gs.goal_ships = 1
	gs.add_colonist(1)
	_check("add_colonist", gs.colonists == 1 and goals.back() == [1, 0], str(goals))
	gs.add_ship(1)
	_check("add_ship", gs.ships == 1 and goals.back() == [1, 1], str(goals))
	_check("no_victory_before_goal", wins[0] == 0, str(wins[0]))
	gs.add_colonist(1)
	_check("victory_exactly_at_goal", wins[0] == 1 and gs.victory_reached, str(wins[0]))
	gs.add_colonist(1)
	gs.add_ship(1)
	gs.add_colonist(-3)
	gs.add_colonist(3)
	_check("victory_only_once", wins[0] == 1, str(wins[0]))
	gs.add_ship(-10)
	_check("ships_not_negative", gs.ships == 0, str(gs.ships))
	gs.add_colonist(-10)
	_check("colonists_not_negative", gs.colonists == 0, str(gs.colonists))

	gs.add(ResKind.CRYSTAL, 30, true)
	gs.add(ResKind.ICE, 12, true)
	gs.spend({ResKind.CRYSTAL: 20})
	_check("gathered_counts_income_only", gs.gathered[ResKind.CRYSTAL] == 30 and gs.gathered[ResKind.ICE] == 12, str(gs.gathered))
	gs.add(ResKind.CRYSTAL, 99)
	_check("reward_add_not_gathered", gs.gathered[ResKind.CRYSTAL] == 30, str(gs.gathered))
	var before: float = gs.play_time
	gs._process(2.5)
	_check("play_time_advances", gs.play_time >= before + 2.5, str(gs.play_time))

	gs.reset()
	_check("reset_counters", gs.colonists == 0 and gs.ships == 0 and not gs.victory_reached, "%d/%d" % [gs.colonists, gs.ships])
	_check("reset_goals", gs.goal_colonists == 20 and gs.goal_ships == 4, "%d/%d" % [gs.goal_colonists, gs.goal_ships])
	_check("reset_stats", gs.gathered[0] == 0 and gs.gathered[1] == 0 and gs.play_time < 0.5, "%s %f" % [gs.gathered, gs.play_time])
	_check("reset_emits_goal", goals.back() == [0, 0], str(goals.back()))
	_check("reset_keeps_start_stock", gs.stock[ResKind.CRYSTAL] == 50 and gs.stock[ResKind.ICE] == 0, str(gs.stock))

	gs.goal_colonists = 1
	gs.goal_ships = 1
	gs.add_ship(1)
	gs.add_colonist(1)
	_check("victory_again_after_reset", wins[0] == 2, str(wins[0]))
	gs.reset()
	quit(1 if _failed else 0)


func _check(test_name: String, ok: bool, why: String) -> void:
	if ok:
		print("PASS ", test_name)
	else:
		print("FAIL ", test_name, ": ", why)
		_failed = true


func _on_timeout() -> void:
	print("FAIL timeout: test did not finish (script error?)")
	quit(1)
