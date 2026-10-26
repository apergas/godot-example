extends SceneTree
## Generates assets/shipyard.png (two 144x144 frames: 0 = finished, 1 = scaffolding) and
## assets/launch_pad.png (64x64 flat pad, 2x2 tiles, where rescue ships park).
## Shipyard frame: the 3x3 footprint is x 0..95, y 40..135; its bottom-centre (48, 136) is the
## building origin, so the scene uses Sprite2D offset = Vector2(-48, -136) and centered = false.
## The 48 px on the right and the 8 px at the bottom only hold the baked shadow.
## Run: tools\godot.cmd --headless --path . --script res://art_src/make_shipyard.gd [-- preview.png]

const W := 144
const H := 144
const FOOT := 96
const BASE_Y := 136
const FOOT_TOP := BASE_Y - FOOT
const PAD := 64
const CAP_RY := 3.0
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
const HULL_LIGHT := Color("f4f6f8")
const HULL_MID := Color("c9d1da")
const HULL_DARK := Color("8a97a6")
const SAND := Color("b5532c")
const SHADOW := Color(0.0, 0.0, 0.0, 0.35)

const ACCENT_TONES := [ACCENT_LIGHT, ACCENT_MID, ACCENT_DARK]


func _initialize() -> void:
	var sheet := _sheet(_finished(), _scaffold())
	var pad := _launch_pad()
	_save(sheet, "res://assets/shipyard.png")
	_save(pad, "res://assets/launch_pad.png")

	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		# Both frames on Mars sand, with a launch pad beside them as in the game.
		var preview := Image.create(W * 2 + PAD, H, false, Image.FORMAT_RGBA8)
		preview.fill(SAND)
		preview.blend_rect(sheet, Rect2i(0, 0, W * 2, H), Vector2i.ZERO)
		preview.blend_rect(pad, Rect2i(0, 0, PAD, PAD), Vector2i(W * 2, BASE_Y - PAD))
		preview.resize(preview.get_width() * PREVIEW_SCALE, preview.get_height() * PREVIEW_SCALE, Image.INTERPOLATE_NEAREST)
		preview.save_png(args[0])
		print("preview ", args[0])
	quit()


func _save(img: Image, path: String) -> void:
	var out := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	img.save_png(out)
	print("saved ", out)


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
	_cast_shadow(shadow, 4, 46, 76, 104)
	_box(tall, 4, 76, 46, 104, BODY_LIGHT, BODY_MID, BODY_DARK)
	_cast_shadow(shadow, 84, 88, 60, 112)
	_rect(tall, 83, 60, 89, 112, OUTLINE)
	_rect(tall, 84, 61, 88, 111, ACCENT_MID)
	_rect(tall, 84, 61, 84, 111, ACCENT_LIGHT)
	# Poles, planks and braces in front.
	for x: int in [6, 30, 54, 78]:
		_cast_shadow(shadow, x, x + 1, 50, 124)
		_rect(tall, x - 1, 50, x + 2, 124, OUTLINE)
		_rect(tall, x, 51, x + 1, 123, ACCENT_MID)
		_rect(tall, x, 51, x, 123, ACCENT_LIGHT)
	for y: int in [58, 82, 106]:
		_rect(tall, 5, y - 1, 80, y + 2, OUTLINE)
		_rect(tall, 6, y, 79, y + 1, BODY_DARK)
		_rect(tall, 6, y, 79, y, BODY_MID)
	for i in 22:
		_put(tall, 8 + i, 104 - i, ACCENT_DARK)
		_put(tall, 56 + i, 82 + i, ACCENT_DARK)
	# Material piles: white hull plates and a crate.
	_box(tall, 40, 120, 52, 127, HULL_LIGHT, HULL_MID, HULL_DARK)
	_box(tall, 58, 118, 68, 127, BODY_LIGHT, BODY_MID, BODY_DARK)
	return _compose(ground, shadow, tall)


