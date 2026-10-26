extends SceneTree

const Sim := preload("res://tests/sim_helpers.gd")
const ICE_DEPOT := "res://scenes/buildings/ice_depot.tscn"
const HQ_CELL := Vector2i(2, 8)
const ICE_CELLS: Array[Vector2i] = [Vector2i(18, 9), Vector2i(18, 10), Vector2i(19, 9), Vector2i(19, 10)]
const GATHER_CELL := Vector2i(19, 9)
const DEPOT_CELL := Vector2i(21, 9)
const WORKER_CELL := Vector2i(16, 9)
const SIM_SECONDS := 60.0


func _initialize() -> void:
	await process_frame
	Sim.accelerate()
	var without: int = await _gathered(false)
	var with_depot: int = await _gathered(true)
	Sim.restore()
	print("ice in %d s: without depot %d, with depot %d" % [int(SIM_SECONDS), without, with_depot])
	var ok := with_depot >= without * 1.5 and with_depot >= without + 20
	if ok:
		print("PASS depot_increases_ice_rate")
	else:
		print("FAIL depot_increases_ice_rate: without %d, with %d" % [without, with_depot])
	quit(0 if ok else 1)


func _gathered(use_depot: bool) -> int:
	var world := Sim.new_world(self)
	Sim.add_building(world, Sim.HQ_SCENE, HQ_CELL)
	var target: ResourceNode = null
	for cell in ICE_CELLS:
		var node := Sim.add_resource(world, Sim.ICE_SCENE, cell)
		if cell == GATHER_CELL:
			target = node
	if use_depot:
		Sim.add_building(world, ICE_DEPOT, DEPOT_CELL)
	var worker: Variant = Sim.add_worker(world, WORKER_CELL)
	await process_frame
	worker.gather(target)
	await Sim.run_for(self, world, SIM_SECONDS)
	var ice: int = Sim.game_state(self).stock[ResKind.ICE]
	Sim.free_world(world)
	return ice
