extends SceneTree
## main._resource_at() finds the resource under a world point.

var _failed := false


func _initialize() -> void:
	await process_frame
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	if not main.has_method("_resource_at"):
		_check(false, "has_resource_at", "main.gd has no _resource_at()")
		quit(1)
		return
	var res := get_nodes_in_group("resources")[0] as ResourceNode
	var hit: ResourceNode = main.call("_resource_at", res.global_position + Vector2(0, -20))
	_check(hit == res, "finds_resource_under_point", str(hit))
	var miss: ResourceNode = main.call("_resource_at", Grid.cell_to_world(Vector2i(2, 2)))
	_check(miss == null, "empty_ground_is_null", str(miss))
	res.take(res.amount)
	var gone: ResourceNode = main.call("_resource_at", res.global_position + Vector2(0, -20))
	_check(gone == null, "ignores_depleted_resource", str(gone))
	quit(1 if _failed else 0)


func _check(ok: bool, name: String, why: String) -> void:
	if ok:
		print("PASS ", name)
	else:
		_failed = true
		print("FAIL ", name, ": ", why)
