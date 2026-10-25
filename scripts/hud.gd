extends CanvasLayer
## Screen overlay: resource bar on top, hover tooltip, and (phases 5-6) selection panels.

const HOVER_OFFSET := Vector2(16, 20)

@onready var _crystal_label: Label = $TopBar/Row/CrystalLabel
@onready var _ice_label: Label = $TopBar/Row/IceLabel
@onready var _hover_label: Label = $HoverLabel


func _ready() -> void:
	GameState.stock_changed.connect(_refresh_stock)
	_refresh_stock()
	_hover_label.hide()


@warning_ignore("unused_parameter")
func show_for_selection(items: Array) -> void:
	pass


func show_hover(text: String, screen_pos: Vector2) -> void:
	_hover_label.text = text
	_hover_label.position = screen_pos + HOVER_OFFSET
	_hover_label.show()


func hide_hover() -> void:
	_hover_label.hide()


func _refresh_stock() -> void:
	_crystal_label.text = str(GameState.stock[ResKind.CRYSTAL])
	_ice_label.text = str(GameState.stock[ResKind.ICE])
