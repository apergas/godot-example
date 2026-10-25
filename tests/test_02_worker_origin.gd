extends SceneTree

var _failed := false


func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/worker.tscn")
	var worker: CharacterBody2D = scene.instantiate()
	worker.position = Vector2(100, 100)
	root.add_child(worker)
	await process_frame

	var sprite: Sprite2D = worker.get_node("Sprite2D")
	_check("sprite_above_feet", sprite.position == Vector2(0, -22), "sprite at %s" % sprite.position)
	var shape_node: CollisionShape2D = worker.get_node("CollisionShape2D")
	var circle := shape_node.shape as CircleShape2D
	_check("collision_radius_10", circle != null and is_equal_approx(circle.radius, 10.0) and shape_node.position == Vector2.ZERO, "bad collision shape")
	_check("collision_layers", worker.collision_layer == 2 and worker.collision_mask == 1, "layer %d mask %d" % [worker.collision_layer, worker.collision_mask])
	_check("in_workers_group", worker.is_in_group("workers"), "worker not in group 'workers'")
	_check("click_body", worker.contains_point(Vector2(100, 78)), "body centre not hit")
	_check("click_feet", worker.contains_point(Vector2(100, 100)), "feet not hit")
	_check("click_head", worker.contains_point(Vector2(100, 56)), "head not hit")
	_check("click_below_misses", not worker.contains_point(Vector2(100, 130)), "point well below the feet was hit")
	quit(1 if _failed else 0)


func _check(test_name: String, ok: bool, why: String) -> void:
	if ok:
		print("PASS ", test_name)
	else:
		print("FAIL ", test_name, ": ", why)
		_failed = true
