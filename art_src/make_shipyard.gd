extends SceneTree
## Generates assets/shipyard.png (two 144x144 frames: 0 = finished, 1 = scaffolding) and
## assets/launch_pad.png (64x64 flat pad, 2x2 tiles, where rescue ships park).
## Shipyard frame: the 3x3 footprint is x 0..95, y 40..135; its bottom-centre (48, 136) is the
## building origin, so the scene uses Sprite2D offset = Vector2(-48, -136) and centered = false.
## The 48 px on the right and the 8 px at the bottom only hold the baked shadow.
## Run: tools\godot.cmd --headless --path . --script res://art_src/make_shipyard.gd [-- preview.png]

const Art := preload("res://art_src/art_lib.gd")

const W := 144
const H := 144
const FOOT := 96
const BASE_Y := 136
const FOOT_TOP := BASE_Y - FOOT
const PAD := 64
const CAP_RY := 3.0
const PREVIEW_SCALE := 8


const ACCENT_TONES := [Art.ACCENT_LIGHT, Art.ACCENT_MID, Art.ACCENT_DARK]


func _initialize() -> void:
	var sheet := _sheet(_finished(), _scaffold())
	var pad := _launch_pad()
	Art.save(sheet, "res://assets/shipyard.png")
	Art.save(pad, "res://assets/launch_pad.png")

	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		# Both frames on Mars sand, with a launch pad beside them as in the game.
		var preview := Image.create(W * 2 + PAD, H, false, Image.FORMAT_RGBA8)
		preview.fill(Art.SAND)
		preview.blend_rect(sheet, Rect2i(0, 0, W * 2, H), Vector2i.ZERO)
		preview.blend_rect(pad, Rect2i(0, 0, PAD, PAD), Vector2i(W * 2, BASE_Y - PAD))
		preview.resize(preview.get_width() * PREVIEW_SCALE, preview.get_height() * PREVIEW_SCALE, Image.INTERPOLATE_NEAREST)
		preview.save_png(args[0])
		print("preview ", args[0])
	quit()


func _new_image() -> Image:
	return Image.create(W, H, false, Image.FORMAT_RGBA8)


func _sheet(finished: Image, scaffold: Image) -> Image:
	var sheet := Image.create(W * 2, H, false, Image.FORMAT_RGBA8)
	sheet.blit_rect(finished, Rect2i(0, 0, W, H), Vector2i.ZERO)
	sheet.blit_rect(scaffold, Rect2i(0, 0, W, H), Vector2i(W, 0))
	return sheet


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
	_pad_marking(ground, 26, 118)
	_hall(tall, shadow)
	_crane(tall, shadow)
	_hull(tall, shadow)
	_gantry(tall, shadow)
	return _compose(ground, shadow, tall)


func _scaffold() -> Image:
	var ground := _new_image()
	var shadow := _new_image()
	var tall := _new_image()
	_plate(ground)
	_pad_marking(ground, 26, 118)
	# Low walls of the hall and the first section of the crane mast.
	Art.cast_shadow(shadow, 4, 46, 76, 104)
	Art.box(tall, 4, 76, 46, 104, Art.BODY_LIGHT, Art.BODY_MID, Art.BODY_DARK)
	Art.cast_shadow(shadow, 84, 88, 60, 112)
	Art.rect(tall, 83, 60, 89, 112, Art.OUTLINE)
	Art.rect(tall, 84, 61, 88, 111, Art.ACCENT_MID)
	Art.rect(tall, 84, 61, 84, 111, Art.ACCENT_LIGHT)
	# Poles, planks and braces in front.
	for x: int in [6, 30, 54, 78]:
		Art.cast_shadow(shadow, x, x + 1, 50, 124)
		Art.rect(tall, x - 1, 50, x + 2, 124, Art.OUTLINE)
		Art.rect(tall, x, 51, x + 1, 123, Art.ACCENT_MID)
		Art.rect(tall, x, 51, x, 123, Art.ACCENT_LIGHT)
	for y: int in [58, 82, 106]:
		Art.rect(tall, 5, y - 1, 80, y + 2, Art.OUTLINE)
		Art.rect(tall, 6, y, 79, y + 1, Art.BODY_DARK)
		Art.rect(tall, 6, y, 79, y, Art.BODY_MID)
	for i in 22:
		Art.put(tall, 8 + i, 104 - i, Art.ACCENT_DARK)
		Art.put(tall, 56 + i, 82 + i, Art.ACCENT_DARK)
	# Material piles: white hull plates and a crate.
	Art.box(tall, 40, 120, 52, 127, Art.HULL_LIGHT, Art.HULL_MID, Art.HULL_DARK)
	Art.box(tall, 58, 118, 68, 127, Art.BODY_LIGHT, Art.BODY_MID, Art.BODY_DARK)
	return _compose(ground, shadow, tall)


