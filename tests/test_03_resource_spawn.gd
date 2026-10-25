extends SceneTree
## MapLayout resource cells and their instancing under World by main.gd.

const BASE_FOOTPRINT := Rect2i(10, 21, 3, 3)

var _failed := false


func _initialize() -> void:
	await process_frame
	var crystal_cells: Array[Vector2i] = MapLayout.CRYSTAL_CELLS
	var ice_cells: Array[Vector2i] = MapLayout.ICE_CELLS
	var keep_out := BASE_FOOTPRINT.grow(2)
	_check(crystal_cells.size() == 16, "crystal_cell_count", str(crystal_cells.size()))
	_check(ice_cells.size() == 20, "ice_cell_count", str(ice_cells.size()))

	var seen := {}
	var bad: Array[Vector2i] = []
	for c: Vector2i in crystal_cells + ice_cells:
		if seen.has(c) or not Grid.in_map(c) or keep_out.has_point(c):
			bad.append(c)
		seen[c] = true
	_check(bad.is_empty(), "cells_unique_in_map_away_from_base", str(bad))

	var near := 0
	for i in mini(8, crystal_cells.size()):
		var c := crystal_cells[i]
		if c.x >= 17 and c.x <= 19 and c.y >= 19 and c.y <= 24:
			near += 1
	_check(near == 8, "near_crystal_field", "%d of 8 in x17-19 y19-24" % near)
	var far := 0
	for i in range(8, crystal_cells.size()):
		if Vector2(crystal_cells[i]).distance_to(Vector2(50, 10)) <= 3.0:
			far += 1
	_check(far == 8, "far_crystal_field", "%d of 8 around (50,10)" % far)
	var ice_ok := 0
	for c in ice_cells:
		if c.x >= 30 and c.x <= 37 and c.y >= 32 and c.y <= 40:
			ice_ok += 1
	_check(ice_ok == ice_cells.size(), "ice_field", "%d of %d in x30-37 y32-40" % [ice_ok, ice_cells.size()])

	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	var nodes := get_nodes_in_group("resources")
	_check(nodes.size() == crystal_cells.size() + ice_cells.size(), "spawned_count", str(nodes.size()))
	var crystals := 0
	var wrong: Array[Vector2i] = []
	for n in nodes:
		var res := n as ResourceNode
		var expected: Array[Vector2i] = crystal_cells if res.kind == ResKind.CRYSTAL else ice_cells
		if res.kind == ResKind.CRYSTAL:
			crystals += 1
		if res.get_parent().name != "World" or not expected.has(res.cell) or keep_out.has_point(res.cell):
			wrong.append(res.cell)
	_check(crystals == crystal_cells.size(), "spawned_crystal_count", str(crystals))
	_check(wrong.is_empty(), "spawned_on_layout_cells_under_world", str(wrong))
	quit(1 if _failed else 0)


func _check(ok: bool, name: String, why: String) -> void:
	if ok:
		print("PASS ", name)
	else:
		_failed = true
		print("FAIL ", name, ": ", why)
