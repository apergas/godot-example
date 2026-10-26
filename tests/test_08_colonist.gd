extends SceneTree
## tests/test_08_colonist.gd — run: tools\godot.cmd --headless --path . --script res://tests/test_08_colonist.gd

const Sim := preload("res://tests/sim_helpers.gd")
const COLONIST := "res://scenes/colonist.tscn"
const SHIP := "res://scenes/rescue_ship.tscn"
const IDLE := 0
const MOVING := 1
const BOARDING := 2

var _failed := false


func _initialize() -> void:
	create_timer(60.0).timeout.connect(_on_timeout)
	await process_frame
	var world := Sim.new_world(self)
	var gs = Sim.game_state(self)
	var colonist := _add(world, Vector2i(10, 10))
	await process_frame

	_check("in_group", colonist.is_in_group("colonists") and not colonist.is_in_group("workers"), str(colonist.get_groups()))
	_check("layers", colonist.collision_layer == 2 and colonist.collision_mask == 1, "layer %d mask %d" % [colonist.collision_layer, colonist.collision_mask])
	var sprite := colonist.get_node("Sprite2D") as Sprite2D
	_check("sprite_layout", sprite.position == Vector2(0, -22) and sprite.hframes == 4 and sprite.vframes == 3
			and sprite.texture.resource_path == "res://assets/colonist.png"
			and sprite.texture.get_size() == Vector2(128, 96), str(sprite.position))
	var shape := (colonist.get_node("CollisionShape2D") as CollisionShape2D).shape as CircleShape2D
	_check("collision_radius_10", shape != null and is_equal_approx(shape.radius, 10.0), str(shape))
	_check("adds_population_and_colonist", gs.population == 1 and gs.colonists == 1, "%d %d" % [gs.population, gs.colonists])
	_check("picks_body", colonist.contains_point(colonist.global_position + Vector2(0, -22)), "body not picked")
	_check("misses_far", not colonist.contains_point(colonist.global_position + Vector2(60, 0)), "picked far away")
	_check("no_gather_or_build", not colonist.has_method("gather") and not colonist.has_method("build"), "has worker orders")
	world.remove_child(colonist)
	_check("exit_removes", gs.population == 0 and gs.colonists == 0, "%d %d" % [gs.population, gs.colonists])
	world.add_child(colonist)
	_check("re_add", gs.population == 1 and gs.colonists == 1, "%d %d" % [gs.population, gs.colonists])

	Sim.accelerate()
	var clock := Sim.clock_of(world)
	var target := Grid.cell_to_world(Vector2i(16, 10))
	colonist.move_to(target)
	_check("move_sets_moving", colonist.state == MOVING, str(colonist.state))
	var end := clock.seconds + 10.0
	while colonist.state == MOVING and clock.seconds < end:
		await physics_frame
	_check("move_reaches_target", colonist.state == IDLE and colonist.global_position.distance_to(target) < 8.0, str(colonist.global_position))
	_check("home_follows_order", colonist.home.distance_to(target) < 8.0, str(colonist.home))

	var max_distance := 0.0
	end = clock.seconds + 40.0
	while clock.seconds < end:
		await physics_frame
		max_distance = maxf(max_distance, colonist.global_position.distance_to(colonist.home))
	_check("wanders", max_distance > 16.0, str(max_distance))
	_check("wanders_within_3_tiles", max_distance <= (Colonist.WANDER_TILES + 0.75) * Grid.TILE, str(max_distance))

	var rect := Rect2i(Vector2i(22, 9), Vector2i(2, 2))
	Sim.nav(self).set_blocked(rect, true)
	var ship := (load(SHIP) as PackedScene).instantiate() as RescueShip
	ship.platform_rect = rect
	ship.position = Shipyard.platform_center(rect)
	world.add_child(ship)
	var boarded := [false]
	colonist.boarded.connect(func() -> void: boarded[0] = true)
	colonist.board(ship)
	_check("board_sets_boarding", colonist.state == BOARDING, str(colonist.state))
	end = clock.seconds + 15.0
	while not boarded[0] and clock.seconds < end:
		await physics_frame
	await process_frame
	Sim.restore()
	_check("boarded", boarded[0], "never boarded")
	_check("freed_after_boarding", not is_instance_valid(colonist), "colonist still alive")
	_check("boarding_removes_counts", gs.colonists == 0 and gs.population == 0, "%d %d" % [gs.colonists, gs.population])
	Sim.free_world(world)
	quit(1 if _failed else 0)


func _add(world: Node2D, cell: Vector2i) -> Colonist:
	var colonist := (load(COLONIST) as PackedScene).instantiate() as Colonist
	colonist.position = Grid.cell_to_world(cell)
	world.add_child(colonist)
	return colonist


func _check(test_name: String, ok: bool, why: String) -> void:
	if ok:
		print("PASS ", test_name)
	else:
		print("FAIL ", test_name, ": ", why)
		_failed = true


func _on_timeout() -> void:
	print("FAIL timeout: test did not finish (script error?)")
	quit(1)
