extends SceneTree

const CameraRTS := preload("res://scripts/camera_rts.gd")
const VIEW := Vector2(1152, 648)
const MAP := Rect2(0, 0, 4096, 3072)

var _failed := 0


func _initialize() -> void:
	await process_frame
	_check("constants", CameraRTS.SPEED == 900.0 and CameraRTS.EDGE_MARGIN == 20.0
			and CameraRTS.ZOOM_MIN == 0.5 and CameraRTS.ZOOM_MAX == 2.0)

	_check("edge: none at centre", CameraRTS.edge_direction(VIEW / 2.0, VIEW, 20.0) == Vector2.ZERO)
	_check("edge: left", CameraRTS.edge_direction(Vector2(5, 300), VIEW, 20.0) == Vector2(-1, 0))
	_check("edge: top-left corner", CameraRTS.edge_direction(Vector2(19.9, 0), VIEW, 20.0) == Vector2(-1, -1))
	_check("edge: left margin is exclusive", CameraRTS.edge_direction(Vector2(20, 300), VIEW, 20.0) == Vector2.ZERO)
	_check("edge: right starts at width - margin",
			CameraRTS.edge_direction(Vector2(1132, 300), VIEW, 20.0) == Vector2(1, 0))
	_check("edge: just before right margin", CameraRTS.edge_direction(Vector2(1131, 300), VIEW, 20.0) == Vector2.ZERO)
	_check("edge: bottom-right corner", CameraRTS.edge_direction(Vector2(1150, 640), VIEW, 20.0) == Vector2(1, 1))

	_check("scroll: 900 px/s at zoom 1",
			CameraRTS.scroll_offset(Vector2(1, 0), 0.5, 1.0).is_equal_approx(Vector2(450, 0)))
	_check("scroll: twice as far in world at zoom 0.5",
			CameraRTS.scroll_offset(Vector2(1, 0), 0.5, 0.5).is_equal_approx(Vector2(900, 0)))
	_check("scroll: diagonal keeps speed",
			is_equal_approx(CameraRTS.scroll_offset(Vector2(1, 1), 1.0, 1.0).length(), 900.0))
	_check("scroll: no direction, no movement", CameraRTS.scroll_offset(Vector2.ZERO, 1.0, 1.0) == Vector2.ZERO)

	_check("clamp_zoom: low", is_equal_approx(CameraRTS.clamp_zoom(0.1), 0.5))
	_check("clamp_zoom: high", is_equal_approx(CameraRTS.clamp_zoom(3.0), 2.0))
	_check("clamp_zoom: inside", is_equal_approx(CameraRTS.clamp_zoom(1.3), 1.3))

	var p: Vector2 = CameraRTS.clamp_position(Vector2.ZERO, VIEW, 1.0, MAP)
	_check("clamp_position: top-left", p.is_equal_approx(Vector2(576, 324)), str(p))
	p = CameraRTS.clamp_position(Vector2(5000, 5000), VIEW, 1.0, MAP)
	_check("clamp_position: bottom-right", p.is_equal_approx(Vector2(3520, 2748)), str(p))
	p = CameraRTS.clamp_position(Vector2(2000, 1500), VIEW, 1.0, MAP)
	_check("clamp_position: inside unchanged", p.is_equal_approx(Vector2(2000, 1500)), str(p))
	p = CameraRTS.clamp_position(Vector2.ZERO, VIEW, 0.5, MAP)
	_check("clamp_position: zoomed out sees more", p.is_equal_approx(Vector2(1152, 648)), str(p))
	p = CameraRTS.clamp_position(Vector2.ZERO, Vector2(10000, 648), 1.0, MAP)
	_check("clamp_position: view wider than map is centred", p.is_equal_approx(Vector2(2048, 324)), str(p))

	p = CameraRTS.zoom_anchor_position(Vector2(1000, 1000), VIEW, VIEW, 1.0, 2.0)
	_check("zoom_anchor: corner point stays under cursor", p.is_equal_approx(Vector2(1288, 1162)), str(p))
	p = CameraRTS.zoom_anchor_position(Vector2(1000, 1000), VIEW / 2.0, VIEW, 1.0, 2.0)
	_check("zoom_anchor: centre keeps position", p.is_equal_approx(Vector2(1000, 1000)), str(p))
	quit(1 if _failed > 0 else 0)


func _check(test_name: String, ok: bool, detail: String = "") -> void:
	if ok:
		print("PASS ", test_name)
	else:
		_failed += 1
		print("FAIL ", test_name, ": ", detail)
