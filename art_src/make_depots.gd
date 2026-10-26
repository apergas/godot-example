extends SceneTree
## Generates assets/crystal_depot.png and assets/ice_depot.png: two 96x104 frames each
## (frame 0 = finished, frame 1 = scaffolding while under construction).
## The 2x2 footprint is x 0..63, y 32..95 of a frame; its bottom-centre (32, 96) is the
## building origin, so scenes use Sprite2D offset = Vector2(-32, -96) and centered = false.
## Run: tools\godot.cmd --headless --path . --script res://art_src/make_depots.gd [-- preview.png]

const Art := preload("res://art_src/art_lib.gd")

const W := 96
const H := 104
const FOOT := 64
const BASE_Y := 96
const CAP_RY := 3.0
const PREVIEW_SCALE := 8


const CRYSTAL_TONES := [Art.CRYSTAL_LIGHT, Art.CRYSTAL_MID, Art.CRYSTAL_DARK]
const ICE_TONES := [Art.ICE_LIGHT, Art.ICE_MID, Art.ICE_DARK]


func _initialize() -> void:
	var crystal := _sheet(_crystal_depot(), _scaffold(CRYSTAL_TONES))
	var ice := _sheet(_ice_depot(), _scaffold(ICE_TONES))
	Art.save(crystal, "res://assets/crystal_depot.png")
	Art.save(ice, "res://assets/ice_depot.png")

	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		# Both sheets on Mars sand, so the baked shadow is visible.
		var preview := Image.create(W * 2, H * 2, false, Image.FORMAT_RGBA8)
		preview.fill(Art.SAND)
		preview.blend_rect(crystal, Rect2i(0, 0, W * 2, H), Vector2i.ZERO)
		preview.blend_rect(ice, Rect2i(0, 0, W * 2, H), Vector2i(0, H))
		preview.resize(W * 2 * PREVIEW_SCALE, H * 2 * PREVIEW_SCALE, Image.INTERPOLATE_NEAREST)
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
	Art.cast_shadow(shadow, 8, 37, 50, 70)
	_cylinder(tall, 8, 37, 50, 70, Art.BODY_LIGHT, Art.BODY_MID, Art.BODY_DARK)
	_band(tall, 8, 37, 60, 2, tones)
	# Poles, planks and braces in front of the shell.
	for x: int in [4, 20, 40, 56]:
		Art.cast_shadow(shadow, x, x + 1, 18, 82)
		Art.rect(tall, x - 1, 18, x + 2, 82, Art.OUTLINE)
		Art.rect(tall, x, 19, x + 1, 81, Art.ACCENT_MID)
		Art.rect(tall, x, 19, x, 81, Art.ACCENT_LIGHT)
	for y: int in [24, 44, 64]:
		Art.rect(tall, 3, y - 1, 58, y + 2, Art.OUTLINE)
		Art.rect(tall, 4, y, 57, y + 1, Art.BODY_DARK)
		Art.rect(tall, 4, y, 57, y, Art.BODY_MID)
	for i in 16:
		Art.put(tall, 6 + i, 64 - i, Art.ACCENT_DARK)
		Art.put(tall, 42 + i, 44 + i, Art.ACCENT_DARK)
	# Material piles on the pad; one is tinted with the depot accent.
	Art.box(tall, 30, 84, 40, 90, Art.BODY_LIGHT, Art.BODY_MID, Art.BODY_DARK)
	Art.box(tall, 44, 84, 54, 90, tones[0], tones[1], tones[2])
	return _compose(pad, shadow, tall)


## Metal plate covering the footprint, with hazard stripes on its front edge.
func _pad(img: Image) -> void:
	Art.rect(img, 0, 34, FOOT - 1, BASE_Y - 1, Art.OUTLINE)
	Art.rect(img, 1, 35, FOOT - 2, BASE_Y - 6, Art.PAD_MID)
	Art.rect(img, 1, 35, FOOT - 2, 35, Art.PAD_LIGHT)
	Art.rect(img, 1, 35, 1, BASE_Y - 6, Art.PAD_LIGHT)
	for x in range(12, FOOT - 2, 12):
		Art.rect(img, x, 36, x, BASE_Y - 7, Art.PAD_DARK)
	for y in range(47, BASE_Y - 6, 12):
		Art.rect(img, 2, y, FOOT - 3, y, Art.PAD_DARK)
	Art.rect(img, 1, BASE_Y - 5, FOOT - 2, BASE_Y - 2, Art.PAD_DARK)
	for x in range(1, FOOT - 1):
		if posmod(x, 6) < 3:
			Art.rect(img, x, BASE_Y - 4, x, BASE_Y - 3, Art.ACCENT_MID)


