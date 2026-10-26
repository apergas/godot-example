extends SceneTree
## tests/test_08_restart.gd — run: tools\godot.cmd --headless --path . --script res://tests/test_08_restart.gd

var _failed := false


func _initialize() -> void:
	create_timer(30.0).timeout.connect(_on_timeout)
	await process_frame
	var gs = root.get_node("GameState")
	var nav = root.get_node("Nav")
	gs.reset()
	nav.reset()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame
	gs.add(ResKind.ICE, 300)
	gs.add_colonist(5)
	gs.add_ship(2)
	gs.goal_colonists = 3

	gs.restart_game()
	gs.restart_game()
	for i in 6:
		await process_frame
	_check("old_scene_freed", not is_instance_valid(main), "old Main still alive")
	_check("new_main_loaded", is_instance_valid(current_scene) and current_scene.name == "Main", str(current_scene))
	_check("stock_reset", gs.stock[ResKind.CRYSTAL] == 50 and gs.stock[ResKind.ICE] == 0, str(gs.stock))
	_check("goals_reset", gs.colonists == 0 and gs.ships == 0 and gs.goal_colonists == 20 and not gs.victory_reached,
			"%d %d %d" % [gs.colonists, gs.ships, gs.goal_colonists])
	_check("population_of_new_game", gs.population == MapLayout.START_WORKERS and gs.population_cap == 5,
			"%d/%d" % [gs.population, gs.population_cap])
	_check("nav_rebuilt", not nav.is_area_free(Rect2i(MapLayout.HQ_CELL, Vector2i.ONE)), "HQ cells are free")
	_check("play_time_reset", gs.play_time < 1.0, str(gs.play_time))
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
