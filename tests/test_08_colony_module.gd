extends SceneTree
## tests/test_08_colony_module.gd — run: tools\godot.cmd --headless --path . --script res://tests/test_08_colony_module.gd

const Sim := preload("res://tests/sim_helpers.gd")
const MODULE := "res://scenes/buildings/colony_module.tscn"
const SHIPYARD := "res://scenes/buildings/shipyard.tscn"

var _failed := false


func _initialize() -> void:
	create_timer(30.0).timeout.connect(_on_timeout)
	await process_frame
	var world := Sim.new_world(self)
	var gs = Sim.game_state(self)
	var module := Sim.add_building(world, MODULE, Vector2i(20, 10)) as ColonyModule
	await process_frame
	module.set_process(false)

	_check("scene_values", module.footprint == Vector2i(3, 2) and is_equal_approx(module.build_time, 20.0)
			and module.kind_id == "colony_module", "%s %f %s" % [module.footprint, module.build_time, module.kind_id])
	_check("scene_cost", module.cost.size() == 2 and int(module.cost.get(ResKind.CRYSTAL, 0)) == 100
			and int(module.cost.get(ResKind.ICE, 0)) == 150, str(module.cost))
	_check("requires_shipyard", module.requires.size() == 1 and module.requires[0] == "shipyard", str(module.requires))
	var sprite := module.get_node("Sprite2D") as Sprite2D
	_check("sprite_layout", sprite.hframes == 2 and not sprite.centered and sprite.offset == Vector2(-48, -104)
			and sprite.texture.get_size() == Vector2(256, 112), str(sprite.offset))
	_check("cell_rect", module.cell_rect() == Rect2i(20, 10, 3, 2), str(module.cell_rect()))
	_check("colonist_constants", ColonyModule.COLONIST_COST == {ResKind.CRYSTAL: 30, ResKind.ICE: 75}
			and ColonyModule.COLONIST_SECONDS == 40.0 and ColonyModule.QUEUE_MAX == 5, "unexpected constants")
	_check("texts", module.title() == "Módulo de colonos" and module.unit_name() == "Colono", module.title())

	_check("enqueue_rejects_without_money", not module.enqueue_colonist() and module.queue == 0, str(module.queue))
	gs.add(ResKind.CRYSTAL, 1000)
	gs.add(ResKind.ICE, 1000)
	for i in 5:
		module.enqueue()
	_check("queue_max_five", module.queue == 5 and not module.enqueue(), str(module.queue))
	_check("paid_each", gs.stock[ResKind.CRYSTAL] == 900 and gs.stock[ResKind.ICE] == 625, str(gs.stock))

	var spawned: Array = []
	module.colonist_spawned.connect(func(c: Colonist) -> void: spawned.append(c))
	_check("no_population_room", not gs.has_room(), "%d/%d" % [gs.population, gs.population_cap])
	for i in 3:
		module._process(ColonyModule.COLONIST_SECONDS)
	_check("waits_without_population", spawned.is_empty() and module.queue == 5 and module.is_blocked()
			and module.train_progress() == 0.0, "spawned=%d queue=%d" % [spawned.size(), module.queue])
	_check("blocked_text", module.blocked_text() == "Población máxima — construye habitáculos", module.blocked_text())
	gs.add_cap(2)
	module._process(ColonyModule.COLONIST_SECONDS + 0.01)
	_check("colonist_spawned", spawned.size() == 1 and module.queue == 4, "spawned=%d queue=%d" % [spawned.size(), module.queue])
	_check("colonist_counts", gs.population == 1 and gs.colonists == 1, "%d %d" % [gs.population, gs.colonists])
	if spawned.size() == 1:
		var c: Colonist = spawned[0]
		_check("spawn_in_world", c.get_parent() == world and c.is_in_group("colonists"), str(c.get_parent()))
		_check("spawn_next_to_module", c.global_position.distance_to(module.global_position) < Grid.TILE * 4.0
				and not module.cell_rect().has_point(Grid.world_to_cell(c.global_position)), str(c.global_position))
		_check("home_is_spawn_point", c.home.distance_to(c.global_position) < 1.0, str(c.home))
	module._process(ColonyModule.COLONIST_SECONDS + 0.01)
	module._process(ColonyModule.COLONIST_SECONDS + 0.01)
	_check("stops_at_cap_again", spawned.size() == 2 and module.is_blocked(), str(spawned.size()))

	var placement := Placement.new()
	placement.world = world
	root.add_child(placement)
	placement.begin(load(MODULE) as PackedScene)
	_check("placement_needs_shipyard", not placement.is_valid_at(Vector2i(30, 30)), "valid without shipyard")
	Sim.add_building(world, SHIPYARD, Vector2i(40, 30))
	_check("placement_ok_with_shipyard", placement.is_valid_at(Vector2i(30, 30)), "invalid with a shipyard")
	placement.cancel()
	placement.free()
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
