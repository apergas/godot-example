class_name VictoryScreen extends CanvasLayer
## End screen: time and totals of the game, and a "play again" button.

signal restart_requested

@onready var _time_label: Label = %TimeLabel
@onready var _colonists_label: Label = %ColonistsLabel
@onready var _ships_label: Label = %ShipsLabel
@onready var _gathered_label: Label = %GatheredLabel
@onready var _workers_label: Label = %WorkersLabel
@onready var _restart_button: Button = %RestartButton


func _ready() -> void:
	_restart_button.pressed.connect(_on_restart_pressed)


func setup(totals: Dictionary) -> void:
	_time_label.text = "Tiempo de partida: " + format_time(float(totals.get("time", 0.0)))
	_colonists_label.text = "Colonos evacuados: %d" % int(totals.get("colonists", 0))
	_ships_label.text = "Naves lanzadas: %d" % int(totals.get("ships", 0))
	_gathered_label.text = "Recogido: %d cristal · %d hielo" % [int(totals.get("crystal", 0)), int(totals.get("ice", 0))]
	_workers_label.text = "Robots: %d" % int(totals.get("workers", 0))


static func format_time(seconds: float) -> String:
	var total := maxi(int(seconds), 0)
	return "%02d:%02d" % [floori(total / 60.0), total % 60]


func _on_restart_pressed() -> void:
	restart_requested.emit()
