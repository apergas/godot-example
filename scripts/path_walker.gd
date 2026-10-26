class_name PathWalker extends RefCounted
## Shared path following for walking units (robots, colonists): walks a CharacterBody2D along
## Nav.find_path waypoints, detects arrival and getting stuck, faces the sprite (row + flip_h)
## and animates the walk phases of a 4x3 sheet (columns = phases, rows = down, up, side).

const NavScript := preload("res://scripts/nav.gd")
const ARRIVE_DISTANCE := 4.0
const STUCK_SECONDS := 0.5
const WALK_FPS := 8.0

# Rows of the unit spritesheets (art_src/make_worker.gd, make_colonist.gd); columns are walk phases.
const ROW_DOWN := 0
const ROW_UP := 1
const ROW_SIDE := 2
const PHASES := 4

# Soft separation between units of the same group (robots, colonists).
const SEPARATION_DISTANCE := 24.0
const SEPARATION_SPEED := 120.0
const SEPARATION_DEADZONE := 0.02

var row := ROW_DOWN
var walk_time := 0.0

var _body: CharacterBody2D
var _sprite: Sprite2D
var _path := PackedVector2Array()
var _path_index := 0
var _stuck_time := 0.0


func _init(body: CharacterBody2D, sprite: Sprite2D) -> void:
	_body = body
	_sprite = sprite


## Paths to point with Nav (or straight to it when Nav is missing).
func set_target(point: Vector2) -> void:
	var nav := _body.get_node_or_null("/root/Nav") as NavScript
	set_path(nav.find_path(_body.global_position, point) if nav != null else PackedVector2Array([point]))


func set_path(path: PackedVector2Array) -> void:
	_path = path
	_path_index = 0
	_stuck_time = 0.0


func clear() -> void:
	_path = PackedVector2Array()
	_path_index = 0


## One physics step along the path at move_speed, plus extra_velocity (e.g. a separation push).
## Returns true when the path is finished or the body is stuck.
func step(delta: float, move_speed: float, extra_velocity := Vector2.ZERO) -> bool:
	if _path_index >= _path.size():
		_body.velocity = Vector2.ZERO
		return true
	var to_target := _path[_path_index] - _body.global_position
	if to_target.length() <= ARRIVE_DISTANCE:
		_path_index += 1
		if _path_index >= _path.size():
			_body.velocity = Vector2.ZERO
			return true
		to_target = _path[_path_index] - _body.global_position
	var dist := to_target.length()
	var step_len := move_speed * delta
	var heading := to_target / dist if dist > 0.0 else Vector2.ZERO
	_body.velocity = (to_target / delta if dist < step_len else heading * move_speed) + extra_velocity
	var before := _body.global_position
	_body.move_and_slide()
	if before.distance_to(_body.global_position) < minf(step_len, dist) * 0.1:
		_stuck_time += delta
		if _stuck_time >= STUCK_SECONDS:
			_body.velocity = Vector2.ZERO
			return true
	else:
		_stuck_time = 0.0
	face(heading)
	walk_time += delta
	update_frame()
	return false


## Drops the path, zeroes the velocity and shows the standing frame of the current row.
func stop() -> void:
	clear()
	_body.velocity = Vector2.ZERO
	walk_time = 0.0
	update_frame()


func face(direction: Vector2) -> void:
	if absf(direction.x) > absf(direction.y):
		row = ROW_SIDE
		_sprite.flip_h = direction.x < 0.0
	else:
		row = ROW_DOWN if direction.y > 0.0 else ROW_UP


func update_frame() -> void:
	_sprite.frame = row * PHASES + int(walk_time * WALK_FPS) % PHASES


## Push away from neighbours closer than min_distance, 0..1 per neighbour by overlap.
## Exact overlaps are split by instance id so the two units move in opposite directions.
static func separation_push(pos: Vector2, self_id: int, others: PackedVector2Array, other_ids: PackedInt64Array, min_distance: float) -> Vector2:
	var push := Vector2.ZERO
	for i in others.size():
		var away: Vector2 = pos - others[i]
		var dist := away.length()
		if dist >= min_distance:
			continue
		var dir: Vector2 = Vector2.RIGHT if self_id > other_ids[i] else Vector2.LEFT
		if dist > 0.01:
			dir = away / dist
		push += dir * (min_distance - dist) / min_distance
	return push


## Separation push of the body from the other members of `group` (the body's own group).
func separation(group: StringName) -> Vector2:
	var positions := PackedVector2Array()
	var ids := PackedInt64Array()
	for other in _body.get_tree().get_nodes_in_group(group):
		if other == _body:
			continue
		var other_pos: Vector2 = (other as Node2D).global_position
		if _body.global_position.distance_to(other_pos) >= SEPARATION_DISTANCE:
			continue
		positions.append(other_pos)
		ids.append(other.get_instance_id())
	return separation_push(_body.global_position, _body.get_instance_id(), positions, ids, SEPARATION_DISTANCE)


## Soft separation while not walking: drift away from overlapping units.
func nudge(push: Vector2) -> void:
	if push.length() < SEPARATION_DEADZONE:
		_body.velocity = Vector2.ZERO
		return
	_body.velocity = push * SEPARATION_SPEED
	_body.move_and_slide()
