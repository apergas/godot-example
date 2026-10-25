extends CharacterBody2D

const RADIUS := 14.0
const ARRIVE_DISTANCE := 4.0

@export var speed := 180.0

var selected := false:
	set(value):
		selected = value
		queue_redraw()

var _target := Vector2.ZERO
var _moving := false


func move_to(point: Vector2) -> void:
	_target = point
	_moving = true


func contains_point(point: Vector2) -> bool:
	return global_position.distance_to(point) <= RADIUS + 4.0


func _physics_process(_delta: float) -> void:
	if not _moving:
		return
	var offset := _target - global_position
	if offset.length() <= ARRIVE_DISTANCE:
		_moving = false
		velocity = Vector2.ZERO
		return
	velocity = offset.normalized() * speed
	move_and_slide()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color(0.3, 0.8, 1.0))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 24, Color(0.05, 0.2, 0.3), 2.0)
	if selected:
		draw_arc(Vector2.ZERO, RADIUS + 5.0, 0.0, TAU, 32, Color(0.3, 1.0, 0.4), 2.0)
