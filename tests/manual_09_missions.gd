extends SceneTree
## Manual run for phase 9: opens the game with extra stock (not counted as gathering) and an
## optional speed-up to walk through the 12 missions. Not a test: run_all.ps1 only runs test_*.gd.
## Jugar de nuevo reloads main.tscn without the boost (extra stock and speed-up are lost).
## Run: tools\godot.cmd --path . --script res://tests/manual_09_missions.gd [-- <time_scale 1..8>]

const BOOST := 3000


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty() and args[0].is_valid_float():
		Engine.time_scale = clampf(args[0].to_float(), 1.0, 8.0)
		Engine.physics_ticks_per_second = roundi(60.0 * Engine.time_scale)
	await process_frame
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	current_scene = main
	var gs: Node = root.get_node("GameState")
	gs.add(ResKind.CRYSTAL, BOOST)
	gs.add(ResKind.ICE, BOOST)
	print("manual_09: +%d crystal, +%d ice, time_scale %.1f" % [BOOST, BOOST, Engine.time_scale])
