extends RefCounted
## Helpers and palette shared by the sprite generators (art_src/make_*.gd).
## Loaded with: const Art := preload("res://art_src/art_lib.gd")

# Palette shared by several generators.
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
const PAD_LIGHT := Color("6b7f96")
const PAD_MID := Color("4b5d73")
const PAD_DARK := Color("2f3c4d")
const HULL_LIGHT := Color("f4f6f8")
const HULL_MID := Color("c9d1da")
const HULL_DARK := Color("8a97a6")
const CRYSTAL_LIGHT := Color("a8fbff")
const CRYSTAL_MID := Color("38d8f0")
const CRYSTAL_DARK := Color("0f6e86")
const ICE_LIGHT := Color("e8f6ff")
const ICE_MID := Color("b8dcf0")
const ICE_DARK := Color("6fa3c4")
const SAND := Color("b5532c")
const SHADOW := Color(0.0, 0.0, 0.0, 0.35)


## Sets a pixel, ignoring coordinates outside the image.
static func put(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, color)


static func rect(img: Image, x0: int, y0: int, x1: int, y1: int, color: Color) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			put(img, x, y, color)


## Filled rectangle with a 1 px outline, light top/left edges and dark bottom/right edges.
static func box(img: Image, x0: int, y0: int, x1: int, y1: int,
		light: Color, mid: Color, dark: Color, outline: Color = OUTLINE) -> void:
	rect(img, x0 - 1, y0 - 1, x1 + 1, y1 + 1, outline)
	rect(img, x0, y0, x1, y1, mid)
	rect(img, x0, y0, x1, y0, light)
	rect(img, x0, y0, x0, y1, light)
	rect(img, x0, y1, x1, y1, dark)
	rect(img, x1, y0, x1, y1, dark)


static func ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, color: Color) -> void:
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				put(img, x, y, color)


## Outlined ellipse lit from the top-left (img must be the full frame; used by the 32x32 characters).
static func shaded_ellipse(img: Image, cx: float, cy: float, rx: float, ry: float,
		light: Color, mid: Color, dark: Color, outline: Color = OUTLINE) -> void:
	ellipse(img, cx, cy, rx + 1.0, ry + 1.0, outline)
	for y in img.get_height():
		for x in img.get_width():
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy > 1.0:
				continue
			# Light comes from the top-left.
			var t := -0.6 * dx - 0.8 * dy
			img.set_pixel(x, y, light if t > 0.4 else (dark if t < -0.45 else mid))


## Drops the shadow of a vertical object down-right (one row of the shadow layer per height step).
static func cast_shadow(shadow: Image, x0: int, x1: int, y_top: int, y_base: int) -> void:
	for h in y_base - y_top + 1:
		var dx := int(h * 0.5)
		var dy := int(h * 0.25)
		for x in range(x0, x1 + 1):
			put(shadow, x + dx, y_base + dy, SHADOW)


## Light / mid / dark tone of column x across a cylinder spanning x0..x1.
static func shade(x: int, x0: int, x1: int, light: Color, mid: Color, dark: Color) -> Color:
	var t := (x - x0 + 0.5) / float(x1 - x0 + 1)
	return light if t < 0.3 else (dark if t > 0.72 else mid)


static func save(img: Image, path: String) -> void:
	var out := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	img.save_png(out)
	print("saved ", out)
