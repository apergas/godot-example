extends SceneTree
## tests/test_08_victory.gd — run: tools\godot.cmd --headless --path . --script res://tests/test_08_victory.gd

const Sim := preload("res://tests/sim_helpers.gd")
const COLONIST := "res://scenes/colonist.tscn"
const SHIP := "res://scenes/rescue_ship.tscn"

var _failed := false
var _wins := 0


func _initialize() -> void:
	create_timer(60.0).timeout.connect(_on_timeout)
	await process_frame
	_check("format_time", VictoryScreen.format_time(83.4) == "01:23" and VictoryScreen.format_time(1505.0) == "25:05",
			VictoryScreen.format_time(83.4))
	var world := Sim.new_world(self)
	var gs = Sim.game_state(self)
	var main := Node2D.new()
	main.name = "Main"
	root.add_child(main)
	var victory := Victory.new()
	victory.name = "Victory"
	main.add_child(victory)
	gs.victory.connect(_on_victory)
	gs.goal_colonists = 2
	gs.goal_ships = 1
	gs.add(ResKind.CRYSTAL, 120, true)
	gs.add(ResKind.ICE, 80, true)

	var rect := Rect2i(30, 10, 2, 2)
	Sim.nav(self).set_blocked(rect, true)
	var ship := (load(SHIP) as PackedScene).instantiate() as RescueShip
	ship.platform_rect = rect
	ship.position = Shipyard.platform_center(rect)
	world.add_child(ship)
	_add_colonist(world, Vector2i(26, 11))
	_check("no_victory_yet", _wins == 0 and not victory.active, str(_wins))
	_add_colonist(world, Vector2i(26, 13))
	_check("victory_emitted_once", _wins == 1 and victory.active, str(_wins))
	_check("totals_captured", victory.totals["colonists"] == 2 and victory.totals["ships"] == 1
			and victory.totals["crystal"] == 120 and victory.totals["ice"] == 80, str(victory.totals))

	Sim.accelerate()
	var clock := Sim.clock_of(world)
	var end := clock.seconds + 30.0
	while victory.screen == null and clock.seconds < end:
		await physics_frame
	await process_frame
	Sim.restore()
	_check("colonists_boarded", get_nodes_in_group("colonists").is_empty(), str(get_nodes_in_group("colonists").size()))
	_check("ships_launched", get_nodes_in_group("ships").is_empty(), str(get_nodes_in_group("ships").size()))
	_check("screen_shown", victory.screen != null and victory.screen.is_inside_tree(), "no victory screen")
	if victory.screen != null:
		var screen := victory.screen
		_check("screen_title", (screen.get_node("%Title") as Label).text == "Evacuación completada", "title")
		_check("screen_colonists", (screen.get_node("%ColonistsLabel") as Label).text == "Colonos evacuados: 2",
				(screen.get_node("%ColonistsLabel") as Label).text)
		_check("screen_ships", (screen.get_node("%ShipsLabel") as Label).text == "Naves lanzadas: 1",
				(screen.get_node("%ShipsLabel") as Label).text)
		_check("screen_gathered", (screen.get_node("%GatheredLabel") as Label).text == "Recogido: 120 cristal · 80 hielo",
				(screen.get_node("%GatheredLabel") as Label).text)
		_check("screen_time", (screen.get_node("%TimeLabel") as Label).text.begins_with("Tiempo de partida: "),
				(screen.get_node("%TimeLabel") as Label).text)
		_check("restart_button", (screen.get_node("%RestartButton") as Button).text == "Jugar de nuevo", "button")
	gs.add_colonist(1)
	gs.add_ship(1)
	_check("victory_not_repeated", _wins == 1, str(_wins))
	main.queue_free()
	Sim.free_world(world)
	gs.reset()
	quit(1 if _failed else 0)


func _on_victory() -> void:
	_wins += 1


func _add_colonist(world: Node2D, cell: Vector2i) -> void:
	var colonist := (load(COLONIST) as PackedScene).instantiate() as Colonist
	colonist.position = Grid.cell_to_world(cell)
	world.add_child(colonist)


func _check(test_name: String, ok: bool, why: String) -> void:
	if ok:
		print("PASS ", test_name)
	else:
		print("FAIL ", test_name, ": ", why)
		_failed = true


func _on_timeout() -> void:
	print("FAIL timeout: test did not finish (script error?)")
	quit(1)
