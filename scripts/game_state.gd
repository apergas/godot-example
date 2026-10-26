extends Node
## Global economy state (autoload "GameState"): resource stock indexed by ResKind.

signal stock_changed
signal population_changed(population: int, cap: int)
signal goal_changed(colonists: int, ships: int)
signal victory

const MAX_CAP := 60
const MAIN_SCENE := "res://scenes/main.tscn"
const GOAL_COLONISTS := 20
const GOAL_SHIPS := 4
const START_STOCK := [50, 0]

var stock: Array[int] = [50, 0]

var population := 0
var population_cap := 0
var goal_colonists := GOAL_COLONISTS
var goal_ships := GOAL_SHIPS
var colonists := 0
var ships := 0
var victory_reached := false
var play_time := 0.0
var gathered: Array[int] = [0, 0]

var _cap_total := 0


func add(kind: int, n: int) -> void:
	if n == 0:
		return
	if n > 0:
		gathered[kind] += n
	stock[kind] += n
	stock_changed.emit()


func can_afford(cost: Dictionary) -> bool:
	for kind in cost:
		if stock[kind] < int(cost[kind]):
			return false
	return true


func spend(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for kind in cost:
		stock[kind] -= int(cost[kind])
	stock_changed.emit()
	return true


func reset() -> void:
	stock.assign(START_STOCK)
	stock_changed.emit()
	population = 0
	population_cap = 0
	_cap_total = 0
	population_changed.emit(population, population_cap)
	goal_colonists = GOAL_COLONISTS
	goal_ships = GOAL_SHIPS
	colonists = 0
	ships = 0
	victory_reached = false
	play_time = 0.0
	gathered.assign([0, 0])
	goal_changed.emit(colonists, ships)


func add_population(n: int) -> void:
	population = maxi(population + n, 0)
	population_changed.emit(population, population_cap)


func add_cap(n: int) -> void:
	_cap_total += n
	population_cap = clampi(_cap_total, 0, MAX_CAP)
	population_changed.emit(population, population_cap)


func has_room() -> bool:
	return population < population_cap


func _process(delta: float) -> void:
	play_time += delta


func add_colonist(n: int) -> void:
	colonists = maxi(colonists + n, 0)
	_update_goal()


func add_ship(n: int) -> void:
	ships = maxi(ships + n, 0)
	_update_goal()


func _update_goal() -> void:
	goal_changed.emit(colonists, ships)
	if victory_reached or colonists < goal_colonists or ships < goal_ships:
		return
	victory_reached = true
	victory.emit()


## Frees the running game, resets the autoloads once it is gone, then loads a fresh main scene.
func restart_game() -> void:
	var tree := get_tree()
	tree.paused = false
	if tree.current_scene != null:
		tree.current_scene.queue_free()
	await tree.process_frame
	reset()
	get_node("/root/Nav").reset()
	tree.change_scene_to_file(MAIN_SCENE)
