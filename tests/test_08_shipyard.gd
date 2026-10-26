extends SceneTree
## tests/test_08_shipyard.gd — run: tools\godot.cmd --headless --path . --script res://tests/test_08_shipyard.gd

const Sim := preload("res://tests/sim_helpers.gd")
const SHIPYARD := "res://scenes/buildings/shipyard.tscn"

var _failed := false


func _initialize() -> void:
	create_timer(30.0).timeout.connect(_on_timeout)
	await process_frame
	var world := Sim.new_world(self)
	var gs = Sim.game_state(self)
	var nav = Sim.nav(self)
	var yard := Sim.add_building(world, SHIPYARD, Vector2i(20, 10)) as Shipyard
	await process_frame
	yard.set_process(false)

	_check("scene_values", yard.footprint == Vector2i(3, 3) and is_equal_approx(yard.build_time, 30.0)
			and yard.kind_id == "shipyard" and yard.requires.is_empty(), "%s %f %s" % [yard.footprint, yard.build_time, yard.kind_id])
	_check("scene_cost", yard.cost.size() == 2 and int(yard.cost.get(ResKind.CRYSTAL, 0)) == 200
			and int(yard.cost.get(ResKind.ICE, 0)) == 100, str(yard.cost))
	_check("is_producer", yard is Producer, "Shipyard does not extend Producer")
	var sprite := yard.get_node("Sprite2D") as Sprite2D
	_check("sprite_layout", sprite.hframes == 2 and not sprite.centered and sprite.offset == Vector2(-48, -136)
			and sprite.scale == Vector2(2, 2) and sprite.texture.get_size() == Vector2(288, 144), str(sprite.offset))
	_check("ship_constants", Shipyard.SHIP_COST == {ResKind.CRYSTAL: 300, ResKind.ICE: 200}
			and Shipyard.SHIP_SECONDS == 60.0 and Shipyard.QUEUE_MAX == 2, "unexpected constants")
	_check("texts", yard.title() == "Astillero" and yard.unit_name() == "Nave", yard.title())

	_check("four_platforms", yard.platforms.size() == 4, str(yard.platforms))
	if yard.platforms.size() == 4:
		_check("platforms_in_a_row_right", yard.platforms[0] == Rect2i(23, 11, 2, 2)
				and yard.platforms[3] == Rect2i(29, 11, 2, 2), str(yard.platforms))
		var blocked := true
		for rect in yard.platforms:
			if nav.is_area_free(rect):
				blocked = false
		_check("platforms_blocked_in_nav", blocked, "a platform is walkable")
		_check("pads_drawn", yard.get_node_or_null("Pad0") != null and yard.get_node_or_null("Pad3") != null, "no pad sprites")

	_check("enqueue_rejects_without_money", not yard.enqueue() and yard.queue == 0, str(yard.queue))
	gs.add(ResKind.CRYSTAL, 2000)
	gs.add(ResKind.ICE, 2000)
	_check("enqueue_pays", yard.enqueue_ship() and yard.queue == 1 and gs.stock[ResKind.CRYSTAL] == 1750
			and gs.stock[ResKind.ICE] == 1800, str(gs.stock))
	_check("queue_max_two", yard.enqueue() and not yard.enqueue() and yard.queue == 2, str(yard.queue))

	var ships: Array = []
	yard.ship_spawned.connect(func(s: RescueShip) -> void: ships.append(s))
	yard._process(Shipyard.SHIP_SECONDS * 0.5)
	_check("half_progress", is_equal_approx(yard.train_progress(), 0.5) and ships.is_empty(), str(yard.train_progress()))
	yard._process(Shipyard.SHIP_SECONDS * 0.5 + 0.01)
	_check("ship_spawned", ships.size() == 1 and yard.queue == 1 and gs.ships == 1, "ships=%d queue=%d" % [ships.size(), yard.queue])
	if ships.size() == 1:
		var first: RescueShip = ships[0]
		_check("ship_on_first_platform", first.platform == 0 and first.platform_rect == yard.platforms[0]
				and first.global_position == Shipyard.platform_center(yard.platforms[0])
				and first.get_parent() == world, str(first.global_position))

	yard._process(Shipyard.SHIP_SECONDS + 0.01)
	yard.enqueue()
	yard.enqueue()
	yard._process(Shipyard.SHIP_SECONDS + 0.01)
	yard._process(Shipyard.SHIP_SECONDS + 0.01)
	_check("four_ships_parked", ships.size() == 4 and gs.ships == 4 and yard.free_platform() == -1, "ships=%d" % ships.size())
	yard.enqueue()
	for i in 3:
		yard._process(Shipyard.SHIP_SECONDS)
	_check("waits_without_free_platform", ships.size() == 4 and yard.queue == 1 and yard.is_blocked()
			and yard.train_progress() == 0.0, "ships=%d queue=%d" % [ships.size(), yard.queue])
	_check("blocked_text", yard.blocked_text() == "Sin plataforma libre — construye otro astillero", yard.blocked_text())
	(ships[1] as RescueShip).queue_free()
	await process_frame
	await process_frame
	_check("platform_freed", yard.free_platform() == 1 and not yard.is_blocked(), str(yard.free_platform()))
	yard._process(Shipyard.SHIP_SECONDS + 0.01)
	_check("resumes_on_freed_platform", ships.size() == 5 and (ships[4] as RescueShip).platform == 1, "ships=%d" % ships.size())

	var site := Sim.add_building(world, SHIPYARD, Vector2i(20, 30)) as Shipyard
	site.start_construction()
	_check("unbuilt_rejects", not site.enqueue(), "enqueued while under construction")

	nav.set_blocked(Rect2i(43, 21, 8, 2), true)
	var left := Sim.add_building(world, SHIPYARD, Vector2i(40, 20)) as Shipyard
	_check("falls_back_to_left_row", left.platforms.size() == 4 and left.platforms[0] == Rect2i(38, 21, 2, 2), str(left.platforms))
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
