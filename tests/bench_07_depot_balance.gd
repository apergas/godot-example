extends SceneTree
## Phase 7 balance bench (not a test: run_all.ps1 only runs tests/test_*.gd).
## Real map layout, ice only:
##   1. one worker: seconds per load delivering at the HQ vs. at an ice depot by the field;
##   2. three workers for 180 s: HQ only vs. worker 0 builds a depot at t=0 (100 crystal, 15 s).
## Run: tools\godot.cmd --headless --path . --script res://tests/bench_07_depot_balance.gd

const Sim := preload("res://tests/sim_helpers.gd")
const ICE_DEPOT := "res://scenes/buildings/ice_depot.tscn"
const DEPOT_SIZE := Vector2i(2, 2)
const DEPOT_COST := 100
const WORKERS := 3
const SIM_SECONDS := 180.0
const SAMPLE_EVERY := 5.0
const TRIP_LOADS := 4
const TRIP_TIMEOUT := 240.0

var _world: Node2D
var _hq: Building
var _hq_center := Vector2.ZERO


func _initialize() -> void:
	await process_frame
	Sim.accelerate()
	var trip_hq: float = await _seconds_per_load(false)
	var trip_depot: float = await _seconds_per_load(true)
	var base: Array[int] = await _three_workers(false)
	var built: Array[int] = await _three_workers(true)
	Sim.restore()
	_report(trip_hq, trip_depot, base, built)
	quit(0)


func _build_map() -> void:
	_world = Sim.new_world(self)
	_hq = Sim.add_building(_world, Sim.HQ_SCENE, MapLayout.HQ_CELL)
	_hq_center = Sim.rect_center(_hq)
	for cell in MapLayout.CRYSTAL_CELLS:
		Sim.add_resource(_world, Sim.CRYSTAL_SCENE, cell)
	for cell in MapLayout.ICE_CELLS:
		Sim.add_resource(_world, Sim.ICE_SCENE, cell)


func _ice_by_distance() -> Array[ResourceNode]:
	var nodes: Array[ResourceNode] = []
	for node in get_nodes_in_group("resources"):
		var res := node as ResourceNode
		if res != null and res.kind == ResKind.ICE:
			nodes.append(res)
	nodes.sort_custom(_closer_to_hq)
	return nodes


func _closer_to_hq(a: ResourceNode, b: ResourceNode) -> bool:
	return a.global_position.distance_to(_hq_center) < b.global_position.distance_to(_hq_center)


## Free 2x2 spot (with a free ring around it) closest to the target node, as a player would pick.
func _depot_cell(target: ResourceNode) -> Vector2i:
	var nav: Variant = Sim.nav(self)
	var best := Vector2i(-1, -1)
	var best_distance := INF
	for y in range(target.cell.y - 6, target.cell.y + 7):
		for x in range(target.cell.x - 6, target.cell.x + 7):
			var cell := Vector2i(x, y)
			if not nav.is_area_free(Rect2i(cell - Vector2i.ONE, DEPOT_SIZE + Vector2i(2, 2))):
				continue
			var center := Vector2(cell * Grid.TILE) + Vector2(DEPOT_SIZE * Grid.TILE) / 2.0
			var distance := center.distance_to(target.global_position)
			if distance < best_distance:
				best_distance = distance
				best = cell
	return best


func _seconds_per_load(with_depot: bool) -> float:
	_build_map()
	var target := _ice_by_distance()[0]
	if with_depot:
		Sim.add_building(_world, ICE_DEPOT, _depot_cell(target))
	var worker: Variant = Sim.add_worker(_world, MapLayout.HQ_CELL + Vector2i(3, 1))
	await process_frame
	var deliveries := Sim.DeliveryLog.new(Sim.game_state(self), worker, Sim.clock_of(_world))
	worker.gather(target)
	await Sim.run_until_deliveries(self, _world, deliveries, TRIP_LOADS + 1, TRIP_TIMEOUT)
	deliveries.detach()
	Sim.free_world(_world)
	var times := deliveries.times
	if times.size() < 2:
		return INF
	return (times[times.size() - 1] - times[0]) / (times.size() - 1)


func _three_workers(build_depot: bool) -> Array[int]:
	_build_map()
	var targets := _ice_by_distance()
	var workers: Array = []
	for i in WORKERS:
		workers.append(Sim.add_worker(_world, MapLayout.HQ_CELL + Vector2i(3, i)))
	await process_frame
	var first_gatherer := 0
	if build_depot:
		var game_state: Variant = Sim.game_state(self)
		game_state.add(ResKind.CRYSTAL, DEPOT_COST)
		game_state.spend({ResKind.CRYSTAL: DEPOT_COST})
		var site := Sim.add_building(_world, ICE_DEPOT, _depot_cell(targets[0]))
		site.start_construction()
		site.completed.connect(_on_site_completed.bind(workers[0], targets[0]))
		workers[0].build(site)
		first_gatherer = 1
	for i in range(first_gatherer, WORKERS):
		workers[i].gather(targets[i])
	var samples: Array[int] = []
	var clock := Sim.clock_of(_world)
	while clock.seconds < SIM_SECONDS:
		await Sim.run_for(self, _world, SAMPLE_EVERY)
		samples.append(Sim.game_state(self).stock[ResKind.ICE])
	Sim.free_world(_world)
	return samples


## The builder may still be in BUILDING for a frame after `completed`; then send it to gather.
func _on_site_completed(worker: Variant, target: ResourceNode) -> void:
	await physics_frame
	await physics_frame
	if is_instance_valid(target):
		worker.gather(target)


func _report(trip_hq: float, trip_depot: float, base: Array[int], built: Array[int]) -> void:
	print("| Medida | Sin depósito (HQ) | Con depósito |")
	print("|---|---|---|")
	print("| Segundos por carga (1 robot) | %.1f | %.1f |" % [trip_hq, trip_depot])
	print("| Hielo/min por robot | %.0f | %.0f |" % [600.0 / trip_hq, 600.0 / trip_depot])
	for t: int in [30, 60, 120, 180]:
		var i := int(t / SAMPLE_EVERY) - 1
		print("| Hielo a los %d s (3 robots) | %d | %d |" % [t, base[i], built[i]])
	var payback := -1.0
	for i in mini(base.size(), built.size()):
		if built[i] - base[i] >= DEPOT_COST:
			payback = (i + 1) * SAMPLE_EVERY
			break
	if payback < 0.0:
		print("| Amortización (≥ %d de hielo extra) | — | no en %d s |" % [DEPOT_COST, int(SIM_SECONDS)])
		print("PAYBACK_TOO_SLOW")
	else:
		print("| Amortización (≥ %d de hielo extra) | — | %.0f s |" % [DEPOT_COST, payback])
		print("PAYBACK_OK" if payback < SIM_SECONDS else "PAYBACK_TOO_SLOW")
