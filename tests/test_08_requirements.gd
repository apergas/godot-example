extends SceneTree
## tests/test_08_requirements.gd — run: tools\godot.cmd --headless --path . --script res://tests/test_08_requirements.gd

const SCENES := {
	"res://scenes/buildings/hq.tscn": "hq",
	"res://scenes/buildings/habitat.tscn": "habitat",
	"res://scenes/buildings/crystal_depot.tscn": "crystal_depot",
	"res://scenes/buildings/ice_depot.tscn": "ice_depot",
}

var _failed := false


func _initialize() -> void:
	create_timer(20.0).timeout.connect(_on_timeout)
	await process_frame
	root.get_node("GameState").reset()
	root.get_node("Nav").reset()

	for path: String in SCENES:
		var building := (load(path) as PackedScene).instantiate() as Building
		var id: String = SCENES[path]
		_check("kind_id_" + id, building.kind_id == id, building.kind_id)
		_check("no_requires_" + id, building.requires.is_empty(), str(building.requires))
		building.free()

	_check("kind_names", Building.KIND_NAMES.get("shipyard") == "Astillero" and Building.KIND_NAMES.get("colony_module") == "Módulo de colonos", str(Building.KIND_NAMES))
	_check("requirement_text", Building.requirement_text("shipyard") == "Requiere: Astillero", Building.requirement_text("shipyard"))

	var world := Node2D.new()
	root.add_child(world)
	var need: Array[String] = ["shipyard"]
	_check("missing_without_building", Building.missing_requirement(self, need) == "shipyard", Building.missing_requirement(self, need))
	_check("nothing_required", Building.missing_requirement(self, []) == "", "not empty")

	var yard := Building.new()
	yard.footprint = Vector2i(3, 3)
	yard.kind_id = "shipyard"
	yard.position = Grid.footprint_origin(Vector2i(20, 10), yard.footprint)
	world.add_child(yard)
	_check("met_when_built", Building.missing_requirement(self, need) == "" and Building.has_finished(self, "shipyard"), "still missing")
	yard.start_construction()
	_check("unmet_while_under_construction", Building.missing_requirement(self, need) == "shipyard", "met while building")
	yard.add_build_progress(yard.build_time)
	_check("met_after_completion", Building.missing_requirement(self, need) == "", "missing after completion")

	var module := Building.new()
	module.footprint = Vector2i(3, 2)
	module.kind_id = "colony_module"
	module.requires = need
	module.position = Grid.footprint_origin(Vector2i(30, 10), module.footprint)
	world.add_child(module)
	_check("instance_requirements_met", module.requirements_met(), "requirements_met() false")
	yard.queue_free()
	await process_frame
	_check("unmet_after_free", not module.requirements_met(), "requirements_met() true without shipyard")
	world.queue_free()
	quit(1 if _failed else 0)


func _check(test_name: String, ok: bool, why: String) -> void:
	if ok:
		print("PASS ", test_name)
	else:
		print("FAIL ", test_name, ": ", why)
		_failed = true


func _on_timeout() -> void:
	print("FAIL timeout: test did not finish (script error?)")
	quit(1)