func _silo(tall: Image, shadow: Image, x0: int, x1: int, y_top: int, y_base: int,
		tones: Array) -> void:
	Art.cast_shadow(shadow, x0, x1, y_top - int(CAP_RY), y_base)
	_cylinder(tall, x0, x1, y_top, y_base, Art.BODY_LIGHT, Art.BODY_MID, Art.BODY_DARK)
	var h := y_base - y_top
	_band(tall, x0, x1, y_top + int(h * 0.25), 3, tones)
	_band(tall, x0, x1, y_top + int(h * 0.7), 2, tones)
	# Glowing sight glass.
	var cx := int((x0 + x1) * 0.5)
	var glass_top := y_top + int(h * 0.38)
	var glass_bottom := y_top + int(h * 0.55)
	Art.rect(tall, cx - 2, glass_top, cx + 1, glass_bottom, Art.OUTLINE)
	Art.rect(tall, cx - 1, glass_top + 1, cx, glass_bottom - 1, tones[1])
	Art.put(tall, cx - 1, glass_top + 1, tones[0])
	# Ladder on the shaded side.
	for y in range(y_top + 4, y_base - 2, 3):
		Art.rect(tall, x1 - 3, y, x1 - 1, y, Art.OUTLINE)


func _crane(tall: Image, shadow: Image) -> void:
	Art.cast_shadow(shadow, 52, 55, 6, 80)
	Art.rect(tall, 51, 6, 56, 80, Art.OUTLINE)
	Art.rect(tall, 52, 7, 55, 79, Art.ACCENT_MID)
	Art.rect(tall, 52, 7, 52, 79, Art.ACCENT_LIGHT)
	Art.rect(tall, 55, 7, 55, 79, Art.ACCENT_DARK)
	for y in range(10, 76, 6):
		Art.rect(tall, 53, y, 54, y + 2, Art.OUTLINE)
	# Jib reaching over the silos, counterweight on the right.
	Art.rect(tall, 30, 3, 62, 8, Art.OUTLINE)
	Art.rect(tall, 31, 4, 61, 7, Art.ACCENT_MID)
	Art.rect(tall, 31, 4, 61, 4, Art.ACCENT_LIGHT)
	Art.rect(tall, 31, 7, 61, 7, Art.ACCENT_DARK)
	Art.box(tall, 58, 9, 61, 12, Art.BODY_MID, Art.BODY_DARK, Art.BODY_DARK)
	# Cable with a crate of crystals.
	Art.rect(tall, 36, 8, 36, 10, Art.OUTLINE)
	Art.box(tall, 33, 11, 39, 15, Art.CRYSTAL_LIGHT, Art.CRYSTAL_MID, Art.CRYSTAL_DARK)
	# Operator cab at the foot of the mast.
	Art.box(tall, 48, 72, 58, 80, Art.BODY_LIGHT, Art.BODY_MID, Art.BODY_DARK)
	Art.rect(tall, 50, 74, 53, 76, Art.CRYSTAL_MID)


func _hopper(tall: Image, shadow: Image, tones: Array) -> void:
	Art.cast_shadow(shadow, 8, 24, 70, 88)
	for i in 5:
		var x := 10 + i * 3
		var top := 70 - (i % 2) * 3
		Art.rect(tall, x - 1, top - 1, x + 2, 77, Art.OUTLINE)
		Art.rect(tall, x, top, x + 1, 77, tones[1])
		Art.rect(tall, x, top, x, top + 2, tones[0])
	Art.box(tall, 8, 76, 24, 88, Art.BODY_LIGHT, Art.BODY_MID, Art.BODY_DARK)
	Art.rect(tall, 8, 80, 24, 81, tones[2])


