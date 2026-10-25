class_name Worker
extends CharacterBody2D

enum State { IDLE, MOVING, TO_RESOURCE, GATHERING, TO_DROPOFF, TO_BUILD, BUILDING }

const NavScript := preload("res://scripts/nav.gd")
const GameStateScript := preload("res://scripts/game_state.gd")
const RADIUS := 20.0
const ARRIVE_DISTANCE := 4.0
const STUCK_SECONDS := 0.5
# The origin is at the feet; the body (and the sprite centre) sits above it.
const BODY_OFFSET := Vector2(0.0, -22.0)
const WALK_FPS := 8.0
const CARRY_MAX := 10
const GATHER_SECONDS := {ResKind.CRYSTAL: 3.0, ResKind.ICE: 4.0}
const GATHER_RANGE := 96.0
const DROPOFF_RANGE := 48.0
const SEARCH_TILES := 6
const CARGO_Y := -64.0
const CRYSTAL_LIGHT := Color("a8fbff")
const CRYSTAL_MID := Color("38d8f0")
const CRYSTAL_DARK := Color("0f6e86")
const ICE_LIGHT := Color("e8f6ff")
const ICE_MID := Color("b8dcf0")
const ICE_DARK := Color("6fa3c4")
const SEPARATION_DISTANCE := 24.0
const SEPARATION_SPEED := 120.0
const SEPARATION_DEADZONE := 0.02

# Rows of the spritesheet (see art_src/make_worker.gd); columns are walk phases.
const ROW_DOWN := 0
const ROW_UP := 1
const ROW_SIDE := 2
const PHASES := 4

@export var speed := 180.0

var selected := false:
	set(value):
		selected = value
		queue_redraw()

var state: State = State.IDLE
var carry_kind: int = -1
var carry_amount: int = 0

var _path := PackedVector2Array()
var _path_index := 0
var _stuck_time := 0.0
var _gather_node: ResourceNode = null
var _gather_kind := -1
var _gather_pos := Vector2.ZERO
var _gather_time := 0.0
var _dropoff: Building = null
var _walk_time := 0.0
var _row := ROW_DOWN

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("workers")


func move_to(point: Vector2) -> void:
	_gather_node = null
	_gather_kind = -1
	_dropoff = null
	_set_path(point)
	state = State.MOVING


func contains_point(point: Vector2) -> bool:
	return (global_position + BODY_OFFSET).distance_to(point) <= RADIUS + 4.0


func gather(node: ResourceNode) -> void:
	if not _node_alive(node):
		return
	if carry_amount > 0 and carry_kind != node.kind:
		carry_amount = 0
		carry_kind = -1
		queue_redraw()
	_gather_node = node
	_gather_kind = node.kind
	_gather_pos = node.global_position
	if carry_amount >= CARRY_MAX:
		_go_to_dropoff(null)
	else:
		_go_to_resource()


func return_cargo(building: Building = null) -> void:
	if carry_amount <= 0:
		return
	_go_to_dropoff(building)


func _nearest_dropoff(kind: int) -> Building:
	var best: Building = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("dropoffs"):
		var building := node as Building
		if building == null or not building.accepts(kind):
			continue
		var d := global_position.distance_squared_to(_footprint_rect(building).get_center())
		if d < best_dist:
			best_dist = d
			best = building
	return best


func _go_to_resource() -> void:
	var nav := get_node_or_null("/root/Nav") as NavScript
	var target := _node_center()
	if nav != null:
		target = nav.approach_point(Rect2i(_gather_node.cell, Vector2i.ONE), global_position)
	_set_path(target)
	state = State.TO_RESOURCE


func _go_to_dropoff(preferred: Building) -> void:
	if preferred != null and preferred.accepts(carry_kind):
		_dropoff = preferred
	else:
		_dropoff = _nearest_dropoff(carry_kind)
	if _dropoff == null:
		_stop()
		return
	var nav := get_node_or_null("/root/Nav") as NavScript
	var target := _footprint_rect(_dropoff).get_center()
	if nav != null:
		target = nav.approach_point(_dropoff.cell_rect(), global_position)
	_set_path(target)
	state = State.TO_DROPOFF


