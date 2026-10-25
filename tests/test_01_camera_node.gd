extends SceneTree

const CameraRTS := preload("res://scripts/camera_rts.gd")

var _failed := 0


func _initialize() -> void:
	# Headless root window is 64x64: with canvas_items stretch, pushed events get scaled 18x.
	# Disable stretch so synthetic events keep their coordinates.
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	var cam := main.get_node("Camera2D") as Camera2D
	var worker := main.get_node("World/Worker") as Node2D
	_check("camera uses camera_rts.gd", cam.get_script() == CameraRTS)
	if cam.get_script() != CameraRTS:
		quit(1)
		return
	cam.set("edge_scroll", false)

	_check("limits match the map", cam.limit_left == 0 and cam.limit_top == 0
			and cam.limit_right == 4096 and cam.limit_bottom == 3072,
			"%d %d %d %d" % [cam.limit_left, cam.limit_top, cam.limit_right, cam.limit_bottom])
	_check("camera starts on the base", Grid.world_to_cell(cam.position) == Vector2i(14, 22), str(cam.position))
	_check("worker starts beside the base", Grid.world_to_cell(worker.position) == Vector2i(14, 22),
			str(worker.position))

	var view := cam.get_viewport_rect().size
	cam.position = Vector2(-5000, 99999)
	# Two frames: the first resume can happen before the camera's _process of that frame.
	await process_frame
	await process_frame
	var expected: Vector2 = CameraRTS.clamp_position(Vector2(-5000, 99999), view, cam.zoom.x, Grid.map_rect_world())
	_check("position clamped to the map", cam.position.is_equal_approx(expected),
			"%s != %s" % [cam.position, expected])

	var center := Grid.map_rect_world().get_center()
	cam.position = center
	_wheel(MOUSE_BUTTON_WHEEL_UP, view / 2.0)
	_check("wheel up zooms in by ZOOM_STEP", is_equal_approx(cam.zoom.x, 1.1), str(cam.zoom))
	_check("zoom at screen centre keeps position", cam.position.is_equal_approx(center), str(cam.position))
	for _i in 30:
		_wheel(MOUSE_BUTTON_WHEEL_UP, view / 2.0)
	_check("zoom capped at 2.0", is_equal_approx(cam.zoom.x, 2.0), str(cam.zoom))
	for _i in 60:
		_wheel(MOUSE_BUTTON_WHEEL_DOWN, view / 2.0)
	_check("zoom floored at 0.5", is_equal_approx(cam.zoom.x, 0.5), str(cam.zoom))

	# Below the HUD top bar (44 px), which would swallow the click.
	var below_bar := Vector2(view.x / 2.0, 60.0)
	cam.zoom = Vector2.ONE
	cam.position = center
	_middle(true, below_bar)
	_motion(Vector2(100, 40), below_bar)
	_check("middle drag pans the camera", cam.position.is_equal_approx(center - Vector2(100, 40)), str(cam.position))
	_middle(false, below_bar)
	_motion(Vector2(100, 40), below_bar)
	_check("no pan after releasing", cam.position.is_equal_approx(center - Vector2(100, 40)), str(cam.position))
	quit(1 if _failed > 0 else 0)


func _wheel(button: MouseButton, at: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	event.position = at
	event.global_position = at
	root.push_input(event)
	# Real wheel events also send a release; without it the HUD panel under the pointer keeps GUI mouse focus.
	event = event.duplicate() as InputEventMouseButton
	event.pressed = false
	root.push_input(event)


func _middle(pressed: bool, at: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_MIDDLE
	event.pressed = pressed
	event.position = at
	event.global_position = at
	root.push_input(event)


func _motion(relative: Vector2, at: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.relative = relative
	event.position = at
	event.global_position = at
	root.push_input(event)


func _check(test_name: String, ok: bool, detail: String = "") -> void:
	if ok:
		print("PASS ", test_name)
	else:
		_failed += 1
		print("FAIL ", test_name, ": ", detail)
