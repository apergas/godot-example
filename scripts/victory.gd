class_name Victory extends Node
## Evacuation when GameState.victory fires: orders stop, colonists walk to the ships and vanish,
## the ships launch one after another, then the victory screen shows the totals.

signal finished

const GameStateScript := preload("res://scripts/game_state.gd")
const SCREEN_SCENE := preload("res://scenes/victory_screen.tscn")
const BOARD_TIMEOUT := 8.0
const LAUNCH_STAGGER := 0.6
const SCREEN_DELAY := 1.0

var active := false
var totals := {}
var screen: VictoryScreen = null


func _ready() -> void:
	var game := _game()
	if game != null:
		game.victory.connect(_on_victory)


func collect_totals() -> Dictionary:
	var game := _game()
	return {
		"time": game.play_time,
		"colonists": game.colonists,
		"ships": game.ships,
		"crystal": game.gathered[ResKind.CRYSTAL],
		"ice": game.gathered[ResKind.ICE],
		"workers": get_tree().get_nodes_in_group("workers").size(),
	}


func _game() -> GameStateScript:
	return get_node_or_null("/root/GameState") as GameStateScript


func _on_victory() -> void:
	if active:
		return
	active = true
	totals = collect_totals()
	_stop_production()
	_play()


func _play() -> void:
	# The unit that reached the goal may still be entering the tree: start on the next frame.
	await get_tree().process_frame
	_stop_orders()
	await _board_colonists()
	await _launch_ships()
	await get_tree().create_timer(SCREEN_DELAY).timeout
	_show_screen()
	finished.emit()


func _stop_orders() -> void:
	var main := get_parent()
	var placement := main.get_node_or_null("Placement") as Placement
	if placement != null:
		placement.cancel()
	var selection := main.get_node_or_null("Selection") as Selection
	if selection != null:
		selection.clear()
	var hud := main.get_node_or_null("HUD") as CanvasLayer
	if hud != null:
		hud.visible = false


func _board_colonists() -> void:
	var ships := _parked_ships()
	for node in get_tree().get_nodes_in_group("colonists"):
		var colonist := node as Colonist
		if colonist == null:
			continue
		if ships.is_empty():
			colonist.vanish()
		else:
			colonist.board(_nearest(colonist.global_position, ships))
	var timer := get_tree().create_timer(BOARD_TIMEOUT)
	while timer.time_left > 0.0 and not get_tree().get_nodes_in_group("colonists").is_empty():
		await get_tree().process_frame
	if get_tree().get_nodes_in_group("colonists").is_empty():
		return
	for node in get_tree().get_nodes_in_group("colonists"):
		(node as Colonist).vanish()
	await get_tree().create_timer(Colonist.VANISH_SECONDS + 0.1).timeout


func _launch_ships() -> void:
	var ships := _parked_ships()
	for ship in ships:
		ship.launch()
		await get_tree().create_timer(LAUNCH_STAGGER).timeout
	if not ships.is_empty():
		await get_tree().create_timer(RescueShip.LAUNCH_SECONDS).timeout


func _show_screen() -> void:
	screen = SCREEN_SCENE.instantiate() as VictoryScreen
	add_child(screen)
	var shown := totals.duplicate()
	# Read now, not in collect_totals(): MissionTracker completes the final mission on the victory signal.
	var tracker := get_parent().get_node_or_null("MissionTracker") as MissionTracker
	if tracker != null:
		shown["missions"] = tracker.index
		shown["missions_total"] = Missions.LIST.size()
	screen.setup(shown)
	screen.restart_requested.connect(_on_restart_requested)


func _on_restart_requested() -> void:
	var game := _game()
	if game != null:
		game.restart_game()


func _parked_ships() -> Array[RescueShip]:
	var result: Array[RescueShip] = []
	for node in get_tree().get_nodes_in_group("ships"):
		var ship := node as RescueShip
		if ship != null and not ship.launching:
			result.append(ship)
	return result


static func _nearest(point: Vector2, ships: Array[RescueShip]) -> RescueShip:
	var best: RescueShip = ships[0]
	for ship in ships:
		if ship.global_position.distance_squared_to(point) < best.global_position.distance_squared_to(point):
			best = ship
	return best


## A queued unit finishing after the boarding snapshot would never board or launch.
func _stop_production() -> void:
	for node in get_tree().get_nodes_in_group("buildings"):
		if node is Producer:
			node.set_process(false)
