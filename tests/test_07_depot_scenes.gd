extends SceneTree

const Sim := preload("res://tests/sim_helpers.gd")
const CRYSTAL_DEPOT := "res://scenes/buildings/crystal_depot.tscn"
const ICE_DEPOT := "res://scenes/buildings/ice_depot.tscn"

var _failed := false
var _completed_count := 0


func _initialize() -> void:
	await process_frame
	await _check_depot(CRYSTAL_DEPOT, ResKind.CRYSTAL, ResKind.ICE, "res://assets/crystal_depot.png")
	await _check_depot(ICE_DEPOT, ResKind.ICE, ResKind.CRYSTAL, "res://assets/ice_depot.png")
	quit(1 if _failed else 0)


func _check(ok: bool, test_name: String, reason: String) -> void:
	if ok:
		print("PASS ", test_name)
	else:
		print("FAIL ", test_name, ": ", reason)
		_failed = true


func _on_completed() -> void:
	_completed_count += 1


func _check_depot(path: String, kind: int, other: int, texture_path: String) -> void:
	var tag := path.get_file().get_basename()
	_check(ResourceLoader.exists(path), tag + "_exists", "missing " + path)
	if not ResourceLoader.exists(path):
		return
	var world := Sim.new_world(self)
	var depot := Sim.add_building(world, path, Vector2i(10, 10))
	await process_frame

	_check(depot.footprint == Vector2i(2, 2), tag + "_footprint", str(depot.footprint))
	_check(depot.accepts_kinds.size() == 1 and depot.accepts_kinds[0] == kind,
			tag + "_accepts_kinds", str(depot.accepts_kinds))
	_check(is_equal_approx(depot.build_time, 15.0), tag + "_build_time", str(depot.build_time))
	_check(depot.cost.size() == 1 and int(depot.cost.get(ResKind.CRYSTAL, 0)) == 100,
			tag + "_cost", str(depot.cost))
	_check(depot.is_in_group("buildings") and depot.is_in_group("dropoffs"), tag + "_groups",
			"groups " + str(depot.get_groups()))
	_check(depot.cell_rect() == Rect2i(Vector2i(10, 10), Vector2i(2, 2)), tag + "_cell_rect",
			str(depot.cell_rect()))
	_check(not Sim.nav(self).is_area_free(depot.cell_rect()), tag + "_blocks_nav", "cells still free")
	_check(depot.built and depot.accepts(kind) and not depot.accepts(other),
			tag + "_accepts_only_its_kind", "built=%s" % depot.built)

	var sprite := depot.get_node("Sprite2D") as Sprite2D
	_check(sprite.texture != null and sprite.texture.resource_path == texture_path,
			tag + "_texture", str(sprite.texture))
	_check(sprite.hframes == 2 and not sprite.centered and sprite.offset == Vector2(-32, -96)
			and sprite.scale == Vector2(2, 2), tag + "_sprite_layout",
			"hframes=%d offset=%s" % [sprite.hframes, sprite.offset])

	_completed_count = 0
	depot.completed.connect(_on_completed)
	depot.start_construction()
	_check(not depot.built and not depot.accepts(kind), tag + "_unfinished_rejects",
			"built=%s" % depot.built)
	_check(sprite.frame == 1, tag + "_scaffold_frame", "frame %d" % sprite.frame)
	depot.add_build_progress(16.0)
	_check(_completed_count == 1 and depot.built and depot.accepts(kind), tag + "_completes",
			"completed=%d built=%s" % [_completed_count, depot.built])
	_check(sprite.frame == 0, tag + "_finished_frame", "frame %d" % sprite.frame)
	Sim.free_world(world)
