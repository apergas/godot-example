extends SceneTree

const Sim := preload("res://tests/sim_helpers.gd")
const ICE_DEPOT := "res://scenes/buildings/ice_depot.tscn"
const CRYSTAL_DEPOT := "res://scenes/buildings/crystal_depot.tscn"
const HQ_CELL := Vector2i(2, 8)
const ICE_CELLS: Array[Vector2i] = [Vector2i(18, 9), Vector2i(18, 10), Vector2i(19, 9), Vector2i(19, 10)]
const GATHER_CELL := Vector2i(19, 9)
const DEPOT_CELL := Vector2i(21, 9)
const WORKER_CELL := Vector2i(16, 9)
const TIMEOUT := 40.0

var _failed := false
var _world: Node2D
var _hq: Building
var _depot: Building
var _target: ResourceNode
var _worker: Variant


func _initialize() -> void:
	await process_frame
	Sim.accelerate()
	await _test_finished_depot()
	await _test_unfinished_depot()
	await _test_crystal_depot_rejects_ice()
	Sim.restore()
	quit(1 if _failed else 0)


func _check(ok: bool, test_name: String, reason: String) -> void:
	if ok:
		print("PASS ", test_name)
	else:
		print("FAIL ", test_name, ": ", reason)
		_failed = true


func _setup(depot_path: String, finished: bool) -> void:
	_world = Sim.new_world(self)
	_hq = Sim.add_building(_world, Sim.HQ_SCENE, HQ_CELL)
	for cell in ICE_CELLS:
		var node := Sim.add_resource(_world, Sim.ICE_SCENE, cell)
		if cell == GATHER_CELL:
			_target = node
	_depot = null
	if depot_path != "":
		_depot = Sim.add_building(_world, depot_path, DEPOT_CELL)
		if not finished:
			_depot.start_construction()
	_worker = Sim.add_worker(_world, WORKER_CELL)
	await process_frame


func _gather_and_log(count: int) -> Sim.DeliveryLog:
	var deliveries := Sim.DeliveryLog.new(Sim.game_state(self), _worker, Sim.clock_of(_world))
	_worker.gather(_target)
	await Sim.run_until_deliveries(self, _world, deliveries, count, TIMEOUT)
	deliveries.detach()
	return deliveries


func _test_finished_depot() -> void:
	await _setup(ICE_DEPOT, true)
	_check(_worker._nearest_dropoff(ResKind.ICE) == _depot, "nearest_ice_dropoff_is_finished_depot",
			"got %s" % _worker._nearest_dropoff(ResKind.ICE))
	_check(_worker._nearest_dropoff(ResKind.CRYSTAL) == _hq, "ice_depot_ignored_for_crystal",
			"got %s" % _worker._nearest_dropoff(ResKind.CRYSTAL))
	var deliveries: Sim.DeliveryLog = await _gather_and_log(2)
	_check(deliveries.positions.size() >= 2, "worker_delivers_ice",
			"%d deliveries in %d s" % [deliveries.positions.size(), int(TIMEOUT)])
	for p in deliveries.positions:
		_check(Sim.closest(p, [_hq, _depot]) == _depot, "delivers_at_finished_ice_depot",
				"delivered at %s" % p)
	Sim.free_world(_world)


func _test_unfinished_depot() -> void:
	await _setup(ICE_DEPOT, false)
	_check(not _depot.accepts(ResKind.ICE), "unfinished_depot_rejects_ice", "accepts(ICE) is true")
	_check(_worker._nearest_dropoff(ResKind.ICE) == _hq, "unfinished_depot_skipped",
			"got %s" % _worker._nearest_dropoff(ResKind.ICE))
	var deliveries: Sim.DeliveryLog = await _gather_and_log(1)
	_check(deliveries.positions.size() >= 1, "worker_delivers_with_unfinished_depot",
			"no delivery in %d s" % int(TIMEOUT))
	for p in deliveries.positions:
		_check(Sim.closest(p, [_hq, _depot]) == _hq, "delivers_at_hq_while_depot_unfinished",
				"delivered at %s" % p)
	Sim.free_world(_world)


func _test_crystal_depot_rejects_ice() -> void:
	await _setup(CRYSTAL_DEPOT, true)
	_check(not _depot.accepts(ResKind.ICE) and _depot.accepts(ResKind.CRYSTAL),
			"crystal_depot_accepts_only_crystal", "accepts_kinds %s" % _depot.accepts_kinds)
	_check(_worker._nearest_dropoff(ResKind.ICE) == _hq, "ice_skips_crystal_depot",
			"got %s" % _worker._nearest_dropoff(ResKind.ICE))
	_check(_worker._nearest_dropoff(ResKind.CRYSTAL) == _depot, "crystal_uses_crystal_depot",
			"got %s" % _worker._nearest_dropoff(ResKind.CRYSTAL))
	var deliveries: Sim.DeliveryLog = await _gather_and_log(1)
	_check(deliveries.positions.size() >= 1, "worker_delivers_next_to_crystal_depot",
			"no delivery in %d s" % int(TIMEOUT))
	for p in deliveries.positions:
		_check(Sim.closest(p, [_hq, _depot]) == _hq, "ice_delivered_at_hq_not_crystal_depot",
				"delivered at %s" % p)
	Sim.free_world(_world)
