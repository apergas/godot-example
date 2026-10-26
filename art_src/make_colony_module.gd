extends SceneTree
## Generates assets/colony_module.png: two 128x112 frames (0 = finished, 1 = scaffolding).
## The 3x2 footprint is x 0..95, y 40..103 of a frame; its bottom-centre (48, 104) is the
## building origin, so the scene uses Sprite2D offset = Vector2(-48, -104) and centered = false.
## The 32 px on the right and the 8 px at the bottom only hold the baked shadow.
## Run: tools\godot.cmd --headless --path . --script res://art_src/make_colony_module.gd [-- preview.png]

const Art := preload("res://art_src/art_lib.gd")

const W := 128
const H := 112
const FOOT_W := 96
const FOOT_H := 64
const BASE_Y := 104
const FOOT_TOP := BASE_Y - FOOT_H
const PREVIEW_SCALE := 8

const GREEN := Color("7fd36a")
const GREEN_DARK := Color("3f8a3a")


func _initialize() -> void:
	var sheet := Image.create(W * 2, H, false, Image.FORMAT_RGBA8)
	sheet.blit_rect(_finished(), Rect2i(0, 0, W, H), Vector2i.ZERO)
	sheet.blit_rect(_scaffold(), Rect2i(0, 0, W, H), Vector2i(W, 0))
	Art.save(sheet, "res://assets/colony_module.png")

	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		var preview := Image.create(W * 2, H, false, Image.FORMAT_RGBA8)
		preview.fill(Art.SAND)
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
	Art.cast_shadow(shadow, 6, 89, 34, 92)
	Art.cast_shadow(shadow, 18, 42, 22, 40)
	Art.cast_shadow(shadow, 77, 79, 4, 36)
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
	Art.cast_shadow(shadow, 6, 89, 46, 92)
	Art.rect(tall, 5, 86, 90, 93, Art.OUTLINE)
	Art.rect(tall, 6, 87, 89, 92, Art.BODY_DARK)
	for x: int in [8, 28, 48, 68, 87]:
		Art.rect(tall, x - 1, 45, x + 1, 87, Art.OUTLINE)
		Art.rect(tall, x, 46, x, 86, Art.BODY_MID)
	Art.rect(tall, 7, 44, 88, 46, Art.OUTLINE)
	Art.rect(tall, 8, 45, 87, 45, Art.BODY_LIGHT)
	_rounded_top(tall, 9, 51, 20, 77, 4, Art.OUTLINE)
	_rounded_top(tall, 10, 52, 19, 76, 3, Art.VISOR_MID)
	# Poles, planks and braces in front.
	for x: int in [3, 33, 63, 92]:
		Art.cast_shadow(shadow, x, x + 1, 36, 98)
		Art.rect(tall, x - 1, 36, x + 2, 98, Art.OUTLINE)
		Art.rect(tall, x, 37, x + 1, 97, Art.ACCENT_MID)
		Art.rect(tall, x, 37, x, 97, Art.ACCENT_LIGHT)
	for y: int in [52, 74]:
		Art.rect(tall, 2, y - 1, 94, y + 2, Art.OUTLINE)
		Art.rect(tall, 3, y, 93, y + 1, Art.BODY_DARK)
		Art.rect(tall, 3, y, 93, y, Art.BODY_MID)
	for i in 20:
		Art.put(tall, 35 + i, 74 - i, Art.ACCENT_DARK)
	# Material piles: a crated cryo pod (cyan) and hull panels.
	Art.box(tall, 40, 94, 52, 100, Art.VISOR_LIGHT, Art.VISOR_MID, Art.VISOR_DARK)
	Art.box(tall, 58, 94, 70, 100, Art.BODY_LIGHT, Art.BODY_MID, Art.BODY_DARK)
	return _compose(ground, shadow, tall)


## Metal plate covering the footprint, with hazard stripes on its front edge.
func _plate(img: Image) -> void:
	Art.rect(img, 0, FOOT_TOP + 2, FOOT_W - 1, BASE_Y - 1, Art.OUTLINE)
	Art.rect(img, 1, FOOT_TOP + 3, FOOT_W - 2, BASE_Y - 6, Art.PAD_MID)
	Art.rect(img, 1, FOOT_TOP + 3, FOOT_W - 2, FOOT_TOP + 3, Art.PAD_LIGHT)
	Art.rect(img, 1, FOOT_TOP + 3, 1, BASE_Y - 6, Art.PAD_LIGHT)
	for x in range(16, FOOT_W - 2, 16):
		Art.rect(img, x, FOOT_TOP + 4, x, BASE_Y - 7, Art.PAD_DARK)
	Art.rect(img, 1, BASE_Y - 5, FOOT_W - 2, BASE_Y - 2, Art.PAD_DARK)
	for x in range(1, FOOT_W - 1):
		if posmod(x, 6) < 3:
			Art.rect(img, x, BASE_Y - 4, x, BASE_Y - 3, Art.ACCENT_MID)


