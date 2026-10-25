extends SceneTree
## ResourceNode: cell, deterministic variant frame, take, low frame, depleted and queue_free.

var _failed := false


func _initialize() -> void:
	await process_frame
	var crystal_scene := load("res://scenes/resources/crystal.tscn") as PackedScene
	var ice_scene := load("res://scenes/resources/ice.tscn") as PackedScene
	if crystal_scene == null or ice_scene == null:
		_check(false, "scenes_exist", "crystal.tscn or ice.tscn missing")
		quit(1)
		return

	var a := _spawn(crystal_scene, Vector2i(5, 6))
	_check(a.cell == Vector2i(5, 6), "cell_from_position", str(a.cell))
	_check(a.is_in_group("resources"), "in_resources_group", "not in group")
	_check(a.kind == ResKind.CRYSTAL and a.amount == 400, "crystal_defaults", "kind=%d amount=%d" % [a.kind, a.amount])

	var sprite := a.get_node("Sprite2D") as Sprite2D
	var b := _spawn(crystal_scene, Vector2i(5, 6))
	_check(sprite.frame == (b.get_node("Sprite2D") as Sprite2D).frame, "variant_is_deterministic", "frames differ on the same cell")
	var frames := {}
	for x in 3:
		var n := _spawn(crystal_scene, Vector2i(20 + x, 6))
		frames[(n.get_node("Sprite2D") as Sprite2D).frame] = true
	_check(frames.size() == 3 and not frames.has(ResourceNode.LOW_FRAME), "variants_differ_by_cell", str(frames.keys()))

	_check(a.take(0) == 0 and a.take(-3) == 0 and a.amount == 400, "take_non_positive", "amount=%d" % a.amount)
	_check(a.take(300) == 300 and a.amount == 100, "take_partial", "amount=%d" % a.amount)
	_check(sprite.frame != ResourceNode.LOW_FRAME, "not_low_at_25_percent", "frame=%d" % sprite.frame)
	_check(a.take(1) == 1 and sprite.frame == ResourceNode.LOW_FRAME, "low_frame_below_25_percent", "frame=%d" % sprite.frame)

	var hits := [0]
	a.depleted.connect(func() -> void: hits[0] += 1)
	var last := a.take(500)
	_check(last == 99, "take_clamped_to_remaining", "took %d" % last)
	_check(a.amount == 0 and hits[0] == 1, "depleted_emitted_once", "amount=%d hits=%d" % [a.amount, hits[0]])
	_check(a.take(5) == 0 and hits[0] == 1, "take_after_depleted", "hits=%d" % hits[0])
	await process_frame
	_check(not is_instance_valid(a), "freed_after_depleted", "node still alive")

	var ice := _spawn(ice_scene, Vector2i(8, 8))
	_check(ice.kind == ResKind.ICE and ice.amount == 250, "ice_defaults", "kind=%d amount=%d" % [ice.kind, ice.amount])
	_check(ice.contains_point(ice.global_position + Vector2(0, -20)), "contains_point_on_sprite", "missed")
	_check(not ice.contains_point(ice.global_position + Vector2(0, -120)), "contains_point_outside", "hit far above")
	_check(not ice.contains_point(ice.global_position + Vector2(64, 0)), "contains_point_next_cell", "hit next cell")
	quit(1 if _failed else 0)


func _spawn(scene: PackedScene, c: Vector2i) -> ResourceNode:
	var node := scene.instantiate() as ResourceNode
	node.position = Grid.cell_to_world(c) + Vector2(0, Grid.TILE / 2.0 - 4)
	root.add_child(node)
	return node


func _check(ok: bool, name: String, why: String) -> void:
	if ok:
		print("PASS ", name)
	else:
		_failed = true
		print("FAIL ", name, ": ", why)
