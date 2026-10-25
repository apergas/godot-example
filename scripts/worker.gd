extends CharacterBody2D

const RADIUS := 20.0
const ARRIVE_DISTANCE := 4.0
const FEET_Y := 22.0
const BOB_SPEED := 12.0
const BOB_HEIGHT := 3.0

@export var speed := 180.0

var selected := false:
	set(value):
		selected = value
		queue_redraw()

var _target := Vector2.ZERO
var _moving := false
var _bob_time := 0.0

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
		_sprite.position.y = 0.0
		return
	velocity = offset.normalized() * speed
	move_and_slide()
	_bob_time += delta
	_sprite.position.y = -absf(sin(_bob_time * BOB_SPEED)) * BOB_HEIGHT


func _draw() -> void:
	if selected:
		# Ellipse on the ground under the feet, to match the 3/4 view.
		draw_set_transform(Vector2(0.0, FEET_Y), 0.0, Vector2(1.0, 0.45))
		draw_arc(Vector2.ZERO, RADIUS + 8.0, 0.0, TAU, 32, Color(0.3, 1.0, 0.4), 2.0)
