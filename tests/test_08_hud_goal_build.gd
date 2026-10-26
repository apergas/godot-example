extends SceneTree
## tests/test_08_hud_goal_build.gd — run: tools\godot.cmd --headless --path . --script res://tests/test_08_hud_goal_build.gd

const SHIPYARD := "res://scenes/buildings/shipyard.tscn"
const MODULE := "res://scenes/buildings/colony_module.tscn"

var _failed := false


func _initialize() -> void:
	create_timer(20.0).timeout.connect(_on_timeout)
	await process_frame
	var gs = root.get_node("GameState")
	gs.reset()
	root.get_node("Nav").reset()
	var hud = load("res://scenes/hud.tscn").instantiate()
	root.add_child(hud)
	var world := Node2D.new()
	root.add_child(world)
	await process_frame

	var goal: Label = hud.get_node("%GoalLabel")
	_check("goal_text_start", goal.text == "Colonos 0/20 · Naves 0/4", goal.text)
	gs.add_colonist(3)
	gs.add_ship(1)
	_check("goal_text_updates", goal.text == "Colonos 3/20 · Naves 1/4", goal.text)
	gs.add_colonist(-3)
	gs.add_ship(-1)

	var yard_button := hud.find_child("ShipyardButton", true, false) as Button
	var module_button := hud.find_child("ColonyModuleButton", true, false) as Button
	var habitat_button := hud.find_child("HabitatButton", true, false) as Button
	_check("buttons_exist", yard_button != null and module_button != null, "ShipyardButton/ColonyModuleButton not found")
	if yard_button == null or module_button == null:
		quit(1)
		return
	_check("buttons_next_to_habitat", yard_button.get_parent() == habitat_button.get_parent()
			and module_button.get_parent() == habitat_button.get_parent(), "different parent")
	var fake_worker := Node2D.new()
	fake_worker.add_to_group("workers")
	root.add_child(fake_worker)
	hud.show_for_selection([fake_worker])
	_check("shipyard_text", yard_button.text == "Astillero [Y]\n200 cristal · 100 hielo", yard_button.text)
	_check("shipyard_disabled_without_money", yard_button.disabled, "enabled with 50 crystal")
	gs.add(ResKind.CRYSTAL, 1000)
	gs.add(ResKind.ICE, 1000)
	_check("shipyard_enabled_with_money", not yard_button.disabled, "disabled with money")
	_check("module_requires_shipyard", module_button.disabled
			and module_button.text == "Módulo de colonos [M]\nRequiere: Astillero", module_button.text)

	var requested: Array = []
	hud.build_requested.connect(func(scene: PackedScene) -> void: requested.append(scene.resource_path))
	module_button.pressed.emit()
	_check("module_press_ignored", requested.is_empty(), str(requested))
	hud._handle_build_keys(_key(KEY_B))
	hud._handle_build_keys(_key(KEY_M))
	_check("b_m_ignored_without_shipyard", requested.is_empty(), str(requested))
	var armed: bool = hud._handle_build_keys(_key(KEY_B))
	var consumed: bool = hud._handle_build_keys(_key(KEY_Y))
	_check("b_y_requests_shipyard", armed and consumed and requested == [SHIPYARD], str(requested))
	hud._handle_build_keys(_key(KEY_B))
	hud._handle_build_keys(_key(KEY_S))
	_check("b_s_does_not_request_shipyard", requested == [SHIPYARD] and hud.build_hotkey_scene(KEY_S) == null, str(requested))

	var yard := (load(SHIPYARD) as PackedScene).instantiate() as Building
	yard.position = Grid.footprint_origin(Vector2i(20, 10), yard.footprint)
	world.add_child(yard)
	yard.start_construction()
	hud._refresh_build_buttons()
	_check("module_locked_while_shipyard_builds", module_button.disabled, "enabled with unfinished shipyard")
	yard.add_build_progress(yard.build_time)
	hud._refresh_build_buttons()
	_check("module_unlocked", not module_button.disabled
			and module_button.text == "Módulo de colonos [M]\n100 cristal · 150 hielo", module_button.text)
	hud._handle_build_keys(_key(KEY_B))
	hud._handle_build_keys(_key(KEY_M))
	_check("b_m_requests_module", requested.size() == 2 and requested[1] == MODULE, str(requested))
	_check("hotkey_table", hud.build_hotkey_scene(KEY_Y).resource_path == SHIPYARD
			and hud.build_hotkey_scene(KEY_M).resource_path == MODULE, "BUILD_HOTKEYS without Y/M")

	yard.queue_free()
	await create_timer(0.4).timeout
	_check("timer_refresh_relocks", module_button.disabled, "still enabled after the shipyard is gone")

	var fake_colonist := Node2D.new()
	fake_colonist.add_to_group("colonists")
	root.add_child(fake_colonist)
	hud.show_for_selection([fake_colonist])
	_check("no_build_menu_for_colonists", not (hud.get_node("BuildMenu") as Control).visible, "build menu visible")
	quit(1 if _failed else 0)


func _key(code: Key) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.pressed = true
	return ev


func _check(test_name: String, ok: bool, why: String) -> void:
	if ok:
		print("PASS ", test_name)
	else:
		print("FAIL ", test_name, ": ", why)
		_failed = true


func _on_timeout() -> void:
	print("FAIL timeout: test did not finish (script error?)")
	quit(1)
