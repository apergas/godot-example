class_name Grid
extends RefCounted
## Static helpers to convert between map cells and world positions.
## 1 cell = 32 px art shown at 2x = 64 px of world.

const TILE := 64
const MAP_SIZE := Vector2i(64, 48)


static func world_to_cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / TILE), floori(p.y / TILE))


static func cell_to_world(c: Vector2i) -> Vector2:
	return Vector2((c.x + 0.5) * TILE, (c.y + 0.5) * TILE)


static func map_rect_world() -> Rect2:
	return Rect2(0.0, 0.0, MAP_SIZE.x * TILE, MAP_SIZE.y * TILE)


static func in_map(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < MAP_SIZE.x and c.y < MAP_SIZE.y


## Bottom-centre point of a footprint of `size` cells whose top-left cell is `cell`.
static func footprint_origin(cell: Vector2i, size: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + size.x * TILE / 2.0, (cell.y + size.y) * TILE)


## Inverse of footprint_origin().
static func footprint_cell(origin: Vector2, size: Vector2i) -> Vector2i:
	return Vector2i(roundi(origin.x / TILE - size.x / 2.0), roundi(origin.y / TILE) - size.y)
