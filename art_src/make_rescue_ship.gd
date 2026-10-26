extends SceneTree
## Generates assets/rescue_ship.png: three 104x104 frames in a row.
## Frame 0 = parked ship, 1 = ship with the engine firing, 2 = its ground shadow only (the
## shadow is a separate frame so it stays on the ground while the ship lifts off).
## The ship stands on (32, 80): scenes use offset = Vector2(-32, -80), centered = false, scale 2.
## Run: tools\godot.cmd --headless --path . --script res://art_src/make_rescue_ship.gd [-- preview.png]

const Art := preload("res://art_src/art_lib.gd")

const FRAME := 104
const FRAMES := 3
const BASE_Y := 80
const BODY_X0 := 21
const BODY_X1 := 42
const CX := 31.5
const PREVIEW_SCALE := 8

const FLAME_CORE := Color("fffbe0")
const FLAME_MID := Color("ffd04a")
const FLAME_OUT := Color("f2701a")


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
		preview.fill(Art.SAND)
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
	Art.rect(img, BODY_X0 - 1, 16, BODY_X1 + 1, 65, Art.OUTLINE)
	for x in range(BODY_X0, BODY_X1 + 1):
		Art.rect(img, x, 17, x, 64, Art.shade(x, BODY_X0, BODY_X1, Art.HULL_LIGHT, Art.HULL_MID, Art.HULL_DARK))
	_nose(img, BODY_X0, BODY_X1, 1, 17)
	for y: int in [26, 56]:
		Art.rect(img, BODY_X0, y - 1, BODY_X1, y - 1, Art.OUTLINE)
		Art.rect(img, BODY_X0, y + 2, BODY_X1, y + 2, Art.OUTLINE)
		for x in range(BODY_X0, BODY_X1 + 1):
			Art.rect(img, x, y, x, y + 1, Art.shade(x, BODY_X0, BODY_X1, Art.ACCENT_LIGHT, Art.ACCENT_MID, Art.ACCENT_DARK))
	Art.ellipse(img, CX, 38.5, 5.0, 5.0, Art.OUTLINE)
	Art.ellipse(img, CX, 38.5, 4.0, 4.0, Art.VISOR_MID)
	Art.rect(img, 29, 36, 30, 37, Art.VISOR_LIGHT)
	Art.rect(img, 33, 40, 34, 41, Art.VISOR_DARK)
	Art.rect(img, 27, 45, 36, 52, Art.OUTLINE)
	Art.rect(img, 28, 46, 35, 51, Art.ACCENT_MID)
	Art.rect(img, 31, 47, 32, 50, Art.HULL_LIGHT)
	Art.rect(img, 29, 48, 34, 49, Art.HULL_LIGHT)


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


func _engine(img: Image) -> void:
	Art.rect(img, 24, 64, 39, 72, Art.OUTLINE)
	Art.rect(img, 25, 65, 38, 71, Art.BODY_DARK)
	Art.rect(img, 25, 65, 38, 65, Art.BODY_MID)
	Art.rect(img, 27, 71, 36, 71, Art.OUTLINE)


## Two swept fins in the accent colour (the left one lit), outlined.
func _fins(img: Image) -> void:
	for side: int in [-1, 1]:
		var root_x := BODY_X0 if side < 0 else BODY_X1
		var tip_x := root_x + side * 13
		_tri(img, Vector2(root_x, 44), Vector2(tip_x, 76), Vector2(root_x, 70), Art.OUTLINE)
		_tri(img, Vector2(root_x, 48), Vector2(tip_x - side * 2, 73), Vector2(root_x, 67), Art.ACCENT_MID if side < 0 else Art.ACCENT_DARK)
		_line(img, Vector2(root_x, 48), Vector2(tip_x - side * 2, 73), Art.ACCENT_LIGHT if side < 0 else Art.ACCENT_MID)


## Two landing legs splayed outwards, with foot pads on the ground line.
func _legs(img: Image) -> void:
	for side: int in [-1, 1]:
		var top := Vector2(CX + side * 10.0, 66.0)
		var foot := Vector2(CX + side * 22.0, float(BASE_Y - 1))
		_line(img, top + Vector2(0, -1), foot + Vector2(0, -1), Art.OUTLINE)
		_line(img, top + Vector2(side, 0), foot + Vector2(side, 0), Art.OUTLINE)
		_line(img, top, foot, Art.BODY_MID)
		Art.rect(img, int(foot.x) - 3, BASE_Y - 1, int(foot.x) + 3, BASE_Y, Art.OUTLINE)
		Art.rect(img, int(foot.x) - 2, BASE_Y - 1, int(foot.x) + 2, BASE_Y - 1, Art.BODY_MID)


## Engine plume under the nozzle: white core, yellow, orange edge, tapering downwards.
func _flame(img: Image) -> void:
	for y in range(72, 101):
		var t := float(y - 72) / 28.0
		var half := lerpf(7.0, 1.0, t)
		for x in range(int(CX - half), int(CX + half) + 1):
			var d := absf(x + 0.5 - (CX + 0.5)) / half
			Art.put(img, x, y, FLAME_CORE if d < 0.35 else (FLAME_MID if d < 0.7 else FLAME_OUT))


func _shadow() -> Image:
	var img := _new_frame()
	Art.cast_shadow(img, BODY_X0, BODY_X1, 0, BASE_Y)
	Art.cast_shadow(img, 9, 54, 60, BASE_Y)
	Art.ellipse(img, CX, BASE_Y + 0.5, 24.0, 3.0, Art.SHADOW)
	return img


## Shadow of an upright element standing on y_base: a parallelogram on the ground,
## pushed down-right; a point at height h lands at (+h/2, +h/4).


## Light from the left: light, mid and dark vertical strips across a round surface.


func _tri(img: Image, a: Vector2, b: Vector2, c: Vector2, color: Color) -> void:
	var polygon := PackedVector2Array([a, b, c])
	var lo := a.min(b).min(c).floor()
	var hi := a.max(b).max(c).ceil()
	for y in range(int(lo.y), int(hi.y) + 1):
		for x in range(int(lo.x), int(hi.x) + 1):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), polygon):
				Art.put(img, x, y, color)


func _line(img: Image, a: Vector2, b: Vector2, color: Color) -> void:
	var steps := int(maxf(absf(b.x - a.x), absf(b.y - a.y)))
	for i in steps + 1:
		var p := a.lerp(b, float(i) / maxf(steps, 1.0))
		Art.put(img, int(round(p.x)), int(round(p.y)), color)


