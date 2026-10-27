extends SceneTree
## Phase 8 balance bench (not a test: run_all.ps1 only runs tests/test_*.gd).
## Greedy economy model without physics: seconds until the evacuation goal with the costs and
## times read from the real scenes and scripts. Gather rates per robot come from the phase 7
## bench: replace the three *_PER_SECOND constants with the values written in row 7 of the index.
## Run: tools\godot.cmd --headless --path . --script res://tests/bench_08_victory_time.gd

# Measured, 1 robot, nearest node, real map: seconds per 10-unit load.
# Ice: phase 7 bench (HQ 17.6 s, depot 4.0 s). Crystal: same method, HQ 4.93 s (3.03 s with depot, unused here).
const CRYSTAL_PER_SECOND := 10.0 / 4.93
const ICE_HQ_PER_SECOND := 10.0 / 17.6
const ICE_DEPOT_PER_SECOND := 10.0 / 4.0
const START_STOCK := [50.0, 0.0]
const START_WORKERS := 3
const TARGET_WORKERS := 14
const DEPOT_AT_WORKERS := 5
const SHIPYARD_AT_WORKERS := 12
const HUMAN_FACTOR := 1.5
const TARGET_MIN := 20.0
const TARGET_MAX := 30.0
const MAX_SECONDS := 7200
# [name, gather rate factor, seconds lost per build order (walking), builders on big buildings]
const SCENARIOS := [
	["Ideal", 1.0, 6.0, 2],
	["Lento (recolección x0.6, 15 s por encargo)", 0.6, 15.0, 2],
	["Muy lento (x0.4, 20 s, 1 constructor)", 0.4, 20.0, 1],
]


func _initialize() -> void:
	await process_frame
	var k := _read_numbers()
	print("| Escenario | Depósito de hielo | Astillero listo | Módulo listo | Primer colono | Primera nave | Victoria | x%.1f (jugador real) |" % HUMAN_FACTOR)
	print("|---|---|---|---|---|---|---|---|")
	var ideal := 0.0
	for scenario in SCENARIOS:
		var events := _simulate(k, scenario[1], scenario[2], scenario[3])
		var victory: float = events["victory"]
		if ideal == 0.0:
			ideal = victory
		print("| %s | %s | %s | %s | %s | %s | **%s** | ~%.1f min |" % [scenario[0],
				_mmss(events.get("depot", -1.0)), _mmss(events.get("shipyard", -1.0)), _mmss(events.get("module", -1.0)),
				_mmss(events.get("first_colonist", -1.0)), _mmss(events.get("first_ship", -1.0)),
				_mmss(victory), victory * HUMAN_FACTOR / 60.0])
	var human_minutes := ideal * HUMAN_FACTOR / 60.0
	print("Ideal %.1f min -> jugador real ~%.1f min (objetivo %.0f-%.0f min)" % [ideal / 60.0, human_minutes, TARGET_MIN, TARGET_MAX])
	if human_minutes < TARGET_MIN:
		print("VICTORY_TIME_SHORT")
	elif human_minutes > TARGET_MAX:
		print("VICTORY_TIME_LONG")
	else:
		print("VICTORY_TIME_OK")
	quit()


func _read_numbers() -> Dictionary:
	var gs = root.get_node("GameState")
	var hq := _proto("res://scenes/buildings/hq.tscn")
	var habitat := _proto("res://scenes/buildings/habitat.tscn")
	var depot := _proto("res://scenes/buildings/ice_depot.tscn")
	var shipyard := _proto("res://scenes/buildings/shipyard.tscn")
	var module := _proto("res://scenes/buildings/colony_module.tscn")
	return {
		"worker_cost": HQ.WORKER_COST, "worker_s": HQ.TRAIN_SECONDS, "worker_queue": HQ.QUEUE_MAX,
		"hq_cap": hq["bonus"],
		"habitat_cost": habitat["cost"], "habitat_s": habitat["time"], "habitat_cap": habitat["bonus"],
		"depot_cost": depot["cost"], "depot_s": depot["time"],
		"shipyard_cost": shipyard["cost"], "shipyard_s": shipyard["time"],
		"module_cost": module["cost"], "module_s": module["time"],
		"ship_cost": Shipyard.SHIP_COST, "ship_s": Shipyard.SHIP_SECONDS, "ship_queue": Shipyard.QUEUE_MAX,
		"colonist_cost": ColonyModule.COLONIST_COST, "colonist_s": ColonyModule.COLONIST_SECONDS,
		"colonist_queue": ColonyModule.QUEUE_MAX,
		"goal_colonists": gs.GOAL_COLONISTS, "goal_ships": gs.GOAL_SHIPS, "max_cap": gs.MAX_CAP,
	}


func _proto(path: String) -> Dictionary:
	var building := (load(path) as PackedScene).instantiate() as Building
	var info := {"cost": building.cost.duplicate(), "time": building.build_time, "bonus": building.pop_cap_bonus}
	building.free()
	return info


