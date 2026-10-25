extends SceneTree

var _failed := false


func _initialize() -> void:
	await process_frame
	var formation: GDScript = load("res://scripts/formation.gd")
	if formation == null:
		_check("formation_script_exists", false, "res://scripts/formation.gd missing")
		quit(1)
		return

	var none: Array = formation.offsets(0, 40.0)
	_check("zero_count_empty", none.is_empty(), "got %d offsets" % none.size())
	var one: Array = formation.offsets(1, 40.0)
	_check("single_is_centre", one.size() == 1 and one[0] == Vector2.ZERO, "got %s" % [one])

	var all_ok := true
	var why := ""
	for count in range(1, 31):
		var offs: Array = formation.offsets(count, 40.0)
		if offs.size() != count or offs[0] != Vector2.ZERO:
			all_ok = false
			why = "count %d: size %d first %s" % [count, offs.size(), offs[0]]
			break
		for a in offs.size():
			for b in range(a + 1, offs.size()):
				if (offs[a] as Vector2).distance_to(offs[b]) < 39.9:
					all_ok = false
					why = "count %d: %s and %s too close" % [count, offs[a], offs[b]]
	_check("offsets_unique_and_spaced", all_ok, why)

	var nine: Array = formation.offsets(9, 40.0)
	var max_len := 0.0
	for o in nine:
		max_len = maxf(max_len, (o as Vector2).length())
	_check("nine_fill_one_ring", max_len <= 40.0 * sqrt(2.0) + 0.01, "max offset %.2f" % max_len)
	var five: Array = formation.offsets(5, 40.0)
	var five_ok := true
	for o in five:
		if not is_equal_approx((o as Vector2).length(), 40.0) and o != Vector2.ZERO:
			five_ok = false
	_check("closest_ring_first", five_ok, "got %s" % [five])

	var centred: Array = formation.targets(Vector2(500, 500), 3, 40.0)
	_check("targets_around_centre", centred.size() == 3 and centred[0] == Vector2(500, 500), "got %s" % [centred])
	var bounds := Rect2(0, 0, 4096, 3072).grow(-32.0)
	var corner: Array = formation.targets(Vector2.ZERO, 5, 40.0)
	var inside := true
	for t in corner:
		if not bounds.has_point(t):
			inside = false
	_check("targets_clamped_to_map", inside, "got %s" % [corner])
	quit(1 if _failed else 0)


func _check(test_name: String, ok: bool, why: String) -> void:
	if ok:
		print("PASS ", test_name)
	else:
		print("FAIL ", test_name, ": ", why)
		_failed = true
