extends Node
## Global economy state (autoload "GameState"): resource stock indexed by ResKind.

signal stock_changed

const START_STOCK := [50, 0]

var stock: Array[int] = [50, 0]


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
