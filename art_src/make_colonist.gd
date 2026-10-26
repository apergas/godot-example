extends SceneTree
## Generates assets/colonist.png: a 4x3 sheet of 32x32 three-quarter view colonist frames,
## laid out like assets/worker.png. Columns: walk phase 0..3 (0 and 2 are standing);
## rows: 0 = facing down (front), 1 = facing up (back), 2 = facing right (mirror for left).
## A human in a white and orange space suit with a round helmet and a gold visor.
## Run: tools\godot.cmd --headless --path . --script res://art_src/make_colonist.gd [-- preview.png]

const Art := preload("res://art_src/art_lib.gd")

const SIZE := 32
const PHASES := 4
const DIRECTIONS := 3
const PREVIEW_SCALE := 8

const OUTLINE := Color("1c1a24")
const SUIT_LIGHT := Color("f8f5ee")
const SUIT_MID := Color("dcd5c6")
const SUIT_DARK := Color("a69d8b")
const ORANGE_LIGHT := Color("ffb45e")
const ORANGE_MID := Color("ff7b1c")
const ORANGE_DARK := Color("b44c0e")
const VISOR_LIGHT := Color("ffeaa6")
const VISOR_MID := Color("e6b13e")
const VISOR_DARK := Color("8c6514")


func _initialize() -> void:
	var sheet := Image.create(SIZE * PHASES, SIZE * DIRECTIONS, false, Image.FORMAT_RGBA8)
	for phase in PHASES:
		var frames: Array[Image] = [_front(phase), _back(phase), _side(phase)]
		for row in DIRECTIONS:
			sheet.blit_rect(frames[row], Rect2i(0, 0, SIZE, SIZE), Vector2i(phase * SIZE, row * SIZE))

	var out := ProjectSettings.globalize_path("res://assets/colonist.png")
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	sheet.save_png(out)
	print("saved ", out)

	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		var preview := sheet.duplicate() as Image
		preview.resize(sheet.get_width() * PREVIEW_SCALE, sheet.get_height() * PREVIEW_SCALE, Image.INTERPOLATE_NEAREST)
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
	# Suit torso with an orange chest panel and belt.
	_box(img, 12, 14, 19, 22, SUIT_LIGHT, SUIT_MID, SUIT_DARK)
	Art.rect(img, 14, 16, 17, 18, ORANGE_MID)
	Art.rect(img, 14, 16, 15, 16, ORANGE_LIGHT)
	Art.rect(img, 12, 21, 19, 21, ORANGE_DARK)
	_helmet(img, true)
	return img


func _back(phase: int) -> Image:
	var img := _new_frame()
	_legs_facing_camera(img, phase)
	_arms_facing_camera(img, phase)
	_box(img, 12, 14, 19, 22, SUIT_LIGHT, SUIT_MID, SUIT_DARK)
	# Life-support pack with two oxygen bottles.
	_box(img, 13, 14, 18, 21, ORANGE_LIGHT, ORANGE_MID, ORANGE_DARK)
	Art.rect(img, 14, 15, 14, 20, SUIT_LIGHT)
	Art.rect(img, 17, 15, 17, 20, SUIT_LIGHT)
	_helmet(img, false)
	return img