## Metal plate covering the footprint, with hazard stripes on its front edge.
func _plate(img: Image) -> void:
	Art.rect(img, 0, FOOT_TOP + 2, FOOT - 1, BASE_Y - 1, Art.OUTLINE)
	Art.rect(img, 1, FOOT_TOP + 3, FOOT - 2, BASE_Y - 6, Art.PAD_MID)
	Art.rect(img, 1, FOOT_TOP + 3, FOOT - 2, FOOT_TOP + 3, Art.PAD_LIGHT)
	Art.rect(img, 1, FOOT_TOP + 3, 1, BASE_Y - 6, Art.PAD_LIGHT)
	for x in range(16, FOOT - 2, 16):
		Art.rect(img, x, FOOT_TOP + 4, x, BASE_Y - 7, Art.PAD_DARK)
	for y in range(FOOT_TOP + 19, BASE_Y - 6, 16):
		Art.rect(img, 2, y, FOOT - 3, y, Art.PAD_DARK)
	Art.rect(img, 1, BASE_Y - 5, FOOT - 2, BASE_Y - 2, Art.PAD_DARK)
	for x in range(1, FOOT - 1):
		if posmod(x, 6) < 3:
			Art.rect(img, x, BASE_Y - 4, x, BASE_Y - 3, Art.ACCENT_MID)


## Painted landing ring on the plate, in front of the hall door.
func _pad_marking(img: Image, cx: int, cy: int) -> void:
	Art.ellipse(img, cx + 0.5, cy + 0.5, 15.0, 6.0, Art.ACCENT_DARK)
	Art.ellipse(img, cx + 0.5, cy + 0.5, 13.0, 5.0, Art.PAD_MID)
	Art.rect(img, cx - 6, cy, cx + 6, cy, Art.ACCENT_LIGHT)
	Art.rect(img, cx, cy - 3, cx, cy + 3, Art.ACCENT_LIGHT)


## Assembly hall at the back-left: tall shed with a skylight and a big striped door.
func _hall(tall: Image, shadow: Image) -> void:
	Art.cast_shadow(shadow, 4, 46, 44, 104)
	Art.box(tall, 4, 44, 46, 104, Art.BODY_LIGHT, Art.BODY_MID, Art.BODY_DARK)
	Art.rect(tall, 4, 44, 46, 47, Art.BODY_LIGHT)
	Art.rect(tall, 8, 50, 42, 52, Art.OUTLINE)
	Art.rect(tall, 9, 51, 41, 51, Art.VISOR_MID)
	Art.rect(tall, 9, 51, 18, 51, Art.VISOR_LIGHT)
	Art.rect(tall, 12, 68, 38, 104, Art.OUTLINE)
	Art.rect(tall, 13, 69, 37, 103, Art.BODY_DARK)
	for y in range(72, 103, 6):
		Art.rect(tall, 13, y, 37, y + 1, Art.PAD_DARK)
	for x in range(13, 38):
		if posmod(x, 6) < 3:
			Art.rect(tall, x, 69, x, 70, Art.ACCENT_MID)
	for y in range(58, 98, 8):
		Art.rect(tall, 41, y, 44, y + 1, Art.BODY_DARK)


