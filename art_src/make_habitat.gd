extends SceneTree
## Generates assets/habitat.png: two 80x80 frames side by side (160x80).
## Frame 0 = finished pressurised habitat module, frame 1 = scaffold (under construction).
## The 2x2 footprint covers x 0..63, y 16..79 of each frame; the scene origin is the
## bottom-centre of the footprint, pixel (32, 80). The baked shadow falls to the bottom-right.
## Run: tools\godot.cmd --headless --path . --script res://art_src/make_habitat.gd [-- preview.png]

const W := 80
const H := 80
const FRAMES := 2

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
const WINDOW_GLOW := Color("ffe9a0")
const HIGHLIGHT := Color("eef6fb")
const PAD_LIGHT := Color("7a3d29")
const PAD_DARK := Color("5e2f22")
const SHADOW := Color(0.0, 0.0, 0.0, 0.35)

# Cylinder module: centre x, radii and wall heights. The dome sits on WALL_TOP.
const CX := 32.0
const RX := 25.0
const RY := 8.0
const WALL_TOP := 40.0
const WALL_BOTTOM := 64.0
const DOME_RY := 28.0


func _initialize() -> void:
	var sheet := Image.create(W * FRAMES, H, false, Image.FORMAT_RGBA8)
	var frames: Array[Image] = [_finished(), _scaffold()]
	for i in FRAMES:
		sheet.blit_rect(frames[i], Rect2i(0, 0, W, H), Vector2i(i * W, 0))

	var out := ProjectSettings.globalize_path("res://assets/habitat.png")
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	sheet.save_png(out)
	print("saved ", out)

	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		var preview := sheet.duplicate() as Image
		preview.resize(sheet.get_width() * 8, sheet.get_height() * 8, Image.INTERPOLATE_NEAREST)
		preview.save_png(args[0])
		print("preview ", args[0])
	quit()


func _new_frame() -> Image:
	return Image.create(W, H, false, Image.FORMAT_RGBA8)


func _finished() -> Image:
	var img := _new_frame()
	_shadow(img, 48.0, 64.0, 30.0, 13.0)
	_pad(img)
	_wall(img, WALL_TOP)
	_band(img, 7.0, 2)
	_dome(img)
	_skylight(img)
	_windows(img)
	_door(img)
	_beacon(img)
	return img


func _scaffold() -> Image:
	var img := _new_frame()
	_shadow(img, 46.0, 66.0, 28.0, 11.0)
	_pad(img)
	_wall(img, 58.0)
	_band(img, 3.0, 2)
	for x: int in [7, 23, 41, 57]:
		_rect(img, x - 1, 12, x + 1, 74, OUTLINE)
		_rect(img, x, 13, x, 73, ACCENT_DARK)
	for y: int in [26, 44]:
		_rect(img, 5, y - 1, 59, y + 2, OUTLINE)
		_rect(img, 6, y, 58, y, ACCENT_LIGHT)
		_rect(img, 6, y + 1, 58, y + 1, ACCENT_MID)
	_line(img, Vector2i(8, 43), Vector2i(22, 28), BODY_MID)
	_line(img, Vector2i(24, 43), Vector2i(40, 28), BODY_MID)
	_line(img, Vector2i(42, 28), Vector2i(56, 43), BODY_MID)
	# A crate of wall panels waiting on the pad.
	_rect(img, 46, 64, 56, 72, OUTLINE)
	_rect(img, 47, 65, 55, 71, BODY_MID)
	_rect(img, 47, 65, 55, 65, BODY_LIGHT)
	_rect(img, 55, 65, 55, 71, BODY_DARK)
	return img


func _pad(img: Image) -> void:
	_ellipse(img, CX, 67.0, 31.0, 11.0, OUTLINE)
	_ellipse(img, CX, 67.0, 30.0, 10.0, PAD_DARK)
	_ellipse(img, CX - 1.0, 66.0, 27.0, 8.0, PAD_LIGHT)


## Cylinder wall from `top` down to the front edge of its base ellipse, lit from the left.
func _wall(img: Image, top: float) -> void:
	var x_min := ceili(CX - RX - 0.5)
	var x_max := floori(CX + RX - 0.5)
	for x in range(x_min, x_max + 1):
		var dx := (x + 0.5 - CX) / RX
		var y_end := int(WALL_BOTTOM + RY * sqrt(maxf(0.0, 1.0 - dx * dx)))
		var color := BODY_LIGHT if dx < -0.45 else (BODY_DARK if dx > 0.5 else BODY_MID)
		_rect(img, x, int(top), x, y_end, color)
		_px(img, x, y_end + 1, OUTLINE)
	_rect(img, x_min, int(top) - 1, x_max, int(top) - 1, OUTLINE)
	_rect(img, x_min - 1, int(top), x_min - 1, int(WALL_BOTTOM), OUTLINE)
	_rect(img, x_max + 1, int(top), x_max + 1, int(WALL_BOTTOM), OUTLINE)


