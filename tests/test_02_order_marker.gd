extends SceneTree

var _failed := false


func _initialize() -> void:
	await process_frame
	var marker_script: GDScript = load("res://scripts/order_marker.gd")
	if marker_script == null:
		_check("marker_script_exists", false, "res://scripts/order_marker.gd missing")
		quit(1)
		return
	var marker: Node2D = marker_script.new()
	marker.position = Vector2(200, 200)
	root.add_child(marker)
	await process_frame
	_check("alive_at_start", is_instance_valid(marker), "marker freed immediately")
	await create_timer(0.8).timeout
	_check("freed_after_lifetime", not is_instance_valid(marker), "marker still alive after 0.8 s")
	quit(1 if _failed else 0)


func _check(test_name: String, ok: bool, why: String) -> void:
	if ok:
		print("PASS ", test_name)
	else:
		print("FAIL ", test_name, ": ", why)
		_failed = true
