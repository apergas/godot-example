extends SceneTree
## HUD top bar follows GameState.stock; hover label shows and hides.

var _failed := false


func _initialize() -> void:
	await process_frame
	var gs: Node = root.get_node("GameState")
	gs.reset()
	var scene := load("res://scenes/hud.tscn") as PackedScene
	if scene == null:
		_check(false, "hud_scene_exists", "scenes/hud.tscn missing")
		quit(1)
		return
	var hud := scene.instantiate()
	root.add_child(hud)
	await process_frame

	var crystal_label := hud.get_node("TopBar/Row/CrystalLabel") as Label
	var ice_label := hud.get_node("TopBar/Row/IceLabel") as Label
	_check(hud is CanvasLayer, "hud_is_canvas_layer", hud.get_class())
	_check(crystal_label.text == "50" and ice_label.text == "0", "initial_labels", "%s / %s" % [crystal_label.text, ice_label.text])
	gs.add(ResKind.ICE, 7)
	_check(ice_label.text == "7", "ice_label_follows_stock", ice_label.text)
	gs.spend({ResKind.CRYSTAL: 20})
	_check(crystal_label.text == "30", "crystal_label_follows_stock", crystal_label.text)
	_check(hud.has_method("show_for_selection"), "has_show_for_selection", "missing")
	hud.show_for_selection([])

	var hover := hud.get_node("HoverLabel") as Label
	_check(not hover.visible, "hover_hidden_by_default", "visible")
	hud.show_hover("Cristal: 400", Vector2(100, 80))
	_check(hover.visible and hover.text == "Cristal: 400", "hover_shows_text", hover.text)
	_check(hover.position == Vector2(116, 100), "hover_follows_mouse", str(hover.position))
	hud.hide_hover()
	_check(not hover.visible, "hover_hides", "still visible")

	hud.queue_free()
	await process_frame
	gs.add(ResKind.CRYSTAL, 1)
	_check(gs.stock[ResKind.CRYSTAL] == 31, "stock_change_after_hud_freed", str(gs.stock))
	quit(1 if _failed else 0)


func _check(ok: bool, name: String, why: String) -> void:
	if ok:
		print("PASS ", name)
	else:
		_failed = true
		print("FAIL ", name, ": ", why)
