class_name Missions extends RefCounted
## Guided missions (phase 9), in fixed order. Each mission: {id, text, stat, target, reward}.
## stat: a GameState.stats key, several keys joined by "|" (their sum, e.g. either depot) or
## "workers_alive" (robots now in the "workers" group). A mission with several conditions uses
## arrays: stat = [keys], target = [ints], labels = [names]; every condition must be reached.

const WORKERS_ALIVE := "workers_alive"
const SUM_SEPARATOR := "|"

const LIST: Array[Dictionary] = [
	{
		"id": "select_worker",
		"text": "Selecciona un robot con clic izquierdo.",
		"stat": "selected_worker",
		"target": 1,
		"reward": {},
	},
	{
		"id": "gather_crystal",
		"text": "Recoge 50 de cristal: con robots seleccionados, clic derecho sobre un cristal.",
		"stat": "gathered_crystal",
		"target": 50,
		"reward": {ResKind.CRYSTAL: 25},
	},
	{
		"id": "train_worker",
		"text": "Entrena 1 robot: selecciona la base central y pulsa Q.",
		"stat": "workers_trained",
		"target": 1,
		"reward": {ResKind.CRYSTAL: 25},
	},
	{
		"id": "gather_ice",
		"text": "Recoge 50 de hielo. Los bloques de hielo están lejos, al sureste de la base.",
		"stat": "gathered_ice",
		"target": 50,
		"reward": {ResKind.CRYSTAL: 25},
	},
	{
		"id": "build_habitat",
		"text": "Construye 1 habitáculo: selecciona un robot y pulsa B + H.",
		"stat": "built_habitat",
		"target": 1,
		"reward": {ResKind.ICE: 50},
	},
	{
		"id": "build_depot",
		"text": "Construye un depósito de cristal o de hielo junto a un campo (B + C o B + I).",
		"stat": "built_crystal_depot|built_ice_depot",
		"target": 1,
		"reward": {ResKind.CRYSTAL: 50},
	},
	{
		"id": "ten_workers",
		"text": "Ten 10 robots a la vez.",
		"stat": "workers_alive",
		"target": 10,
		"reward": {ResKind.CRYSTAL: 100},
	},
	{
		"id": "build_more_habitats",
		"text": "Construye 2 habitáculos más (3 en total). Los colonos también ocupan población.",
		"stat": "built_habitat",
		"target": 3,
		"reward": {ResKind.ICE: 50},
	},
	{
		"id": "build_shipyard",
		"text": "Construye el astillero.",
		"stat": "built_shipyard",
		"target": 1,
		"reward": {ResKind.ICE: 100},
	},
	{
		"id": "build_colony_module",
		"text": "Construye el módulo de colonos (requiere el astillero).",
		"stat": "built_colony_module",
		"target": 1,
		"reward": {ResKind.CRYSTAL: 50},
	},
	{
		"id": "first_ship_and_colonist",
		"text": "Fabrica la primera nave y el primer colono. Cada colono ocupa 1 de población: construye otro habitáculo si hace falta.",
		"stat": ["ships", "colonists"],
		"target": [1, 1],
		"labels": ["Naves", "Colonos"],
		"reward": {ResKind.CRYSTAL: 100},
	},
	{
		"id": "final_goal",
		"text": "Meta final: 20 colonos y 4 naves. Los colonos necesitan habitáculos.",
		"stat": ["colonists", "ships"],
		"target": [20, 4],
		"labels": ["Colonos", "Naves"],
		"reward": {},
	},
]


static func conditions(mission: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if mission.is_empty():
		return out
	var stat: Variant = mission["stat"]
	if stat is Array:
		for i in stat.size():
			out.append({"stat": String(stat[i]), "target": int(mission["target"][i]), "label": String(mission["labels"][i])})
	else:
		out.append({"stat": String(stat), "target": int(mission["target"]), "label": ""})
	return out


static func value(stat: String, stats: Dictionary, workers_alive: int) -> int:
	if stat == WORKERS_ALIVE:
		return workers_alive
	var total := 0
	for key in stat.split(SUM_SEPARATOR):
		total += int(stats.get(key, 0))
	return total


static func reward_text(reward: Dictionary) -> String:
	var parts := PackedStringArray()
	for kind in reward:
		parts.append("+%d %s" % [int(reward[kind]), String(ResKind.NAMES[kind]).to_lower()])
	return " · ".join(parts)
