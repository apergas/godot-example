extends SceneTree
## Generates assets/worker.png: 32x32 three-quarter view robot worker, facing the camera.
## Run: tools\godot.cmd --headless --path . --script res://art_src/make_worker.gd [-- preview.png]

const SIZE := 32

const OUTLINE := Color("141d29")
const SHADOW := Color(0.0, 0.0, 0.0, 0.35)
const BODY_LIGHT := Color("c3d3e2")
const BODY_MID := Color("8ea6bd")
const BODY_DARK := Color("5b7390")
const ACCENT_LIGHT := Color("ffc15a")
const ACCENT_MID := Color("f28a1a")
const ACCENT_DARK := Color("a8530c")
const VISOR_LIGHT := Color("a8fbff")
const VISOR_MID := Color("38d8f0")
const VISOR_DARK := Color("0f6e86")


func _initialize() -> void:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)

	# Ground shadow.
	_ellipse(img, 16.0, 28.5, 9.5, 3.0, SHADOW)

	# Legs and feet.
	for x0: int in [11, 17]:
		_box(img, x0, 24, x0 + 3, 27, BODY_LIGHT, BODY_MID, BODY_DARK)
		_rect(img, x0, 27, x0 + 3, 27, ACCENT_MID)

	# Arms with orange hands.
	for x0: int in [5, 24]:
		_box(img, x0, 15, x0 + 2, 22, BODY_LIGHT, BODY_MID, BODY_DARK)
		_box(img, x0, 22, x0 + 2, 24, ACCENT_LIGHT, ACCENT_MID, ACCENT_DARK)

	# Torso with a chest lamp.
	_box(img, 10, 15, 21, 23, BODY_LIGHT, BODY_MID, BODY_DARK)
	_rect(img, 13, 17, 18, 20, OUTLINE)
	_rect(img, 14, 18, 17, 19, BODY_DARK)
	_rect(img, 15, 18, 16, 19, ACCENT_LIGHT)

	# Antenna.
	_rect(img, 14, 0, 17, 3, OUTLINE)
	_rect(img, 15, 1, 16, 2, ACCENT_LIGHT)

	# Head (dome) with a visor across the face.
	_shaded_ellipse(img, 16.0, 9.5, 6.5, 5.5, BODY_LIGHT, BODY_MID, BODY_DARK)
	_rect(img, 10, 7, 21, 11, OUTLINE)
	_rect(img, 11, 8, 20, 10, VISOR_MID)
	_rect(img, 11, 8, 14, 8, VISOR_LIGHT)
	_rect(img, 17, 10, 20, 10, VISOR_DARK)

	var out := ProjectSettings.globalize_path("res://assets/worker.png")
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	img.save_png(out)
	print("saved ", out)

	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		var preview := img.duplicate() as Image
		preview.resize(SIZE * 10, SIZE * 10, Image.INTERPOLATE_NEAREST)
		preview.save_png(args[0])
		print("preview ", args[0])
	quit()


func _rect(img: Image, x0: int, y0: int, x1: int, y1: int, color: Color) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			img.set_pixel(x, y, color)


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
	for y in SIZE:
		for x in SIZE:
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, color)


func _shaded_ellipse(img: Image, cx: float, cy: float, rx: float, ry: float,
		light: Color, mid: Color, dark: Color) -> void:
	_ellipse(img, cx, cy, rx + 1.0, ry + 1.0, OUTLINE)
	for y in SIZE:
		for x in SIZE:
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy > 1.0:
				continue
			# Light comes from the top-left.
			var t := -0.6 * dx - 0.8 * dy
			img.set_pixel(x, y, light if t > 0.4 else (dark if t < -0.45 else mid))
