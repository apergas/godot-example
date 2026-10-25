extends SceneTree
## Generates assets/hq.png: the central base (HQ), a 3x3-tile building in three-quarter view.
## The footprint is the 96x96 square x 0..95, y 32..127. Its bottom-centre pixel edge (48, 128)
## is the scene origin: Sprite2D centered = false, offset = Vector2(-48, -128), scale 2.
## Columns 96..103 and rows 128..131 only hold the baked shadow (cast down-right).
## Run: tools\godot.cmd --headless --path . --script res://art_src/make_hq.gd [-- preview.png]

const W := 104
const H := 132
const SLAB_TOP := 36

const OUTLINE := Color("141d29")
const BODY_LIGHT := Color("c3d3e2")
const BODY_MID := Color("8ea6bd")
const BODY_DARK := Color("5b7390")
const ACCENT_LIGHT := Color("ffc15a")
const ACCENT_MID := Color("f28a1a")
const ACCENT_DARK := Color("a8530c")
const GLASS_LIGHT := Color("a8fbff")
const GLASS_MID := Color("38d8f0")
const GLASS_DARK := Color("0f6e86")
const SLAB := Color("47566a")
const SLAB_LINE := Color("3a475a")
const SLAB_EDGE := Color("2b3544")
const SAND := Color("b5532c")
const SHADOW := Color(0.0, 0.0, 0.0, 0.35)

var _mask := PackedByteArray()


func _initialize() -> void:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	_mask.resize(W * H)
	_mask.fill(0)

	_rect(img, 4, SLAB_TOP + 4, 99, 131, SHADOW)
	_slab(img)
	_landing_pad(img)
	_cast_shadows(img)
	_main_block(img)
	_dome(img)
	_tower(img)
	_dish(img)
	_lights(img)

	var out := ProjectSettings.globalize_path("res://assets/hq.png")
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	img.save_png(out)
	print("saved ", out)

	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		# Preview over sand, to judge the baked shadow.
		var preview := Image.create(W, H, false, Image.FORMAT_RGBA8)
		preview.fill(SAND)
		preview.blend_rect(img, Rect2i(0, 0, W, H), Vector2i.ZERO)
		preview.resize(W * 8, H * 8, Image.INTERPOLATE_NEAREST)
		preview.save_png(args[0])
		print("preview ", args[0])
	quit()


func _slab(img: Image) -> void:
	_rect(img, 0, SLAB_TOP, 95, 127, OUTLINE)
	_rect(img, 1, SLAB_TOP + 1, 94, 122, SLAB)
	for x in range(16, 95, 16):
		_rect(img, x, SLAB_TOP + 1, x, 122, SLAB_LINE)
	for y in range(52, 122, 16):
		_rect(img, 1, y, 94, y, SLAB_LINE)
	_rect(img, 1, SLAB_TOP + 1, 94, SLAB_TOP + 1, BODY_DARK)
	# Front edge of the slab with hazard stripes.
	_rect(img, 1, 123, 94, 126, SLAB_EDGE)
	for x in range(2, 92, 6):
		_rect(img, x, 124, x + 2, 125, ACCENT_MID)


func _landing_pad(img: Image) -> void:
	_ellipse(img, 79.0, 104.0, 15.0, 10.0, OUTLINE)
	_ellipse(img, 79.0, 104.0, 14.0, 9.0, ACCENT_MID)
	_ellipse(img, 79.0, 104.0, 12.0, 7.5, SLAB_EDGE)
	_ellipse(img, 79.0, 104.0, 9.0, 5.5, BODY_DARK)
	_rect(img, 74, 101, 75, 107, ACCENT_LIGHT)
	_rect(img, 83, 101, 84, 107, ACCENT_LIGHT)
	_rect(img, 76, 103, 82, 104, ACCENT_LIGHT)


## Shadows cast on the slab and on the ground, applied before the tall parts are drawn.
func _cast_shadows(img: Image) -> void:
	_sweep(6, 46, 65, 99, 14, 7)
	_sweep(48, 8, 61, 57, 40, 20)
	_sweep(76, 28, 84, 58, 10, 5)
	for y in range(SLAB_TOP, H):
		for x in W:
			if _mask[y * W + x] == 0:
				continue
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, SHADOW if c.a == 0.0 else c.darkened(0.35))


func _main_block(img: Image) -> void:
	_rect(img, 5, 45, 66, 100, OUTLINE)
	_rect(img, 6, 46, 65, 57, BODY_LIGHT)
	_rect(img, 6, 58, 65, 99, BODY_MID)
	_rect(img, 6, 58, 65, 58, OUTLINE)
	_rect(img, 6, 59, 6, 99, BODY_LIGHT)
	_rect(img, 65, 59, 65, 99, BODY_DARK)
	_rect(img, 6, 96, 65, 99, BODY_DARK)
	_rect(img, 6, 61, 65, 62, ACCENT_MID)
	# Window band.
	_rect(img, 9, 66, 58, 72, OUTLINE)
	for x in range(10, 56, 7):
		_rect(img, x, 67, x + 5, 71, GLASS_MID)
		_rect(img, x, 67, x + 2, 67, GLASS_LIGHT)
		_rect(img, x + 3, 71, x + 5, 71, GLASS_DARK)
	# Door with an orange frame.
	_rect(img, 25, 80, 38, 99, OUTLINE)
	_rect(img, 26, 81, 37, 99, ACCENT_MID)
	_rect(img, 26, 81, 37, 81, ACCENT_LIGHT)
	_rect(img, 28, 83, 35, 99, OUTLINE)
	_rect(img, 29, 84, 34, 99, GLASS_DARK)
	_rect(img, 31, 84, 32, 99, OUTLINE)
	# Roof vents.
	_rect(img, 33, 48, 44, 55, OUTLINE)
	_rect(img, 34, 49, 43, 54, BODY_MID)
	_rect(img, 34, 51, 43, 51, BODY_DARK)
	_rect(img, 34, 53, 43, 53, BODY_DARK)


