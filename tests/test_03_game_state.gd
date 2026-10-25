extends SceneTree
## GameState: stock, add, can_afford, spend, reset and stock_changed.

var _failed := false


func _initialize() -> void:
	await process_frame
	var gs: Node = root.get_node_or_null("GameState")
	if gs == null:
		_check(false, "game_state_present", "no /root/GameState node")
		quit(1)
		return
	gs.reset()
	_check(_stock_is(gs, 50, 0), "initial_stock", str(gs.stock))

	var hits := [0]
	gs.stock_changed.connect(func() -> void: hits[0] += 1)

	gs.add(ResKind.CRYSTAL, 25)
	_check(_stock_is(gs, 75, 0), "add_crystal", str(gs.stock))
	_check(hits[0] == 1, "add_emits_stock_changed", "hits=%d" % hits[0])
	gs.add(ResKind.ICE, 0)
	_check(hits[0] == 1, "add_zero_is_silent", "hits=%d" % hits[0])

	_check(gs.can_afford({ResKind.CRYSTAL: 75}), "can_afford_exact", str(gs.stock))
	_check(not gs.can_afford({ResKind.CRYSTAL: 76}), "cannot_afford_more", str(gs.stock))
	_check(not gs.can_afford({ResKind.CRYSTAL: 10, ResKind.ICE: 1}), "cannot_afford_missing_kind", str(gs.stock))
	_check(gs.can_afford({}), "can_afford_empty_cost", "")

	var ok: bool = gs.spend({ResKind.CRYSTAL: 10, ResKind.ICE: 1})
	_check(not ok, "spend_refuses_when_short", "returned true")
	_check(_stock_is(gs, 75, 0), "spend_refused_keeps_stock", str(gs.stock))
	_check(hits[0] == 1, "spend_refused_is_silent", "hits=%d" % hits[0])

	ok = gs.spend({ResKind.CRYSTAL: 30})
	_check(ok, "spend_succeeds", "returned false")
	_check(_stock_is(gs, 45, 0), "spend_subtracts", str(gs.stock))
	_check(hits[0] == 2, "spend_emits_stock_changed", "hits=%d" % hits[0])

	gs.add(ResKind.ICE, 12)
	gs.reset()
	_check(_stock_is(gs, 50, 0), "reset_restores_stock", str(gs.stock))
	_check(hits[0] == 4, "reset_emits_stock_changed", "hits=%d" % hits[0])
	quit(1 if _failed else 0)


func _stock_is(gs: Node, crystal: int, ice: int) -> bool:
	return gs.stock.size() == ResKind.COUNT and gs.stock[ResKind.CRYSTAL] == crystal and gs.stock[ResKind.ICE] == ice


func _check(ok: bool, name: String, why: String) -> void:
	if ok:
		print("PASS ", name)
	else:
		_failed = true
		print("FAIL ", name, ": ", why)
