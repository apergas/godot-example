extends SceneTree

const HABITAT := "res://scenes/buildings/habitat.tscn"

var _failed := false


func _initialize() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.reset()
	var hud = (load("res://scenes/hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	await process_frame
	var menu := hud.get_node_or_null("BuildMenu") as Control
	var button := hud.get_node_or_null("BuildMenu/Buttons/HabitatButton") as Button
	_check("menu and habitat button exist", menu != null and button != null)
	if menu == null or button == null:
		quit(1)
		return
	_check("hidden by default", not menu.visible)
	hud.show_for_selection([])
	_check("hidden with empty selection", not menu.visible)
	var fake := Node2D.new()
	fake.add_to_group("workers")
	root.add_child(fake)
	hud.show_for_selection([fake])
	_check("visible with workers selected", menu.visible)
	_check("label shows cost", button.text.contains("Habitáculo") and button.text.contains("30 cristal") and button.text.contains("60 hielo"), button.text)
	_check("disabled when unaffordable", button.disabled)
	gs.add(ResKind.ICE, 60)
	_check("enabled when affordable", not button.disabled)

	var requested: Array = []
	hud.build_requested.connect(func(scene: PackedScene) -> void: requested.append(scene))
	button.pressed.emit()
	_check("button requests the habitat", requested.size() == 1 and requested[0].resource_path == HABITAT)
	_check("H alone does nothing", not hud._handle_build_keys(_key(KEY_H)) and requested.size() == 1)
	_check("B arms the build keys", hud._handle_build_keys(_key(KEY_B)))
	_check("B then H requests the habitat", hud._handle_build_keys(_key(KEY_H)) and requested.size() == 2)
	gs.reset()
	hud._handle_build_keys(_key(KEY_B))
	hud._handle_build_keys(_key(KEY_H))
	_check("B then H ignored when unaffordable", requested.size() == 2)
	hud.show_for_selection([])
	_check("keys ignored while the menu is hidden", not hud._handle_build_keys(_key(KEY_B)))
	quit(1 if _failed else 0)


func _key(code: Key) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.pressed = true
	return ev


func _check(name: String, ok: bool, why: String = "") -> void:
	if ok:
		print("PASS ", name)
	else:
		_failed = true
		print("FAIL ", name, ": ", why)