## Tall crane at the back-right; its jib reaches over the hull being assembled.
func _crane(tall: Image, shadow: Image) -> void:
	Art.cast_shadow(shadow, 84, 88, 6, 112)
	Art.rect(tall, 83, 6, 89, 112, Art.OUTLINE)
	Art.rect(tall, 84, 7, 88, 111, Art.ACCENT_MID)
	Art.rect(tall, 84, 7, 84, 111, Art.ACCENT_LIGHT)
	Art.rect(tall, 88, 7, 88, 111, Art.ACCENT_DARK)
	for y in range(10, 108, 6):
		Art.rect(tall, 85, y, 87, y + 2, Art.OUTLINE)
		Art.put(tall, 86, y + 1, Art.ACCENT_DARK)
	Art.rect(tall, 36, 2, 104, 8, Art.OUTLINE)
	Art.rect(tall, 37, 3, 103, 7, Art.ACCENT_MID)
	Art.rect(tall, 37, 3, 103, 3, Art.ACCENT_LIGHT)
	Art.rect(tall, 37, 7, 103, 7, Art.ACCENT_DARK)
	for x in range(40, 102, 5):
		Art.put(tall, x, 5, Art.ACCENT_DARK)
	Art.box(tall, 96, 9, 103, 16, Art.BODY_MID, Art.BODY_DARK, Art.BODY_DARK)
	Art.rect(tall, 62, 8, 62, 21, Art.OUTLINE)
	Art.rect(tall, 60, 20, 64, 21, Art.OUTLINE)
	# Operator cab at the foot of the mast.
	Art.box(tall, 78, 100, 92, 112, Art.BODY_LIGHT, Art.BODY_MID, Art.BODY_DARK)
	Art.rect(tall, 80, 102, 84, 105, Art.VISOR_MID)
	Art.put(tall, 80, 102, Art.VISOR_LIGHT)


## Rescue ship hull being assembled in the middle of the yard (white with orange bands).
func _hull(tall: Image, shadow: Image) -> void:
	Art.cast_shadow(shadow, 54, 70, 22, 116)
	_cylinder(tall, 54, 70, 34, 116, Art.HULL_LIGHT, Art.HULL_MID, Art.HULL_DARK)
	_nose(tall, 54, 70, 22, 34)
	_band(tall, 54, 70, 50, 3, ACCENT_TONES)
	_band(tall, 54, 70, 96, 2, ACCENT_TONES)
	Art.ellipse(tall, 62.5, 66.5, 3.0, 3.0, Art.OUTLINE)
	Art.ellipse(tall, 62.5, 66.5, 2.0, 2.0, Art.VISOR_MID)
	Art.put(tall, 61, 65, Art.VISOR_LIGHT)


## Service gantry beside the hull, with two arms holding it.
func _gantry(tall: Image, shadow: Image) -> void:
	Art.cast_shadow(shadow, 73, 77, 30, 116)
	Art.rect(tall, 72, 30, 78, 116, Art.OUTLINE)
	Art.rect(tall, 73, 31, 77, 115, Art.BODY_DARK)
	for y in range(32, 112, 6):
		for i in 5:
			Art.put(tall, 73 + i, y + i, Art.ACCENT_MID)
	Art.rect(tall, 73, 31, 73, 115, Art.ACCENT_LIGHT)
	Art.rect(tall, 77, 31, 77, 115, Art.ACCENT_MID)
	for y: int in [44, 80]:
		Art.rect(tall, 69, y - 1, 73, y + 2, Art.OUTLINE)
		Art.rect(tall, 70, y, 72, y + 1, Art.ACCENT_MID)