## Long pressurised module: light roof, front wall, shaded right end, orange stripe.
func _body(img: Image) -> void:
	_rounded_top(img, 5, 33, 90, 93, 6, Art.OUTLINE)
	_rounded_top(img, 6, 34, 89, 92, 5, Art.BODY_MID)
	_rounded_top(img, 6, 34, 89, 45, 5, Art.BODY_LIGHT)
	Art.rect(img, 6, 46, 89, 46, Art.BODY_DARK)
	Art.rect(img, 82, 47, 89, 91, Art.BODY_DARK)
	Art.rect(img, 6, 47, 6, 84, Art.BODY_LIGHT)
	Art.rect(img, 7, 87, 88, 91, Art.BODY_DARK)
	for x in range(7, 89):
		var stripe := Art.ACCENT_MID if posmod(x, 6) < 3 else Art.ACCENT_DARK
		Art.rect(img, x, 85, x, 86, stripe)
	# Roof pipe.
	Art.rect(img, 46, 38, 76, 40, Art.OUTLINE)
	Art.rect(img, 47, 39, 75, 39, Art.BODY_DARK)


## Four cryo pods behind round-topped windows, each with a sleeping colonist.
func _pods(img: Image) -> void:
	for i in 4:
		var x0 := 10 + i * 14
		_rounded_top(img, x0 - 1, 51, x0 + 10, 77, 4, Art.OUTLINE)
		_rounded_top(img, x0, 52, x0 + 9, 76, 3, Art.VISOR_MID)
		Art.rect(img, x0, 72, x0 + 9, 76, Art.VISOR_DARK)
		Art.rect(img, x0 + 1, 53, x0 + 2, 60, Art.VISOR_LIGHT)
		Art.ellipse(img, x0 + 5.0, 57.5, 2.5, 2.5, Art.VISOR_DARK)
		Art.rect(img, x0 + 3, 60, x0 + 6, 70, Art.VISOR_DARK)
		Art.put(img, x0 + 8, 54, Color.WHITE)


func _door(img: Image) -> void:
	Art.rect(img, 67, 59, 80, 87, Art.OUTLINE)
	Art.rect(img, 68, 60, 79, 86, Art.BODY_DARK)
	Art.rect(img, 73, 60, 74, 86, Art.OUTLINE)
	Art.rect(img, 68, 60, 79, 60, Art.BODY_LIGHT)
	Art.rect(img, 72, 54, 75, 56, Art.OUTLINE)
	Art.rect(img, 73, 55, 74, 55, Art.ACCENT_LIGHT)


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
				Art.put(img, x, y, Art.OUTLINE)
	for y in range(int(base - ry), int(base)):
		for x in range(int(cx - rx), int(cx + rx) + 1):
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - base) / ry
			if dx * dx + dy * dy > 1.0:
				continue
			var t := -0.6 * dx - 0.8 * dy
			Art.put(img, x, y, Art.VISOR_LIGHT if t > 0.7 else (Art.VISOR_DARK if t < 0.1 else Art.VISOR_MID))
	Art.rect(img, 27, 33, 33, 39, GREEN_DARK)
	Art.rect(img, 28, 30, 32, 35, GREEN)
	Art.rect(img, int(cx - rx) - 1, int(base), int(cx + rx) + 1, int(base) + 1, Art.OUTLINE)


func _antenna(img: Image) -> void:
	Art.rect(img, 77, 8, 79, 36, Art.OUTLINE)
	Art.rect(img, 78, 9, 78, 35, Art.BODY_LIGHT)
	Art.ellipse(img, 78.5, 10.5, 6.0, 2.5, Art.OUTLINE)
	Art.ellipse(img, 78.5, 10.5, 5.0, 1.5, Art.BODY_LIGHT)
	Art.rect(img, 78, 4, 78, 7, Art.OUTLINE)
	Art.put(img, 78, 3, Art.ACCENT_LIGHT)


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
			Art.put(img, x, y, color)
