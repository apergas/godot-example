extends SceneTree

# Values of Worker.State (contract order: IDLE, MOVING, TO_RESOURCE, GATHERING, TO_DROPOFF, TO_BUILD, BUILDING).
const IDLE := 0
const TO_BUILD := 5
const BUILDING := 6
const HABITAT := "res://scenes/buildings/habitat.tscn"
const WORKER := "res://scenes/worker.tscn"
const SITE_CELL := Vector2i(20, 10)

var _failed := false
var _gs
var _nav
var _step := 1.0 / 60.0


func _initialize() -> void:
	await process_frame
	_gs = root.get_node("GameState")
	_nav = root.get_node("Nav")
	_step = 1.0 / Engine.physics_ticks_per_second
	var single := await _test_one_builder()
	await _test_two_builders(single)
	await _test_abandon_and_resume()
	quit(1 if _failed else 0)


func _check(name: String, ok: bool, why: String = "") -> void:
	if ok:
		print("PASS ", name)
	else:
		_failed = true
		print("FAIL ", name, ": ", why)


func _setup() -> Node2D:
	_gs.reset()
	_nav.reset()
	var world := Node2D.new()
	world.y_sort_enabled = true
	root.add_child(world)
	return world


func _spawn_site(world: Node2D) -> Building:
	var site := (load(HABITAT) as PackedScene).instantiate() as Building
	site.position = Grid.footprint_origin(SITE_CELL, site.footprint)
	world.add_child(site)
	site.start_construction()
	return site


func _spawn_worker(world: Node2D, cell: Vector2i):
	var w = (load(WORKER) as PackedScene).instantiate()
	w.position = Grid.cell_to_world(cell)
	world.add_child(w)
	return w


func _teardown(world: Node2D) -> void:
	world.queue_free()
	await process_frame


## Returns the simulated seconds from the build order until the site is built.
func _test_one_builder() -> float:
	var world := _setup()
	var site := _spawn_site(world)
	var w = _spawn_worker(world, Vector2i(17, 11))
	await physics_frame
	var cap0: int = _gs.population_cap
	w.build(site)
	_check("one: order sets TO_BUILD", w.state == TO_BUILD, str(w.state))
	var t := 0.0
	var working := 0.0
	var mid_checked := false
	while not site.built and t < 20.0:
		await physics_frame
		t += _step
		if w.state == BUILDING:
			working += _step
		if working > 6.0 and not mid_checked:
			mid_checked = true
			_check("one: cap unchanged half way", _gs.population_cap == cap0 and not site.built)
			_check("one: progress about half", absf(site.build_progress - 0.5) < 0.05, str(site.build_progress))
	await physics_frame
	_check("one: site completed", site.built)
	_check("one: about 12 s of work", working > 11.7 and working < 12.3, "%.2f s" % working)
	_check("one: total time includes a short walk", t > 12.0 and t < 14.5, "%.2f s" % t)
	_check("one: worker idle afterwards", w.state == IDLE, str(w.state))
	_check("one: cap +5 after completion", _gs.population_cap == cap0 + 5, str(_gs.population_cap))
	await _teardown(world)
	return t


func _test_two_builders(single: float) -> void:
	var world := _setup()
	var site := _spawn_site(world)
	var a = _spawn_worker(world, Vector2i(17, 11))
	var b = _spawn_worker(world, Vector2i(24, 11))
	await physics_frame
	a.build(site)
	b.build(site)
	var t := 0.0
	var both := false
	while not site.built and t < 20.0:
		await physics_frame
		t += _step
		if a.state == BUILDING and b.state == BUILDING:
			both = true
	await physics_frame
	_check("two: both robots worked at once", both)
	_check("two: about 6 s", t > 6.0 and t < 8.0, "%.2f s" % t)
	_check("two: faster than one", t < single * 0.7, "%.2f vs %.2f" % [t, single])
	_check("two: both idle afterwards", a.state == IDLE and b.state == IDLE)
	await _teardown(world)


func _test_abandon_and_resume() -> void:
	var world := _setup()
	var site := _spawn_site(world)
	var w = _spawn_worker(world, Vector2i(17, 11))
	await physics_frame
	w.build(site)
	var working := 0.0
	var t := 0.0
	while working < 3.0 and t < 10.0:
		await physics_frame
		t += _step
		if w.state == BUILDING:
			working += _step
	w.move_to(Grid.cell_to_world(Vector2i(14, 11)))
	var progress: float = site.build_progress
	for i in 120:
		await physics_frame
	_check("abandon: progress kept, not built", not site.built and is_equal_approx(site.build_progress, progress) and progress > 0.2,
		"%.3f -> %.3f" % [progress, site.build_progress])
	_check("abandon: worker no longer building", w.state != BUILDING and w.state != TO_BUILD, str(w.state))
	w.build(site)
	t = 0.0
	while not site.built and t < 15.0:
		await physics_frame
		t += _step
	_check("resume: site completed", site.built, "%.3f" % site.build_progress)
	_check("resume: remaining work only", t < 12.0, "%.2f s" % t)
	await _teardown(world)
