extends CanvasLayer
## Screen overlay: resource bar on top, hover tooltip, and (phases 5-6) selection panels.

signal train_requested
signal build_requested(scene: PackedScene)

const HOVER_OFFSET := Vector2(16, 20)
const POP_FULL_COLOR := Color(1.0, 0.35, 0.3)
const HABITAT_SCENE := preload("res://scenes/buildings/habitat.tscn")
const BUILDABLES := [
	{"id": "Habitat", "name": "Habitáculo", "key": KEY_H, "scene": HABITAT_SCENE},
]

var _hq: HQ = null
var _build_armed := false
var _build_buttons := {}
var _build_costs := {}

@onready var _crystal_label: Label = $TopBar/Row/CrystalLabel
@onready var _ice_label: Label = $TopBar/Row/IceLabel
@onready var _hover_label: Label = $HoverLabel
@onready var _pop_label: Label = %PopLabel
@onready var _hq_panel: Control = %HQPanel
@onready var _train_button: Button = %TrainButton
@onready var _queue_label: Label = %QueueLabel
@onready var _train_bar: ProgressBar = %TrainBar
@onready var _status_label: Label = %StatusLabel
@onready var _build_menu: Control = $BuildMenu
@onready var _build_box: HBoxContainer = $BuildMenu/Buttons


func _ready() -> void:
	GameState.stock_changed.connect(_refresh_stock)
	_refresh_stock()
	_hover_label.hide()
	GameState.population_changed.connect(_update_pop)
	GameState.stock_changed.connect(_refresh_hq)
	_train_button.pressed.connect(_on_train_pressed)
	_hq_panel.hide()
	_update_pop(GameState.population, GameState.population_cap)
	_setup_build_menu()


func show_for_selection(items: Array) -> void:
	var hq: HQ = null
	if items.size() == 1 and is_instance_valid(items[0]) and items[0] is HQ:
		hq = items[0]
	_set_hq(hq)
	_update_build_menu(items)


func show_hover(text: String, screen_pos: Vector2) -> void:
	_hover_label.text = text
	_hover_label.position = screen_pos + HOVER_OFFSET
	_hover_label.show()


func hide_hover() -> void:
	_hover_label.hide()


func _refresh_stock() -> void:
	_crystal_label.text = str(GameState.stock[ResKind.CRYSTAL])
	_ice_label.text = str(GameState.stock[ResKind.ICE])


func _set_hq(hq: HQ) -> void:
	if is_instance_valid(_hq) and _hq.queue_changed.is_connected(_on_queue_changed):
		_hq.queue_changed.disconnect(_on_queue_changed)
	_hq = hq
	_hq_panel.visible = _hq != null
	if _hq != null:
		_hq.queue_changed.connect(_on_queue_changed)
		_refresh_hq()


func _on_queue_changed(_count: int, _progress: float) -> void:
	_refresh_hq()


func _refresh_hq() -> void:
	if not is_instance_valid(_hq):
		return
	_queue_label.text = "Cola: %d/%d" % [_hq.queue, HQ.QUEUE_MAX]
	_train_bar.value = _hq.train_progress()
	_train_button.disabled = _hq.queue >= HQ.QUEUE_MAX or not GameState.can_afford(HQ.WORKER_COST)
	_status_label.visible = _hq.is_blocked()


func _update_pop(population: int, cap: int) -> void:
	_pop_label.text = "pob %d/%d" % [population, cap]
	if population >= cap:
		_pop_label.add_theme_color_override("font_color", POP_FULL_COLOR)
	else:
		_pop_label.remove_theme_color_override("font_color")
	_refresh_hq()


func _on_train_pressed() -> void:
	train_requested.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	if _handle_build_keys(event):
		get_viewport().set_input_as_handled()
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.keycode != KEY_Q:
		return
	if not _hq_panel.visible:
		return
	train_requested.emit()
	get_viewport().set_input_as_handled()


func _setup_build_menu() -> void:
	for entry in BUILDABLES:
		var id: String = entry["id"]
		var scene: PackedScene = entry["scene"]
		var proto := scene.instantiate() as Building
		_build_costs[id] = proto.cost.duplicate()
		proto.free()
		var button := Button.new()
		button.name = id + "Button"
		button.text = "%s [%s]\n%s" % [entry["name"], OS.get_keycode_string(entry["key"]), _cost_text(_build_costs[id])]
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_request_build.bind(id))
		_build_box.add_child(button)
		_build_buttons[id] = button
	_build_menu.visible = false
	GameState.stock_changed.connect(_refresh_build_buttons)
	_refresh_build_buttons()


func _cost_text(cost: Dictionary) -> String:
	var parts := PackedStringArray()
	for kind in cost:
		parts.append("%d %s" % [cost[kind], String(ResKind.NAMES[kind]).to_lower()])
	return " · ".join(parts)


func _refresh_build_buttons() -> void:
	for id in _build_buttons:
		(_build_buttons[id] as Button).disabled = not GameState.can_afford(_build_costs[id])


func _update_build_menu(items: Array) -> void:
	_build_menu.visible = items.any(func(item) -> bool: return is_instance_valid(item) and item.is_in_group("workers"))
	if not _build_menu.visible:
		_build_armed = false


func _request_build(id: String) -> void:
	_build_armed = false
	if not GameState.can_afford(_build_costs[id]):
		return
	for entry in BUILDABLES:
		if entry["id"] == id:
			build_requested.emit(entry["scene"])
			return


func _handle_build_keys(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or not _build_menu.visible:
		return false
	if key.keycode == KEY_B:
		_build_armed = true
		return true
	if not _build_armed:
		return false
	_build_armed = false
	for entry in BUILDABLES:
		if key.keycode == entry["key"]:
			_request_build(entry["id"])
			return true
	return false
