extends SceneTree

const NavScript := preload("res://scripts/nav.gd")
const GameStateScript := preload("res://scripts/game_state.gd")
const WorkerScript := preload("res://scripts/worker.gd")

const MAX_FRAMES := 1200

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
	var node := _spawn_resource(world, "crystal", Vector2i(15, 22), 400)
	var worker := _spawn_worker(world, Vector2i(8, 22))
	await physics_frame

	var start_stock: int = game.stock[ResKind.CRYSTAL]
	worker.gather(node)
	_check(worker.state == WorkerScript.State.TO_RESOURCE, "gather_starts_walking", str(worker.state))
	var entered_hq := false
	var max_carry := 0
	var delivered := false
	for frame in MAX_FRAMES:
		await physics_frame
		if hq.cell_rect().has_point(Grid.world_to_cell(worker.global_position)):
			entered_hq = true
		max_carry = maxi(max_carry, worker.carry_amount)
		if game.stock[ResKind.CRYSTAL] != start_stock:
			delivered = true
			break
	_check(delivered, "delivers_in_time", "no delivery in %d physics frames" % MAX_FRAMES)
	_check(game.stock[ResKind.CRYSTAL] == start_stock + WorkerScript.CARRY_MAX, "adds_carry_max", str(game.stock))
	_check(node.amount == 400 - WorkerScript.CARRY_MAX, "node_loses_amount", str(node.amount))
	_check(max_carry == WorkerScript.CARRY_MAX, "carries_full_load", str(max_carry))
	_check(worker.carry_amount == 0 and worker.carry_kind == -1, "empties_on_delivery", str(worker.carry_amount))
	_check(not entered_hq, "path_avoids_hq", "worker stepped into the HQ footprint")
	_check(worker.state == WorkerScript.State.TO_RESOURCE or worker.state == WorkerScript.State.GATHERING,
			"returns_to_same_node", str(worker.state))
	_check(worker._gather_node == node, "keeps_node", "target changed")

	_check(worker._nearest_dropoff(ResKind.ICE) == hq, "hq_is_ice_dropoff", "")
	hq.built = false
	_check(worker._nearest_dropoff(ResKind.CRYSTAL) == null, "unbuilt_is_not_dropoff", "")
	hq.built = true
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
