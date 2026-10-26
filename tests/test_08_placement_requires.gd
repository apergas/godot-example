extends SceneTree
## tests/test_08_placement_requires.gd — run: tools\godot.cmd --headless --path . --script res://tests/test_08_placement_requires.gd

const FREE_CELL := Vector2i(20, 10)
const HABITAT := "res://scenes/buildings/habitat.tscn"

var _failed := false


func _initialize() -> void:
	create_timer(20.0).timeout.connect(_on_timeout)
	await process_frame
	var gs = root.get_node("GameState")
	var nav = root.get_node("Nav")
	gs.reset()
	nav.reset()
	var world := Node2D.new()
	root.add_child(world)
	var placement := Placement.new()
	placement.world = world
	root.add_child(placement)
	await process_frame

	var proto := Building.new()
	proto.footprint = Vector2i(2, 2)
	var need: Array[String] = ["shipyard"]
	proto.requires = need
	var scene := PackedScene.new()
	scene.pack(proto)
	proto.free()

	placement.begin(scene)
	_check("begin_reads_requires", placement.requires.size() == 1 and placement.requires[0] == "shipyard", str(placement.requires))
	_check("rejected_without_shipyard", not placement.is_valid_at(FREE_CELL), "valid without shipyard")
	_check("confirm_rejected_without_shipyard", placement.confirm_at(FREE_CELL, true) == null and placement.active, "placed")

	var yard := Building.new()
	yard.footprint = Vector2i(3, 3)
	yard.kind_id = "shipyard"
	yard.position = Grid.footprint_origin(Vector2i(40, 10), yard.footprint)
	world.add_child(yard)
	_check("valid_with_finished_shipyard", placement.is_valid_at(FREE_CELL), "invalid with shipyard")
	yard.start_construction()
	_check("rejected_while_shipyard_unfinished", not placement.is_valid_at(FREE_CELL), "valid while shipyard unfinished")
	yard.add_build_progress(yard.build_time)
	var site := placement.confirm_at(FREE_CELL)
	_check("placed_with_shipyard", site != null and site.requires.size() == 1, "not placed")

	gs.add(ResKind.CRYSTAL, 100)
	gs.add(ResKind.ICE, 100)
	placement.begin(load(HABITAT) as PackedScene)
	_check("habitat_has_no_requires", placement.requires.is_empty() and placement.is_valid_at(Vector2i(20, 20)), str(placement.requires))
	placement.cancel()
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
