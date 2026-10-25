extends SceneTree

const NavScript := preload("res://scripts/nav.gd")

var _failed := false


func _initialize() -> void:
	await process_frame
	var nav := root.get_node("Nav") as NavScript
	nav.reset()
	var hq := (load("res://scenes/buildings/hq.tscn") as PackedScene).instantiate() as Building
	hq.position = Grid.footprint_origin(Vector2i(10, 21), hq.footprint)
	root.add_child(hq)
	await process_frame

	_check(hq is HQ, "hq_class", "scene root is not an HQ")
	_check(hq.footprint == Vector2i(3, 3), "hq_footprint", str(hq.footprint))
	_check(hq.cell == Vector2i(10, 21), "hq_cell", str(hq.cell))
	_check(hq.cell_rect() == Rect2i(10, 21, 3, 3), "hq_cell_rect", str(hq.cell_rect()))
	_check(hq.is_in_group("buildings") and hq.is_in_group("dropoffs"), "hq_groups", str(hq.get_groups()))
	_check(not nav.is_area_free(Rect2i(10, 21, 1, 1)) and not nav.is_area_free(Rect2i(12, 23, 1, 1)),
			"hq_blocks_footprint", "footprint corners free")
	_check(nav.is_area_free(Rect2i(13, 21, 1, 3)) and nav.is_area_free(Rect2i(10, 24, 3, 1)),
			"hq_blocks_only_footprint", "cells next to the HQ blocked")
	_check(hq.accepts(ResKind.CRYSTAL) and hq.accepts(ResKind.ICE), "hq_accepts_both", str(hq.accepts_kinds))

	_check(hq.contains_point(hq.global_position + Vector2(0.0, -Grid.TILE * 1.5)), "pick_footprint", "")
	_check(hq.contains_point(hq.global_position + Vector2(0.0, -240.0)), "pick_tower", "")
	_check(not hq.contains_point(hq.global_position + Vector2(200.0, -96.0)), "pick_outside", "")

	var sprite := hq.get_node("Sprite2D") as Sprite2D
	_check(not sprite.centered and sprite.offset == Vector2(-48, -128) and sprite.scale == Vector2(2, 2),
			"sprite_anchor", "centered=%s offset=%s scale=%s" % [sprite.centered, sprite.offset, sprite.scale])
	_check(sprite.texture != null and sprite.texture.get_size() == Vector2(104, 132),
			"hq_texture", "missing or wrong size texture")

	hq.built = false
	_check(not hq.accepts(ResKind.CRYSTAL), "unbuilt_rejects", "unbuilt building accepts resources")
	hq.built = true

	hq.queue_free()
	await process_frame
	_check(nav.is_area_free(Rect2i(10, 21, 3, 3)), "free_on_exit", "footprint still blocked after free")
	quit(1 if _failed else 0)


func _check(ok: bool, name: String, why: String) -> void:
	if ok:
		print("PASS ", name)
	else:
		print("FAIL ", name, ": ", why)
		_failed = true
