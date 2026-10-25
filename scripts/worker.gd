extends CharacterBody2D

const RADIUS := 20.0
const ARRIVE_DISTANCE := 4.0
# The origin is at the feet; the body (and the sprite centre) sits above it.
const BODY_OFFSET := Vector2(0.0, -22.0)
const WALK_FPS := 8.0
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

var _target := Vector2.ZERO
var _moving := false
var _walk_time := 0.0
var _row := ROW_DOWN

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("workers")


func move_to(point: Vector2) -> void:
	_target = point
	_moving = true


func contains_point(point: Vector2) -> bool:
	return (global_position + BODY_OFFSET).distance_to(point) <= RADIUS + 4.0


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
	if _moving:
		var offset := _target - global_position
		if offset.length() > ARRIVE_DISTANCE:
			velocity = offset.normalized() * speed + push * SEPARATION_SPEED
			move_and_slide()
			_face(velocity)
			_walk_time += delta
			_update_frame()
			return
		_moving = false
		_walk_time = 0.0
		_update_frame()
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
