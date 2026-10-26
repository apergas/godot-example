class_name ProducerPanel extends PanelContainer
## Bottom panel for a selected Producer (shipyard, colony module): queue button, queue count,
## progress bar and the reason it is waiting. Same layout and Q shortcut as the HQ panel.

signal requested

const GameStateScript := preload("res://scripts/game_state.gd")

var producer: Producer = null

@onready var _title: Label = %Title
@onready var _button: Button = %ProduceButton
@onready var _queue_label: Label = %QueueLabel
@onready var _bar: ProgressBar = %ProduceBar
@onready var _status: Label = %StatusLabel


func _ready() -> void:
	_button.pressed.connect(_on_pressed)
	var gs := _game_state()
	if gs != null:
		gs.stock_changed.connect(refresh)
		gs.population_changed.connect(_on_population_changed)
	hide()


func bind(next: Producer) -> void:
	if is_instance_valid(producer) and producer.queue_changed.is_connected(_on_queue_changed):
		producer.queue_changed.disconnect(_on_queue_changed)
	producer = next
	visible = producer != null
	if producer == null:
		return
	producer.queue_changed.connect(_on_queue_changed)
	_title.text = producer.title()
	_button.text = "%s (%s)" % [producer.unit_name(), cost_text(producer.unit_cost())]
	_status.text = producer.blocked_text()
	refresh()


func refresh() -> void:
	if not is_instance_valid(producer):
		return
	var gs := _game_state()
	_queue_label.text = "Cola: %d/%d" % [producer.queue, producer.queue_max()]
	_bar.value = producer.train_progress()
	_button.disabled = not producer.built or producer.queue >= producer.queue_max() \
			or gs == null or not gs.can_afford(producer.unit_cost())
	_status.visible = producer.is_blocked()


static func cost_text(cost: Dictionary) -> String:
	var parts := PackedStringArray()
	for kind in cost:
		parts.append("%d %s" % [cost[kind], String(ResKind.NAMES[kind]).to_lower()])
	return " · ".join(parts)


func _game_state() -> GameStateScript:
	return get_node_or_null("/root/GameState") as GameStateScript


func _on_queue_changed(_count: int, _progress: float) -> void:
	refresh()


func _on_population_changed(_population: int, _cap: int) -> void:
	refresh()


func _on_pressed() -> void:
	requested.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.keycode != KEY_Q or not visible:
		return
	requested.emit()
	get_viewport().set_input_as_handled()