func _process_to_resource(delta: float, push: Vector2) -> void:
	if not _node_alive(_gather_node):
		_retarget()
		return
	if global_position.distance_to(_node_center()) <= GATHER_RANGE:
		_begin_gathering()
		return
	if _follow_path(delta, push):
		if global_position.distance_to(_node_center()) <= GATHER_RANGE * 1.5:
			_begin_gathering()
		else:
			_stop()


func _begin_gathering() -> void:
	state = State.GATHERING
	_gather_time = 0.0
	_path = PackedVector2Array()
	_path_index = 0
	velocity = Vector2.ZERO
	_face(_node_center() - global_position)
	_walk_time = 0.0
	_update_frame()


func _process_gathering(delta: float, push: Vector2) -> void:
	_nudge(push)
	if not _node_alive(_gather_node):
		if carry_amount > 0:
			_go_to_dropoff(null)
		else:
			_retarget()
		return
	_gather_time += delta
	var interval: float = GATHER_SECONDS[_gather_kind] / CARRY_MAX
	while _gather_time >= interval and carry_amount < CARRY_MAX and _node_alive(_gather_node):
		_gather_time -= interval
		var got := _gather_node.take(1)
		if got <= 0:
			break
		carry_kind = _gather_kind
		carry_amount += got
		queue_redraw()
	if carry_amount >= CARRY_MAX:
		_go_to_dropoff(null)


func _process_to_dropoff(delta: float, push: Vector2) -> void:
	if not is_instance_valid(_dropoff) or not _dropoff.accepts(carry_kind):
		_go_to_dropoff(null)
		return
	if _footprint_rect(_dropoff).grow(DROPOFF_RANGE).has_point(global_position):
		_deliver()
		return
	if _follow_path(delta, push):
		if _footprint_rect(_dropoff).grow(DROPOFF_RANGE * 2.0).has_point(global_position):
			_deliver()
		else:
			_stop()


func _deliver() -> void:
	var game := get_node_or_null("/root/GameState") as GameStateScript
	if game != null:
		game.add(carry_kind, carry_amount)
	carry_amount = 0
	carry_kind = -1
	_dropoff = null
	queue_redraw()
	if _node_alive(_gather_node):
		_go_to_resource()
	elif _gather_kind >= 0:
		_retarget()
	else:
		_stop()


## The current node is gone: move on to the nearest node of the same kind around it.
func _retarget() -> void:
	var next := _find_resource_near(_gather_kind, _gather_pos)
	if next == null:
		_gather_node = null
		_gather_kind = -1
		_stop()
		return
	_gather_node = next
	_gather_pos = next.global_position
	_go_to_resource()


func _find_resource_near(kind: int, center: Vector2) -> ResourceNode:
	var best: ResourceNode = null
	var best_dist := float(SEARCH_TILES * Grid.TILE)
	for node in get_tree().get_nodes_in_group("resources"):
		var res := node as ResourceNode
		if res == null or res.kind != kind or res.amount <= 0 or res.is_queued_for_deletion():
			continue
		var d := center.distance_to(res.global_position)
		if d <= best_dist:
			best_dist = d
			best = res
	return best


func _node_alive(node: Variant) -> bool:
	return is_instance_valid(node) and not node.is_queued_for_deletion()


func _node_center() -> Vector2:
	return Grid.cell_to_world(_gather_node.cell)


func _footprint_rect(building: Building) -> Rect2:
	return Rect2(Vector2(building.cell * Grid.TILE), Vector2(building.footprint * Grid.TILE))


## Push away from neighbours closer than min_distance, 0..1 per neighbour by overlap.
## Exact overlaps are split by instance id so the two robots move in opposite directions.
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


