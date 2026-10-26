extends SceneTree
## Generates assets/colony_module.png: two 128x112 frames (0 = finished, 1 = scaffolding).
## The 3x2 footprint is x 0..95, y 40..103 of a frame; its bottom-centre (48, 104) is the
## building origin, so the scene uses Sprite2D offset = Vector2(-48, -104) and centered = false.
## The 32 px on the right and the 8 px at the bottom only hold the baked shadow.
## Run: tools\godot.cmd --headless --path . --script res://art_src/make_colony_module.gd [-- preview.png]

const W := 128
const H := 112
const FOOT_W := 96
const FOOT_H := 64
const BASE_Y := 104
const FOOT_TOP := BASE_Y - FOOT_H
const PREVIEW_SCALE := 8

const OUTLINE := Color("141d29")
const BODY_LIGHT := Color("c3d3e2")
const BODY_MID := Color("8ea6bd")
const BODY_DARK := Color("5b7390")
const ACCENT_LIGHT := Color("ffc15a")
const ACCENT_MID := Color("f28a1a")
const ACCENT_DARK := Color("a8530c")
const VISOR_LIGHT := Color("a8fbff")
const VISOR_MID := Color("38d8f0")
const VISOR_DARK := Color("0f6e86")
const PAD_LIGHT := Color("6b7f96")
const PAD_MID := Color("4b5d73")
const PAD_DARK := Color("2f3c4d")
const GREEN := Color("7fd36a")
const GREEN_DARK := Color("3f8a3a")
const SAND := Color("b5532c")
const SHADOW := Color(0.0, 0.0, 0.0, 0.35)


func _initialize() -> void:
	var sheet := Image.create(W * 2, H, false, Image.FORMAT_RGBA8)
	sheet.blit_rect(_finished(), Rect2i(0, 0, W, H), Vector2i.ZERO)
	sheet.blit_rect(_scaffold(), Rect2i(0, 0, W, H), Vector2i(W, 0))
	var out := ProjectSettings.globalize_path("res://assets/colony_module.png")
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	sheet.save_png(out)
	print("saved ", out)

	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		var preview := Image.create(W * 2, H, false, Image.FORMAT_RGBA8)
		preview.fill(SAND)
		preview.blend_rect(sheet, Rect2i(0, 0, W * 2, H), Vector2i.ZERO)
		preview.resize(W * 2 * PREVIEW_SCALE, H * PREVIEW_SCALE, Image.INTERPOLATE_NEAREST)
		preview.save_png(args[0])
		print("preview ", args[0])
	quit()


func _new_image() -> Image:
	return Image.create(W, H, false, Image.FORMAT_RGBA8)


## Ground layer, then the baked shadow, then everything that stands up.
func _compose(ground: Image, shadow: Image, tall: Image) -> Image:
	var out := _new_image()
	var full := Rect2i(0, 0, W, H)
	out.blend_rect(ground, full, Vector2i.ZERO)
	out.blend_rect(shadow, full, Vector2i.ZERO)
	out.blend_rect(tall, full, Vector2i.ZERO)
	return out


func _finished() -> Image:
	var ground := _new_image()
	var shadow := _new_image()
	var tall := _new_image()
	_plate(ground)
	_cast_shadow(shadow, 6, 89, 34, 92)
	_cast_shadow(shadow, 18, 42, 22, 40)
	_cast_shadow(shadow, 77, 79, 4, 36)
	_body(tall)
	_pods(tall)
	_door(tall)
	_dome(tall)
	_antenna(tall)
	return _compose(ground, shadow, tall)


