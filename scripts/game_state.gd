extends Node
## Global economy state (autoload "GameState"): resource stock indexed by ResKind.

signal stock_changed
signal population_changed(population: int, cap: int)

const MAX_CAP := 50
const START_STOCK := [50, 0]

var stock: Array[int] = [50, 0]

var population := 0
var population_cap := 0

var _cap_total := 0


func add(kind: int, n: int) -> void:
	if n == 0:
		return
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


func add_population(n: int) -> void:
	population = maxi(population + n, 0)
	population_changed.emit(population, population_cap)


func add_cap(n: int) -> void:
	_cap_total += n
	population_cap = clampi(_cap_total, 0, MAX_CAP)
	population_changed.emit(population, population_cap)


func has_room() -> bool:
	return population < population_cap
