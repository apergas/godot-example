extends SceneTree
## Probe: autoloads exist under --script, and scripts loaded at runtime can use their global name.

var _failed := false


func _initialize() -> void:
	await process_frame
	var gs: Node = root.get_node_or_null("GameState")
	_check(gs != null, "autoload_node_in_root", "root has no GameState child")
	if gs == null:
		quit(1)
		return
	var probe := GDScript.new()
	probe.source_code = "extends RefCounted\n\nfunc crystal() -> int:\n\treturn GameState.stock[ResKind.CRYSTAL]\n"
	var err := probe.reload()
	_check(err == OK, "autoload_name_compiles_in_loaded_script", "reload() returned %d" % err)
	if err == OK:
		var obj: RefCounted = probe.new()
		var value: int = obj.call("crystal")
		_check(value == 50, "autoload_name_resolves_at_runtime", "got %d" % value)
	quit(1 if _failed else 0)


func _check(ok: bool, name: String, why: String) -> void:
	if ok:
		print("PASS ", name)
	else:
		_failed = true
		print("FAIL ", name, ": ", why)
