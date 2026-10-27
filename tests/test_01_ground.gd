extends SceneTree

const SAND_TILES: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
const ROCK_TILES: Array[Vector2i] = [Vector2i(0, 1), Vector2i(1, 1)]
const PEBBLE_TILES: Array[Vector2i] = [Vector2i(2, 1), Vector2i(3, 1)]
const CRATER_ORIGIN := Vector2i(0, 2)

var _failed := 0


func _initialize() -> void:
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	var ground := main.get_node_or_null("Ground") as TileMapLayer
	_check("Ground is a TileMapLayer", ground != null)
	if ground == null:
		quit(1)
		return

	_check("z_index -10", ground.z_index == -10, str(ground.z_index))
	_check("scale 2", ground.scale == Vector2(2, 2), str(ground.scale))
	var atlas := ground.tile_set.get_source(0) as TileSetAtlasSource
	_check("atlas source 0 has the crater", atlas != null and atlas.has_tile(Vector2i(1, 3)))

	var cells := ground.get_used_cells()
	_check("every cell painted", cells.size() == Grid.MAP_SIZE.x * Grid.MAP_SIZE.y, str(cells.size()))
	_check("used rect is the map", ground.get_used_rect() == Rect2i(Vector2i.ZERO, Grid.MAP_SIZE),
			str(ground.get_used_rect()))
	var wrong_source := 0
	for c in cells:
		if ground.get_cell_source_id(c) != 0:
			wrong_source += 1
	_check("all cells use source 0", wrong_source == 0, str(wrong_source))

	var tile_world := Vector2(ground.tile_set.tile_size) * ground.scale
	var world_rect := Rect2(ground.to_global(Vector2.ZERO), Vector2(Grid.MAP_SIZE) * tile_world)
	_check("world size matches Grid.map_rect_world()", world_rect == Grid.map_rect_world(), str(world_rect))
	for c in [Vector2i(0, 0), Vector2i(10, 21), Vector2i(63, 47)]:
		var center := ground.to_global(ground.map_to_local(c))
		_check("cell %s centre matches Grid" % c, center == Grid.cell_to_world(c), str(center))
	var probe := Vector2(1000.5, 2047.9)
	_check("local_to_map matches Grid.world_to_cell",
			ground.local_to_map(ground.to_local(probe)) == Grid.world_to_cell(probe))

	var bad_rock := 0
	for patch in MapLayout.ROCK_PATCHES:
		for y in range(patch.position.y, patch.end.y):
			for x in range(patch.position.x, patch.end.x):
				if not ROCK_TILES.has(ground.get_cell_atlas_coords(Vector2i(x, y))):
					bad_rock += 1
	_check("rock patches painted with rock", bad_rock == 0, str(bad_rock))

	var bad_crater := 0
	for crater in MapLayout.CRATERS:
		for dy in 2:
			for dx in 2:
				var quad := Vector2i(dx, dy)
				if ground.get_cell_atlas_coords(crater + quad) != CRATER_ORIGIN + quad:
					bad_crater += 1
	_check("craters painted as 2x2", bad_crater == 0, str(bad_crater))

	var seen := {}
	for c in cells:
		seen[ground.get_cell_atlas_coords(c)] = true
	var sand_variants := 0
	for coords in SAND_TILES:
		if seen.has(coords):
			sand_variants += 1
	_check("all four sand variants used", sand_variants == 4, str(sand_variants))
	_check("pebbles used", seen.has(PEBBLE_TILES[0]) or seen.has(PEBBLE_TILES[1]))

	var before := _snapshot(ground)
	ground.call("paint")
	_check("paint is deterministic", _snapshot(ground) == before)
	quit(1 if _failed > 0 else 0)


func _snapshot(ground: TileMapLayer) -> Array:
	var tiles := []
	for y in Grid.MAP_SIZE.y:
		for x in Grid.MAP_SIZE.x:
			tiles.append(ground.get_cell_atlas_coords(Vector2i(x, y)))
	return tiles


func _check(test_name: String, ok: bool, detail: String = "") -> void:
	if ok:
		print("PASS ", test_name)
	else:
		_failed += 1
		print("FAIL ", test_name, ": ", detail)
