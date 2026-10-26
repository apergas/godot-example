extends SceneTree
## Generates assets/rescue_ship.png: three 104x104 frames in a row.
## Frame 0 = parked ship, 1 = ship with the engine firing, 2 = its ground shadow only (the
## shadow is a separate frame so it stays on the ground while the ship lifts off).
## The ship stands on (32, 80): scenes use offset = Vector2(-32, -80), centered = false, scale 2.
## Run: tools\godot.cmd --headless --path . --script res://art_src/make_rescue_ship.gd [-- preview.png]

const FRAME := 104
const FRAMES := 3
const BASE_Y := 80
const BODY_X0 := 21
const BODY_X1 := 42
const CX := 31.5
const PREVIEW_SCALE := 8

const OUTLINE := Color("141d29")
const BODY_MID := Color("8ea6bd")
const BODY_DARK := Color("5b7390")
const ACCENT_LIGHT := Color("ffc15a")
const ACCENT_MID := Color("f28a1a")
const ACCENT_DARK := Color("a8530c")
const VISOR_LIGHT := Color("a8fbff")
const VISOR_MID := Color("38d8f0")
const VISOR_DARK := Color("0f6e86")
const HULL_LIGHT := Color("f4f6f8")
const HULL_MID := Color("c9d1da")
const HULL_DARK := Color("8a97a6")
const FLAME_CORE := Color("fffbe0")
const FLAME_MID := Color("ffd04a")
const FLAME_OUT := Color("f2701a")
const SAND := Color("b5532c")
const SHADOW := Color(0.0, 0.0, 0.0, 0.35)


func _initialize() -> void:
	var frames: Array[Image] = [_ship(false), _ship(true), _shadow()]
	var sheet := Image.create(FRAME * FRAMES, FRAME, false, Image.FORMAT_RGBA8)
	for i in FRAMES:
		sheet.blit_rect(frames[i], Rect2i(0, 0, FRAME, FRAME), Vector2i(i * FRAME, 0))
	var out := ProjectSettings.globalize_path("res://assets/rescue_ship.png")
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	sheet.save_png(out)
	print("saved ", out)

	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		# The three frames on sand, then shadow + parked ship composed as in the game.
		var preview := Image.create(FRAME * (FRAMES + 1), FRAME, false, Image.FORMAT_RGBA8)
		preview.fill(SAND)
		preview.blend_rect(sheet, Rect2i(0, 0, FRAME * FRAMES, FRAME), Vector2i.ZERO)
		preview.blend_rect(frames[2], Rect2i(0, 0, FRAME, FRAME), Vector2i(FRAME * FRAMES, 0))
		preview.blend_rect(frames[0], Rect2i(0, 0, FRAME, FRAME), Vector2i(FRAME * FRAMES, 0))
		preview.resize(preview.get_width() * PREVIEW_SCALE, preview.get_height() * PREVIEW_SCALE, Image.INTERPOLATE_NEAREST)
		preview.save_png(args[0])
		print("preview ", args[0])
	quit()


func _new_frame() -> Image:
	return Image.create(FRAME, FRAME, false, Image.FORMAT_RGBA8)


func _ship(firing: bool) -> Image:
	var img := _new_frame()
	if firing:
		_flame(img)
	_legs(img)
	_fins(img)
	_engine(img)
	_body(img)
	return img


## White hull with a nose cone, two orange bands, a porthole and the rescue cross.
func _body(img: Image) -> void:
	_rect(img, BODY_X0 - 1, 16, BODY_X1 + 1, 65, OUTLINE)
	for x in range(BODY_X0, BODY_X1 + 1):
		_rect(img, x, 17, x, 64, _shade(x, BODY_X0, BODY_X1, HULL_LIGHT, HULL_MID, HULL_DARK))
	_nose(img, BODY_X0, BODY_X1, 1, 17)
	for y: int in [26, 56]:
		_rect(img, BODY_X0, y - 1, BODY_X1, y - 1, OUTLINE)
		_rect(img, BODY_X0, y + 2, BODY_X1, y + 2, OUTLINE)
		for x in range(BODY_X0, BODY_X1 + 1):
			_rect(img, x, y, x, y + 1, _shade(x, BODY_X0, BODY_X1, ACCENT_LIGHT, ACCENT_MID, ACCENT_DARK))
	_ellipse(img, CX, 38.5, 5.0, 5.0, OUTLINE)
	_ellipse(img, CX, 38.5, 4.0, 4.0, VISOR_MID)
	_rect(img, 29, 36, 30, 37, VISOR_LIGHT)
	_rect(img, 33, 40, 34, 41, VISOR_DARK)
	_rect(img, 27, 45, 36, 52, OUTLINE)
	_rect(img, 28, 46, 35, 51, ACCENT_MID)
	_rect(img, 31, 47, 32, 50, HULL_LIGHT)
	_rect(img, 29, 48, 34, 49, HULL_LIGHT)


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


