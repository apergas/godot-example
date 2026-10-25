extends Node
## Navigation grid over the whole map: blocked cells, A* paths and free spots next to things.

const APPROACH_MAX_RING := 4

var grid: AStarGrid2D


func _init() -> void:
	reset()


func reset() -> void:
	grid = AStarGrid2D.new()
	grid.region = Rect2i(Vector2i.ZERO, Grid.MAP_SIZE)
	grid.cell_size = Vector2(Grid.TILE, Grid.TILE)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()


func set_blocked(rect: Rect2i, blocked: bool) -> void:
	var area := rect.intersection(grid.region)
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			grid.set_point_solid(Vector2i(x, y), blocked)


func is_area_free(rect: Rect2i) -> bool:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var c := Vector2i(x, y)
			if not Grid.in_map(c) or grid.is_point_solid(c):
				return false
	return true


func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	var from_cell := _clamp_cell(Grid.world_to_cell(from))
	var to_cell := _clamp_cell(Grid.world_to_cell(to))
	var goal := to
	if grid.is_point_solid(to_cell):
		goal = approach_point(Rect2i(to_cell, Vector2i.ONE), from)
		to_cell = Grid.world_to_cell(goal)
	elif not Grid.in_map(Grid.world_to_cell(to)):
		goal = Grid.cell_to_world(to_cell)
	if from_cell == to_cell:
		result.append(goal)
		return result
	var start_solid := grid.is_point_solid(from_cell)
	if start_solid:
		grid.set_point_solid(from_cell, false)
	var cells := grid.get_id_path(from_cell, to_cell, true)
	if start_solid:
		grid.set_point_solid(from_cell, true)
	for i in range(1, cells.size()):
		result.append(Grid.cell_to_world(cells[i]))
	if not result.is_empty() and cells[cells.size() - 1] == to_cell:
		result[result.size() - 1] = goal
	return result


func approach_point(rect: Rect2i, from: Vector2) -> Vector2:
	# Ring 1 is the contract; wider rings only kick in when no adjacent cell is free and reachable.
	var from_cell := _clamp_cell(Grid.world_to_cell(from))
	var fallback := from
	var fallback_dist := INF
	for r in range(1, APPROACH_MAX_RING + 1):
		var ring := rect.grow(r)
		var candidates: Array[Vector2i] = []
		for y in range(ring.position.y, ring.end.y):
			for x in range(ring.position.x, ring.end.x):
				var inside := x > ring.position.x and x < ring.end.x - 1 \
						and y > ring.position.y and y < ring.end.y - 1
				var c := Vector2i(x, y)
				if inside or not Grid.in_map(c) or grid.is_point_solid(c):
					continue
				candidates.append(c)
		candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return Grid.cell_to_world(a).distance_squared_to(from) < Grid.cell_to_world(b).distance_squared_to(from))
		for c in candidates:
			var p := Grid.cell_to_world(c)
			if _reachable(from_cell, c):
				return p
			var d := p.distance_squared_to(from)
			if d < fallback_dist:
				fallback_dist = d
				fallback = p
	# Nothing reachable: keep the closest free cell so callers still get a partial path.
	return fallback


func _reachable(from_cell: Vector2i, to_cell: Vector2i) -> bool:
	if from_cell == to_cell:
		return true
	var start_solid := grid.is_point_solid(from_cell)
	if start_solid:
		grid.set_point_solid(from_cell, false)
	var path := grid.get_id_path(from_cell, to_cell)
	if start_solid:
		grid.set_point_solid(from_cell, true)
	return not path.is_empty()


func _clamp_cell(c: Vector2i) -> Vector2i:
	return Vector2i(clampi(c.x, 0, Grid.MAP_SIZE.x - 1), clampi(c.y, 0, Grid.MAP_SIZE.y - 1))
