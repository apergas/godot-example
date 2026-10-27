class_name MissionTracker extends Node
## Walks Missions.LIST in order: checks GameState.stats, pays rewards and chains met missions.

signal mission_changed(index: int)
signal mission_completed(index: int, reward: Dictionary)
signal progress_changed

const GameStateScript := preload("res://scripts/game_state.gd")

var index := 0


func _ready() -> void:
	var gs := _gs()
	gs.stats_changed.connect(evaluate)
	gs.population_changed.connect(_on_population_changed)
	gs.victory.connect(_on_victory)
	evaluate.call_deferred()


func current() -> Dictionary:
	if is_finished():
		return {}
	return Missions.LIST[index]


func is_finished() -> bool:
	return index >= Missions.LIST.size()


func progress() -> int:
	var total := 0
	for c in Missions.conditions(current()):
		total += mini(_value(c["stat"]), int(c["target"]))
	return total


func target() -> int:
	var total := 0
	for c in Missions.conditions(current()):
		total += int(c["target"])
	return total


func progress_text() -> String:
	var parts := PackedStringArray()
	for c in Missions.conditions(current()):
		var goal := int(c["target"])
		var count := "%d/%d" % [mini(_value(c["stat"]), goal), goal]
		parts.append(count if c["label"] == "" else "%s %s" % [c["label"], count])
	return " · ".join(parts)


func evaluate() -> void:
	while not is_finished() and _is_met(current()):
		var done := index
		var reward: Dictionary = current()["reward"]
		index += 1
		for kind in reward:
			_gs().add(kind, int(reward[kind]))
		mission_completed.emit(done, reward)
		mission_changed.emit(index)
	progress_changed.emit()


func _is_met(mission: Dictionary) -> bool:
	for c in Missions.conditions(mission):
		if _value(c["stat"]) < int(c["target"]):
			return false
	return true


func _value(stat: String) -> int:
	return Missions.value(stat, _gs().stats, _workers_alive())


func _gs() -> GameStateScript:
	return get_node_or_null("/root/GameState") as GameStateScript


func _workers_alive() -> int:
	var count := 0
	for worker in get_tree().get_nodes_in_group("workers"):
		if not worker.is_queued_for_deletion():
			count += 1
	return count


func _on_population_changed(_population: int, _cap: int) -> void:
	evaluate.call_deferred()


func _on_victory() -> void:
	if is_finished():
		return
	index = Missions.LIST.size()
	mission_changed.emit(index)
	progress_changed.emit()