func _engine(img: Image) -> void:
	_rect(img, 24, 64, 39, 72, OUTLINE)
	_rect(img, 25, 65, 38, 71, BODY_DARK)
	_rect(img, 25, 65, 38, 65, BODY_MID)
	_rect(img, 27, 71, 36, 71, OUTLINE)


## Two swept fins in the accent colour (the left one lit), outlined.
func _fins(img: Image) -> void:
	for side: int in [-1, 1]:
		var root_x := BODY_X0 if side < 0 else BODY_X1
		var tip_x := root_x + side * 13
		_tri(img, Vector2(root_x, 44), Vector2(tip_x, 76), Vector2(root_x, 70), OUTLINE)
		_tri(img, Vector2(root_x, 48), Vector2(tip_x - side * 2, 73), Vector2(root_x, 67), ACCENT_MID if side < 0 else ACCENT_DARK)
		_line(img, Vector2(root_x, 48), Vector2(tip_x - side * 2, 73), ACCENT_LIGHT if side < 0 else ACCENT_MID)


## Two landing legs splayed outwards, with foot pads on the ground line.
func _legs(img: Image) -> void:
	for side: int in [-1, 1]:
		var top := Vector2(CX + side * 10.0, 66.0)
		var foot := Vector2(CX + side * 22.0, float(BASE_Y - 1))
		_line(img, top + Vector2(0, -1), foot + Vector2(0, -1), OUTLINE)
		_line(img, top + Vector2(side, 0), foot + Vector2(side, 0), OUTLINE)
		_line(img, top, foot, BODY_MID)
		_rect(img, int(foot.x) - 3, BASE_Y - 1, int(foot.x) + 3, BASE_Y, OUTLINE)
		_rect(img, int(foot.x) - 2, BASE_Y - 1, int(foot.x) + 2, BASE_Y - 1, BODY_MID)


## Engine plume under the nozzle: white core, yellow, orange edge, tapering downwards.
func _flame(img: Image) -> void:
	for y in range(72, 101):
		var t := float(y - 72) / 28.0
		var half := lerpf(7.0, 1.0, t)
		for x in range(int(CX - half), int(CX + half) + 1):
			var d := absf(x + 0.5 - (CX + 0.5)) / half
			_put(img, x, y, FLAME_CORE if d < 0.35 else (FLAME_MID if d < 0.7 else FLAME_OUT))


func _shadow() -> Image:
	var img := _new_frame()
	_cast_shadow(img, BODY_X0, BODY_X1, 0, BASE_Y)
	_cast_shadow(img, 9, 54, 60, BASE_Y)
	_ellipse(img, CX, BASE_Y + 0.5, 24.0, 3.0, SHADOW)
	return img


## Shadow of an upright element standing on y_base: a parallelogram on the ground,
## pushed down-right; a point at height h lands at (+h/2, +h/4).
func _cast_shadow(shadow: Image, x0: int, x1: int, y_top: int, y_base: int) -> void:
	for h in y_base - y_top + 1:
		var dx := int(h * 0.5)
		var dy := int(h * 0.25)
		for x in range(x0, x1 + 1):
			_put(shadow, x + dx, y_base + dy, SHADOW)


## Light from the left: light, mid and dark vertical strips across a round surface.
func _shade(x: int, x0: int, x1: int, light: Color, mid: Color, dark: Color) -> Color:
	var t := (x - x0 + 0.5) / float(x1 - x0 + 1)
	return light if t < 0.3 else (dark if t > 0.72 else mid)


func _tri(img: Image, a: Vector2, b: Vector2, c: Vector2, color: Color) -> void:
	var polygon := PackedVector2Array([a, b, c])
	var lo := a.min(b).min(c).floor()
	var hi := a.max(b).max(c).ceil()
	for y in range(int(lo.y), int(hi.y) + 1):
		for x in range(int(lo.x), int(hi.x) + 1):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), polygon):
				_put(img, x, y, color)


func _line(img: Image, a: Vector2, b: Vector2, color: Color) -> void:
	var steps := int(maxf(absf(b.x - a.x), absf(b.y - a.y)))
	for i in steps + 1:
		var p := a.lerp(b, float(i) / maxf(steps, 1.0))
		_put(img, int(round(p.x)), int(round(p.y)), color)


func _put(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, color)


func _rect(img: Image, x0: int, y0: int, x1: int, y1: int, color: Color) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			_put(img, x, y, color)


func _ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, color: Color) -> void:
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				_put(img, x, y, color)
