extends SceneTree
## tests/test_08_producer_panels.gd — run: tools\godot.cmd --headless --path . --script res://tests/test_08_producer_panels.gd

const Sim := preload("res://tests/sim_helpers.gd")

var _failed := false


func _initialize() -> void:
	create_timer(20.0).timeout.connect(_on_timeout)
	await process_frame
	var world := Sim.new_world(self)
	var gs = Sim.game_state(self)
	var hud = load("res://scenes/hud.tscn").instantiate()
	root.add_child(hud)
	var yard := Sim.add_building(world, "res://scenes/buildings/shipyard.tscn", Vector2i(20, 10)) as Shipyard
	var module := Sim.add_building(world, "res://scenes/buildings/colony_module.tscn", Vector2i(20, 20)) as ColonyModule
	await process_frame
	yard.set_process(false)
	module.set_process(false)

	var yard_panel := hud.get_node("%ShipyardPanel") as ProducerPanel
	var colony_panel := hud.get_node("%ColonyPanel") as ProducerPanel
	var hq_panel: Control = hud.get_node("%HQPanel")
	_check("panels_hidden_at_start", not yard_panel.visible and not colony_panel.visible, "visible")

	hud.show_for_selection([yard])
	_check("shipyard_panel_shown", yard_panel.visible and not colony_panel.visible and not hq_panel.visible, "wrong panels")
	var button := yard_panel.get_node("%ProduceButton") as Button
	var queue_label := yard_panel.get_node("%QueueLabel") as Label
	_check("shipyard_panel_texts", (yard_panel.get_node("%Title") as Label).text == "Astillero"
			and button.text == "Nave (300 cristal · 200 hielo)" and queue_label.text == "Cola: 0/2", button.text)
	_check("disabled_without_money", button.disabled, "enabled with 50 crystal")

	var requests: Array = []
	hud.produce_requested.connect(func(p: Producer) -> void: requests.append(p))
	yard_panel._unhandled_key_input(_key(KEY_Q))
	_check("q_requests_shipyard", requests == [yard], str(requests))
	button.pressed.emit()
	_check("button_requests_shipyard", requests.size() == 2 and requests[1] == yard, str(requests))
	gs.add(ResKind.CRYSTAL, 1000)
	gs.add(ResKind.ICE, 1000)
	_check("enabled_with_money", not button.disabled, "disabled with money")
	yard.enqueue()
	_check("queue_label_updates", queue_label.text == "Cola: 1/2", queue_label.text)

	hud.show_for_selection([module])
	_check("colony_panel_shown", colony_panel.visible and not yard_panel.visible, "wrong panels")
	var status := colony_panel.get_node("%StatusLabel") as Label
	_check("colony_panel_texts", (colony_panel.get_node("%Title") as Label).text == "Módulo de colonos"
			and (colony_panel.get_node("%ProduceButton") as Button).text == "Colono (25 cristal · 60 hielo)"
			and (colony_panel.get_node("%QueueLabel") as Label).text == "Cola: 0/5", "texts")
	module.enqueue()
	module._process(1.0)
	_check("colony_status_when_blocked", status.visible and status.text == "Población máxima — construye habitáculos", status.text)
	yard_panel._unhandled_key_input(_key(KEY_Q))
	_check("hidden_panel_ignores_q", requests.size() == 2, str(requests.size()))
	hud.show_for_selection([])
	_check("panels_hidden_for_empty", not yard_panel.visible and not colony_panel.visible, "visible")
	var late := Sim.add_building(world, "res://scenes/buildings/shipyard.tscn", Vector2i(30, 10)) as Shipyard
	await process_frame
	late.set_process(false)
	late.start_construction()
	hud.show_for_selection([late])
	_check("unbuilt_producer_disabled", button_of(yard_panel).disabled, "enabled while under construction")
	late.add_build_progress(late.build_time + 1.0)
	_check("completed_refreshes_panel", late.built and not button_of(yard_panel).disabled, "still disabled after completion")
	hud.free()
	Sim.free_world(world)
	quit(1 if _failed else 0)


func button_of(panel: ProducerPanel) -> Button:
	return panel.get_node("%ProduceButton") as Button


func _key(code: Key) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.pressed = true
	return ev


func _check(test_name: String, ok: bool, why: String) -> void:
	if ok:
		print("PASS ", test_name)
	else:
		print("FAIL ", test_name, ": ", why)
		_failed = true


func _on_timeout() -> void:
	print("FAIL timeout: test did not finish (script error?)")
	quit(1)
