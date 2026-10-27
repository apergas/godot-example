class_name ColonyModule extends Producer
## Wakes colonists from cryo sleep: each one costs resources and takes 1 population.
## Needs a finished shipyard to be placed (requires = ["shipyard"] in colony_module.tscn).

signal colonist_spawned(colonist: Colonist)

const NavScript := preload("res://scripts/nav.gd")
const COLONIST_COST := {ResKind.CRYSTAL: 30, ResKind.ICE: 75}
const COLONIST_SECONDS := 40.0
const QUEUE_MAX := 5
const COLONIST_SCENE := preload("res://scenes/colonist.tscn")
const SPAWN_OFFSETS := [Vector2.ZERO, Vector2(24, 0), Vector2(-24, 0), Vector2(0, 20), Vector2(24, 20)]

var _spawned := 0


func unit_cost() -> Dictionary:
	return COLONIST_COST


func unit_seconds() -> float:
	return COLONIST_SECONDS


func queue_max() -> int:
	return QUEUE_MAX


func title() -> String:
	return "Módulo de colonos"


func unit_name() -> String:
	return "Colono"


func blocked_text() -> String:
	return "Población máxima — construye habitáculos"


func enqueue_colonist() -> bool:
	return enqueue()


func _can_release() -> bool:
	var gs := get_node_or_null("/root/GameState") as GameStateScript
	return gs != null and gs.has_room()


func _release_unit() -> void:
	var from := global_position + Vector2(0, 32)
	var nav := get_node_or_null("/root/Nav") as NavScript
	var spot: Vector2 = nav.approach_point(cell_rect(), from) if nav else from
	spot += SPAWN_OFFSETS[_spawned % SPAWN_OFFSETS.size()]
	_spawned += 1
	var parent := get_parent() as Node2D
	var colonist := COLONIST_SCENE.instantiate() as Colonist
	colonist.position = parent.to_local(spot)
	colonist.home = spot
	parent.add_child(colonist)
	colonist_spawned.emit(colonist)
