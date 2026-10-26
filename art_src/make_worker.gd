extends SceneTree
## Generates assets/worker.png: a 4x3 sheet of 32x32 three-quarter view robot frames.
## Columns: walk cycle phase 0..3 (0 and 2 are the idle/standing pose).
## Rows: 0 = facing down (front), 1 = facing up (back), 2 = facing right (mirror for left).
## Run: tools\godot.cmd --headless --path . --script res://art_src/make_worker.gd [-- preview.png]

const Art := preload("res://art_src/art_lib.gd")

const SIZE := 32
const PHASES := 4
const DIRECTIONS := 3


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
	Art.box(img, 10, 15, 21, 23, Art.BODY_LIGHT, Art.BODY_MID, Art.BODY_DARK)
	Art.rect(img, 13, 17, 18, 20, Art.OUTLINE)
	Art.rect(img, 14, 18, 17, 19, Art.BODY_DARK)
	Art.rect(img, 15, 18, 16, 19, Art.ACCENT_LIGHT)

	_antenna(img, 16)

	# Head (dome) with a visor across the face.
	Art.shaded_ellipse(img, 16.0, 9.5, 6.5, 5.5, Art.BODY_LIGHT, Art.BODY_MID, Art.BODY_DARK)
	Art.rect(img, 10, 7, 21, 11, Art.OUTLINE)
	Art.rect(img, 11, 8, 20, 10, Art.VISOR_MID)
	Art.rect(img, 11, 8, 14, 8, Art.VISOR_LIGHT)
	Art.rect(img, 17, 10, 20, 10, Art.VISOR_DARK)
	return img


func _back(phase: int) -> Image:
	var img := _new_frame()
	_legs_facing_camera(img, phase)
	_arms_facing_camera(img, phase)

	# Torso with a big backpack.
	Art.box(img, 10, 15, 21, 23, Art.BODY_LIGHT, Art.BODY_MID, Art.BODY_DARK)
	Art.box(img, 12, 16, 19, 22, Art.ACCENT_LIGHT, Art.ACCENT_MID, Art.ACCENT_DARK)
	Art.rect(img, 12, 19, 19, 19, Art.ACCENT_DARK)
	Art.rect(img, 15, 17, 16, 18, Art.ACCENT_DARK)

	_antenna(img, 16)

	# Head seen from behind: no visor, just a vent.
	Art.shaded_ellipse(img, 16.0, 9.5, 6.5, 5.5, Art.BODY_LIGHT, Art.BODY_MID, Art.BODY_DARK)
	Art.rect(img, 13, 9, 18, 9, Art.OUTLINE)
	Art.rect(img, 13, 11, 18, 11, Art.BODY_DARK)
	return img


func _side(phase: int) -> Image:
	var img := _new_frame()

	# Far leg (darker), then near leg. Facing right: swings forward = +x.
	var far_x: int = [14, 17, 14, 11][phase]
	var near_x: int = [16, 11, 16, 17][phase]
	var near_lift := 2 if phase == 1 else 0
	var far_lift := 2 if phase == 3 else 0
	Art.box(img, far_x, 24 - far_lift, far_x + 3, 27 - far_lift, Art.BODY_MID, Art.BODY_DARK, Art.BODY_DARK)
	Art.rect(img, far_x, 27 - far_lift, far_x + 3, 27 - far_lift, Art.ACCENT_DARK)
	Art.box(img, near_x, 24 - near_lift, near_x + 3, 27 - near_lift, Art.BODY_LIGHT, Art.BODY_MID, Art.BODY_DARK)
	Art.rect(img, near_x, 27 - near_lift, near_x + 3, 27 - near_lift, Art.ACCENT_MID)

	# Backpack on the back (left side).
	Art.box(img, 8, 15, 12, 22, Art.ACCENT_LIGHT, Art.ACCENT_MID, Art.ACCENT_DARK)

	# Torso.
	Art.box(img, 12, 15, 20, 23, Art.BODY_LIGHT, Art.BODY_MID, Art.BODY_DARK)

	# Near arm swings opposite to the near leg.
	var arm_dx := 2 if phase == 1 else (-2 if phase == 3 else 0)
	Art.box(img, 14 + arm_dx, 15, 16 + arm_dx, 22, Art.BODY_LIGHT, Art.BODY_MID, Art.BODY_DARK)
	Art.box(img, 14 + arm_dx, 22, 16 + arm_dx, 24, Art.ACCENT_LIGHT, Art.ACCENT_MID, Art.ACCENT_DARK)

	_antenna(img, 17)

	# Head with the visor on the front (right side).
	Art.shaded_ellipse(img, 17.0, 9.5, 6.0, 5.5, Art.BODY_LIGHT, Art.BODY_MID, Art.BODY_DARK)
	Art.rect(img, 16, 7, 23, 11, Art.OUTLINE)
	Art.rect(img, 17, 8, 22, 10, Art.VISOR_MID)
	Art.rect(img, 17, 8, 19, 8, Art.VISOR_LIGHT)
	Art.rect(img, 20, 10, 22, 10, Art.VISOR_DARK)
	return img


func _legs_facing_camera(img: Image, phase: int) -> void:
	var lifts := _lifts(phase)
	var lift_for := [lifts.x, lifts.y]
	var x_for := [11, 17]
	for i in 2:
		var x0: int = x_for[i]
		var lift: int = lift_for[i]
		Art.box(img, x0, 24 - lift, x0 + 3, 27 - lift, Art.BODY_LIGHT, Art.BODY_MID, Art.BODY_DARK)
		Art.rect(img, x0, 27 - lift, x0 + 3, 27 - lift, Art.ACCENT_MID)


func _arms_facing_camera(img: Image, phase: int) -> void:
	var swing := _arm_swing(phase)
	_arm(img, 5, swing)
	_arm(img, 24, -swing)


func _arm(img: Image, x0: int, dy: int) -> void:
	Art.box(img, x0, 15 + dy, x0 + 2, 22 + dy, Art.BODY_LIGHT, Art.BODY_MID, Art.BODY_DARK)
	Art.box(img, x0, 22 + dy, x0 + 2, 24 + dy, Art.ACCENT_LIGHT, Art.ACCENT_MID, Art.ACCENT_DARK)


func _antenna(img: Image, x: int) -> void:
	Art.rect(img, x - 2, 0, x + 1, 3, Art.OUTLINE)
	Art.rect(img, x - 1, 1, x, 2, Art.ACCENT_LIGHT)


## Outlined box whose edges are shaded: light on top/left, dark on bottom/right.


