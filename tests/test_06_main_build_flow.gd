extends SceneTree

const HABITAT := "res://scenes/buildings/habitat.tscn"
const TO_BUILD := 5
const BUILDING := 6

var _failed := false


func _initialize() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	var nav = root.get_node("Nav")
	gs.reset()
	nav.reset()
	var main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var placement := main.get_node_or_null("Placement") as Placement
	_check("Placement node in main", placement != null)
	if placement == null:
		quit(1)
		return
	var selection := main.get_node("Selection") as Selection
	var hud = main.get_node("HUD")
	_check("placement builds into World", placement.world == main.get_node("World"))
	var workers := get_nodes_in_group("workers")
	_check("at least two workers", workers.size() >= 2, str(workers.size()))
	var w0 = workers[0]
	var w1 = workers[1]
	gs.add(ResKind.CRYSTAL, 200)
	gs.add(ResKind.ICE, 200)

	selection.select([w0])
	_check("build menu shown for workers", (hud.get_node("BuildMenu") as Control).visible)
	hud.build_requested.emit(load(HABITAT))
	_check("build request starts placement", placement.active)
	var cell := _find_valid_cell(placement)
	_check("found a free cell", cell != Vector2i(-1, -1))
	var site := placement.confirm_at(cell)
	_check("site placed", site != null)
	if site == null:
		quit(1)
		return
	_check("selected worker goes to build", w0.state == TO_BUILD or w0.state == BUILDING, str(w0.state))
	_check("unselected worker untouched", w1.state != TO_BUILD and w1.state != BUILDING)

	selection.select([w1])
	var centre := (Vector2(site.cell) + Vector2(site.footprint) / 2.0) * Grid.TILE
	_check("right click on the site is a build order", main._try_build_order(centre))
	_check("second worker helps", w1.state == TO_BUILD or w1.state == BUILDING, str(w1.state))
	_check("right click on bare ground is not a build order", not main._try_build_order(Vector2(2, 2) * Grid.TILE))
	quit(1 if _failed else 0)


func _find_valid_cell(placement: Placement) -> Vector2i:
	for y in range(25, 31):
		for x in range(13, 30):
			if placement.is_valid_at(Vector2i(x, y)):
				return Vector2i(x, y)
	return Vector2i(-1, -1)


func _check(name: String, ok: bool, why: String = "") -> void:
	if ok:
		print("PASS ", name)
	else:
		_failed = true
		print("FAIL ", name, ": ", why)
