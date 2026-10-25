extends Node2D

const LIFETIME := 0.5
const COLOR := Color(0.3, 1.0, 0.4)
const START_RADIUS := 16.0
const END_RADIUS := 6.0

var _age := 0.0


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := clampf(_age / LIFETIME, 0.0, 1.0)
	var color := COLOR
	color.a = 1.0 - t
	# Flattened ellipse on the ground, like the worker's selection ring.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.35))
	draw_arc(Vector2.ZERO, lerpf(START_RADIUS, END_RADIUS, t), 0.0, TAU, 24, color, 2.0)
