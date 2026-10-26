extends SceneTree

const HABITAT := "res://scenes/buildings/habitat.tscn"
const FREE_CELL := Vector2i(20, 10)
const CRYSTAL_CELL := Vector2i(30, 10)

var _failed := false


func _initialize() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	var nav = root.get_node("Nav")
	gs.reset()
	nav.reset()
	var world := Node2D.new()
	world.y_sort_enabled = true
	root.add_child(world)
	var crystal := (load("res://scenes/resources/crystal.tscn") as PackedScene).instantiate() as Node2D
	crystal.position = Grid.cell_to_world(CRYSTAL_CELL) + Vector2(0, Grid.TILE / 2.0 - 4)
	world.add_child(crystal)
	var hq := (load("res://scenes/buildings/hq.tscn") as PackedScene).instantiate() as Node2D
	hq.position = Grid.footprint_origin(MapLayout.HQ_CELL, Vector2i(3, 3))
	world.add_child(hq)
	var placement := Placement.new()
	placement.world = world
	root.add_child(placement)
	await process_frame

	var habitat := load(HABITAT) as PackedScene
	placement.begin(habitat)
	_check("begin activates with the scene footprint", placement.active and placement.footprint == Vector2i(2, 2))
	var centre := Vector2(FREE_CELL + Vector2i.ONE) * Grid.TILE
	_check("cell under the mouse centres the footprint",
		placement.cell_under(centre) == FREE_CELL and placement.cell_under(centre + Vector2(20, -25)) == FREE_CELL,
		str(placement.cell_under(centre)))

	_check("invalid without money", not placement.is_valid_at(FREE_CELL))
	gs.add(ResKind.CRYSTAL, 50)
	gs.add(ResKind.ICE, 100)
	_check("valid on free ground", placement.is_valid_at(FREE_CELL))
	_check("invalid outside the map",
		not placement.is_valid_at(Vector2i(-1, 5)) and not placement.is_valid_at(Vector2i(63, 10)) and not placement.is_valid_at(Vector2i(10, 47)))
	_check("invalid over a resource",
		not placement.is_valid_at(CRYSTAL_CELL) and not placement.is_valid_at(CRYSTAL_CELL - Vector2i(1, 1)))
	_check("invalid over the HQ",
		not placement.is_valid_at(MapLayout.HQ_CELL + Vector2i(1, 1)) and not placement.is_valid_at(MapLayout.HQ_CELL + Vector2i(2, 2)))
	_check("valid right next to the HQ", placement.is_valid_at(MapLayout.HQ_CELL + Vector2i(3, 0)))

	var placed: Array = []
	placement.placed.connect(func(b: Building) -> void: placed.append(b))
	var site := placement.confirm_at(FREE_CELL)
	_check("confirm returns and emits the site", site != null and placed.size() == 1 and placed[0] == site)
	_check("cost charged on placement", gs.stock[ResKind.CRYSTAL] == 70 and gs.stock[ResKind.ICE] == 40, str(gs.stock))
	_check("site is under construction in World",
		site != null and not site.built and site.cell == FREE_CELL and site.get_parent() == world)
	_check("site blocks navigation", not nav.is_area_free(Rect2i(FREE_CELL, Vector2i(2, 2))))
	_check("mode ends without Shift", not placement.active)
	_check("confirm does nothing when inactive", placement.confirm_at(Vector2i(24, 14)) == null)

	gs.add(ResKind.CRYSTAL, 100)
	gs.add(ResKind.ICE, 200)
	placement.begin(habitat)
	var second := placement.confirm_at(Vector2i(24, 10), true)
	_check("Shift keeps the mode", second != null and placement.active)

	var target := Vector2i(28, 14)
	_check("target valid before it gets occupied", placement.is_valid_at(target))
	nav.set_blocked(Rect2i(target, Vector2i.ONE), true)
	var crystal_before: int = gs.stock[ResKind.CRYSTAL]
	var ice_before: int = gs.stock[ResKind.ICE]
	var rejected := placement.confirm_at(target, true)
	_check("occupied zone is rejected without charge",
		rejected == null and gs.stock[ResKind.CRYSTAL] == crystal_before and gs.stock[ResKind.ICE] == ice_before and placement.active)

	placement.cancel()
	_check("cancel ends the mode", not placement.active)
	quit(1 if _failed else 0)


func _check(name: String, ok: bool, why: String = "") -> void:
	if ok:
		print("PASS ", name)
	else:
		_failed = true
		print("FAIL ", name, ": ", why)
