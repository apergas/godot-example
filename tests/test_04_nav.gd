extends SceneTree

const NavScript := preload("res://scripts/nav.gd")

var _failed := false


func _initialize() -> void:
	await process_frame
	_check(root.get_node_or_null("Nav") != null, "nav_autoload", "no /root/Nav node")

	var nav := NavScript.new()
	var block := Rect2i(10, 5, 3, 3)
	nav.set_blocked(block, true)
	_check(not nav.is_area_free(Rect2i(11, 6, 1, 1)), "blocked_cell", "cell inside block reported free")
	_check(not nav.is_area_free(Rect2i(9, 4, 2, 2)), "overlap_not_free", "area overlapping block reported free")
	_check(nav.is_area_free(Rect2i(0, 0, 4, 4)), "free_area", "empty area reported blocked")
	_check(not nav.is_area_free(Rect2i(62, 46, 3, 3)), "outside_map_not_free", "area leaving the map reported free")

	var from := Grid.cell_to_world(Vector2i(8, 6))
	var to := Grid.cell_to_world(Vector2i(14, 6)) + Vector2(5.0, 7.0)
	var path := nav.find_path(from, to)
	_check(path.size() > 1, "path_found", str(path))
	var crosses := false
	for p in path:
		if block.has_point(Grid.world_to_cell(p)):
			crosses = true
	_check(not crosses, "path_avoids_block", str(path))
	_check(path.size() > 0 and path[path.size() - 1] == to, "path_ends_at_target", str(path))

	var into := nav.find_path(from, Grid.cell_to_world(Vector2i(11, 6)))
	var last_cell := Grid.world_to_cell(into[into.size() - 1]) if into.size() > 0 else Vector2i(-1, -1)
	_check(not block.has_point(last_cell) and block.grow(1).has_point(last_cell),
			"path_to_blocked_stops_adjacent", str(last_cell))

	var ap := nav.approach_point(block, Grid.cell_to_world(Vector2i(2, 6)))
	var ap_cell := Grid.world_to_cell(ap)
	_check(ap_cell == Vector2i(9, 6), "approach_closest_side", str(ap_cell))
	_check(ap == Grid.cell_to_world(ap_cell), "approach_is_cell_center", str(ap))

	nav.set_blocked(Rect2i(9, 5, 1, 3), true)
	ap_cell = Grid.world_to_cell(nav.approach_point(block, Grid.cell_to_world(Vector2i(2, 6))))
	_check(not block.has_point(ap_cell) and block.grow(1).has_point(ap_cell)
			and nav.is_area_free(Rect2i(ap_cell, Vector2i.ONE)), "approach_skips_blocked", str(ap_cell))

	nav.set_blocked(Rect2i(7, 6, 1, 1), true)
	var from_blocked := nav.find_path(Grid.cell_to_world(Vector2i(7, 6)), to)
	_check(from_blocked.size() > 0, "path_from_blocked_cell", "empty path when standing on a blocked cell")

	nav.set_blocked(block, false)
	_check(nav.is_area_free(block), "unblock", "block still solid after set_blocked(false)")
	nav.reset()
	_check(nav.is_area_free(Rect2i(9, 5, 1, 3)) and nav.is_area_free(Rect2i(7, 6, 1, 1)), "reset_clears", "reset kept solid cells")
	nav.free()
	quit(1 if _failed else 0)


func _check(ok: bool, name: String, why: String) -> void:
	if ok:
		print("PASS ", name)
	else:
		print("FAIL ", name, ": ", why)
		_failed = true
