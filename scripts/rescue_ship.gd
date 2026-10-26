class_name RescueShip extends Node2D
## Rescue ship parked on a shipyard launch pad. Selectable, never moves; launch() lifts it off.

signal launched

const GameStateScript := preload("res://scripts/game_state.gd")
const PARKED_FRAME := 0
const FLAME_FRAME := 1
const PICK_RECT := Rect2(-44.0, -156.0, 88.0, 160.0)
const RING_RADIUS := 56.0
const LAUNCH_SECONDS := 2.5
const LAUNCH_HEIGHT := 900.0
const SELECT_COLOR := Color(0.3, 1.0, 0.4)

var selected := false:
	set(value):
		selected = value
		queue_redraw()
var platform := -1
var platform_rect := Rect2i()
var launching := false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _shadow: Sprite2D = $Shadow


func _enter_tree() -> void:
	add_to_group("ships")
	var game := get_node_or_null("/root/GameState") as GameStateScript
	if game != null:
		game.add_ship(1)


func _exit_tree() -> void:
	var game := get_node_or_null("/root/GameState") as GameStateScript
	if game != null:
		game.add_ship(-1)


func contains_point(p: Vector2) -> bool:
	if launching:
		return false
	return Rect2(global_position + PICK_RECT.position, PICK_RECT.size).has_point(p)


func launch() -> void:
	if launching:
		return
	launching = true
	selected = false
	_sprite.frame = FLAME_FRAME
	var tween := create_tween()
	tween.tween_property(_sprite, "position:y", _sprite.position.y - LAUNCH_HEIGHT, LAUNCH_SECONDS) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(_shadow, "modulate:a", 0.0, LAUNCH_SECONDS * 0.5)
	tween.parallel().tween_property(_sprite, "modulate:a", 0.0, LAUNCH_SECONDS * 0.3).set_delay(LAUNCH_SECONDS * 0.7)
	tween.finished.connect(_on_launch_finished)


func _on_launch_finished() -> void:
	launched.emit()
	queue_free()


func _draw() -> void:
	if not selected:
		return
	# Flattened ring on the pad, like the units' selection ring.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.35))
	draw_arc(Vector2.ZERO, RING_RADIUS, 0.0, TAU, 40, SELECT_COLOR, 2.0)
	draw_set_transform(Vector2.ZERO)