## Flat 2x2-tile launch pad (no height, no shadow): metal disc, hazard ring, cross and lamps.
func _launch_pad() -> Image:
	var img := Image.create(PAD, PAD, false, Image.FORMAT_RGBA8)
	var c := PAD * 0.5
	for y in PAD:
		for x in PAD:
			var d := Vector2(x + 0.5 - c, y + 0.5 - c)
			var r := d.length()
			if r >= 31.0:
				continue
			if r >= 30.0:
				img.set_pixel(x, y, Art.OUTLINE)
			elif r >= 27.0:
				img.set_pixel(x, y, Art.PAD_LIGHT if d.x + d.y < 0.0 else Art.PAD_MID)
			elif r >= 22.0:
				var stripe := posmod(int(floor((d.angle() + PI) / TAU * 24.0)), 2) == 0
				img.set_pixel(x, y, Art.ACCENT_MID if stripe else Art.PAD_DARK)
			elif r >= 14.0:
				img.set_pixel(x, y, Art.PAD_MID)
			elif r >= 12.0:
				img.set_pixel(x, y, Art.PAD_DARK)
			else:
				img.set_pixel(x, y, Art.PAD_LIGHT)
	Art.rect(img, 24, 31, 39, 32, Art.ACCENT_LIGHT)
	Art.rect(img, 31, 24, 32, 39, Art.ACCENT_LIGHT)
	for p: Vector2i in [Vector2i(13, 13), Vector2i(50, 13), Vector2i(13, 50), Vector2i(50, 50)]:
		Art.rect(img, p.x - 1, p.y - 1, p.x + 1, p.y + 1, Art.OUTLINE)
		Art.put(img, p.x, p.y, Art.VISOR_LIGHT)
	return img


## Nose cone narrowing from the full hull width at y_base to a point at y_top.
func _nose(img: Image, x0: int, x1: int, y_top: int, y_base: int) -> void:
	var cx := (x0 + x1) * 0.5
	var half := (x1 - x0) * 0.5
	for y in range(y_top, y_base + 1):
		var t := float(y - y_top) / float(y_base - y_top)
		var w := half * sqrt(t)
		var left := int(round(cx - w))
		var right := int(round(cx + w))
		Art.rect(img, left - 1, y, right + 1, y, Art.OUTLINE)
		for x in range(left, right + 1):
			Art.put(img, x, y, Art.shade(x, x0, x1, Art.HULL_LIGHT, Art.HULL_MID, Art.HULL_DARK))
	Art.rect(img, int(cx) - 1, y_top - 1, int(cx) + 1, y_top - 1, Art.OUTLINE)


func _cylinder(img: Image, x0: int, x1: int, y_top: int, y_base: int,
		light: Color, mid: Color, dark: Color) -> void:
	var cx := (x0 + x1 + 1) * 0.5
	var rx := (x1 - x0 + 1) * 0.5
	Art.ellipse(img, cx, y_base + 0.5, rx + 1.0, CAP_RY + 1.0, Art.OUTLINE)
	Art.rect(img, x0 - 1, y_top, x1 + 1, y_base, Art.OUTLINE)
	for x in range(x0, x1 + 1):
		var dx := (x + 0.5 - cx) / rx
		var bulge := int(CAP_RY * sqrt(maxf(0.0, 1.0 - dx * dx)))
		Art.rect(img, x, y_top, x, y_base + bulge, Art.shade(x, x0, x1, light, mid, dark))


func _band(img: Image, x0: int, x1: int, y: int, rows: int, tones: Array) -> void:
	Art.rect(img, x0, y - 1, x1, y - 1, Art.OUTLINE)
	Art.rect(img, x0, y + rows, x1, y + rows, Art.OUTLINE)
	for x in range(x0, x1 + 1):
		Art.rect(img, x, y, x, y + rows - 1, Art.shade(x, x0, x1, tones[0], tones[1], tones[2]))
