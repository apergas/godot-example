extends SceneTree

const HABITAT := "res://scenes/buildings/habitat.tscn"

var _failed := false


func _initialize() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	var nav = root.get_node("Nav")
	gs.reset()
	nav.reset()
	var scene := load(HABITAT) as PackedScene
	_check("scene loads", scene != null)
	if scene == null:
		quit(1)
		return
	var h := scene.instantiate() as Building
	_check("root is a Building", h != null)
	_check("footprint 2x2", h.footprint == Vector2i(2, 2))
	_check("build time 12 s", is_equal_approx(h.build_time, 12.0))
	_check("pop cap bonus 5", h.pop_cap_bonus == 5)
	_check("cost 30 crystal + 60 ice", h.cost.size() == 2 and h.cost.get(ResKind.CRYSTAL, 0) == 30 and h.cost.get(ResKind.ICE, 0) == 60, str(h.cost))
	_check("not a dropoff", h.accepts_kinds.is_empty())
	var sprite := h.get_node("Sprite2D") as Sprite2D
	_check("two frames", sprite.hframes == 2 and sprite.texture.get_size() == Vector2(160, 80))
	var rect := sprite.transform * sprite.get_rect()
	_check("sprite bottom on origin, footprint centred", rect.position == Vector2(-64, -160) and rect.size == Vector2(160, 160), str(rect))
	_check("has collision", h.get_node_or_null("CollisionShape2D") != null)

	var world := Node2D.new()
	root.add_child(world)
	var cap0: int = gs.population_cap
	h.position = Grid.footprint_origin(Vector2i(20, 10), h.footprint)
	world.add_child(h)
	h.start_construction()
	_check("cell from origin", h.cell == Vector2i(20, 10), str(h.cell))
	_check("cap unchanged while building", gs.population_cap == cap0)
	h.add_build_progress(11.9)
	_check("not done at 11.9 s", not h.built)
	h.add_build_progress(0.1)
	_check("done at 12 s with +5 cap", h.built and gs.population_cap == cap0 + 5, str(gs.population_cap))
	quit(1 if _failed else 0)


func _check(name: String, ok: bool, why: String = "") -> void:
	if ok:
		print("PASS ", name)
	else:
		_failed = true
		print("FAIL ", name, ": ", why)