func _dome(img: Image) -> void:
	_shaded_ellipse(img, 19.0, 53.0, 11.0, 11.0, GLASS_LIGHT, GLASS_MID, GLASS_DARK, 52)
	_rect(img, 19, 43, 19, 52, GLASS_DARK)
	_rect(img, 9, 48, 29, 48, GLASS_DARK)
	_rect(img, 8, 52, 30, 55, OUTLINE)
	_rect(img, 9, 53, 29, 54, BODY_DARK)


func _tower(img: Image) -> void:
	_box(img, 51, 8, 58, 56, BODY_LIGHT, BODY_MID, BODY_DARK)
	_rect(img, 51, 30, 58, 31, ACCENT_MID)
	_rect(img, 51, 42, 58, 43, ACCENT_MID)
	# Control room with a window band at the top.
	_box(img, 48, 12, 61, 22, BODY_LIGHT, BODY_MID, BODY_DARK)
	_rect(img, 49, 16, 60, 19, OUTLINE)
	_rect(img, 50, 17, 59, 18, GLASS_MID)
	_rect(img, 50, 17, 53, 17, GLASS_LIGHT)
	# Antenna mast.
	_rect(img, 54, 2, 55, 10, OUTLINE)
	_rect(img, 54, 3, 54, 10, BODY_LIGHT)


func _dish(img: Image) -> void:
	_rect(img, 79, 36, 81, 58, OUTLINE)
	_rect(img, 80, 37, 80, 57, BODY_MID)
	_rect(img, 76, 56, 84, 59, OUTLINE)
	_rect(img, 77, 57, 83, 58, BODY_DARK)
	_shaded_ellipse(img, 80.0, 33.0, 8.0, 4.5, BODY_LIGHT, BODY_MID, BODY_DARK, H)
	_rect(img, 80, 29, 80, 33, OUTLINE)


func _lights(img: Image) -> void:
	_light(img, 2, 38)
	_light(img, 92, 38)
	_light(img, 2, 119)
	_light(img, 92, 119)
	_light(img, 64, 103)
	_light(img, 93, 103)
	_light(img, 78, 94)
	_light(img, 78, 113)
	_light(img, 5, 45)
	_light(img, 65, 45)
	_rect(img, 53, 0, 56, 1, ACCENT_LIGHT)
	_rect(img, 54, 1, 55, 1, ACCENT_MID)


func _light(img: Image, x: int, y: int) -> void:
	_rect(img, x, y, x + 1, y + 1, ACCENT_LIGHT)
	_rect(img, x + 1, y + 1, x + 1, y + 1, ACCENT_MID)


## Marks in the shadow mask the area swept by rect (x0,y0)-(x1,y1) moving by (dx, dy).
func _sweep(x0: int, y0: int, x1: int, y1: int, dx: int, dy: int) -> void:
	var poly := PackedVector2Array([
		Vector2(x0, y0), Vector2(x1 + 1, y0), Vector2(x1 + 1 + dx, y0 + dy),
		Vector2(x1 + 1 + dx, y1 + 1 + dy), Vector2(x0 + dx, y1 + 1 + dy), Vector2(x0, y1 + 1),
	])
	for y in H:
		for x in W:
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), poly):
				_mask[y * W + x] = 1


func _rect(img: Image, x0: int, y0: int, x1: int, y1: int, color: Color) -> void:
	for y in range(maxi(y0, 0), mini(y1, H - 1) + 1):
		for x in range(maxi(x0, 0), mini(x1, W - 1) + 1):
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
	for y in H:
		for x in W:
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, color)


## Ellipse lit from the top-left, with a 1 px outline; rows below max_y are left untouched.
func _shaded_ellipse(img: Image, cx: float, cy: float, rx: float, ry: float,
		light: Color, mid: Color, dark: Color, max_y: int) -> void:
	for y in mini(max_y + 1, H):
		for x in W:
			var ox := (x + 0.5 - cx) / (rx + 1.0)
			var oy := (y + 0.5 - cy) / (ry + 1.0)
			if ox * ox + oy * oy > 1.0:
				continue
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy > 1.0:
				img.set_pixel(x, y, OUTLINE)
				continue
			var t := -0.6 * dx - 0.8 * dy
			img.set_pixel(x, y, light if t > 0.4 else (dark if t < -0.45 else mid))
