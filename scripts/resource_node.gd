class_name ResourceNode extends StaticBody2D
## A gatherable resource (crystal cluster or ice block) occupying one cell.
## Origin = ground contact point. Sprite sheet: frames 0..2 are variants, frame 3 is "almost depleted".

signal depleted

const VARIANTS := 3
const LOW_FRAME := 3
const LOW_FRACTION := 0.25
const PICK_HALF_WIDTH := 26.0
const PICK_HEIGHT := 56.0

@export var kind: int = ResKind.CRYSTAL
@export var amount: int = 400

var cell: Vector2i
var max_amount := 0

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("resources")
	cell = Grid.world_to_cell(global_position - Vector2(0, 1))
	max_amount = amount
	_update_frame()
	_set_nav_blocked(true)


func _exit_tree() -> void:
	_set_nav_blocked(false)


func take(n: int) -> int:
	if n <= 0 or amount <= 0:
		return 0
	var taken := mini(n, amount)
	amount -= taken
	_update_frame()
	if amount == 0:
		depleted.emit()
		queue_free()
	return taken


func contains_point(p: Vector2) -> bool:
	var top_left := global_position - Vector2(PICK_HALF_WIDTH, PICK_HEIGHT)
	return Rect2(top_left, Vector2(PICK_HALF_WIDTH * 2.0, PICK_HEIGHT + 8.0)).has_point(p)


func is_low() -> bool:
	return amount < max_amount * LOW_FRACTION


func variant() -> int:
	return posmod(cell.x * 7 + cell.y * 13 + MapLayout.SEED, VARIANTS)


func _update_frame() -> void:
	_sprite.frame = LOW_FRAME if is_low() else variant()


# Looked up by path: class_name scripts compile before autoloads exist in --script runs.
func _set_nav_blocked(blocked: bool) -> void:
	var nav := get_node_or_null("/root/Nav")
	if nav:
		nav.set_blocked(Rect2i(cell, Vector2i.ONE), blocked)
