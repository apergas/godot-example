class_name Colonist extends CharacterBody2D
## Human colonist made by a ColonyModule. Walks along Nav paths, wanders near its home when
## idle and, at the end of the game, walks to a rescue ship and vanishes. Never gathers or builds.

signal boarded

enum State { IDLE, MOVING, BOARDING }

const NavScript := preload("res://scripts/nav.gd")
const GameStateScript := preload("res://scripts/game_state.gd")
const PICK_RADIUS := 20.0
const SPRITE_Y := -22.0
const ARRIVE_DISTANCE := 4.0
const STUCK_SECONDS := 0.5
const WALK_FPS := 8.0
const WANDER_TILES := 3
const WANDER_SPEED_FACTOR := 0.5
const WANDER_PAUSE_MIN := 2.0
const WANDER_PAUSE_MAX := 5.0
const VANISH_SECONDS := 0.4
const SELECT_COLOR := Color(0.3, 1.0, 0.4)

# Rows of the spritesheet (see art_src/make_colonist.gd); columns are walk phases.
const ROW_DOWN := 0
const ROW_UP := 1
const ROW_SIDE := 2
const PHASES := 4

@export var speed := 140.0

var selected := false:
	set(value):
		selected = value
		queue_redraw()

var state: State = State.IDLE
var home := Vector2.ZERO
var leaving := false

var _path := PackedVector2Array()
var _path_index := 0
var _stuck_time := 0.0
var _walk_time := 0.0
var _row := ROW_DOWN
var _wandering := false
var _wander_wait := 0.0
var _rng := RandomNumberGenerator.new()

@onready var _sprite: Sprite2D = $Sprite2D


func _enter_tree() -> void:
	add_to_group("colonists")
	var game := get_node_or_null("/root/GameState") as GameStateScript
	if game != null:
		game.add_population(1)
		game.add_colonist(1)


func _exit_tree() -> void:
	var game := get_node_or_null("/root/GameState") as GameStateScript
	if game != null:
		game.add_population(-1)
		game.add_colonist(-1)


func _ready() -> void:
	if home == Vector2.ZERO:
		home = global_position
	_rng.randomize()
	_wander_wait = _rng.randf_range(WANDER_PAUSE_MIN, WANDER_PAUSE_MAX)


func move_to(point: Vector2) -> void:
	if leaving:
		return
	state = State.MOVING
	_wandering = false
	_set_path(point)


func board(ship: RescueShip) -> void:
	if leaving:
		return
	state = State.BOARDING
	_wandering = false
	var target := ship.global_position
	if ship.platform_rect.has_area():
		var nav := _nav()
		if nav != null:
			target = nav.approach_point(ship.platform_rect, global_position)
	_set_path(target)


func vanish() -> void:
	if leaving:
		return
	leaving = true
	selected = false
	velocity = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, VANISH_SECONDS)
	tween.finished.connect(_on_vanished)


func contains_point(point: Vector2) -> bool:
	return not leaving and (global_position + Vector2(0.0, SPRITE_Y)).distance_to(point) <= PICK_RADIUS


func _physics_process(delta: float) -> void:
	if leaving:
		return
	match state:
		State.MOVING:
			if _follow_path(delta, speed):
				home = global_position
				_stop()
		State.BOARDING:
			if _follow_path(delta, speed):
				vanish()
		State.IDLE:
			_wander(delta)


func _nav() -> NavScript:
	return get_node_or_null("/root/Nav") as NavScript


func _wander(delta: float) -> void:
	if _wandering:
		if _follow_path(delta, speed * WANDER_SPEED_FACTOR):
			_wandering = false
			_stop()
		return
	_wander_wait -= delta
	if _wander_wait > 0.0:
		return
	_wander_wait = _rng.randf_range(WANDER_PAUSE_MIN, WANDER_PAUSE_MAX)
	var target := _wander_target()
	if target.distance_to(global_position) > ARRIVE_DISTANCE:
		_set_path(target)
		_wandering = true


## Random free cell centre within WANDER_TILES of home, or the current position if none is found.
func _wander_target() -> Vector2:
	var nav := _nav()
	if nav == null:
		return global_position
	var center := Grid.world_to_cell(home)
	for attempt in 8:
		var offset := Vector2i(_rng.randi_range(-WANDER_TILES, WANDER_TILES), _rng.randi_range(-WANDER_TILES, WANDER_TILES))
		if Vector2(offset).length() > WANDER_TILES:
			continue
		var target_cell := center + offset
		if nav.is_area_free(Rect2i(target_cell, Vector2i.ONE)):
			return Grid.cell_to_world(target_cell)
	return global_position


func _set_path(point: Vector2) -> void:
	var nav := _nav()
	_path = nav.find_path(global_position, point) if nav != null else PackedVector2Array([point])
	_path_index = 0
	_stuck_time = 0.0


## Walks along _path. Returns true when the path is finished or the colonist is stuck.
func _follow_path(delta: float, move_speed: float) -> bool:
	if _path_index >= _path.size():
		velocity = Vector2.ZERO
		return true
	var to_target := _path[_path_index] - global_position
	if to_target.length() <= ARRIVE_DISTANCE:
		_path_index += 1
		if _path_index >= _path.size():
			velocity = Vector2.ZERO
			return true
		to_target = _path[_path_index] - global_position
	var dist := to_target.length()
	var step := move_speed * delta
	velocity = to_target / delta if dist < step else to_target / dist * move_speed
	var before := global_position
	move_and_slide()
	if before.distance_to(global_position) < minf(step, dist) * 0.1:
		_stuck_time += delta
		if _stuck_time >= STUCK_SECONDS:
			velocity = Vector2.ZERO
			return true
	else:
		_stuck_time = 0.0
	_face(velocity)
	_walk_time += delta
	_update_frame()
	return false


func _stop() -> void:
	state = State.IDLE
	_path = PackedVector2Array()
	_path_index = 0
	velocity = Vector2.ZERO
	_walk_time = 0.0
	_wander_wait = _rng.randf_range(WANDER_PAUSE_MIN, WANDER_PAUSE_MAX)
	_update_frame()


func _on_vanished() -> void:
	boarded.emit()
	queue_free()


func _face(direction: Vector2) -> void:
	if absf(direction.x) > absf(direction.y):
		_row = ROW_SIDE
		_sprite.flip_h = direction.x < 0.0
	else:
		_row = ROW_DOWN if direction.y > 0.0 else ROW_UP


func _update_frame() -> void:
	var phase := int(_walk_time * WALK_FPS) % PHASES
	_sprite.frame = _row * PHASES + phase


func _draw() -> void:
	# Ground shadow and selection ring, both flattened ellipses at the feet.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 13.0, Color(0.0, 0.0, 0.0, 0.35))
	if selected:
		draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 32, SELECT_COLOR, 2.0)
