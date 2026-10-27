extends SceneTree

const HABITAT := "res://scenes/buildings/habitat.tscn"
const CRYSTAL_DEPOT := "res://scenes/buildings/crystal_depot.tscn"
const ICE_DEPOT := "res://scenes/buildings/ice_depot.tscn"

var _failed := false
var _requested: Array[String] = []


func _initialize() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.reset()
	var hud = (load("res://scenes/hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	await process_frame
	hud.connect("build_requested", _on_build_requested)
	var worker := Node2D.new()
	worker.add_to_group("workers")
	root.add_child(worker)
	hud.show_for_selection([worker])
	gs.add(ResKind.CRYSTAL, 100)

	var habitat_button := hud.find_child("HabitatButton", true, false) as Button
	var crystal_button := hud.find_child("CrystalDepotButton", true, false) as Button
	var ice_button := hud.find_child("IceDepotButton", true, false) as Button
	_check(crystal_button != null and ice_button != null, "depot_buttons_exist", "buttons not found")
	if crystal_button != null and ice_button != null:
		_check(crystal_button.get_parent() == habitat_button.get_parent()
				and ice_button.get_parent() == habitat_button.get_parent(),
				"depot_buttons_next_to_habitat", "different parent")
		_check(crystal_button.text.begins_with("Depósito de cristal"), "crystal_button_text", crystal_button.text)
		_check(ice_button.text.begins_with("Depósito de hielo"), "ice_button_text", ice_button.text)
		crystal_button.pressed.emit()
		ice_button.pressed.emit()
		_check(_requested.size() == 2 and _requested[0] == CRYSTAL_DEPOT and _requested[1] == ICE_DEPOT,
				"buttons_request_depots", str(_requested))

	_check_hotkey(hud, KEY_H, HABITAT, "hotkey_b_h_habitat")
	_check_hotkey(hud, KEY_C, CRYSTAL_DEPOT, "hotkey_b_c_crystal_depot")
	_check_hotkey(hud, KEY_I, ICE_DEPOT, "hotkey_b_i_ice_depot")
	_check(hud.call("build_hotkey_scene", KEY_X) == null, "hotkey_b_x_nothing", "KEY_X returned a scene")

	_requested.clear()
	_press_b_then(hud, KEY_C)
	_press_b_then(hud, KEY_I)
	_check(_requested.size() == 2 and _requested[0] == CRYSTAL_DEPOT and _requested[1] == ICE_DEPOT,
			"key_path_requests_depots", str(_requested))
	_requested.clear()
	_press_b_then(hud, KEY_X)
	_check(_requested.is_empty(), "b_then_x_does_nothing", str(_requested))
	hud.show_for_selection([])
	_press_b_then(hud, KEY_C)
	_check(_requested.is_empty(), "keys_ignored_without_workers", str(_requested))
	hud.free()
	quit(1 if _failed else 0)


func _press_b_then(hud: Node, code: Key) -> void:
	hud.call("_handle_build_keys", _key(KEY_B))
	hud.call("_handle_build_keys", _key(code))


func _key(code: Key) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.pressed = true
	return ev


func _check(ok: bool, test_name: String, reason: String) -> void:
	if ok:
		print("PASS ", test_name)
	else:
		print("FAIL ", test_name, ": ", reason)
		_failed = true


func _check_hotkey(hud: Node, keycode: Key, expected: String, test_name: String) -> void:
	if not hud.has_method("build_hotkey_scene"):
		_check(false, test_name, "hud.gd has no build_hotkey_scene()")
		return
	var scene := hud.call("build_hotkey_scene", keycode) as PackedScene
	_check(scene != null and scene.resource_path == expected, test_name, str(scene))


func _on_build_requested(scene: PackedScene) -> void:
	_requested.append(scene.resource_path)
