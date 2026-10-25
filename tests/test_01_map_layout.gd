extends SceneTree

## Areas that later phases fill (HQ + 2-tile margin, crystal fields, ice field).
const RESERVED: Array[Rect2i] = [
	Rect2i(8, 19, 7, 7),
	Rect2i(17, 19, 3, 6),
	Rect2i(47, 7, 7, 7),
	Rect2i(30, 32, 8, 9),
]

var _failed := 0


func _initialize() -> void:
	await process_frame
	var map := Rect2i(Vector2i.ZERO, Grid.MAP_SIZE)
	_check("SEED", MapLayout.SEED == 7, str(MapLayout.SEED))
	_check("has rock patches", MapLayout.ROCK_PATCHES.size() >= 5, str(MapLayout.ROCK_PATCHES.size()))
	_check("has craters", MapLayout.CRATERS.size() >= 5, str(MapLayout.CRATERS.size()))

	var areas: Array[Rect2i] = []
	for patch in MapLayout.ROCK_PATCHES:
		_check("rock %s inside map" % patch, map.encloses(patch))
		areas.append(patch)
	for crater in MapLayout.CRATERS:
		var rect := Rect2i(crater, Vector2i(2, 2))
		_check("crater %s inside map" % crater, map.encloses(rect))
		areas.append(rect)

	var overlaps := 0
	for i in areas.size():
		for j in range(i + 1, areas.size()):
			if areas[i].intersects(areas[j]):
				overlaps += 1
				print("  overlap: ", areas[i], " ", areas[j])
	_check("no overlapping rocks or craters", overlaps == 0, str(overlaps))

	var reserved_hits := 0
	for area in areas:
		for reserved in RESERVED:
			if area.intersects(reserved):
				reserved_hits += 1
				print("  reserved hit: ", area, " ", reserved)
	_check("reserved areas left clear", reserved_hits == 0, str(reserved_hits))
	quit(1 if _failed > 0 else 0)


func _check(test_name: String, ok: bool, detail: String = "") -> void:
	if ok:
		print("PASS ", test_name)
	else:
		_failed += 1
		print("FAIL ", test_name, ": ", detail)
