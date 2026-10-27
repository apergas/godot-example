extends SceneTree

const NavScript := preload("res://scripts/nav.gd")

var _failed := false


func _initialize() -> void:
	await process_frame
	var nav := root.get_node("Nav") as NavScript
	nav.reset()
	var cell := Vector2i(20, 20)
	var node := (load("res://scenes/resources/crystal.tscn") as PackedScene).instantiate() as ResourceNode
	node.position = Grid.cell_to_world(cell) + Vector2(0.0, Grid.TILE / 2.0 - 4.0)
	node.amount = 3
	root.add_child(node)
	await process_frame
	_check(node.cell == cell, "resource_cell", str(node.cell))
	_check(not nav.is_area_free(Rect2i(cell, Vector2i.ONE)), "resource_blocks_cell", "cell still free")
	_check(nav.is_area_free(Rect2i(cell + Vector2i(1, 0), Vector2i.ONE)), "resource_blocks_one_cell", "neighbour blocked")
	node.take(3)
	await process_frame
	await process_frame
	_check(not is_instance_valid(node), "resource_freed", "node still alive after take(amount)")
	_check(nav.is_area_free(Rect2i(cell, Vector2i.ONE)), "depleted_frees_cell", "cell still blocked")
	quit(1 if _failed else 0)


func _check(ok: bool, name: String, why: String) -> void:
	if ok:
		print("PASS ", name)
	else:
		print("FAIL ", name, ": ", why)
		_failed = true
