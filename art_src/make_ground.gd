extends SceneTree
## Generates assets/ground_tiles.png: a 4x4 atlas of 32x32 Mars ground tiles.
## Row 0: sand variants 0..3. Row 1: rock 0, rock 1, pebbles 0, pebbles 1.
## Rows 2-3, columns 0-1: one 2x2 crater split into four tiles. Other cells stay empty.
## Every tile keeps its features away from the edges so any two tiles can sit side by side.
## Run: tools\godot.cmd --headless --path . --script res://art_src/make_ground.gd [-- preview.png]
## The preview shows the atlas at 8x (left) and a 12x8 tile sample at 4x (right).

const SIZE := 32
const COLUMNS := 4
const ROWS := 4

const SAND_MID := Color("b5532c")
const SAND_LIGHT := Color("c96a3a")
const SAND_DARK := Color("9a4424")
const SAND_HIGHLIGHT := Color("d98552")
const ROCK_DARK := Color("5e2f22")
const ROCK_LIGHT := Color("7a3d29")
const SHADOW := Color("2a120c")
const SHADOW_ALPHA := 0.35

# Sand speckle thresholds over a uniform random value per pixel.
const DARK_BELOW := 0.14
const LIGHT_ABOVE := 0.80
const HIGHLIGHT_ABOVE := 0.97

const ROCK_A: Array[Rect2i] = [
	Rect2i(1, 1, 13, 11),
	Rect2i(16, 1, 15, 8),
	Rect2i(16, 11, 15, 9),
	Rect2i(1, 14, 12, 17),
	Rect2i(15, 22, 16, 9),
]
const ROCK_B: Array[Rect2i] = [
	Rect2i(1, 1, 9, 9),
	Rect2i(12, 1, 19, 12),
	Rect2i(1, 12, 9, 19),
	Rect2i(12, 15, 10, 16),
	Rect2i(24, 15, 7, 16),
]
const PEBBLES_A: Array[Vector2i] = [
	Vector2i(5, 6), Vector2i(14, 4), Vector2i(24, 9), Vector2i(9, 17),
	Vector2i(20, 20), Vector2i(27, 25), Vector2i(6, 26),
]
const PEBBLES_B: Array[Vector2i] = [
	Vector2i(4, 12), Vector2i(12, 8), Vector2i(18, 15),
	Vector2i(26, 5), Vector2i(15, 25), Vector2i(24, 22),
]


func _initialize() -> void:
	var atlas := Image.create(SIZE * COLUMNS, SIZE * ROWS, false, Image.FORMAT_RGBA8)
	for variant in 4:
		_sand(atlas, Vector2i(variant, 0) * SIZE, variant)
	_rock(atlas, Vector2i(0, 1) * SIZE, ROCK_A, 201)
	_rock(atlas, Vector2i(1, 1) * SIZE, ROCK_B, 202)
	_pebbles(atlas, Vector2i(2, 1) * SIZE, PEBBLES_A, 211)
	_pebbles(atlas, Vector2i(3, 1) * SIZE, PEBBLES_B, 212)
	_crater(atlas, Vector2i(0, 2) * SIZE)

	var out := ProjectSettings.globalize_path("res://assets/ground_tiles.png")
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	atlas.save_png(out)
	print("saved ", out)

	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_preview(atlas).save_png(args[0])
		print("preview ", args[0])
	quit()


