extends SceneTree

const NavScript := preload("res://scripts/nav.gd")
const GameStateScript := preload("res://scripts/game_state.gd")
const WorkerScript := preload("res://scripts/worker.gd")

const MAX_FRAMES := 900

var _failed := false


func _initialize() -> void:
	await process_frame
	var nav := root.get_node("Nav") as NavScript
	var game := root.get_node("GameState") as GameStateScript
	nav.reset()
	game.reset()
	var world := Node2D.new()
	root.add_child(world)
	var hq := _spawn_hq(world, Vector2i(10, 21))
	var crystal := _spawn_resource(world, "crystal", Vector2i(16, 22), 400)
	var ice := _spawn_resource(world, "ice", Vector2i(16, 25), 400)
	var worker := _spawn_worker(world, Vector2i(8, 22))
	await physics_frame

	# gather() with another kind discards the cargo.
	worker.carry_kind = ResKind.ICE
	worker.carry_amount = 4
	worker.gather(crystal)
	_check(worker.carry_amount == 0 and worker.carry_kind == -1, "other_kind_discards_cargo",
			"%d of %d" % [worker.carry_amount, worker.carry_kind])
	_check(worker.state == WorkerScript.State.TO_RESOURCE, "other_kind_walks_to_node", str(worker.state))

	# gather() with the same kind keeps it.
	worker.carry_kind = ResKind.CRYSTAL
	worker.carry_amount = 4
	worker.gather(crystal)
	_check(worker.carry_amount == 4, "same_kind_keeps_cargo", str(worker.carry_amount))

	# gather() with a full load goes straight to the dropoff.
	worker.carry_amount = WorkerScript.CARRY_MAX
	worker.gather(crystal)
	_check(worker.state == WorkerScript.State.TO_DROPOFF, "full_load_goes_to_dropoff", str(worker.state))

	# return_cargo without cargo does nothing; with cargo goes to the given or nearest building.
	worker.move_to(Grid.cell_to_world(Vector2i(8, 22)))
	worker.carry_amount = 0
	worker.carry_kind = -1
	worker.return_cargo()
	_check(worker.state == WorkerScript.State.MOVING, "return_without_cargo_noop", str(worker.state))
	worker.carry_kind = ResKind.CRYSTAL
	worker.carry_amount = 3
	worker.return_cargo()
	_check(worker.state == WorkerScript.State.TO_DROPOFF and worker._dropoff == hq, "return_nearest", str(worker.state))
	worker.move_to(Grid.cell_to_world(Vector2i(8, 22)))
	worker.return_cargo(hq)
	_check(worker.state == WorkerScript.State.TO_DROPOFF and worker._dropoff == hq, "return_given_building", str(worker.state))

	# No next node while carrying: head to the dropoff instead of idling with the cargo.
	var solo := _spawn_resource(world, "ice", Vector2i(30, 5), 400)
	var carrier := _spawn_worker(world, Vector2i(28, 5))
	carrier.carry_kind = ResKind.ICE
	carrier.carry_amount = 5
	carrier.gather(solo)
	solo.take(solo.amount)
	await physics_frame
	await physics_frame
	_check(carrier.state == WorkerScript.State.TO_DROPOFF, "retarget_with_cargo_goes_to_dropoff", str(carrier.state))
	for frame in MAX_FRAMES:
		await physics_frame
		if carrier.carry_amount == 0:
			break
	_check(carrier.carry_amount == 0 and game.stock[ResKind.ICE] >= 5, "carrier_delivers", str(game.stock))
	_check(carrier.state == WorkerScript.State.IDLE, "carrier_idle_after_delivery", str(carrier.state))
	carrier.queue_free()

	# Node depleted while GATHERING, another node of the same kind nearby, no cargo: retarget.
	var a := _spawn_resource(world, "crystal", Vector2i(20, 10), 400)
	var b := _spawn_resource(world, "crystal", Vector2i(22, 10), 400)
	var gatherer := _spawn_worker(world, Vector2i(18, 10))
	gatherer.gather(a)
	for frame in MAX_FRAMES:
		await physics_frame
		if gatherer.state == WorkerScript.State.GATHERING:
			break
	_check(gatherer.state == WorkerScript.State.GATHERING, "reaches_gathering", str(gatherer.state))
	a.take(a.amount)
	await physics_frame
	await physics_frame
	_check(gatherer._gather_node == b and gatherer.state == WorkerScript.State.TO_RESOURCE,
			"depleted_while_gathering_retargets", "%s %s" % [gatherer._gather_node, gatherer.state])

	# Node depleted while GATHERING with partial cargo and nothing else around: dropoff.
	var c := _spawn_resource(world, "ice", Vector2i(40, 30), 400)
	var g2 := _spawn_worker(world, Vector2i(38, 30))
	g2.gather(c)
	for frame in MAX_FRAMES:
		await physics_frame
		if g2.state == WorkerScript.State.GATHERING:
			break
	g2.carry_kind = ResKind.ICE
	g2.carry_amount = 3
	c.take(c.amount)
	await physics_frame
	await physics_frame
	_check(g2.state == WorkerScript.State.TO_DROPOFF, "depleted_while_gathering_with_cargo_dropoff", str(g2.state))

	# Target depleted externally before arrival, empty-handed: retarget in _process_to_resource.
	var far_a := _spawn_resource(world, "crystal", Vector2i(50, 10), 400)
	var far_b := _spawn_resource(world, "crystal", Vector2i(52, 12), 400)
	var walker := _spawn_worker(world, Vector2i(40, 10))
	walker.gather(far_a)
	await physics_frame
	far_a.take(far_a.amount)
	await physics_frame
	await physics_frame
	_check(walker._gather_node == far_b and walker.state == WorkerScript.State.TO_RESOURCE,
			"depleted_before_arrival_retargets", "%s %s" % [walker._gather_node, walker.state])

	# ...and with nothing else left it goes idle.
	far_b.take(far_b.amount)
	await physics_frame
	await physics_frame
	_check(walker.state == WorkerScript.State.IDLE and walker._gather_node == null,
			"depleted_before_arrival_no_more_idles", str(walker.state))
	ice.queue_free()
	quit(1 if _failed else 0)


func _spawn_hq(parent: Node, cell: Vector2i) -> Building:
	var hq := (load("res://scenes/buildings/hq.tscn") as PackedScene).instantiate() as Building
	hq.position = Grid.footprint_origin(cell, hq.footprint)
	parent.add_child(hq)
	return hq


func _spawn_resource(parent: Node, scene: String, cell: Vector2i, amount: int) -> ResourceNode:
	var node := (load("res://scenes/resources/%s.tscn" % scene) as PackedScene).instantiate() as ResourceNode
	node.position = Grid.cell_to_world(cell) + Vector2(0.0, Grid.TILE / 2.0 - 4.0)
	node.amount = amount
	parent.add_child(node)
	return node


func _spawn_worker(parent: Node, cell: Vector2i) -> WorkerScript:
	var worker := (load("res://scenes/worker.tscn") as PackedScene).instantiate() as WorkerScript
	worker.position = Grid.cell_to_world(cell)
	worker.speed = 400.0
	parent.add_child(worker)
	return worker


func _check(ok: bool, name: String, why: String) -> void:
	if ok:
		print("PASS ", name)
	else:
		print("FAIL ", name, ": ", why)
		_failed = true
