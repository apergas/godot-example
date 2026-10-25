extends SceneTree
## Generates assets/worker.png: a 4x3 sheet of 32x32 three-quarter view robot frames.
## Columns: walk cycle phase 0..3 (0 and 2 are the idle/standing pose).
## Rows: 0 = facing down (front), 1 = facing up (back), 2 = facing right (mirror for left).
## Run: tools\godot.cmd --headless --path . --script res://art_src/make_worker.gd [-- preview.png]

const SIZE := 32
const PHASES := 4
const DIRECTIONS := 3

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
	var sheet := Image.create(SIZE * PHASES, SIZE * DIRECTIONS, false, Image.FORMAT_RGBA8)
	for phase in PHASES:
		var frames: Array[Image] = [_front(phase), _back(phase), _side(phase)]
		for row in DIRECTIONS:
			sheet.blit_rect(frames[row], Rect2i(0, 0, SIZE, SIZE), Vector2i(phase * SIZE, row * SIZE))

	var out := ProjectSettings.globalize_path("res://assets/worker.png")
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
	return Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)


## Vertical lift of the left/right foot for a walk phase (phase 1 lifts left, 3 lifts right).
func _lifts(phase: int) -> Vector2i:
	return Vector2i(2 if phase == 1 else 0, 2 if phase == 3 else 0)


## Vertical swing of the left arm for a walk phase; the right arm swings the opposite way.
func _arm_swing(phase: int) -> int:
	return 1 if phase == 1 else (-1 if phase == 3 else 0)


func _front(phase: int) -> Image:
	var img := _new_frame()
	_legs_facing_camera(img, phase)
	_arms_facing_camera(img, phase)

	# Torso with a chest lamp.
	_box(img, 10, 15, 21, 23, BODY_LIGHT, BODY_MID, BODY_DARK)
	_rect(img, 13, 17, 18, 20, OUTLINE)
	_rect(img, 14, 18, 17, 19, BODY_DARK)
	_rect(img, 15, 18, 16, 19, ACCENT_LIGHT)

	_antenna(img, 16)

	# Head (dome) with a visor across the face.
	_shaded_ellipse(img, 16.0, 9.5, 6.5, 5.5, BODY_LIGHT, BODY_MID, BODY_DARK)
	_rect(img, 10, 7, 21, 11, OUTLINE)
	_rect(img, 11, 8, 20, 10, VISOR_MID)
	_rect(img, 11, 8, 14, 8, VISOR_LIGHT)
	_rect(img, 17, 10, 20, 10, VISOR_DARK)
	return img


func _back(phase: int) -> Image:
	var img := _new_frame()
	_legs_facing_camera(img, phase)
	_arms_facing_camera(img, phase)

	# Torso with a big backpack.
	_box(img, 10, 15, 21, 23, BODY_LIGHT, BODY_MID, BODY_DARK)
	_box(img, 12, 16, 19, 22, ACCENT_LIGHT, ACCENT_MID, ACCENT_DARK)
	_rect(img, 12, 19, 19, 19, ACCENT_DARK)
	_rect(img, 15, 17, 16, 18, ACCENT_DARK)

	_antenna(img, 16)

	# Head seen from behind: no visor, just a vent.
	_shaded_ellipse(img, 16.0, 9.5, 6.5, 5.5, BODY_LIGHT, BODY_MID, BODY_DARK)
	_rect(img, 13, 9, 18, 9, OUTLINE)
	_rect(img, 13, 11, 18, 11, BODY_DARK)
	return img


func _side(phase: int) -> Image:
	var img := _new_frame()

	# Far leg (darker), then near leg. Facing right: swings forward = +x.
	var far_x: int = [14, 17, 14, 11][phase]
	var near_x: int = [16, 11, 16, 17][phase]
	var near_lift := 2 if phase == 1 else 0
	var far_lift := 2 if phase == 3 else 0
	_box(img, far_x, 24 - far_lift, far_x + 3, 27 - far_lift, BODY_MID, BODY_DARK, BODY_DARK)
	_rect(img, far_x, 27 - far_lift, far_x + 3, 27 - far_lift, ACCENT_DARK)
	_box(img, near_x, 24 - near_lift, near_x + 3, 27 - near_lift, BODY_LIGHT, BODY_MID, BODY_DARK)
	_rect(img, near_x, 27 - near_lift, near_x + 3, 27 - near_lift, ACCENT_MID)

	# Backpack on the back (left side).
	_box(img, 8, 15, 12, 22, ACCENT_LIGHT, ACCENT_MID, ACCENT_DARK)

	# Torso.
	_box(img, 12, 15, 20, 23, BODY_LIGHT, BODY_MID, BODY_DARK)

	# Near arm swings opposite to the near leg.
	var arm_dx := 2 if phase == 1 else (-2 if phase == 3 else 0)
	_box(img, 14 + arm_dx, 15, 16 + arm_dx, 22, BODY_LIGHT, BODY_MID, BODY_DARK)
	_box(img, 14 + arm_dx, 22, 16 + arm_dx, 24, ACCENT_LIGHT, ACCENT_MID, ACCENT_DARK)

	_antenna(img, 17)

	# Head with the visor on the front (right side).
	_shaded_ellipse(img, 17.0, 9.5, 6.0, 5.5, BODY_LIGHT, BODY_MID, BODY_DARK)
	_rect(img, 16, 7, 23, 11, OUTLINE)
	_rect(img, 17, 8, 22, 10, VISOR_MID)
	_rect(img, 17, 8, 19, 8, VISOR_LIGHT)
	_rect(img, 20, 10, 22, 10, VISOR_DARK)
	return img


func _legs_facing_camera(img: Image, phase: int) -> void:
	var lifts := _lifts(phase)
	var lift_for := [lifts.x, lifts.y]
	var x_for := [11, 17]
	for i in 2:
		var x0: int = x_for[i]
		var lift: int = lift_for[i]
		_box(img, x0, 24 - lift, x0 + 3, 27 - lift, BODY_LIGHT, BODY_MID, BODY_DARK)
		_rect(img, x0, 27 - lift, x0 + 3, 27 - lift, ACCENT_MID)


func _arms_facing_camera(img: Image, phase: int) -> void:
	var swing := _arm_swing(phase)
	_arm(img, 5, swing)
	_arm(img, 24, -swing)


func _arm(img: Image, x0: int, dy: int) -> void:
	_box(img, x0, 15 + dy, x0 + 2, 22 + dy, BODY_LIGHT, BODY_MID, BODY_DARK)
	_box(img, x0, 22 + dy, x0 + 2, 24 + dy, ACCENT_LIGHT, ACCENT_MID, ACCENT_DARK)


func _antenna(img: Image, x: int) -> void:
	_rect(img, x - 2, 0, x + 1, 3, OUTLINE)
	_rect(img, x - 1, 1, x, 2, ACCENT_LIGHT)


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
