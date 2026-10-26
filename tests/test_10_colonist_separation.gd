extends SceneTree
## tests/test_10_colonist_separation.gd â€” run: tools\godot.cmd --headless --path . --script res://tests/test_10_colonist_separation.gd

const Sim := preload("res://tests/sim_helpers.gd")
const COLONIST := "res://scenes/colonist.tscn"
const COUNT := 4

var _failed := false


func _initialize() -> void:
	create_timer(60.0).timeout.connect(_on_timeout)
	await process_frame
	var world := Sim.new_world(self)
	var colonists: Array[Colonist] = []
	for i in COUNT:
		var colonist := (load(COLONIST) as PackedScene).instantiate() as Colonist
		colonist.position = Grid.cell_to_world(Vector2i(8 + i, 10))
		world.add_child(colonist)
		colonists.append(colonist)
	await process_frame

	Sim.accelerate()
	var target := Grid.cell_to_world(Vector2i(16, 10))
	for colonist in colonists:
		colonist.move_to(target)
	await Sim.run_for(self, world, 5.2)
	Sim.restore()

	var min_distance := INF
	var max_from_target := 0.0
	for i in colonists.size():
		max_from_target = maxf(max_from_target, colonists[i].global_position.distance_to(target))
		for j in range(i + 1, colonists.size()):
			min_distance = minf(min_distance, colonists[i].global_position.distance_to(colonists[j].global_position))
	_check("colonists_apart", min_distance >= Worker.SEPARATION_DISTANCE * 0.7, "min distance %.1f" % min_distance)
	_check("colonists_near_target", max_from_target <= 2.0 * Grid.TILE, "max from target %.1f" % max_from_target)
	Sim.free_world(world)
	quit(1 if _failed else 0)


func _check(test_name: String, ok: bool, why: String) -> void:
	if ok:
		print("PASS ", test_name)
	else:
		print("FAIL ", test_name, ": ", why)
		_failed = true


func _on_timeout() -> void:
	print("FAIL timeout: test did not finish (script error?)")
	quit(1)
