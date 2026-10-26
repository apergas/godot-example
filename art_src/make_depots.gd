extends SceneTree
## Generates assets/crystal_depot.png and assets/ice_depot.png: two 96x104 frames each
## (frame 0 = finished, frame 1 = scaffolding while under construction).
## The 2x2 footprint is x 0..63, y 32..95 of a frame; its bottom-centre (32, 96) is the
## building origin, so scenes use Sprite2D offset = Vector2(-32, -96) and centered = false.
## Run: tools\godot.cmd --headless --path . --script res://art_src/make_depots.gd [-- preview.png]

const W := 96
const H := 104
const FOOT := 64
const BASE_Y := 96
const CAP_RY := 3.0
const PREVIEW_SCALE := 8

const OUTLINE := Color("141d29")
const BODY_LIGHT := Color("c3d3e2")
const BODY_MID := Color("8ea6bd")
const BODY_DARK := Color("5b7390")
const ACCENT_LIGHT := Color("ffc15a")
const ACCENT_MID := Color("f28a1a")
const ACCENT_DARK := Color("a8530c")
const PAD_LIGHT := Color("6b7f96")
const PAD_MID := Color("4b5d73")
const PAD_DARK := Color("2f3c4d")
const CRYSTAL_LIGHT := Color("a8fbff")
const CRYSTAL_MID := Color("38d8f0")
const CRYSTAL_DARK := Color("0f6e86")
const ICE_LIGHT := Color("e8f6ff")
const ICE_MID := Color("b8dcf0")
const ICE_DARK := Color("6fa3c4")
const SAND := Color("b5532c")
const SHADOW := Color(0.0, 0.0, 0.0, 0.35)

const CRYSTAL_TONES := [CRYSTAL_LIGHT, CRYSTAL_MID, CRYSTAL_DARK]
const ICE_TONES := [ICE_LIGHT, ICE_MID, ICE_DARK]


func _initialize() -> void:
	var crystal := _sheet(_crystal_depot(), _scaffold(CRYSTAL_TONES))
	var ice := _sheet(_ice_depot(), _scaffold(ICE_TONES))
	_save(crystal, "res://assets/crystal_depot.png")
	_save(ice, "res://assets/ice_depot.png")

	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		# Both sheets on Mars sand, so the baked shadow is visible.
		var preview := Image.create(W * 2, H * 2, false, Image.FORMAT_RGBA8)
		preview.fill(SAND)
		preview.blend_rect(crystal, Rect2i(0, 0, W * 2, H), Vector2i.ZERO)
		preview.blend_rect(ice, Rect2i(0, 0, W * 2, H), Vector2i(0, H))
		preview.resize(W * 2 * PREVIEW_SCALE, H * 2 * PREVIEW_SCALE, Image.INTERPOLATE_NEAREST)
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
func _compose(pad: Image, shadow: Image, tall: Image) -> Image:
	var out := _new_image()
	var full := Rect2i(0, 0, W, H)
	out.blend_rect(pad, full, Vector2i.ZERO)
	out.blend_rect(shadow, full, Vector2i.ZERO)
	out.blend_rect(tall, full, Vector2i.ZERO)
	return out


func _crystal_depot() -> Image:
	var pad := _new_image()
	var shadow := _new_image()
	var tall := _new_image()
	_pad(pad)
	_silo(tall, shadow, 6, 25, 8, 66, CRYSTAL_TONES)
	_silo(tall, shadow, 28, 45, 20, 74, CRYSTAL_TONES)
	_crane(tall, shadow)
	_hopper(tall, shadow, CRYSTAL_TONES)
	return _compose(pad, shadow, tall)


func _ice_depot() -> Image:
	var pad := _new_image()
	var shadow := _new_image()
	var tall := _new_image()
	_pad(pad)
	_silo(tall, shadow, 4, 33, 14, 70, ICE_TONES)
	_cooler(tall, shadow)
	_conveyor(tall, shadow)
	return _compose(pad, shadow, tall)