## Metal plate covering the footprint, with hazard stripes on its front edge.
func _plate(img: Image) -> void:
	_rect(img, 0, FOOT_TOP + 2, FOOT - 1, BASE_Y - 1, OUTLINE)
	_rect(img, 1, FOOT_TOP + 3, FOOT - 2, BASE_Y - 6, PAD_MID)
	_rect(img, 1, FOOT_TOP + 3, FOOT - 2, FOOT_TOP + 3, PAD_LIGHT)
	_rect(img, 1, FOOT_TOP + 3, 1, BASE_Y - 6, PAD_LIGHT)
	for x in range(16, FOOT - 2, 16):
		_rect(img, x, FOOT_TOP + 4, x, BASE_Y - 7, PAD_DARK)
	for y in range(FOOT_TOP + 19, BASE_Y - 6, 16):
		_rect(img, 2, y, FOOT - 3, y, PAD_DARK)
	_rect(img, 1, BASE_Y - 5, FOOT - 2, BASE_Y - 2, PAD_DARK)
	for x in range(1, FOOT - 1):
		if posmod(x, 6) < 3:
			_rect(img, x, BASE_Y - 4, x, BASE_Y - 3, ACCENT_MID)


## Painted landing ring on the plate, in front of the hall door.
func _pad_marking(img: Image, cx: int, cy: int) -> void:
	_ellipse(img, cx + 0.5, cy + 0.5, 15.0, 6.0, ACCENT_DARK)
	_ellipse(img, cx + 0.5, cy + 0.5, 13.0, 5.0, PAD_MID)
	_rect(img, cx - 6, cy, cx + 6, cy, ACCENT_LIGHT)
	_rect(img, cx, cy - 3, cx, cy + 3, ACCENT_LIGHT)


## Assembly hall at the back-left: tall shed with a skylight and a big striped door.
func _hall(tall: Image, shadow: Image) -> void:
	_cast_shadow(shadow, 4, 46, 44, 104)
	_box(tall, 4, 44, 46, 104, BODY_LIGHT, BODY_MID, BODY_DARK)
	_rect(tall, 4, 44, 46, 47, BODY_LIGHT)
	_rect(tall, 8, 50, 42, 52, OUTLINE)
	_rect(tall, 9, 51, 41, 51, VISOR_MID)
	_rect(tall, 9, 51, 18, 51, VISOR_LIGHT)
	_rect(tall, 12, 68, 38, 104, OUTLINE)
	_rect(tall, 13, 69, 37, 103, BODY_DARK)
	for y in range(72, 103, 6):
		_rect(tall, 13, y, 37, y + 1, PAD_DARK)
	for x in range(13, 38):
		if posmod(x, 6) < 3:
			_rect(tall, x, 69, x, 70, ACCENT_MID)
	for y in range(58, 98, 8):
		_rect(tall, 41, y, 44, y + 1, BODY_DARK)


## Tall crane at the back-right; its jib reaches over the hull being assembled.
func _crane(tall: Image, shadow: Image) -> void:
	_cast_shadow(shadow, 84, 88, 6, 112)
	_rect(tall, 83, 6, 89, 112, OUTLINE)
	_rect(tall, 84, 7, 88, 111, ACCENT_MID)
	_rect(tall, 84, 7, 84, 111, ACCENT_LIGHT)
	_rect(tall, 88, 7, 88, 111, ACCENT_DARK)
	for y in range(10, 108, 6):
		_rect(tall, 85, y, 87, y + 2, OUTLINE)
		_put(tall, 86, y + 1, ACCENT_DARK)
	_rect(tall, 36, 2, 104, 8, OUTLINE)
	_rect(tall, 37, 3, 103, 7, ACCENT_MID)
	_rect(tall, 37, 3, 103, 3, ACCENT_LIGHT)
	_rect(tall, 37, 7, 103, 7, ACCENT_DARK)
	for x in range(40, 102, 5):
		_put(tall, x, 5, ACCENT_DARK)
	_box(tall, 96, 9, 103, 16, BODY_MID, BODY_DARK, BODY_DARK)
	_rect(tall, 62, 8, 62, 21, OUTLINE)
	_rect(tall, 60, 20, 64, 21, OUTLINE)
	# Operator cab at the foot of the mast.
	_box(tall, 78, 100, 92, 112, BODY_LIGHT, BODY_MID, BODY_DARK)
	_rect(tall, 80, 102, 84, 105, VISOR_MID)
	_put(tall, 80, 102, VISOR_LIGHT)


## Rescue ship hull being assembled in the middle of the yard (white with orange bands).
func _hull(tall: Image, shadow: Image) -> void:
	_cast_shadow(shadow, 54, 70, 22, 116)
	_cylinder(tall, 54, 70, 34, 116, HULL_LIGHT, HULL_MID, HULL_DARK)
	_nose(tall, 54, 70, 22, 34)
	_band(tall, 54, 70, 50, 3, ACCENT_TONES)
	_band(tall, 54, 70, 96, 2, ACCENT_TONES)
	_ellipse(tall, 62.5, 66.5, 3.0, 3.0, OUTLINE)
	_ellipse(tall, 62.5, 66.5, 2.0, 2.0, VISOR_MID)
	_put(tall, 61, 65, VISOR_LIGHT)


