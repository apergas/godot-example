extends SceneTree
## Generates assets/worker.png: 32x32 top-down robot worker, facing up.
## Run: tools\godot.cmd --headless --path . --script res://art_src/make_worker.gd [-- preview.png]

const SIZE := 32

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


func _initialize() -> void:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)

	# Arms (drawn first so the torso overlaps their top).
	for side: int in [-1, 1]:
		var cx: float = 16.0 + side * 10.5
		_shaded_ellipse(img, cx, 17.0, 2.6, 6.5, BODY_LIGHT, BODY_MID, BODY_DARK)
		_shaded_ellipse(img, cx, 10.0, 2.2, 2.2, ACCENT_LIGHT, ACCENT_MID, ACCENT_DARK)

	# Backpack (rear, towards the bottom of the sprite).
	_rect(img, 10, 21, 21, 28, OUTLINE)
	_rect(img, 11, 22, 20, 27, ACCENT_MID)
	_rect(img, 11, 22, 20, 22, ACCENT_LIGHT)
	_rect(img, 11, 27, 20, 27, ACCENT_DARK)
	_rect(img, 15, 23, 16, 26, ACCENT_DARK)

	# Torso.
	_shaded_ellipse(img, 16.0, 17.0, 8.0, 7.0, BODY_LIGHT, BODY_MID, BODY_DARK)
	_rect(img, 14, 16, 17, 19, OUTLINE)
	_rect(img, 15, 17, 16, 18, ACCENT_MID)

	# Head (dome) with visor facing up.
	_shaded_ellipse(img, 16.0, 11.0, 6.0, 5.5, BODY_LIGHT, BODY_MID, BODY_DARK)
	_rect(img, 11, 7, 20, 10, OUTLINE)
	_rect(img, 12, 8, 19, 9, VISOR_MID)
	_rect(img, 12, 8, 14, 8, VISOR_LIGHT)
	_rect(img, 17, 9, 19, 9, VISOR_DARK)

	# Antenna on top of the head.
	_rect(img, 15, 11, 16, 13, OUTLINE)
	_rect(img, 15, 12, 16, 12, ACCENT_LIGHT)

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
