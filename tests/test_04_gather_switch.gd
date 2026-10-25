extends SceneTree

const NavScript := preload("res://scripts/nav.gd")
const GameStateScript := preload("res://scripts/game_state.gd")
const WorkerScript := preload("res://scripts/worker.gd")

const MAX_FRAMES := 1200

var _failed := false
var _nav: NavScript
var _game: GameStateScript


func _initialize() -> void:
	await process_frame
	_nav = root.get_node("Nav") as NavScript
	_game = root.get_node("GameState") as GameStateScript
	await _switches_to_nearby_node()
	await _idles_without_nearby_node()
	quit(1 if _failed else 0)


func _switches_to_nearby_node() -> void:
	_nav.reset()
	_game.reset()
	var world := Node2D.new()
	root.add_child(world)
	_spawn_hq(world, Vector2i(10, 21))
	var first := _spawn_resource(world, "crystal", Vector2i(15, 22), 4)
	var ice := _spawn_resource(world, "ice", Vector2i(15, 24), 150)
	var second := _spawn_resource(world, "crystal", Vector2i(16, 25), 400)
	var worker := _spawn_worker(world, Vector2i(13, 22))
	await physics_frame

	var start_stock: int = _game.stock[ResKind.CRYSTAL]
	worker.gather(first)
	var delivered := false
	for frame in MAX_FRAMES:
		await physics_frame
		if _game.stock[ResKind.CRYSTAL] != start_stock:
			delivered = true
			break
	_check(delivered and _game.stock[ResKind.CRYSTAL] == start_stock + 4, "delivers_partial_load", str(_game.stock))
	_check(not is_instance_valid(first), "first_node_depleted", "first node still alive")
	_check(worker._gather_node == second, "switches_to_same_kind", "target is not the nearby crystal")
	var gathered := false
	for frame in MAX_FRAMES:
		await physics_frame
		if second.amount < 400:
			gathered = true
			break
	_check(gathered, "gathers_from_new_node", "second node untouched")
	_check(ice.amount == 150, "ignores_other_kind", str(ice.amount))
	world.queue_free()
	await process_frame


func _idles_without_nearby_node() -> void:
	_nav.reset()
	_game.reset()
	var world := Node2D.new()
	root.add_child(world)
	_spawn_hq(world, Vector2i(10, 21))
	var only := _spawn_resource(world, "crystal", Vector2i(15, 22), 3)
	var far := _spawn_resource(world, "crystal", Vector2i(15, 30), 400)
	var worker := _spawn_worker(world, Vector2i(13, 22))
	await physics_frame

	var start_stock: int = _game.stock[ResKind.CRYSTAL]
	worker.gather(only)
	var delivered := false
	for frame in MAX_FRAMES:
		await physics_frame
		if _game.stock[ResKind.CRYSTAL] != start_stock:
			delivered = true
			break
	_check(delivered and _game.stock[ResKind.CRYSTAL] == start_stock + 3, "delivers_last_load", str(_game.stock))
	_check(worker.state == WorkerScript.State.IDLE, "idles_when_field_empty", str(worker.state))
	_check(worker._gather_node == null, "clears_target", "target kept")
	_check(far.amount == 400, "ignores_far_node", str(far.amount))
	world.queue_free()
	await process_frame


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
