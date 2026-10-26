extends SceneTree
## Missions.LIST matches the README (order, stats, targets, rewards) and the pure helpers work.

var _failed := false


func _initialize() -> void:
	create_timer(20.0).timeout.connect(_on_timeout)
	await process_frame
	var gs: Node = root.get_node("GameState")
	var list: Array = Missions.LIST
	_check("twelve_missions", list.size() == 12, str(list.size()))
	if list.size() != 12:
		quit(1)
		return
	var ids: Array = list.map(func(m: Dictionary) -> String: return m["id"])
	_check("ids_in_order", ids == ["select_worker", "gather_crystal", "train_worker", "gather_ice", "build_habitat", "build_depot", "ten_workers", "build_more_habitats", "build_shipyard", "build_colony_module", "first_ship_and_colonist", "final_goal"], str(ids))
	var stats: Array = list.map(func(m: Dictionary) -> Variant: return m["stat"])
	_check("stats_in_order", stats == ["selected_worker", "gathered_crystal", "workers_trained", "gathered_ice", "built_habitat", "built_crystal_depot|built_ice_depot", "workers_alive", "built_habitat", "built_shipyard", "built_colony_module", ["ships", "colonists"], ["colonists", "ships"]], str(stats))
	var targets: Array = list.map(func(m: Dictionary) -> Variant: return m["target"])
	_check("targets_in_order", targets == [1, 50, 1, 50, 1, 1, 10, 3, 1, 1, [1, 1], [20, 4]], str(targets))
	var rewards: Array = list.map(func(m: Dictionary) -> Dictionary: return m["reward"])
	var expected_rewards := [
		{},
		{ResKind.CRYSTAL: 25},
		{ResKind.CRYSTAL: 25},
		{ResKind.CRYSTAL: 25},
		{ResKind.ICE: 50},
		{ResKind.CRYSTAL: 50},
		{ResKind.CRYSTAL: 100},
		{ResKind.ICE: 50},
		{ResKind.ICE: 100},
		{ResKind.CRYSTAL: 50},
		{ResKind.CRYSTAL: 100},
		{},
	]
	_check("rewards_in_order", rewards == expected_rewards, str(rewards))
	var all_text := true
	for m in list:
		if String(m["text"]).strip_edges() == "":
			all_text = false
	_check("every_mission_has_text", all_text, "empty text")
	_check("final_goal_matches_game_state", list[11]["target"] == [gs.GOAL_COLONISTS, gs.GOAL_SHIPS], "%s vs %d/%d" % [list[11]["target"], gs.GOAL_COLONISTS, gs.GOAL_SHIPS])

	var single: Array[Dictionary] = Missions.conditions(list[1])
	_check("conditions_single", single.size() == 1 and single[0]["stat"] == "gathered_crystal" and single[0]["target"] == 50 and single[0]["label"] == "", str(single))
	var multi: Array[Dictionary] = Missions.conditions(list[10])
	_check("conditions_multi", multi.size() == 2 and multi[0]["label"] == "Naves" and multi[1]["label"] == "Colonos" and multi[1]["target"] == 1, str(multi))
	_check("conditions_empty", Missions.conditions({}).is_empty(), "not empty")

	var depot: String = list[5]["stat"]
	_check("value_sum_one", Missions.value(depot, {"built_ice_depot": 1}, 0) == 1, "")
	_check("value_sum_both", Missions.value(depot, {"built_ice_depot": 1, "built_crystal_depot": 2}, 0) == 3, "")
	_check("value_workers_alive", Missions.value(Missions.WORKERS_ALIVE, {}, 7) == 7, "")
	_check("value_missing_is_zero", Missions.value("built_shipyard", {}, 3) == 0, "")
	_check("value_plain", Missions.value("gathered_ice", {"gathered_ice": 42}, 0) == 42, "")

	_check("reward_text_crystal", Missions.reward_text({ResKind.CRYSTAL: 25}) == "+25 cristal", Missions.reward_text({ResKind.CRYSTAL: 25}))
	_check("reward_text_ice", Missions.reward_text({ResKind.ICE: 50}) == "+50 hielo", Missions.reward_text({ResKind.ICE: 50}))
	_check("reward_text_empty", Missions.reward_text({}) == "", Missions.reward_text({}))
	quit(1 if _failed else 0)


func _check(test_name: String, ok: bool, why: String) -> void:
	if ok:
		print("PASS ", test_name)
	else:
		_failed = true
		print("FAIL ", test_name, ": ", why)


func _on_timeout() -> void:
	print("FAIL timeout: test did not finish (script error?)")
	quit(1)