## One second per step. Returns the second at which each milestone happened.
func _simulate(k: Dictionary, rate: float, walk: float, builders: int) -> Dictionary:
	var stock: Array[float] = [START_STOCK[0], START_STOCK[1]]
	var events := {}
	var goal_c: int = k["goal_colonists"]
	var goal_s: int = k["goal_ships"]
	var workers := START_WORKERS
	var pop := START_WORKERS
	var cap: int = k["hq_cap"]
	var busy := 0
	var train_q := 0
	var train_t := 0.0
	var depot_at := -1.0
	var has_depot := false
	var habitats: Array[float] = []
	var shipyard_at := -1.0
	var has_shipyard := false
	var module_at := -1.0
	var has_module := false
	var ships := 0
	var ship_q := 0
	var ship_t := 0.0
	var colonists := 0
	var col_q := 0
	var col_t := 0.0
	for t in MAX_SECONDS:
		var now := float(t)
		# Ice depot by the ice field once there are a few robots.
		if depot_at < 0.0 and workers >= DEPOT_AT_WORKERS and _pay(stock, k["depot_cost"]):
			depot_at = now + float(k["depot_s"]) + walk
			busy += 1
		if depot_at >= 0.0 and not has_depot and now >= depot_at:
			has_depot = true
			busy -= 1
			events["depot"] = now
		# Habitats: keep the cap ahead of the robots, and of the colonists once the shipyard exists.
		var pending: int = cap + int(k["habitat_cap"]) * habitats.size()
		var want: int = mini(workers + (goal_c if shipyard_at >= 0.0 else 2), int(k["max_cap"]))
		if pending < want and pop >= pending - 1 and habitats.size() < 2 and _pay(stock, k["habitat_cost"]):
			habitats.append(now + float(k["habitat_s"]) + walk)
			busy += 1
		for i in range(habitats.size() - 1, -1, -1):
			if now >= habitats[i]:
				habitats.remove_at(i)
				cap = mini(cap + int(k["habitat_cap"]), int(k["max_cap"]))
				busy -= 1
		# Robots.
		if workers + train_q < TARGET_WORKERS and train_q < int(k["worker_queue"]) and _pay(stock, k["worker_cost"]):
			train_q += 1
		# Shipyard, then the colony module, then their queues.
		if shipyard_at < 0.0 and workers >= SHIPYARD_AT_WORKERS and _pay(stock, k["shipyard_cost"]):
			shipyard_at = now + float(k["shipyard_s"]) / builders + walk
			busy += builders
		if shipyard_at >= 0.0 and not has_shipyard and now >= shipyard_at:
			has_shipyard = true
			busy -= builders
			events["shipyard"] = now
		if has_shipyard and module_at < 0.0 and _pay(stock, k["module_cost"]):
			module_at = now + float(k["module_s"]) / builders + walk
			busy += builders
		if module_at >= 0.0 and not has_module and now >= module_at:
			has_module = true
			busy -= builders
			events["module"] = now
		if has_shipyard and ships + ship_q < goal_s and ship_q < int(k["ship_queue"]) and _pay(stock, k["ship_cost"]):
			ship_q += 1
		if has_module and colonists + col_q < goal_c and col_q < int(k["colonist_queue"]) and _pay(stock, k["colonist_cost"]):
			col_q += 1
		# One second of production.
		if train_q > 0 and pop < cap:
			train_t += 1.0
			if train_t >= float(k["worker_s"]):
				train_t = 0.0
				train_q -= 1
				workers += 1
				pop += 1
		if ship_q > 0:
			ship_t += 1.0
			if ship_t >= float(k["ship_s"]):
				ship_t = 0.0
				ship_q -= 1
				ships += 1
				if ships == 1:
					events["first_ship"] = now
		if col_q > 0 and pop < cap:
			col_t += 1.0
			if col_t >= float(k["colonist_s"]):
				col_t = 0.0
				col_q -= 1
				colonists += 1
				pop += 1
				if colonists == 1:
					events["first_colonist"] = now
		# One second of gathering; more robots on ice while ice is short.
		var gatherers := maxi(workers - busy, 0)
		var ice_share := 0.5 if stock[ResKind.ICE] < 150.0 else 0.35
		var ice_rate := ICE_DEPOT_PER_SECOND if has_depot else ICE_HQ_PER_SECOND
		stock[ResKind.CRYSTAL] += gatherers * (1.0 - ice_share) * CRYSTAL_PER_SECOND * rate
		stock[ResKind.ICE] += gatherers * ice_share * ice_rate * rate
		if colonists >= goal_c and ships >= goal_s:
			events["victory"] = now
			return events
	events["victory"] = float(MAX_SECONDS)
	return events


func _pay(stock: Array[float], cost: Dictionary) -> bool:
	for kind in cost:
		if stock[kind] < float(cost[kind]):
			return false
	for kind in cost:
		stock[kind] -= float(cost[kind])
	return true


func _mmss(seconds: float) -> String:
	if seconds < 0.0:
		return "-"
	var total := int(seconds)
	return "%d:%02d" % [floori(total / 60.0), total % 60]