func _cooler(tall: Image, shadow: Image) -> void:
	Art.cast_shadow(shadow, 38, 56, 36, 78)
	Art.box(tall, 38, 40, 56, 78, Art.BODY_LIGHT, Art.BODY_MID, Art.BODY_DARK)
	for x in range(41, 55, 3):
		Art.rect(tall, x, 46, x, 72, Art.BODY_DARK)
	# Roof fan seen from above, frost on the top edge, status lamp.
	Art.ellipse(tall, 47.5, 40.5, 7.0, 3.0, Art.OUTLINE)
	Art.ellipse(tall, 47.5, 40.5, 6.0, 2.0, Art.ICE_DARK)
	Art.rect(tall, 47, 39, 48, 42, Art.ICE_LIGHT)
	Art.rect(tall, 38, 40, 56, 40, Art.ICE_LIGHT)
	Art.rect(tall, 40, 74, 42, 76, Art.ICE_MID)


func _conveyor(tall: Image, shadow: Image) -> void:
	# Inclined belt feeding the tank from the front, with ice blocks riding on it.
	var start := Vector2(58.0, 92.0)
	var end := Vector2(30.0, 62.0)
	var steps := int(start.distance_to(end))
	for f: float in [0.45, 0.85]:
		var top := start.lerp(end, f)
		var ground_y := int(lerpf(92.0, 82.0, f))
		Art.cast_shadow(shadow, int(top.x), int(top.x) + 1, int(top.y), ground_y)
		Art.rect(tall, int(top.x) - 1, int(top.y), int(top.x) + 2, ground_y, Art.OUTLINE)
		Art.rect(tall, int(top.x), int(top.y), int(top.x) + 1, ground_y - 1, Art.BODY_DARK)
	for i in steps + 1:
		var p := start.lerp(end, float(i) / steps)
		Art.rect(tall, int(p.x) - 1, int(p.y) - 2, int(p.x) + 1, int(p.y) + 2, Art.OUTLINE)
	for i in steps + 1:
		var p := start.lerp(end, float(i) / steps)
		Art.rect(tall, int(p.x), int(p.y) - 1, int(p.x), int(p.y) + 1, Art.BODY_DARK if i % 4 == 0 else Art.BODY_MID)
	for f: float in [0.25, 0.55, 0.8]:
		var p := start.lerp(end, f)
		Art.box(tall, int(p.x) - 2, int(p.y) - 6, int(p.x) + 1, int(p.y) - 3, Art.ICE_LIGHT, Art.ICE_MID, Art.ICE_DARK)


## Shadow of an upright element standing on y_base: a parallelogram on the ground,
## pushed down-right; a point at height h lands at (+h/2, +h/4).


func _cylinder(img: Image, x0: int, x1: int, y_top: int, y_base: int,
		light: Color, mid: Color, dark: Color) -> void:
	var cx := (x0 + x1 + 1) * 0.5
	var rx := (x1 - x0 + 1) * 0.5
	Art.ellipse(img, cx, y_base + 0.5, rx + 1.0, CAP_RY + 1.0, Art.OUTLINE)
	Art.ellipse(img, cx, y_top + 0.5, rx + 1.0, CAP_RY + 1.0, Art.OUTLINE)
	Art.rect(img, x0 - 1, y_top, x1 + 1, y_base, Art.OUTLINE)
	for x in range(x0, x1 + 1):
		var dx := (x + 0.5 - cx) / rx
		var bulge := int(CAP_RY * sqrt(maxf(0.0, 1.0 - dx * dx)))
		Art.rect(img, x, y_top, x, y_base + bulge, Art.shade(x, x0, x1, light, mid, dark))
	# Top cap seen from above, with a hatch.
	Art.ellipse(img, cx, y_top + 0.5, rx, CAP_RY, light)
	Art.ellipse(img, cx, y_top + 0.5, rx * 0.35, CAP_RY * 0.5, dark)


func _band(img: Image, x0: int, x1: int, y: int, rows: int, tones: Array) -> void:
	Art.rect(img, x0, y - 1, x1, y - 1, Art.OUTLINE)
	Art.rect(img, x0, y + rows, x1, y + rows, Art.OUTLINE)
	for x in range(x0, x1 + 1):
		Art.rect(img, x, y, x, y + rows - 1, Art.shade(x, x0, x1, tones[0], tones[1], tones[2]))


## Light from the left: light, mid and dark vertical strips across a round surface.


## Outlined box whose edges are shaded: light on top/left, dark on bottom/right.