## Orange stripe following the curve of the wall, `lift` px above its base.
func _band(img: Image, lift: float, thickness: int) -> void:
	for x in range(ceili(CX - RX - 0.5), floori(CX + RX - 0.5) + 1):
		var dx := (x + 0.5 - CX) / RX
		var y := int(WALL_BOTTOM + RY * sqrt(maxf(0.0, 1.0 - dx * dx)) - lift)
		var color := ACCENT_LIGHT if dx < -0.45 else (ACCENT_DARK if dx > 0.5 else ACCENT_MID)
		_rect(img, x, y, x, y + thickness - 1, color)


## Dome on top of the wall, down to the front rim of the wall's top ellipse.
func _dome(img: Image) -> void:
	for y in range(0, int(WALL_TOP) + 1):
		for x in W:
			var ox := (x + 0.5 - CX) / (RX + 1.0)
			var oy := (y + 0.5 - WALL_TOP) / (DOME_RY + 1.0)
			if ox * ox + oy * oy <= 1.0:
				_px(img, x, y, OUTLINE)
	for x in range(ceili(CX - RX - 0.5), floori(CX + RX - 0.5) + 1):
		var dx := (x + 0.5 - CX) / RX
		var k := sqrt(maxf(0.0, 1.0 - dx * dx))
		var y_top := int(WALL_TOP - DOME_RY * k)
		var y_rim := int(WALL_TOP + RY * k)
		for y in range(y_top, y_rim + 1):
			# Light comes from the top-left.
			var dy := clampf((y + 0.5 - WALL_TOP) / DOME_RY, -1.0, 0.0)
			var t := -0.6 * dx - 0.8 * dy
			_px(img, x, y, BODY_LIGHT if t > 0.75 else (BODY_DARK if t < 0.0 else BODY_MID))
		_px(img, x, y_rim + 1, BODY_DARK)
	_rect(img, 19, 20, 21, 21, HIGHLIGHT)


func _skylight(img: Image) -> void:
	_rect(img, 27, 23, 38, 27, OUTLINE)
	_rect(img, 28, 24, 37, 26, VISOR_MID)
	_rect(img, 28, 24, 31, 24, VISOR_LIGHT)
	_rect(img, 34, 26, 37, 26, VISOR_DARK)


func _windows(img: Image) -> void:
	for x0: int in [12, 44]:
		_rect(img, x0 - 1, 51, x0 + 6, 57, OUTLINE)
		_rect(img, x0, 52, x0 + 5, 56, WINDOW_GLOW)
		_rect(img, x0, 52, x0 + 5, 52, ACCENT_LIGHT)
		_rect(img, x0 + 3, 52, x0 + 3, 56, ACCENT_DARK)


func _door(img: Image) -> void:
	_rect(img, 27, 57, 37, 71, OUTLINE)
	_rect(img, 28, 58, 36, 71, BODY_DARK)
	_rect(img, 29, 59, 35, 70, ACCENT_DARK)
	_rect(img, 31, 60, 33, 63, WINDOW_GLOW)


func _beacon(img: Image) -> void:
	_rect(img, 40, 6, 40, 13, OUTLINE)
	_rect(img, 39, 3, 41, 5, OUTLINE)
	_px(img, 40, 4, ACCENT_LIGHT)


func _shadow(img: Image, cx: float, cy: float, rx: float, ry: float) -> void:
	for y in H:
		for x in W:
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0 and img.get_pixel(x, y).a == 0.0:
				img.set_pixel(x, y, SHADOW)


func _px(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < W and y < H:
		img.set_pixel(x, y, color)


func _rect(img: Image, x0: int, y0: int, x1: int, y1: int, color: Color) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			_px(img, x, y, color)


func _line(img: Image, a: Vector2i, b: Vector2i, color: Color) -> void:
	var steps := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in steps + 1:
		var p := Vector2(a).lerp(Vector2(b), float(i) / maxf(float(steps), 1.0))
		_px(img, roundi(p.x), roundi(p.y), color)


func _ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, color: Color) -> void:
	for y in H:
		for x in W:
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				_px(img, x, y, color)
