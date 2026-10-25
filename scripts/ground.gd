extends TileMapLayer
## Paints the whole map from MapLayout with a deterministic variation (MapLayout.SEED).
## Purely decorative: no collision, every cell is walkable.

const SOURCE_ID := 0
const SAND: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
const ROCKS: Array[Vector2i] = [Vector2i(0, 1), Vector2i(1, 1)]
const PEBBLES: Array[Vector2i] = [Vector2i(2, 1), Vector2i(3, 1)]
const CRATER_ORIGIN := Vector2i(0, 2)
const PEBBLE_CHANCE := 0.04
const PLAIN_SAND_CHANCE := 0.55


func _ready() -> void:
	paint()


func paint() -> void:
	clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = MapLayout.SEED
	for y in Grid.MAP_SIZE.y:
		for x in Grid.MAP_SIZE.x:
			var cell := Vector2i(x, y)
			set_cell(cell, SOURCE_ID, _pick_tile(cell, rng))
	for crater in MapLayout.CRATERS:
		for dy in 2:
			for dx in 2:
				var quad := Vector2i(dx, dy)
				set_cell(crater + quad, SOURCE_ID, CRATER_ORIGIN + quad)


func _pick_tile(cell: Vector2i, rng: RandomNumberGenerator) -> Vector2i:
	var roll := rng.randf()
	if _in_rock(cell):
		return ROCKS[0] if roll < 0.6 else ROCKS[1]
	if roll < PEBBLE_CHANCE:
		return PEBBLES[rng.randi() % PEBBLES.size()]
	if roll < PLAIN_SAND_CHANCE:
		return SAND[0]
	return SAND[1 + rng.randi() % 3]


func _in_rock(cell: Vector2i) -> bool:
	for patch in MapLayout.ROCK_PATCHES:
		if patch.has_point(cell):
			return true
	return false