## Service gantry beside the hull, with two arms holding it.
func _gantry(tall: Image, shadow: Image) -> void:
	_cast_shadow(shadow, 73, 77, 30, 116)
	_rect(tall, 72, 30, 78, 116, OUTLINE)
	_rect(tall, 73, 31, 77, 115, BODY_DARK)
	for y in range(32, 112, 6):
		for i in 5:
			_put(tall, 73 + i, y + i, ACCENT_MID)
	_rect(tall, 73, 31, 73, 115, ACCENT_LIGHT)
	_rect(tall, 77, 31, 77, 115, ACCENT_MID)
	for y: int in [44, 80]:
		_rect(tall, 69, y - 1, 73, y + 2, OUTLINE)
		_rect(tall, 70, y, 72, y + 1, ACCENT_MID)


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
				img.set_pixel(x, y, OUTLINE)
			elif r >= 27.0:
				img.set_pixel(x, y, PAD_LIGHT if d.x + d.y < 0.0 else PAD_MID)
			elif r >= 22.0:
				var stripe := posmod(int(floor((d.angle() + PI) / TAU * 24.0)), 2) == 0
				img.set_pixel(x, y, ACCENT_MID if stripe else PAD_DARK)
			elif r >= 14.0:
				img.set_pixel(x, y, PAD_MID)
			elif r >= 12.0:
				img.set_pixel(x, y, PAD_DARK)
			else:
				img.set_pixel(x, y, PAD_LIGHT)
	_rect(img, 24, 31, 39, 32, ACCENT_LIGHT)
	_rect(img, 31, 24, 32, 39, ACCENT_LIGHT)
	for p: Vector2i in [Vector2i(13, 13), Vector2i(50, 13), Vector2i(13, 50), Vector2i(50, 50)]:
		_rect(img, p.x - 1, p.y - 1, p.x + 1, p.y + 1, OUTLINE)
		_put(img, p.x, p.y, VISOR_LIGHT)
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
		_rect(img, left - 1, y, right + 1, y, OUTLINE)
		for x in range(left, right + 1):
			_put(img, x, y, _shade(x, x0, x1, HULL_LIGHT, HULL_MID, HULL_DARK))
	_rect(img, int(cx) - 1, y_top - 1, int(cx) + 1, y_top - 1, OUTLINE)


## Shadow of an upright element standing on y_base: a parallelogram on the ground,
## pushed down-right; a point at height h lands at (+h/2, +h/4).
func _cast_shadow(shadow: Image, x0: int, x1: int, y_top: int, y_base: int) -> void:
	for h in y_base - y_top + 1:
		var dx := int(h * 0.5)
		var dy := int(h * 0.25)
		for x in range(x0, x1 + 1):
			_put(shadow, x + dx, y_base + dy, SHADOW)


func _cylinder(img: Image, x0: int, x1: int, y_top: int, y_base: int,
		light: Color, mid: Color, dark: Color) -> void:
	var cx := (x0 + x1 + 1) * 0.5
	var rx := (x1 - x0 + 1) * 0.5
	_ellipse(img, cx, y_base + 0.5, rx + 1.0, CAP_RY + 1.0, OUTLINE)
	_rect(img, x0 - 1, y_top, x1 + 1, y_base, OUTLINE)
	for x in range(x0, x1 + 1):
		var dx := (x + 0.5 - cx) / rx
		var bulge := int(CAP_RY * sqrt(maxf(0.0, 1.0 - dx * dx)))
		_rect(img, x, y_top, x, y_base + bulge, _shade(x, x0, x1, light, mid, dark))


func _band(img: Image, x0: int, x1: int, y: int, rows: int, tones: Array) -> void:
	_rect(img, x0, y - 1, x1, y - 1, OUTLINE)
	_rect(img, x0, y + rows, x1, y + rows, OUTLINE)
	for x in range(x0, x1 + 1):
		_rect(img, x, y, x, y + rows - 1, _shade(x, x0, x1, tones[0], tones[1], tones[2]))


## Light from the left: light, mid and dark vertical strips across a round surface.
func _shade(x: int, x0: int, x1: int, light: Color, mid: Color, dark: Color) -> Color:
	var t := (x - x0 + 0.5) / float(x1 - x0 + 1)
	return light if t < 0.3 else (dark if t > 0.72 else mid)


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
