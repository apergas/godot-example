extends SceneTree
## tests/test_10_path_walker.gd — run: tools\godot.cmd --headless --path . --script res://tests/test_10_path_walker.gd

const DELTA := 1.0 / 60.0

var _failed := false


func _initialize() -> void:
	create_timer(30.0).timeout.connect(_on_timeout)
	await process_frame
	var body := CharacterBody2D.new()
	body.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var sprite := Sprite2D.new()
	sprite.texture = PlaceholderTexture2D.new()
	(sprite.texture as PlaceholderTexture2D).size = Vector2(128, 96)
	sprite.hframes = PathWalker.PHASES
	sprite.vframes = 3
	body.add_child(sprite)
	body.position = Vector2(100, 100)
	root.add_child(body)
	await physics_frame
	var walker := PathWalker.new(body, sprite)

	# Facing: rows down/up/side, left is the side row flipped.
	walker.face(Vector2(0, 1))
	_check("face_down", walker.row == PathWalker.ROW_DOWN, str(walker.row))
	walker.face(Vector2(0, -1))
	_check("face_up", walker.row == PathWalker.ROW_UP, str(walker.row))
	walker.face(Vector2(1, 0.2))
	_check("face_right", walker.row == PathWalker.ROW_SIDE and not sprite.flip_h, "%d %s" % [walker.row, sprite.flip_h])
	walker.face(Vector2(-1, 0.2))
	_check("face_left_flips", walker.row == PathWalker.ROW_SIDE and sprite.flip_h, "%d %s" % [walker.row, sprite.flip_h])

	# Empty path: finished at once, velocity zeroed.
	body.velocity = Vector2(5, 5)
	_check("empty_path_done", walker.step(DELTA, 100.0) and body.velocity == Vector2.ZERO, str(body.velocity))

	# Walks a two-waypoint path to the end, facing the heading and cycling walk phases.
	var goal := Vector2(100, 300)
	walker.set_path(PackedVector2Array([Vector2(300, 100), goal]))
	var frames := {}
	var faced_right := false
	var done := false
	for i in 600:
		done = walker.step(DELTA, 180.0)
		if done:
			break
		frames[sprite.frame % PathWalker.PHASES] = true
		if walker.row == PathWalker.ROW_SIDE and not sprite.flip_h:
			faced_right = true
		await physics_frame
	_check("reaches_end", done and body.global_position.distance_to(goal) <= PathWalker.ARRIVE_DISTANCE,
			str(body.global_position))
	_check("faced_heading", faced_right, "never faced right on the first leg")
	_check("cycles_frames", frames.size() == PathWalker.PHASES, str(frames.keys()))
	_check("last_leg_faces_down_left", walker.row == PathWalker.ROW_DOWN, str(walker.row))

	# Stop: standing frame (phase 0) of the current row, path dropped.
	walker.face(Vector2(0, -1))
	walker.walk_time = 0.3
	walker.update_frame()
	_check("walk_frame", sprite.frame == PathWalker.ROW_UP * PathWalker.PHASES + 2, str(sprite.frame))
	walker.set_path(PackedVector2Array([Vector2(500, 500)]))
	walker.stop()
	_check("stop_rest_frame", sprite.frame == PathWalker.ROW_UP * PathWalker.PHASES and walker.walk_time == 0.0
			and body.velocity == Vector2.ZERO, str(sprite.frame))
	_check("stop_drops_path", walker.step(DELTA, 180.0), "path still followed after stop")

	# Extra velocity (separation push) is added on top of the walking velocity.
	walker.set_path(PackedVector2Array([body.global_position + Vector2(400, 0)]))
	walker.step(DELTA, 100.0, Vector2(0, 50))
	_check("adds_extra_velocity", body.velocity.is_equal_approx(Vector2(100, 50)), str(body.velocity))
	_check("heading_ignores_push", walker.row == PathWalker.ROW_SIDE, str(walker.row))

	body.queue_free()
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
