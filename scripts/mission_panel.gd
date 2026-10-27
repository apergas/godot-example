class_name MissionPanel extends VBoxContainer
## Guided missions panel (top right): current mission, progress, completion toast, hide/show toggle.

const TOAST_SECONDS := 3.0
const DONE_MARK := "✔"
const HIDE_TEXT := "Ocultar guía"
const SHOW_TEXT := "Mostrar guía"
const IDLE_TITLE := "Misiones"
const FINISHED_TITLE := "¡Misión cumplida!"
const FINISHED_TEXT := "Has completado todas las misiones."

static var guide_hidden := false

var _tracker: MissionTracker
var _toast_left := 0.0

@onready var _toggle: Button = %ToggleButton
@onready var _body: Control = %Body
@onready var _title: Label = %Title
@onready var _text: Label = %Text
@onready var _bar: ProgressBar = %Bar
@onready var _count: Label = %Count
@onready var _toast: Label = %Toast


func _ready() -> void:
	_toggle.pressed.connect(toggle)
	_toast.hide()
	_apply_hidden()
	refresh()


func bind(tracker: MissionTracker) -> void:
	_tracker = tracker
	tracker.mission_changed.connect(_on_mission_changed)
	tracker.mission_completed.connect(_on_mission_completed)
	tracker.progress_changed.connect(refresh)
	refresh()


func refresh() -> void:
	if not is_instance_valid(_tracker):
		_title.text = IDLE_TITLE
		_text.text = ""
		_bar.value = 0.0
		_count.text = ""
		return
	if _tracker.is_finished():
		_title.text = FINISHED_TITLE
		_text.text = FINISHED_TEXT
		_bar.max_value = 1.0
		_bar.value = 1.0
		_count.text = ""
		return
	_title.text = "Misión %d/%d" % [_tracker.index + 1, Missions.LIST.size()]
	_text.text = _tracker.current()["text"]
	_bar.max_value = _tracker.target()
	_bar.value = _tracker.progress()
	_count.text = _tracker.progress_text()


func toggle() -> void:
	guide_hidden = not guide_hidden
	_apply_hidden()


func show_toast(text: String) -> void:
	_toast.text = text
	_toast.show()
	_toast_left = TOAST_SECONDS


func _process(delta: float) -> void:
	if _toast_left <= 0.0:
		return
	_toast_left -= delta
	if _toast_left <= 0.0:
		_toast.hide()


func _apply_hidden() -> void:
	_body.visible = not guide_hidden
	_toggle.text = SHOW_TEXT if guide_hidden else HIDE_TEXT


func _on_mission_changed(_index: int) -> void:
	refresh()


func _on_mission_completed(_index: int, reward: Dictionary) -> void:
	var text := "%s Misión completada" % DONE_MARK
	var gain := Missions.reward_text(reward)
	if gain != "":
		text += ": " + gain
	show_toast(text)
