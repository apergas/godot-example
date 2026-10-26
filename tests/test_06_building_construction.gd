extends SceneTree

var _failed := false
var _gs
var _nav


func _initialize() -> void:
	create_timer(20.0).timeout.connect(_on_timeout)
	await process_frame
	_gs = root.get_node("GameState")
	_nav = root.get_node("Nav")
	await _test_construction_cycle()
	await _test_start_before_tree()
	await _test_dropoff_waits_until_built()
	quit(1 if _failed else 0)


func _on_timeout() -> void:
	print("FAIL timeout: test did not finish (script error?)")
	quit(1)


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
	root.add_child(world)
	return world


func _make_building(cell: Vector2i, bonus: int, kinds: Array[int], frames: int) -> Building:
	var b := Building.new()
	b.footprint = Vector2i(2, 2)
	b.build_time = 12.0
	b.pop_cap_bonus = bonus
	b.accepts_kinds = kinds
	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = ImageTexture.create_from_image(Image.create(80 * frames, 80, false, Image.FORMAT_RGBA8))
	sprite.hframes = frames
	sprite.centered = false
	sprite.offset = Vector2(-32, -80)
	sprite.scale = Vector2(2, 2)
	b.add_child(sprite)
	b.position = Grid.footprint_origin(cell, b.footprint)
	return b


func _test_construction_cycle() -> void:
	var world := _setup()
	var cap0: int = _gs.population_cap
	var none: Array[int] = []
	var b := _make_building(Vector2i(20, 10), 5, none, 2)
	world.add_child(b)
	await process_frame  # Building applies its cap deferred from _ready
	_check("built building counts its cap", _gs.population_cap == cap0 + 5, str(_gs.population_cap))
	b.start_construction()
	_check("start_construction resets state", not b.built and b.build_progress == 0.0)
	_check("start_construction removes cap", _gs.population_cap == cap0, str(_gs.population_cap))
	var sprite := b.get_node("Sprite2D") as Sprite2D
	_check("scaffold frame while building", sprite.frame == 1 and sprite.modulate.a < 1.0, "frame %d alpha %f" % [sprite.frame, sprite.modulate.a])
	var bar := b.get_node_or_null("BuildBar") as Node2D
	_check("build bar exists and is visible", bar != null and bar.visible)
	_check("build bar sits above the sprite", bar != null and bar.position.y < -160.0, str(bar.position if bar else null))
	var emitted := [0]
	b.completed.connect(func() -> void: emitted[0] += 1)
	b.add_build_progress(6.0)
	_check("half progress after half the time", is_equal_approx(b.build_progress, 0.5) and not b.built, str(b.build_progress))
	_check("no cap while under construction", _gs.population_cap == cap0)
	b.add_build_progress(6.5)
	_check("completes at build_time", b.built and b.build_progress == 1.0 and emitted[0] == 1)
	_check("cap added on completion", _gs.population_cap == cap0 + 5, str(_gs.population_cap))
	_check("finished look", sprite.frame == 0 and sprite.modulate.a == 1.0 and not bar.visible)
	b.add_build_progress(5.0)
	_check("no double completion", emitted[0] == 1 and _gs.population_cap == cap0 + 5)
	b.queue_free()
	await process_frame
	_check("cap removed when freed", _gs.population_cap == cap0, str(_gs.population_cap))
	world.queue_free()
	await process_frame


func _test_start_before_tree() -> void:
	var world := _setup()
	var cap0: int = _gs.population_cap
	var none: Array[int] = []
	var b := _make_building(Vector2i(30, 10), 5, none, 2)
	b.start_construction()
	world.add_child(b)
	await process_frame
	_check("start before tree: no cap", _gs.population_cap == cap0 and not b.built)
	_check("start before tree: scaffold", (b.get_node("Sprite2D") as Sprite2D).frame == 1)
	b.add_build_progress(12.0)
	_check("start before tree: completes with cap", b.built and _gs.population_cap == cap0 + 5)
	world.queue_free()
	await process_frame


func _test_dropoff_waits_until_built() -> void:
	var world := _setup()
	var kinds: Array[int] = [ResKind.CRYSTAL]
	var d := _make_building(Vector2i(40, 10), 0, kinds, 1)
	world.add_child(d)
	d.start_construction()
	var sprite := d.get_node("Sprite2D") as Sprite2D
	_check("dropoff is in group", d.is_in_group("dropoffs"))
	_check("single-frame sprite stays on frame 0 but translucent", sprite.frame == 0 and sprite.modulate.a < 1.0)
	_check("no resources accepted while building", not d.accepts(ResKind.CRYSTAL))
	d.add_build_progress(12.0)
	_check("resources accepted once built", d.accepts(ResKind.CRYSTAL))
	world.queue_free()
	await process_frame
