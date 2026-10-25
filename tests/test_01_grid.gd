extends SceneTree

var _failed := 0


func _initialize() -> void:
	await process_frame
	_check("TILE", Grid.TILE == 64, str(Grid.TILE))
	_check("MAP_SIZE", Grid.MAP_SIZE == Vector2i(64, 48), str(Grid.MAP_SIZE))
	_check("world_to_cell origin", Grid.world_to_cell(Vector2.ZERO) == Vector2i.ZERO)
	_check("world_to_cell inside first cell", Grid.world_to_cell(Vector2(63.9, 63.9)) == Vector2i.ZERO)
	_check("world_to_cell next cells", Grid.world_to_cell(Vector2(64, 128)) == Vector2i(1, 2))
	_check("world_to_cell floors negatives", Grid.world_to_cell(Vector2(-1, -0.5)) == Vector2i(-1, -1))
	_check("cell_to_world centre", Grid.cell_to_world(Vector2i.ZERO) == Vector2(32, 32),
			str(Grid.cell_to_world(Vector2i.ZERO)))
	_check("cell_to_world HQ cell", Grid.cell_to_world(Vector2i(10, 21)) == Vector2(672, 1376),
			str(Grid.cell_to_world(Vector2i(10, 21))))
	_check("cell round trip", Grid.world_to_cell(Grid.cell_to_world(Vector2i(37, 5))) == Vector2i(37, 5))
	_check("map_rect_world", Grid.map_rect_world() == Rect2(0, 0, 4096, 3072), str(Grid.map_rect_world()))
	_check("in_map corners", Grid.in_map(Vector2i(0, 0)) and Grid.in_map(Vector2i(63, 47)))
	_check("in_map outside", not (Grid.in_map(Vector2i(64, 0)) or Grid.in_map(Vector2i(0, 48))
			or Grid.in_map(Vector2i(-1, 5)) or Grid.in_map(Vector2i(5, -1))))
	_check("footprint_origin 3x3", Grid.footprint_origin(Vector2i(10, 21), Vector2i(3, 3)) == Vector2(736, 1536),
			str(Grid.footprint_origin(Vector2i(10, 21), Vector2i(3, 3))))
	_check("footprint_origin 2x2", Grid.footprint_origin(Vector2i(5, 7), Vector2i(2, 2)) == Vector2(384, 576),
			str(Grid.footprint_origin(Vector2i(5, 7), Vector2i(2, 2))))
	_check("footprint_cell inverse 3x3", Grid.footprint_cell(Vector2(736, 1536), Vector2i(3, 3)) == Vector2i(10, 21))
	_check("footprint_cell inverse 2x2", Grid.footprint_cell(Vector2(384, 576), Vector2i(2, 2)) == Vector2i(5, 7))
	_check("footprint_cell tolerates drift", Grid.footprint_cell(Vector2(387, 571), Vector2i(2, 2)) == Vector2i(5, 7))
	quit(1 if _failed > 0 else 0)


func _check(test_name: String, ok: bool, detail: String = "") -> void:
	if ok:
		print("PASS ", test_name)
	else:
		_failed += 1
		print("FAIL ", test_name, ": ", detail)