func _side(phase: int) -> Image:
	var img := _new_frame()

	# Far leg (darker), then near leg. Facing right: swings forward = +x.
	var far_x: int = [14, 17, 14, 11][phase]
	var near_x: int = [15, 11, 15, 17][phase]
	var near_lift := 2 if phase == 1 else 0
	var far_lift := 2 if phase == 3 else 0
	_box(img, far_x, 23 - far_lift, far_x + 2, 27 - far_lift, SUIT_MID, SUIT_DARK, SUIT_DARK)
	Art.rect(img, far_x, 26 - far_lift, far_x + 2, 27 - far_lift, ORANGE_DARK)
	_box(img, near_x, 23 - near_lift, near_x + 2, 27 - near_lift, SUIT_LIGHT, SUIT_MID, SUIT_DARK)
	Art.rect(img, near_x, 26 - near_lift, near_x + 2, 27 - near_lift, ORANGE_MID)

	# Life-support pack on the back (left side), then the torso.
	_box(img, 9, 14, 11, 21, ORANGE_LIGHT, ORANGE_MID, ORANGE_DARK)
	_box(img, 12, 14, 18, 22, SUIT_LIGHT, SUIT_MID, SUIT_DARK)
	Art.rect(img, 12, 21, 18, 21, ORANGE_DARK)

	# Near arm swings opposite to the near leg.
	var arm_dx := 2 if phase == 1 else (-2 if phase == 3 else 0)
	_box(img, 14 + arm_dx, 15, 15 + arm_dx, 21, SUIT_LIGHT, SUIT_MID, SUIT_DARK)
	Art.rect(img, 14 + arm_dx, 21, 15 + arm_dx, 22, ORANGE_MID)

	# Helmet with the visor on the front (right side).
	_shaded_ellipse(img, 16.0, 8.5, 5.5, 5.0, SUIT_LIGHT, SUIT_MID, SUIT_DARK)
	Art.rect(img, 16, 6, 21, 10, OUTLINE)
	Art.rect(img, 17, 7, 21, 9, VISOR_MID)
	Art.rect(img, 17, 7, 18, 7, VISOR_LIGHT)
	Art.rect(img, 19, 9, 21, 9, VISOR_DARK)
	Art.rect(img, 13, 13, 18, 13, ORANGE_MID)
	Art.rect(img, 15, 2, 16, 3, OUTLINE)
	Art.put(img, 15, 2, ORANGE_LIGHT)
	return img


## Round helmet with an orange neck ring; from the front it shows the gold visor.
func _helmet(img: Image, front: bool) -> void:
	_shaded_ellipse(img, 15.5, 8.5, 5.5, 5.0, SUIT_LIGHT, SUIT_MID, SUIT_DARK)
	Art.rect(img, 12, 13, 19, 13, ORANGE_MID)
	if front:
		Art.rect(img, 11, 6, 20, 10, OUTLINE)
		Art.rect(img, 12, 7, 19, 9, VISOR_MID)
		Art.rect(img, 12, 7, 14, 7, VISOR_LIGHT)
		Art.rect(img, 17, 9, 19, 9, VISOR_DARK)
	else:
		Art.rect(img, 13, 6, 18, 6, ORANGE_MID)
	# Helmet lamp.
	Art.rect(img, 15, 2, 16, 3, OUTLINE)
	Art.put(img, 15, 2, ORANGE_LIGHT)


func _legs_facing_camera(img: Image, phase: int) -> void:
	var lifts := _lifts(phase)
	var lift_for := [lifts.x, lifts.y]
	var x_for := [12, 17]
	for i in 2:
		var x0: int = x_for[i]
		var lift: int = lift_for[i]
		_box(img, x0, 23 - lift, x0 + 2, 27 - lift, SUIT_LIGHT, SUIT_MID, SUIT_DARK)
		Art.rect(img, x0, 26 - lift, x0 + 2, 27 - lift, ORANGE_MID)


func _arms_facing_camera(img: Image, phase: int) -> void:
	var swing := _arm_swing(phase)
	_arm(img, 9, swing)
	_arm(img, 21, -swing)


func _arm(img: Image, x0: int, dy: int) -> void:
	_box(img, x0, 15 + dy, x0 + 1, 21 + dy, SUIT_LIGHT, SUIT_MID, SUIT_DARK)
	Art.rect(img, x0, 21 + dy, x0 + 1, 22 + dy, ORANGE_MID)


## Outlined box whose edges are shaded: light on top/left, dark on bottom/right.
func _box(img: Image, x0: int, y0: int, x1: int, y1: int,
		light: Color, mid: Color, dark: Color) -> void:
	Art.box(img, x0, y0, x1, y1, light, mid, dark, OUTLINE)


func _shaded_ellipse(img: Image, cx: float, cy: float, rx: float, ry: float,
		light: Color, mid: Color, dark: Color) -> void:
	Art.shaded_ellipse(img, cx, cy, rx, ry, light, mid, dark, OUTLINE)
