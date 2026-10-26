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
	root.add_child(world)
	var crystal := (load("res://scenes/resources/crystal.tscn") as PackedScene).instantiate() as Node2D
	crystal.position = Grid.cell_to_world(CRYSTAL_CELL) + Vector2(0, Grid.TILE / 2.0 - 4)
	world.add_child(crystal)
	var placement := Placement.new()
	placement.world = world
	root.add_child(placement)
	await process_frame

	gs.add(ResKind.ICE, 100)
	placement.begin(load(HABITAT) as PackedScene)
	var ghost := placement.get_node_or_null("Ghost") as Sprite2D
	_check("ghost sprite created", ghost != null and ghost.texture != null and ghost.texture.resource_path == "res://assets/habitat.png")
	_check("ghost shows the finished frame", ghost != null and ghost.hframes == 2 and ghost.frame == 0)

	placement.update_cursor(Vector2(FREE_CELL + Vector2i.ONE) * Grid.TILE)
	_check("cursor on free ground is valid", placement.ghost_valid and placement.ghost_cell == FREE_CELL)
	_check("ghost snapped to the footprint origin", ghost.position == Grid.footprint_origin(FREE_CELL, Vector2i(2, 2)), str(ghost.position))
	var valid_tint := ghost.modulate
	placement.update_cursor(Vector2(CRYSTAL_CELL) * Grid.TILE + Vector2(32, 32))
	_check("cursor over a resource is invalid", not placement.ghost_valid)
	_check("invalid ghost is tinted red", ghost.modulate != valid_tint and ghost.modulate.g < ghost.modulate.r)

	gs.reset()
	placement._unhandled_input(_mouse(MOUSE_BUTTON_LEFT, true))
	_check("left click on an invalid spot keeps the mode", placement.active and get_nodes_in_group("buildings").is_empty())
	placement._unhandled_input(_mouse(MOUSE_BUTTON_LEFT, false))

	placement._unhandled_input(_mouse(MOUSE_BUTTON_RIGHT, true))
	_check("right click cancels", not placement.active)
	await process_frame
	_check("ghost freed on cancel", placement.get_node_or_null("Ghost") == null)

	placement.begin(load(HABITAT) as PackedScene)
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	placement._unhandled_input(esc)
	_check("Esc cancels", not placement.active)

	# A robot standing on the footprint is moved off when the site is confirmed.
	gs.add(ResKind.CRYSTAL, 50)
	gs.add(ResKind.ICE, 100)
	var robot := (load("res://scenes/worker.tscn") as PackedScene).instantiate() as Node2D
	robot.position = Vector2(FREE_CELL) * Grid.TILE + Vector2(Grid.TILE, Grid.TILE)
	world.add_child(robot)
	await process_frame
	var start := robot.global_position
	placement.begin(load(HABITAT) as PackedScene)
	var site := placement.confirm_at(FREE_CELL)
	_check("site placed over the robot", site != null)
	for i in 120:
		await physics_frame
	var rect := Rect2(Vector2(FREE_CELL) * Grid.TILE, Vector2(2, 2) * Grid.TILE)
	_check("robot evicted off the footprint", robot.global_position != start and not rect.has_point(robot.global_position), str(robot.global_position))
	quit(1 if _failed else 0)


func _mouse(button: MouseButton, pressed: bool) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.pressed = pressed
	return ev


func _check(name: String, ok: bool, why: String = "") -> void:
	if ok:
		print("PASS ", name)
	else:
		_failed = true
		print("FAIL ", name, ": ", why)
