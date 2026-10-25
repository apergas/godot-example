extends SceneTree
## Generated resource sheets: size, ground contact pixel and baked shadow per frame.

const FRAME := Vector2i(32, 48)
const FRAMES := 4
const CONTACT := Vector2i(16, 39)

var _failed := false


func _initialize() -> void:
	await process_frame
	for path: String in ["res://assets/crystal.png", "res://assets/ice.png"]:
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img == null or img.is_empty():
			_check(false, path, "cannot load")
			continue
		_check(img.get_size() == Vector2i(FRAME.x * FRAMES, FRAME.y), "%s size" % path, str(img.get_size()))
		for f in FRAMES:
			var x0 := f * FRAME.x
			_check(img.get_pixel(x0 + CONTACT.x, CONTACT.y).a > 0.9, "%s frame %d contact pixel" % [path, f], "transparent")
			_check(_has_shadow(img, x0), "%s frame %d baked shadow" % [path, f], "no alpha 0.35 pixel below the base")
	quit(1 if _failed else 0)


func _has_shadow(img: Image, x0: int) -> bool:
	for y in range(41, FRAME.y):
		for x in range(x0, x0 + FRAME.x):
			var a := img.get_pixel(x, y).a
			if a > 0.3 and a < 0.4:
				return true
	return false


func _check(ok: bool, name: String, why: String) -> void:
	if ok:
		print("PASS ", name)
	else:
		_failed = true
		print("FAIL ", name, ": ", why)