func _physics_process(delta: float) -> void:
	var push := _separation()
	match state:
		State.MOVING:
			if _follow_path(delta, push):
				_stop()
		State.TO_RESOURCE:
			_process_to_resource(delta, push)
		State.GATHERING:
			_process_gathering(delta, push)
		State.TO_DROPOFF:
			_process_to_dropoff(delta, push)
		_:
			_nudge(push)


func _set_path(point: Vector2) -> void:
	var nav := get_node_or_null("/root/Nav") as NavScript
	_path = nav.find_path(global_position, point) if nav != null else PackedVector2Array([point])
	_path_index = 0
	_stuck_time = 0.0


## Walks along _path. Returns true when the path is finished or the robot is stuck.
func _follow_path(delta: float, push: Vector2) -> bool:
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
	var step := speed * delta
	var heading := to_target / dist if dist > 0.0 else Vector2.ZERO
	velocity = (to_target / delta if dist < step else heading * speed) + push * SEPARATION_SPEED
	var before := global_position
	move_and_slide()
	if before.distance_to(global_position) < minf(step, dist) * 0.1:
		_stuck_time += delta
		if _stuck_time >= STUCK_SECONDS:
			velocity = Vector2.ZERO
			return true
	else:
		_stuck_time = 0.0
	# Face the path direction, not the velocity: the separation push would make it flicker.
	_face(heading)
	_walk_time += delta
	_update_frame()
	return false


func _stop() -> void:
	state = State.IDLE
	_path = PackedVector2Array()
	_path_index = 0
	velocity = Vector2.ZERO
	_walk_time = 0.0
	_update_frame()


## Soft separation while not walking: drift away from overlapping robots.
func _nudge(push: Vector2) -> void:
	if push.length() < SEPARATION_DEADZONE:
		velocity = Vector2.ZERO
		return
	velocity = push * SEPARATION_SPEED
	move_and_slide()


func _separation() -> Vector2:
	var positions := PackedVector2Array()
	var ids := PackedInt64Array()
	for other in get_tree().get_nodes_in_group("workers"):
		if other == self:
			continue
		var other_pos: Vector2 = (other as Node2D).global_position
		if global_position.distance_to(other_pos) >= SEPARATION_DISTANCE:
			continue
		positions.append(other_pos)
		ids.append(other.get_instance_id())
	return separation_push(global_position, get_instance_id(), positions, ids, SEPARATION_DISTANCE)


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
	# Both shapes are flattened ellipses on the ground at the feet, to match the 3/4 view.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 17.0, Color(0.0, 0.0, 0.0, 0.35))
	if selected:
		draw_arc(Vector2.ZERO, RADIUS + 8.0, 0.0, TAU, 32, Color(0.3, 1.0, 0.4), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if carry_amount > 0:
		_draw_cargo(Vector2(0.0, CARGO_Y))


## Small crystal or ice block floating over the head while the robot carries something.
func _draw_cargo(at: Vector2) -> void:
	if carry_kind == ResKind.CRYSTAL:
		draw_colored_polygon(PackedVector2Array([
			at + Vector2(0, -10), at + Vector2(8, -2), at + Vector2(0, 10), at + Vector2(-8, -2),
		]), CRYSTAL_DARK)
		draw_colored_polygon(PackedVector2Array([
			at + Vector2(0, -8), at + Vector2(6, -2), at + Vector2(0, 8), at + Vector2(-6, -2),
		]), CRYSTAL_MID)
		draw_colored_polygon(PackedVector2Array([
			at + Vector2(0, -8), at + Vector2(0, 8), at + Vector2(-6, -2),
		]), CRYSTAL_LIGHT)
	else:
		draw_rect(Rect2(at - Vector2(8, 6), Vector2(16, 12)), ICE_DARK)
		draw_rect(Rect2(at - Vector2(6, 4), Vector2(12, 8)), ICE_MID)
		draw_rect(Rect2(at - Vector2(6, 4), Vector2(12, 2)), ICE_LIGHT)
