extends RefCounted
## Helpers shared by the phase 7 simulation tests and the balance bench. Not a test itself.

const TIME_SCALE := 8.0
const BASE_TICKS := 60
const HQ_SCENE := "res://scenes/buildings/hq.tscn"
const ICE_SCENE := "res://scenes/resources/ice.tscn"
const CRYSTAL_SCENE := "res://scenes/resources/crystal.tscn"
const WORKER_SCENE := "res://scenes/worker.tscn"


class Clock extends Node:
	var seconds := 0.0

	func _physics_process(delta: float) -> void:
		seconds += delta


## Records where the worker stands each time the ice stock goes up.
class DeliveryLog extends RefCounted:
	var positions: Array[Vector2] = []
	var times: Array[float] = []
	var _game_state: Node
	var _worker: Node2D
	var _clock: Node
	var _last := 0

	func _init(game_state: Node, worker: Node2D, clock: Node) -> void:
		_game_state = game_state
		_worker = worker
		_clock = clock
		_last = game_state.stock[ResKind.ICE]
		game_state.stock_changed.connect(_on_stock_changed)

	func detach() -> void:
		if _game_state.stock_changed.is_connected(_on_stock_changed):
			_game_state.stock_changed.disconnect(_on_stock_changed)

	func _on_stock_changed() -> void:
		var now: int = _game_state.stock[ResKind.ICE]
		if now > _last:
			positions.append(_worker.global_position)
			times.append(_clock.seconds)
		_last = now


static func accelerate() -> void:
	Engine.time_scale = TIME_SCALE
	Engine.physics_ticks_per_second = int(BASE_TICKS * TIME_SCALE)


static func restore() -> void:
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = BASE_TICKS


static func game_state(tree: SceneTree):
	return tree.root.get_node("GameState")


static func nav(tree: SceneTree):
	return tree.root.get_node("Nav")


static func new_world(tree: SceneTree) -> Node2D:
	game_state(tree).reset()
	nav(tree).reset()
	var world := Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	var clock := Clock.new()
	clock.name = "Clock"
	world.add_child(clock)
	tree.root.add_child(world)
	return world


static func clock_of(world: Node2D) -> Clock:
	return world.get_node("Clock") as Clock


static func free_world(world: Node2D) -> void:
	world.free()


static func add_building(world: Node2D, path: String, cell: Vector2i) -> Building:
	var building := (load(path) as PackedScene).instantiate() as Building
	building.position = Grid.footprint_origin(cell, building.footprint)
	world.add_child(building)
	return building


static func add_resource(world: Node2D, path: String, cell: Vector2i) -> ResourceNode:
	var node := (load(path) as PackedScene).instantiate() as ResourceNode
	node.position = Grid.cell_to_world(cell) + Vector2(0, Grid.TILE / 2.0 - 4)
	world.add_child(node)
	return node


static func add_worker(world: Node2D, cell: Vector2i) -> Node2D:
	var worker := (load(WORKER_SCENE) as PackedScene).instantiate() as Node2D
	worker.position = Grid.cell_to_world(cell)
	world.add_child(worker)
	return worker


static func rect_center(building: Building) -> Vector2:
	var rect := building.cell_rect()
	return Vector2(rect.position * Grid.TILE) + Vector2(rect.size * Grid.TILE) / 2.0


static func closest(point: Vector2, buildings: Array) -> Building:
	var best: Building = null
	var best_distance := INF
	for building: Building in buildings:
		var distance := point.distance_to(rect_center(building))
		if distance < best_distance:
			best_distance = distance
			best = building
	return best


static func run_for(tree: SceneTree, world: Node2D, seconds: float) -> void:
	var clock := clock_of(world)
	var end := clock.seconds + seconds
	while clock.seconds < end:
		await tree.physics_frame


static func run_until_deliveries(tree: SceneTree, world: Node2D, deliveries: DeliveryLog,
		count: int, timeout: float) -> bool:
	var clock := clock_of(world)
	var end := clock.seconds + timeout
	while deliveries.positions.size() < count and clock.seconds < end:
		await tree.physics_frame
	return deliveries.positions.size() >= count
