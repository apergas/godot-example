extends SceneTree

const Sim := preload("res://tests/sim_helpers.gd")
const HintsScript := preload("res://scripts/resource_hints.gd")
const ICE_DEPOT := "res://scenes/buildings/ice_depot.tscn"
const CRYSTAL_DEPOT := "res://scenes/buildings/crystal_depot.tscn"
const HABITAT := "res://scenes/buildings/habitat.tscn"

var _failed := false


func _initialize() -> void:
	create_timer(30.0).timeout.connect(func() -> void:
		print("FAIL timeout: test did not finish")
		quit(1))
	await process_frame
	var world := Sim.new_world(self)
	var near_ice := Sim.add_resource(world, Sim.ICE_SCENE, Vector2i(10, 10))
	var edge_ice := Sim.add_resource(world, Sim.ICE_SCENE, Vector2i(15, 10))
	var far_ice := Sim.add_resource(world, Sim.ICE_SCENE, Vector2i(20, 10))
	var crystal := Sim.add_resource(world, Sim.CRYSTAL_SCENE, Vector2i(11, 10))
	var hints := HintsScript.new()
	root.add_child(hints)
	await process_frame
	var center := Grid.cell_to_world(Vector2i(10, 10))

	hints.show_for(load(ICE_DEPOT))
	_check(hints.kinds.size() == 1 and hints.kinds[0] == ResKind.ICE, "ice_depot_hints_ice", str(hints.kinds))
	var found: Array[ResourceNode] = hints.nodes_in_range(center)
	_check(found.has(near_ice) and found.has(edge_ice), "ice_within_6_tiles_highlighted", str(found))
	_check(not found.has(far_ice), "ice_beyond_6_tiles_ignored", str(found))
	_check(not found.has(crystal), "crystal_ignored_for_ice_depot", str(found))
	_check(world.get_node_or_null("IceDepot") == null and Sim.nav(self).is_area_free(Rect2i(0, 0, 2, 2)),
			"show_for_does_not_place_anything", "a depot was added")

	hints.show_for(load(CRYSTAL_DEPOT))
	found = hints.nodes_in_range(center)
	_check(found.size() == 1 and found[0] == crystal, "crystal_depot_hints_crystal_only", str(found))

	hints.show_for(load(HABITAT))
	_check(hints.kinds.is_empty() and hints.nodes_in_range(center).is_empty(), "habitat_has_no_hints",
			str(hints.kinds))

	hints.show_for(load(ICE_DEPOT))
	hints.hide_hints()
	_check(hints.nodes_in_range(center).is_empty(), "hide_clears_hints", str(hints.kinds))

	hints.free()
	Sim.free_world(world)
	quit(1 if _failed else 0)


func _check(ok: bool, test_name: String, reason: String) -> void:
	if ok:
		print("PASS ", test_name)
	else:
		print("FAIL ", test_name, ": ", reason)
		_failed = true
