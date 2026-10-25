class_name Formation
extends RefCounted


## count distinct points of a square grid with the given spacing, from the centre outwards.
static func offsets(count: int, spacing: float) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if count <= 0:
		return result
	var radius := 0
	while (2 * radius + 1) * (2 * radius + 1) < count:
		radius += 1
	var cells: Array[Vector2i] = []
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			cells.append(Vector2i(x, y))
	var closer := func(a: Vector2i, b: Vector2i) -> bool:
		var la := a.length_squared()
		var lb := b.length_squared()
		if la != lb:
			return la < lb
		return Vector2(a).angle() < Vector2(b).angle()
	cells.sort_custom(closer)
	for i in count:
		result.append(Vector2(cells[i]) * spacing)
	return result


static func targets(center: Vector2, count: int, spacing: float) -> Array[Vector2]:
	var bounds := Grid.map_rect_world().grow(-Grid.TILE / 2.0)
	var result: Array[Vector2] = []
	for offset in offsets(count, spacing):
		result.append((center + offset).clamp(bounds.position, bounds.end))
	return result