func _scaffold() -> Image:
	var ground := _new_image()
	var shadow := _new_image()
	var tall := _new_image()
	_plate(ground)
	# Floor and ribs of the module; the first cryo pod is already in place.
	_cast_shadow(shadow, 6, 89, 46, 92)
	_rect(tall, 5, 86, 90, 93, OUTLINE)
	_rect(tall, 6, 87, 89, 92, BODY_DARK)
	for x: int in [8, 28, 48, 68, 87]:
		_rect(tall, x - 1, 45, x + 1, 87, OUTLINE)
		_rect(tall, x, 46, x, 86, BODY_MID)
	_rect(tall, 7, 44, 88, 46, OUTLINE)
	_rect(tall, 8, 45, 87, 45, BODY_LIGHT)
	_rounded_top(tall, 9, 51, 20, 77, 4, OUTLINE)
	_rounded_top(tall, 10, 52, 19, 76, 3, VISOR_MID)
	# Poles, planks and braces in front.
	for x: int in [3, 33, 63, 92]:
		_cast_shadow(shadow, x, x + 1, 36, 98)
		_rect(tall, x - 1, 36, x + 2, 98, OUTLINE)
		_rect(tall, x, 37, x + 1, 97, ACCENT_MID)
		_rect(tall, x, 37, x, 97, ACCENT_LIGHT)
	for y: int in [52, 74]:
		_rect(tall, 2, y - 1, 94, y + 2, OUTLINE)
		_rect(tall, 3, y, 93, y + 1, BODY_DARK)
		_rect(tall, 3, y, 93, y, BODY_MID)
	for i in 20:
		_put(tall, 35 + i, 74 - i, ACCENT_DARK)
	# Material piles: a crated cryo pod (cyan) and hull panels.
	_box(tall, 40, 94, 52, 100, VISOR_LIGHT, VISOR_MID, VISOR_DARK)
	_box(tall, 58, 94, 70, 100, BODY_LIGHT, BODY_MID, BODY_DARK)
	return _compose(ground, shadow, tall)


## Metal plate covering the footprint, with hazard stripes on its front edge.
func _plate(img: Image) -> void:
	_rect(img, 0, FOOT_TOP + 2, FOOT_W - 1, BASE_Y - 1, OUTLINE)
	_rect(img, 1, FOOT_TOP + 3, FOOT_W - 2, BASE_Y - 6, PAD_MID)
	_rect(img, 1, FOOT_TOP + 3, FOOT_W - 2, FOOT_TOP + 3, PAD_LIGHT)
	_rect(img, 1, FOOT_TOP + 3, 1, BASE_Y - 6, PAD_LIGHT)
	for x in range(16, FOOT_W - 2, 16):
		_rect(img, x, FOOT_TOP + 4, x, BASE_Y - 7, PAD_DARK)
	_rect(img, 1, BASE_Y - 5, FOOT_W - 2, BASE_Y - 2, PAD_DARK)
	for x in range(1, FOOT_W - 1):
		if posmod(x, 6) < 3:
			_rect(img, x, BASE_Y - 4, x, BASE_Y - 3, ACCENT_MID)


## Long pressurised module: light roof, front wall, shaded right end, orange stripe.
func _body(img: Image) -> void:
	_rounded_top(img, 5, 33, 90, 93, 6, OUTLINE)
	_rounded_top(img, 6, 34, 89, 92, 5, BODY_MID)
	_rounded_top(img, 6, 34, 89, 45, 5, BODY_LIGHT)
	_rect(img, 6, 46, 89, 46, BODY_DARK)
	_rect(img, 82, 47, 89, 91, BODY_DARK)
	_rect(img, 6, 47, 6, 84, BODY_LIGHT)
	_rect(img, 7, 87, 88, 91, BODY_DARK)
	for x in range(7, 89):
		var stripe := ACCENT_MID if posmod(x, 6) < 3 else ACCENT_DARK
		_rect(img, x, 85, x, 86, stripe)
	# Roof pipe.
	_rect(img, 46, 38, 76, 40, OUTLINE)
	_rect(img, 47, 39, 75, 39, BODY_DARK)


## Four cryo pods behind round-topped windows, each with a sleeping colonist.
func _pods(img: Image) -> void:
	for i in 4:
		var x0 := 10 + i * 14
		_rounded_top(img, x0 - 1, 51, x0 + 10, 77, 4, OUTLINE)
		_rounded_top(img, x0, 52, x0 + 9, 76, 3, VISOR_MID)
		_rect(img, x0, 72, x0 + 9, 76, VISOR_DARK)
		_rect(img, x0 + 1, 53, x0 + 2, 60, VISOR_LIGHT)
		_ellipse(img, x0 + 5.0, 57.5, 2.5, 2.5, VISOR_DARK)
		_rect(img, x0 + 3, 60, x0 + 6, 70, VISOR_DARK)
		_put(img, x0 + 8, 54, Color.WHITE)


