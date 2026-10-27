extends SceneTree

const Sim := preload("res://tests/sim_helpers.gd")
const ICE_DEPOT := "res://scenes/buildings/ice_depot.tscn"
const HQ_CELL := Vector2i(2, 8)
const ICE_CELLS: Array[Vector2i] = [Vector2i(18, 9), Vector2i(18, 10), Vector2i(19, 9), Vector2i(19, 10)]
const GATHER_CELL := Vector2i(19, 9)
const DEPOT_CELL := Vector2i(21, 9)
const WORKER_CELL := Vector2i(16, 9)
const TIMEOUT := 40.0

var _failed := false


func _initialize() -> void:
	await process_frame
	Sim.accelerate()
	var world := Sim.new_world(self)
	var hq := Sim.add_building(world, Sim.HQ_SCENE, HQ_CELL)
	var target: ResourceNode = null
	for cell in ICE_CELLS:
		var node := Sim.add_resource(world, Sim.ICE_SCENE, cell)
		if cell == GATHER_CELL:
			target = node
	var worker: Variant = Sim.add_worker(world, WORKER_CELL)
	await process_frame

	var deliveries := Sim.DeliveryLog.new(Sim.game_state(self), worker, Sim.clock_of(world))
	worker.gather(target)
	var first: bool = await Sim.run_until_deliveries(self, world, deliveries, 1, TIMEOUT)
	_check(first and deliveries.positions[0].distance_to(Sim.rect_center(hq)) < 3 * Grid.TILE,
			"first_delivery_at_hq", "positions %s" % [deliveries.positions])

	var depot := Sim.add_building(world, ICE_DEPOT, DEPOT_CELL)
	var second: bool = await Sim.run_until_deliveries(self, world, deliveries, 2, TIMEOUT)
	_check(second and Sim.closest(deliveries.positions[1], [hq, depot]) == depot,
			"switches_to_new_depot_on_next_trip", "positions %s" % [deliveries.positions])

	deliveries.detach()
	Sim.free_world(world)
	Sim.restore()
	quit(1 if _failed else 0)


func _check(ok: bool, test_name: String, reason: String) -> void:
	if ok:
		print("PASS ", test_name)
	else:
		print("FAIL ", test_name, ": ", reason)
		_failed = true
