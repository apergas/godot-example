class_name Shipyard extends Producer
## Builds rescue ships and parks them on up to PLATFORM_COUNT launch pads in a row beside it.
## The pads are claimed (blocked in Nav) when the shipyard enters the tree: first the row to its
## right, then the row to its left for the slots that are not free.

signal ship_spawned(ship: RescueShip)

const NavScript := preload("res://scripts/nav.gd")
const SHIP_COST := {ResKind.CRYSTAL: 360, ResKind.ICE: 240}
const SHIP_SECONDS := 75.0
const QUEUE_MAX := 2
const PLATFORM_COUNT := 4
const PLATFORM_SIZE := Vector2i(2, 2)
const SHIP_SCENE := preload("res://scenes/rescue_ship.tscn")
const PAD_TEXTURE := preload("res://assets/launch_pad.png")
const PAD_OUTLINE := Color(0.3, 1.0, 0.4, 0.8)

var platforms: Array[Rect2i] = []

var _docked: Array = []


func _ready() -> void:
	super()
	_claim_platforms()


func _exit_tree() -> void:
	super()
	var nav := get_node_or_null("/root/Nav") as NavScript
	if nav == null:
		return
	for rect in platforms:
		nav.set_blocked(rect, false)


func unit_cost() -> Dictionary:
	return SHIP_COST


func unit_seconds() -> float:
	return SHIP_SECONDS


func queue_max() -> int:
	return QUEUE_MAX


func title() -> String:
	return "Astillero"


func unit_name() -> String:
	return "Nave"


func blocked_text() -> String:
	return "Sin plataforma libre — construye otro astillero"


func enqueue() -> bool:
	if platforms.is_empty():
		return false
	return super()


func enqueue_ship() -> bool:
	return enqueue()


func free_platform() -> int:
	for i in platforms.size():
		if not is_instance_valid(_docked[i]):
			return i
	return -1


func platform_slots() -> Array[Rect2i]:
	var slots: Array[Rect2i] = []
	var row_y := cell.y + footprint.y - PLATFORM_SIZE.y
	for i in PLATFORM_COUNT:
		slots.append(Rect2i(Vector2i(cell.x + footprint.x + i * PLATFORM_SIZE.x, row_y), PLATFORM_SIZE))
	for i in PLATFORM_COUNT:
		slots.append(Rect2i(Vector2i(cell.x - (i + 1) * PLATFORM_SIZE.x, row_y), PLATFORM_SIZE))
	return slots


static func platform_center(rect: Rect2i) -> Vector2:
	return Vector2(rect.position * Grid.TILE) + Vector2(rect.size * Grid.TILE) / 2.0


func _can_release() -> bool:
	return free_platform() >= 0


func _release_unit() -> void:
	var index := free_platform()
	if index < 0:
		return
	var rect := platforms[index]
	var ship := SHIP_SCENE.instantiate() as RescueShip
	ship.platform = index
	ship.platform_rect = rect
	var parent := get_parent() as Node2D
	ship.position = parent.to_local(platform_center(rect))
	_docked[index] = ship
	parent.add_child(ship)
	ship_spawned.emit(ship)


func _claim_platforms() -> void:
	var nav := get_node_or_null("/root/Nav") as NavScript
	if nav == null:
		return
	for rect in platform_slots():
		if platforms.size() >= PLATFORM_COUNT:
			return
		if not nav.is_area_free(rect):
			continue
		nav.set_blocked(rect, true)
		platforms.append(rect)
		_docked.append(null)
		_add_pad(rect, platforms.size() - 1)
		_evict_units(rect, nav)


func _add_pad(rect: Rect2i, index: int) -> void:
	var pad := Sprite2D.new()
	pad.name = "Pad%d" % index
	pad.texture = PAD_TEXTURE
	pad.scale = Vector2(2, 2)
	pad.z_index = -1
	pad.position = to_local(platform_center(rect))
	add_child(pad)


## Units standing on a new pad walk to the nearest free cell around it.
func _evict_units(rect: Rect2i, nav: NavScript) -> void:
	var area := Rect2(Vector2(rect.position * Grid.TILE), Vector2(rect.size * Grid.TILE))
	for group: String in ["workers", "colonists"]:
		for node in get_tree().get_nodes_in_group(group):
			var unit := node as Node2D
			if unit != null and area.has_point(unit.global_position):
				unit.call("move_to", nav.approach_point(rect, unit.global_position))


func _draw_overlay() -> void:
	super()
	if not selected:
		return
	for rect in platforms:
		var area := Rect2(Vector2(rect.position * Grid.TILE) - global_position, Vector2(rect.size * Grid.TILE))
		_overlay.draw_rect(area.grow(-4.0), PAD_OUTLINE, false, 2.0)