func _scaffold(tones: Array) -> Image:
	var pad := _new_image()
	var shadow := _new_image()
	var tall := _new_image()
	_pad(pad)
	# Half-built shell: the lower ring of the main silo.
	_cast_shadow(shadow, 8, 37, 50, 70)
	_cylinder(tall, 8, 37, 50, 70, BODY_LIGHT, BODY_MID, BODY_DARK)
	_band(tall, 8, 37, 60, 2, tones)
	# Poles, planks and braces in front of the shell.
	for x: int in [4, 20, 40, 56]:
		_cast_shadow(shadow, x, x + 1, 18, 82)
		_rect(tall, x - 1, 18, x + 2, 82, OUTLINE)
		_rect(tall, x, 19, x + 1, 81, ACCENT_MID)
		_rect(tall, x, 19, x, 81, ACCENT_LIGHT)
	for y: int in [24, 44, 64]:
		_rect(tall, 3, y - 1, 58, y + 2, OUTLINE)
		_rect(tall, 4, y, 57, y + 1, BODY_DARK)
		_rect(tall, 4, y, 57, y, BODY_MID)
	for i in 16:
		_put(tall, 6 + i, 64 - i, ACCENT_DARK)
		_put(tall, 42 + i, 44 + i, ACCENT_DARK)
	# Material piles on the pad; one is tinted with the depot accent.
	_box(tall, 30, 84, 40, 90, BODY_LIGHT, BODY_MID, BODY_DARK)
	_box(tall, 44, 84, 54, 90, tones[0], tones[1], tones[2])
	return _compose(pad, shadow, tall)


## Metal plate covering the footprint, with hazard stripes on its front edge.
func _pad(img: Image) -> void:
	_rect(img, 0, 34, FOOT - 1, BASE_Y - 1, OUTLINE)
	_rect(img, 1, 35, FOOT - 2, BASE_Y - 6, PAD_MID)
	_rect(img, 1, 35, FOOT - 2, 35, PAD_LIGHT)
	_rect(img, 1, 35, 1, BASE_Y - 6, PAD_LIGHT)
	for x in range(12, FOOT - 2, 12):
		_rect(img, x, 36, x, BASE_Y - 7, PAD_DARK)
	for y in range(47, BASE_Y - 6, 12):
		_rect(img, 2, y, FOOT - 3, y, PAD_DARK)
	_rect(img, 1, BASE_Y - 5, FOOT - 2, BASE_Y - 2, PAD_DARK)
	for x in range(1, FOOT - 1):
		if posmod(x, 6) < 3:
			_rect(img, x, BASE_Y - 4, x, BASE_Y - 3, ACCENT_MID)


func _silo(tall: Image, shadow: Image, x0: int, x1: int, y_top: int, y_base: int,
		tones: Array) -> void:
	_cast_shadow(shadow, x0, x1, y_top - int(CAP_RY), y_base)
	_cylinder(tall, x0, x1, y_top, y_base, BODY_LIGHT, BODY_MID, BODY_DARK)
	var h := y_base - y_top
	_band(tall, x0, x1, y_top + int(h * 0.25), 3, tones)
	_band(tall, x0, x1, y_top + int(h * 0.7), 2, tones)
	# Glowing sight glass.
	var cx := int((x0 + x1) * 0.5)
	var glass_top := y_top + int(h * 0.38)
	var glass_bottom := y_top + int(h * 0.55)
	_rect(tall, cx - 2, glass_top, cx + 1, glass_bottom, OUTLINE)
	_rect(tall, cx - 1, glass_top + 1, cx, glass_bottom - 1, tones[1])
	_put(tall, cx - 1, glass_top + 1, tones[0])
	# Ladder on the shaded side.
	for y in range(y_top + 4, y_base - 2, 3):
		_rect(tall, x1 - 3, y, x1 - 1, y, OUTLINE)


func _crane(tall: Image, shadow: Image) -> void:
	_cast_shadow(shadow, 52, 55, 6, 80)
	_rect(tall, 51, 6, 56, 80, OUTLINE)
	_rect(tall, 52, 7, 55, 79, ACCENT_MID)
	_rect(tall, 52, 7, 52, 79, ACCENT_LIGHT)
	_rect(tall, 55, 7, 55, 79, ACCENT_DARK)
	for y in range(10, 76, 6):
		_rect(tall, 53, y, 54, y + 2, OUTLINE)
	# Jib reaching over the silos, counterweight on the right.
	_rect(tall, 30, 3, 62, 8, OUTLINE)
	_rect(tall, 31, 4, 61, 7, ACCENT_MID)
	_rect(tall, 31, 4, 61, 4, ACCENT_LIGHT)
	_rect(tall, 31, 7, 61, 7, ACCENT_DARK)
	_box(tall, 58, 9, 61, 12, BODY_MID, BODY_DARK, BODY_DARK)
	# Cable with a crate of crystals.
	_rect(tall, 36, 8, 36, 10, OUTLINE)
	_box(tall, 33, 11, 39, 15, CRYSTAL_LIGHT, CRYSTAL_MID, CRYSTAL_DARK)
	# Operator cab at the foot of the mast.
	_box(tall, 48, 72, 58, 80, BODY_LIGHT, BODY_MID, BODY_DARK)
	_rect(tall, 50, 74, 53, 76, CRYSTAL_MID)


