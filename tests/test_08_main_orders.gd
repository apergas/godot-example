extends SceneTree
## tests/test_08_main_orders.gd — run: tools\godot.cmd --headless --path . --script res://tests/test_08_main_orders.gd

const COLONIST := "res://scenes/colonist.tscn"
const HABITAT := "res://scenes/buildings/habitat.tscn"
const SHIPYARD := "res://scenes/buildings/shipyard.tscn"
const IDLE := 0
const MOVING := 1
const TO_RESOURCE := 2

var _failed := false


func _initialize() -> void:
	create_timer(30.0).timeout.connect(_on_timeout)
	await process_frame
	var gs = root.get_node("GameState")
	gs.reset()
	root.get_node("Nav").reset()
	var main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var world: Node2D = main.get_node("World")
	var selection: Selection = main.get_node("Selection")
	_check("victory_node", main.get_node_or_null("Victory") is Victory, "no Victory node in main.tscn")

	var colonist := (load(COLONIST) as PackedScene).instantiate() as Colonist
	colonist.position = Grid.cell_to_world(Vector2i(14, 27))
	world.add_child(colonist)
	await process_frame
	colonist.set_physics_process(false)
	var worker = get_nodes_in_group("workers")[0]
	var crystal := _nearest_crystal(worker.global_position)
	var on_crystal := crystal.global_position + Vector2(0, -16)

	selection.select([colonist, worker])
	_check("selected_colonists", main._selected_colonists() == [colonist], str(main._selected_colonists()))
	main._command_right_click(on_crystal)
	_check("worker_gathers", worker.state == TO_RESOURCE, str(worker.state))
	_check("colonist_only_moves", colonist.state == MOVING, str(colonist.state))

	var site := (load(HABITAT) as PackedScene).instantiate() as Building
	var cell := Vector2i(20, 30)
	site.position = Grid.footprint_origin(cell, site.footprint)
	world.add_child(site)
	site.start_construction()
	selection.select([colonist])
	var centre := (Vector2(cell) + Vector2(site.footprint) / 2.0) * Grid.TILE
	_check("colonist_is_not_a_builder", not main._try_build_order(centre), "build order with only colonists")
	main._command_right_click(centre)
	_check("colonist_moves_to_site", colonist.state == MOVING, str(colonist.state))

	gs.add(ResKind.CRYSTAL, 1000)
	gs.add(ResKind.ICE, 1000)
	var yard := (load(SHIPYARD) as PackedScene).instantiate() as Shipyard
	yard.position = Grid.footprint_origin(Vector2i(14, 4), yard.footprint)
	world.add_child(yard)
	main.get_node("HUD").produce_requested.emit(yard)
	_check("produce_request_enqueues", yard.queue == 1, str(yard.queue))

	var victory: Victory = main.get_node("Victory")
	victory.active = true
	selection.select([colonist])
	colonist.state = Colonist.State.IDLE
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	click.pressed = true
	main._unhandled_input(click)
	_check("no_orders_during_victory", colonist.state == IDLE, str(colonist.state))
	victory.active = false
	main._unhandled_input(click)
	_check("orders_again_without_victory", colonist.state == MOVING, str(colonist.state))
	quit(1 if _failed else 0)


func _nearest_crystal(from: Vector2) -> ResourceNode:
	var best: ResourceNode = null
	for node in get_nodes_in_group("resources"):
		var res := node as ResourceNode
		if res != null and res.kind == ResKind.CRYSTAL and (best == null
				or res.global_position.distance_to(from) < best.global_position.distance_to(from)):
			best = res
	return best


func _check(test_name: String, ok: bool, why: String) -> void:
	if ok:
		print("PASS ", test_name)
	else:
		print("FAIL ", test_name, ": ", why)
		_failed = true


func _on_timeout() -> void:
	print("FAIL timeout: test did not finish (script error?)")
	quit(1)
