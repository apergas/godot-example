extends CharacterBody2D

const RADIUS := 20.0
const ARRIVE_DISTANCE := 4.0
const FEET_Y := 22.0
const WALK_FPS := 8.0

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


func move_to(point: Vector2) -> void:
	_target = point
	_moving = true


func contains_point(point: Vector2) -> bool:
	return global_position.distance_to(point) <= RADIUS + 4.0


func _physics_process(delta: float) -> void:
	if not _moving:
		return
	var offset := _target - global_position
	if offset.length() <= ARRIVE_DISTANCE:
		_moving = false
		velocity = Vector2.ZERO
		_walk_time = 0.0
		_update_frame()
		return
	velocity = offset.normalized() * speed
	move_and_slide()
	_face(velocity)
	_walk_time += delta
	_update_frame()


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
	# Both shapes are flattened ellipses on the ground, to match the 3/4 view.
	draw_set_transform(Vector2(0.0, FEET_Y), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 17.0, Color(0.0, 0.0, 0.0, 0.35))
	if selected:
		draw_arc(Vector2.ZERO, RADIUS + 8.0, 0.0, TAU, 32, Color(0.3, 1.0, 0.4), 2.0)