func _hopper(tall: Image, shadow: Image, tones: Array) -> void:
	_cast_shadow(shadow, 8, 24, 70, 88)
	for i in 5:
		var x := 10 + i * 3
		var top := 70 - (i % 2) * 3
		_rect(tall, x - 1, top - 1, x + 2, 77, OUTLINE)
		_rect(tall, x, top, x + 1, 77, tones[1])
		_rect(tall, x, top, x, top + 2, tones[0])
	_box(tall, 8, 76, 24, 88, BODY_LIGHT, BODY_MID, BODY_DARK)
	_rect(tall, 8, 80, 24, 81, tones[2])


func _cooler(tall: Image, shadow: Image) -> void:
	_cast_shadow(shadow, 38, 56, 36, 78)
	_box(tall, 38, 40, 56, 78, BODY_LIGHT, BODY_MID, BODY_DARK)
	for x in range(41, 55, 3):
		_rect(tall, x, 46, x, 72, BODY_DARK)
	# Roof fan seen from above, frost on the top edge, status lamp.
	_ellipse(tall, 47.5, 40.5, 7.0, 3.0, OUTLINE)
	_ellipse(tall, 47.5, 40.5, 6.0, 2.0, ICE_DARK)
	_rect(tall, 47, 39, 48, 42, ICE_LIGHT)
	_rect(tall, 38, 40, 56, 40, ICE_LIGHT)
	_rect(tall, 40, 74, 42, 76, ICE_MID)


func _conveyor(tall: Image, shadow: Image) -> void:
	# Inclined belt feeding the tank from the front, with ice blocks riding on it.
	var start := Vector2(58.0, 92.0)
	var end := Vector2(30.0, 62.0)
	var steps := int(start.distance_to(end))
	for f: float in [0.45, 0.85]:
		var top := start.lerp(end, f)
		var ground_y := int(lerpf(92.0, 82.0, f))
		_cast_shadow(shadow, int(top.x), int(top.x) + 1, int(top.y), ground_y)
		_rect(tall, int(top.x) - 1, int(top.y), int(top.x) + 2, ground_y, OUTLINE)
		_rect(tall, int(top.x), int(top.y), int(top.x) + 1, ground_y - 1, BODY_DARK)
	for i in steps + 1:
		var p := start.lerp(end, float(i) / steps)
		_rect(tall, int(p.x) - 1, int(p.y) - 2, int(p.x) + 1, int(p.y) + 2, OUTLINE)
	for i in steps + 1:
		var p := start.lerp(end, float(i) / steps)
		_rect(tall, int(p.x), int(p.y) - 1, int(p.x), int(p.y) + 1, BODY_DARK if i % 4 == 0 else BODY_MID)
	for f: float in [0.25, 0.55, 0.8]:
		var p := start.lerp(end, f)
		_box(tall, int(p.x) - 2, int(p.y) - 6, int(p.x) + 1, int(p.y) - 3, ICE_LIGHT, ICE_MID, ICE_DARK)


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
	_ellipse(img, cx, y_top + 0.5, rx + 1.0, CAP_RY + 1.0, OUTLINE)
	_rect(img, x0 - 1, y_top, x1 + 1, y_base, OUTLINE)
	for x in range(x0, x1 + 1):
		var dx := (x + 0.5 - cx) / rx
		var bulge := int(CAP_RY * sqrt(maxf(0.0, 1.0 - dx * dx)))
		_rect(img, x, y_top, x, y_base + bulge, _shade(x, x0, x1, light, mid, dark))
	# Top cap seen from above, with a hatch.
	_ellipse(img, cx, y_top + 0.5, rx, CAP_RY, light)
	_ellipse(img, cx, y_top + 0.5, rx * 0.35, CAP_RY * 0.5, dark)


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