func _door(img: Image) -> void:
	_rect(img, 67, 59, 80, 87, OUTLINE)
	_rect(img, 68, 60, 79, 86, BODY_DARK)
	_rect(img, 73, 60, 74, 86, OUTLINE)
	_rect(img, 68, 60, 79, 60, BODY_LIGHT)
	_rect(img, 72, 54, 75, 56, OUTLINE)
	_rect(img, 73, 55, 74, 55, ACCENT_LIGHT)


## Glass greenhouse dome on the roof, lit from the top-left, with a plant inside.
func _dome(img: Image) -> void:
	var cx := 30.0
	var base := 40.0
	var rx := 12.0
	var ry := 16.0
	for y in range(int(base - ry) - 1, int(base) + 1):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx := (x + 0.5 - cx) / (rx + 1.0)
			var dy := (y + 0.5 - base) / (ry + 1.0)
			if dx * dx + dy * dy <= 1.0:
				_put(img, x, y, OUTLINE)
	for y in range(int(base - ry), int(base)):
		for x in range(int(cx - rx), int(cx + rx) + 1):
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - base) / ry
			if dx * dx + dy * dy > 1.0:
				continue
			var t := -0.6 * dx - 0.8 * dy
			_put(img, x, y, VISOR_LIGHT if t > 0.7 else (VISOR_DARK if t < 0.1 else VISOR_MID))
	_rect(img, 27, 33, 33, 39, GREEN_DARK)
	_rect(img, 28, 30, 32, 35, GREEN)
	_rect(img, int(cx - rx) - 1, int(base), int(cx + rx) + 1, int(base) + 1, OUTLINE)


func _antenna(img: Image) -> void:
	_rect(img, 77, 8, 79, 36, OUTLINE)
	_rect(img, 78, 9, 78, 35, BODY_LIGHT)
	_ellipse(img, 78.5, 10.5, 6.0, 2.5, OUTLINE)
	_ellipse(img, 78.5, 10.5, 5.0, 1.5, BODY_LIGHT)
	_rect(img, 78, 4, 78, 7, OUTLINE)
	_put(img, 78, 3, ACCENT_LIGHT)


## Filled rectangle whose two top corners are rounded with radius r.
func _rounded_top(img: Image, x0: int, y0: int, x1: int, y1: int, r: int, color: Color) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var dy := y0 + r - y
			if dy > 0:
				var dx := 0
				if x < x0 + r:
					dx = x0 + r - x
				elif x > x1 - r:
					dx = x - (x1 - r)
				if dx * dx + dy * dy > r * r:
					continue
			_put(img, x, y, color)


## Shadow of an upright element standing on y_base: a parallelogram on the ground,
## pushed down-right; a point at height h lands at (+h/2, +h/4).
func _cast_shadow(shadow: Image, x0: int, x1: int, y_top: int, y_base: int) -> void:
	for h in y_base - y_top + 1:
		var dx := int(h * 0.5)
		var dy := int(h * 0.25)
		for x in range(x0, x1 + 1):
			_put(shadow, x + dx, y_base + dy, SHADOW)


func _put(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, color)


func _rect(img: Image, x0: int, y0: int, x1: int, y1: int, color: Color) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			_put(img, x, y, color)


## Outlined box whose edges are shaded: light on top/left, dark on bottom/right.
func _box(img: Image, x0: int, y0: int, x1: int, y1: int,
		light: Color, mid: Color, dark: Color) -> void:
	_rect(img, x0 - 1, y0 - 1, x1 + 1, y1 + 1, OUTLINE)
	_rect(img, x0, y0, x1, y1, mid)
	_rect(img, x0, y0, x1, y0, light)
	_rect(img, x0, y0, x0, y1, light)
	_rect(img, x0, y1, x1, y1, dark)
	_rect(img, x1, y0, x1, y1, dark)


func _ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, color: Color) -> void:
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				_put(img, x, y, color)