func _sand_noise(img: Image, origin: Vector2i, size: int, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for y in size:
		for x in size:
			var t := rng.randf()
			var color := SAND_MID
			if t < DARK_BELOW:
				color = SAND_DARK
			elif t > HIGHLIGHT_ABOVE:
				color = SAND_HIGHLIGHT
			elif t > LIGHT_ABOVE:
				color = SAND_LIGHT
			img.set_pixel(origin.x + x, origin.y + y, color)


func _sand(img: Image, origin: Vector2i, variant: int) -> void:
	_sand_noise(img, origin, SIZE, 100 + variant)
	match variant:
		1:
			# Wind ripples: a light crest with a dark trough under it.
			for row in [8, 17, 25]:
				for x in range(3, 29):
					var y: int = row + (1 if int(x / 4.0) % 2 == 0 else 0)
					img.set_pixel(origin.x + x, origin.y + y, SAND_LIGHT)
					img.set_pixel(origin.x + x, origin.y + y + 1, SAND_DARK)
		2:
			for p in [Vector2i(7, 8), Vector2i(22, 14), Vector2i(12, 24)]:
				_grain(img, origin + p)
		3:
			# Darker oxide stain in the middle of the tile.
			var rng := RandomNumberGenerator.new()
			rng.seed = 200
			for y in SIZE:
				for x in SIZE:
					var dx := (x + 0.5 - 16.0) / 10.0
					var dy := (y + 0.5 - 16.0) / 6.0
					if dx * dx + dy * dy <= 1.0 and rng.randf() < 0.45:
						img.set_pixel(origin.x + x, origin.y + y, SAND_DARK)


## Flat rock plates: lit top/left edge, shadowed bottom/right edge, dark grout between them.
func _rock(img: Image, origin: Vector2i, plates: Array[Rect2i], seed_value: int) -> void:
	for y in SIZE:
		for x in SIZE:
			img.set_pixel(origin.x + x, origin.y + y, ROCK_DARK)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for plate in plates:
		for y in range(plate.position.y, plate.end.y):
			for x in range(plate.position.x, plate.end.x):
				var color := ROCK_LIGHT
				if x == plate.position.x or y == plate.position.y:
					color = SAND_DARK
				elif x == plate.end.x - 1 or y == plate.end.y - 1:
					color = SHADOW
				elif rng.randf() < 0.12:
					color = ROCK_DARK
				img.set_pixel(origin.x + x, origin.y + y, color)


func _pebbles(img: Image, origin: Vector2i, spots: Array[Vector2i], seed_value: int) -> void:
	_sand_noise(img, origin, SIZE, seed_value)
	for spot in spots:
		_grain(img, origin + spot)


## A 2x2 stone lit from the top-left, with its shadow baked towards the bottom-right.
func _grain(img: Image, p: Vector2i) -> void:
	_shade(img, p + Vector2i(2, 1))
	_shade(img, p + Vector2i(1, 2))
	_shade(img, p + Vector2i(2, 2))
	img.set_pixel(p.x, p.y, SAND_HIGHLIGHT)
	img.set_pixel(p.x + 1, p.y, ROCK_LIGHT)
	img.set_pixel(p.x, p.y + 1, ROCK_LIGHT)
	img.set_pixel(p.x + 1, p.y + 1, ROCK_DARK)


func _shade(img: Image, p: Vector2i) -> void:
	img.set_pixelv(p, img.get_pixelv(p).lerp(Color.BLACK, SHADOW_ALPHA))


## A 64x64 crater seen in 3/4 view: flattened bowl, raised rim, light from the top-left.
func _crater(img: Image, origin: Vector2i) -> void:
	var span := SIZE * 2
	_sand_noise(img, origin, span, 300)
	var rng := RandomNumberGenerator.new()
	rng.seed = 301
	var center := Vector2(span / 2.0, span / 2.0 + 1.0)
	var radii := Vector2(26.0, 18.0)
	for y in span:
		for x in span:
			var p := Vector2i(origin.x + x, origin.y + y)
			var d := (Vector2(x + 0.5, y + 0.5) - center) / radii
			var r := d.length()
			# Positive towards the top-left, where the light comes from.
			var t := -0.6 * d.x - 0.8 * d.y
			if r < 0.78:
				# Inside the bowl the top-left wall faces away from the light.
				var color := SAND_DARK
				if t > 0.45:
					color = ROCK_DARK
				elif t > 0.15:
					color = ROCK_LIGHT
				elif t < -0.4:
					color = SAND_LIGHT
				elif rng.randf() < 0.1:
					color = ROCK_LIGHT
				img.set_pixelv(p, color)
			elif r < 1.0:
				img.set_pixelv(p, SAND_HIGHLIGHT if t > 0.0 else SAND_LIGHT)
			elif r < 1.14:
				if t > 0.2:
					img.set_pixelv(p, SAND_LIGHT)
				elif t < -0.2:
					_shade(img, p)


func _preview(atlas: Image) -> Image:
	var big := atlas.duplicate() as Image
	big.resize(atlas.get_width() * 8, atlas.get_height() * 8, Image.INTERPOLATE_NEAREST)

	# A small patch of ground built from the atlas, to look for seams between tiles.
	var sample := Image.create(SIZE * 12, SIZE * 8, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for y in 8:
		for x in 12:
			var tile := Vector2i(rng.randi() % 4, 0)
			if x >= 1 and x <= 4 and y >= 1 and y <= 3:
				tile = Vector2i(x % 2, 1)
			elif rng.randf() < 0.08:
				tile = Vector2i(2 + rng.randi() % 2, 1)
			sample.blit_rect(atlas, Rect2i(tile * SIZE, Vector2i(SIZE, SIZE)), Vector2i(x, y) * SIZE)
	sample.blit_rect(atlas, Rect2i(0, 2 * SIZE, 2 * SIZE, 2 * SIZE), Vector2i(7, 4) * SIZE)
	sample.resize(sample.get_width() * 4, sample.get_height() * 4, Image.INTERPOLATE_NEAREST)

	var out := Image.create(big.get_width() + sample.get_width(),
			maxi(big.get_height(), sample.get_height()), false, Image.FORMAT_RGBA8)
	out.fill(Color("202020"))
	out.blit_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i.ZERO)
	out.blit_rect(sample, Rect2i(Vector2i.ZERO, sample.get_size()), Vector2i(big.get_width(), 0))
	return out
