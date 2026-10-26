extends SceneTree

var _failed := false


func _initialize() -> void:
	create_timer(20.0).timeout.connect(_on_timeout)
	await process_frame
	var gs = root.get_node("GameState")
	gs.reset()
	var got: Array = []
	gs.population_changed.connect(func(p: int, c: int) -> void: got.append([p, c]))

	_check("starts_empty", gs.population == 0 and gs.population_cap == 0, "%d/%d" % [gs.population, gs.population_cap])
	_check("no_room_at_zero", not gs.has_room(), "has_room() true with 0/0")

	gs.add_cap(5)
	_check("add_cap", gs.population_cap == 5, str(gs.population_cap))
	_check("signal_on_cap", got.size() == 1 and got[0] == [0, 5], str(got))
	_check("room_with_cap", gs.has_room(), "has_room() false with 0/5")

	gs.add_population(5)
	_check("add_population", gs.population == 5, str(gs.population))
	_check("signal_on_population", got.back() == [5, 5], str(got.back()))
	_check("full_has_no_room", not gs.has_room(), "has_room() true with 5/5")

	gs.add_cap(100)
	_check("cap_clamped", gs.population_cap == gs.MAX_CAP and gs.MAX_CAP == 50, str(gs.population_cap))
	gs.add_cap(-100)
	_check("cap_unclamps_consistently", gs.population_cap == 5, str(gs.population_cap))

	gs.add_population(-10)
	_check("population_not_negative", gs.population == 0, str(gs.population))

	got.clear()
	gs.add_population(2)
	gs.reset()
	_check("reset_clears_population", gs.population == 0 and gs.population_cap == 0, "%d/%d" % [gs.population, gs.population_cap])
	_check("reset_emits", got.back() == [0, 0], str(got))
	_check("reset_keeps_stock", gs.stock[ResKind.CRYSTAL] == 50 and gs.stock[ResKind.ICE] == 0, str(gs.stock))
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
