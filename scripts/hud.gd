extends CanvasLayer
## Screen overlay: resource bar on top, hover tooltip, and (phases 5-6) selection panels.

signal train_requested

const HOVER_OFFSET := Vector2(16, 20)
const POP_FULL_COLOR := Color(1.0, 0.35, 0.3)

var _hq: HQ = null

@onready var _crystal_label: Label = $TopBar/Row/CrystalLabel
@onready var _ice_label: Label = $TopBar/Row/IceLabel
@onready var _hover_label: Label = $HoverLabel
@onready var _pop_label: Label = %PopLabel
@onready var _hq_panel: Control = %HQPanel
@onready var _train_button: Button = %TrainButton
@onready var _queue_label: Label = %QueueLabel
@onready var _train_bar: ProgressBar = %TrainBar
@onready var _status_label: Label = %StatusLabel


func _ready() -> void:
	GameState.stock_changed.connect(_refresh_stock)
	_refresh_stock()
	_hover_label.hide()
	GameState.population_changed.connect(_update_pop)
	GameState.stock_changed.connect(_refresh_hq)
	_train_button.pressed.connect(_on_train_pressed)
	_hq_panel.hide()
	_update_pop(GameState.population, GameState.population_cap)


func show_for_selection(items: Array) -> void:
	var hq: HQ = null
	if items.size() == 1 and is_instance_valid(items[0]) and items[0] is HQ:
		hq = items[0]
	_set_hq(hq)


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
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.keycode != KEY_Q:
		return
	if not _hq_panel.visible:
		return
	train_requested.emit()
	get_viewport().set_input_as_handled()
