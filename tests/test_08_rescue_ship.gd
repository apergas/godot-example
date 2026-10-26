extends SceneTree
## tests/test_08_rescue_ship.gd — run: tools\godot.cmd --headless --path . --script res://tests/test_08_rescue_ship.gd

const Sim := preload("res://tests/sim_helpers.gd")
const SHIP := "res://scenes/rescue_ship.tscn"

var _failed := false


func _initialize() -> void:
	create_timer(30.0).timeout.connect(_on_timeout)
	await process_frame
	var world := Sim.new_world(self)
	var gs = Sim.game_state(self)
	var goals: Array = []
	gs.goal_changed.connect(func(c: int, s: int) -> void: goals.append([c, s]))
	var ship := (load(SHIP) as PackedScene).instantiate() as RescueShip
	ship.position = Vector2(640, 640)
	world.add_child(ship)
	await process_frame

	_check("in_ships_group", ship.is_in_group("ships"), str(ship.get_groups()))
	_check("enter_adds_ship", gs.ships == 1 and goals.back() == [0, 1], "%d %s" % [gs.ships, goals])
	var sprite := ship.get_node("Sprite2D") as Sprite2D
	var shadow := ship.get_node("Shadow") as Sprite2D
	_check("sprite_layout", sprite.texture.resource_path == "res://assets/rescue_ship.png" and sprite.hframes == 3
			and sprite.frame == 0 and not sprite.centered and sprite.offset == Vector2(-32, -80)
			and sprite.scale == Vector2(2, 2), "frame %d offset %s" % [sprite.frame, sprite.offset])
	_check("texture_size", sprite.texture.get_size() == Vector2(312, 104), str(sprite.texture.get_size()))
	_check("shadow_frame", shadow.frame == 2 and shadow.hframes == 3 and shadow.offset == Vector2(-32, -80), str(shadow.frame))
	_check("picks_hull", ship.contains_point(ship.global_position + Vector2(0, -80)), "hull not picked")
	_check("misses_ground_in_front", not ship.contains_point(ship.global_position + Vector2(0, 40)), "picked below the ship")
	ship.selected = true
	_check("selectable", ship.selected, "selected stayed false")

	var launched := [false]
	ship.launched.connect(func() -> void: launched[0] = true)
	Sim.accelerate()
	ship.launch()
	_check("launch_flags", ship.launching and not ship.selected and sprite.frame == 1, "frame %d" % sprite.frame)
	_check("not_pickable_while_launching", not ship.contains_point(ship.global_position + Vector2(0, -80)), "picked")
	await Sim.run_for(self, world, RescueShip.LAUNCH_SECONDS * 0.5)
	_check("rises", sprite.position.y < -100.0, str(sprite.position.y))
	await Sim.run_for(self, world, RescueShip.LAUNCH_SECONDS)
	await process_frame
	Sim.restore()
	_check("launched_signal", launched[0], "launched not emitted")
	_check("freed_after_launch", not is_instance_valid(ship), "ship still alive")
	_check("exit_removes_ship", gs.ships == 0, str(gs.ships))
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
