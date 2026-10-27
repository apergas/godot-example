extends SceneTree
## tests/test_08_victory_stops_production.gd — run: tools\godot.cmd --headless --path . --script res://tests/test_08_victory_stops_production.gd

const SHIPYARD := "res://scenes/buildings/shipyard.tscn"

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
	gs.add(ResKind.CRYSTAL, 1000)
	gs.add(ResKind.ICE, 1000)
	var yard := (load(SHIPYARD) as PackedScene).instantiate() as Shipyard
	yard.position = Grid.footprint_origin(Vector2i(14, 4), yard.footprint)
	main.get_node("World").add_child(yard)
	await process_frame
	_check("processing_before", yard.is_processing(), "yard not processing")
	main.get_node("Victory")._on_victory()
	_check("processing_stopped", not yard.is_processing(), "yard still processing after victory")
	var hq := get_nodes_in_group("buildings").filter(func(b) -> bool: return b is HQ)[0] as HQ
	_check("hq_stopped", not hq.is_processing(), "hq still processing after victory")
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
