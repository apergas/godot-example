extends SceneTree
## Generates assets/crystal.png and assets/ice.png: 4 frames of 32x48 side by side.
## Frames 0..2 are full variants, frame 3 is the "almost depleted" look.
## The ground contact point of every frame is pixel (16, 40); the baked shadow falls down-right.
## Run: tools\godot.cmd --headless --path . --script res://art_src/make_resources.gd [-- preview.png]

const Art := preload("res://art_src/art_lib.gd")

const W := 32
const H := 48
const FRAMES := 4
const BASE_Y := 40
const CENTER_X := 16

const DUST := Color("c96a3a")
const ROCK_LIGHT := Color("7a3d29")
const ROCK_DARK := Color("5e2f22")
const SPARK := Color("ffffff")

# Shards, back to front: [center x, half width, height, lean of the tip in px].
const CRYSTAL_FRAMES := [
	[[16, 3, 26, 0], [10, 2, 18, -3], [22, 2, 20, 3], [13, 2, 11, -1], [20, 2, 12, 1]],
	[[13, 3, 24, -2], [20, 3, 21, 2], [8, 2, 13, -3], [24, 2, 11, 2], [16, 2, 9, 0]],
	[[18, 3, 27, 1], [11, 2, 21, -2], [24, 2, 14, 2], [8, 2, 10, -2], [15, 2, 12, 0]],
	[[13, 2, 8, -1], [19, 2, 6, 1]],
]

# Blocks, back to front: [left x, right x, bottom y, front face height, top face depth].
const ICE_FRAMES := [
	[[6, 25, 40, 13, 6]],
	[[5, 18, 40, 11, 5], [8, 19, 28, 7, 4], [16, 27, 41, 8, 4]],
	[[4, 14, 39, 9, 4], [17, 27, 39, 12, 5], [10, 21, 41, 7, 4]],
	[[9, 22, 40, 5, 3]],
]


func _initialize() -> void:
	var crystal := _sheet(CRYSTAL_FRAMES, _crystal_frame)
	var ice := _sheet(ICE_FRAMES, _ice_frame)
	Art.save(crystal, "res://assets/crystal.png")
	Art.save(ice, "res://assets/ice.png")

	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		# Both sheets on sand, to judge the shadow against the real ground colour.
		var preview := Image.create(W * FRAMES, H * 2, false, Image.FORMAT_RGBA8)
		preview.fill(Art.SAND)
		preview.blend_rect(crystal, Rect2i(0, 0, W * FRAMES, H), Vector2i.ZERO)
		preview.blend_rect(ice, Rect2i(0, 0, W * FRAMES, H), Vector2i(0, H))
		preview.resize(preview.get_width() * 8, preview.get_height() * 8, Image.INTERPOLATE_NEAREST)
		preview.save_png(args[0])
		print("preview ", args[0])
	quit()


func _sheet(frames: Array, draw: Callable) -> Image:
	var sheet := Image.create(W * FRAMES, H, false, Image.FORMAT_RGBA8)
	for i in FRAMES:
		var obj := Image.create(W, H, false, Image.FORMAT_RGBA8)
		draw.call(obj, frames[i])
		sheet.blit_rect(_with_shadow(obj), Rect2i(0, 0, W, H), Vector2i(i * W, 0))
	return sheet


## Contact shadow plus the object's silhouette sheared down-right (length ~ half its height).
func _with_shadow(obj: Image) -> Image:
	var out := Image.create(W, H, false, Image.FORMAT_RGBA8)
	Art.ellipse(out, CENTER_X + 0.5, BASE_Y + 0.5, 12.0, 3.0, Art.SHADOW)
	for y in range(0, BASE_Y + 1):
		for x in W:
			if obj.get_pixel(x, y).a == 0.0:
				continue
			var up := BASE_Y - y
			Art.put(out, x + roundi(up * 0.4), BASE_Y + roundi(up * 0.25), Art.SHADOW)
	out.blend_rect(obj, Rect2i(0, 0, W, H), Vector2i.ZERO)
	return out


func _crystal_frame(img: Image, shards: Array) -> void:
	_mound(img)
	for s in shards:
		_shard(img, s[0], s[1], s[2], s[3])


func _ice_frame(img: Image, blocks: Array) -> void:
	for b in blocks:
		_block(img, b[0], b[1], b[2], b[3], b[4])


## Small rock mound the crystals grow from.
func _mound(img: Image) -> void:
	Art.ellipse(img, CENTER_X + 0.5, BASE_Y - 0.5, 12.0, 4.0, Art.OUTLINE)
	Art.ellipse(img, CENTER_X + 0.5, BASE_Y - 0.5, 11.0, 3.0, ROCK_DARK)
	Art.ellipse(img, CENTER_X - 1.5, BASE_Y - 1.5, 7.0, 2.0, ROCK_LIGHT)


func _shard_mid(cx: int, lean: int, height: int, y: int) -> int:
	return cx + roundi(lean * float(BASE_Y - y) / height)


## Faceted crystal prism with a pointed tip: light facet left, dark facet right.
func _shard(img: Image, cx: int, half_w: int, height: int, lean: int) -> void:
	var top := BASE_Y - height
	var tip := maxi(3, floori(height / 3.0))
	for pass_index in 2:
		for y in range(top, BASE_Y):
			var mid := _shard_mid(cx, lean, height, y)
			var hw := half_w
			if y - top < tip:
				hw = roundi(half_w * float(y - top) / tip)
			if pass_index == 0:
				Art.rect(img, mid - hw - 1, y - 1, mid + hw + 1, y + 1, Art.OUTLINE)
				continue
			for x in range(mid - hw, mid + hw + 1):
				var c := Art.CRYSTAL_MID
				if x < mid:
					c = Art.CRYSTAL_LIGHT
				elif x > mid:
					c = Art.CRYSTAL_DARK
				Art.put(img, x, y, c)
	var spark_y := top + tip + 1
	Art.put(img, _shard_mid(cx, lean, height, spark_y) - 1, spark_y, SPARK)


## Martian ice block in 3/4 view: frosty top face, front face with a crack and red dust at the foot.
func _block(img: Image, x0: int, x1: int, bottom: int, front_h: int, depth: int) -> void:
	var front_top := bottom - front_h + 1
	var top_top := front_top - depth
	Art.rect(img, x0 - 1, top_top - 1, x1 + 1, bottom + 1, Art.OUTLINE)
	for y in range(top_top, front_top):
		for x in range(x0, x1 + 1):
			Art.put(img, x, y, SPARK if (x * 3 + y * 5) % 7 == 0 else Art.ICE_LIGHT)
	for y in range(front_top, bottom + 1):
		for x in range(x0, x1 + 1):
			var c := Art.ICE_MID
			if x == x0:
				c = Art.ICE_LIGHT
			elif x == x1 or y == bottom:
				c = Art.ICE_DARK
			elif (x + 2 * y) % 9 == 0:
				c = Art.ICE_LIGHT
			Art.put(img, x, y, c)
	Art.rect(img, x0, front_top, x1, front_top, SPARK)
	if front_h >= 8:
		for i in 4:
			Art.put(img, x0 + 3 + i, front_top + 2 + i, Art.ICE_DARK)
	for x in range(x0 + 1, x1, 2):
		Art.put(img, x, bottom, DUST)


