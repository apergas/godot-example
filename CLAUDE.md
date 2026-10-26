# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

2D real-time-strategy prototype (`godot-example`): a StarCraft / Age of Empires style resource-gathering game set in the future, with "rare" resources and **no combat**. The work is done from Claude Code, not the Godot editor, so scenes (`.tscn`) and scripts (`.gd`) are written directly as text files.

Current state (after phases 1–9 of the initial plan): a fixed 64×48-tile Mars map defined in code (`MapLayout`), RTS camera (WASD/arrows/edges/middle-drag/wheel zoom 0.5-2.0, clamped to the map), box and Shift selection of robots (`Worker`) and colonists (`Colonist`), two resources (crystal, ice; 400 / 250 units per node) shown in a top HUD bar with a hover tooltip, an HQ that trains robots (50 crystal, 8 s, queue of 5, population cap, `pob X/Y`), robots that gather 10 units (crystal 3 s, ice 4 s) and carry them to the nearest finished building that accepts that kind, and robots that construct buildings placed with a grid ghost from the build menu: habitats (+5 population cap; 30 crystal + 60 ice) and crystal / ice depots (nearby dropoffs, 100 crystal, 15 s; while placing one, resource nodes within 6 tiles are highlighted). When a node runs out, robots retarget to the same kind within 6 tiles.
Endgame (phase 8): a shipyard (3×3, needs nothing) builds rescue ships that park on up to 4 launch pads beside it; a colony module (3×2, needs a finished shipyard) wakes colonists that walk around it and take 1 population each. With 20 colonists and 4 ships (`GameState.GOAL_*`) the colonists board, the ships launch and a victory screen shows the game time and totals, with "Jugar de nuevo". No combat.
Guided missions (phase 9): a fixed list of 12 steps (select a robot → … → 20 colonists + 4 ships) shown top right with progress, a small resource reward and a 3 s toast; the guide can be hidden. Implementation plans live in `plans/` (local only, not versioned).

## Layout

- `scenes/main.tscn` — main scene (`run/main_scene`): `Ground` (`TileMapLayer`, scale 2, z_index -10, `scripts/ground.gd` paints it from `MapLayout` with `assets/ground_tiles.tres`), `World` (y-sorted parent of robots, resources and buildings), `Selection`, `Placement` (with child `ResourceHints`), `Camera2D` (`scripts/camera_rts.gd`), `HUD` instance. Script `scripts/main.gd` spawns the HQ, the start robots and the resources from `MapLayout`, drives the hover tooltip, and is the only reader of mouse orders: left = `Selection`, right = `_command_right_click` (-> `_try_build_order` for an unfinished building, colonists via `_order_colonists` (move only), robots via `_order_workers`: a resource -> `gather`, an unfinished building -> `build`, a building that accepts the carried cargo -> `return_cargo`, else `move_to` / `command_move` in formation). It connects `HUD.build_requested` to `Placement.begin`, `HUD.produce_requested` to `Producer.enqueue()`, sends robots to build each placed building, and ignores orders once victory starts.
- `scenes/worker.tscn` + `scripts/worker.gd` — robot (`CharacterBody2D`, origin at the feet, group `workers`): state machine (`IDLE, MOVING, TO_RESOURCE, GATHERING, TO_DROPOFF, TO_BUILD, BUILDING`), `move_to()`, `gather()`, `build()`, `return_cargo()`, `_nearest_dropoff(kind)` (re-picked on every delivery trip), follows `Nav.find_path` waypoints, counts toward population while in the tree. Collision circle r10, `collision_layer = 2`, `collision_mask = 1`; static `separation_push()` keeps robots apart.
- `scenes/resources/crystal.tscn`, `ice.tscn` + `scripts/resource_node.gd` (`ResourceNode`, group `resources`), origin at the ground contact point; art is 4 frames of 32x48.
- `scenes/buildings/` — `hq.tscn` (`HQ`), `habitat.tscn`, `crystal_depot.tscn`, `ice_depot.tscn` (only `scripts/building.gd`), `shipyard.tscn` (`Shipyard`) and `colony_module.tscn` (`ColonyModule`). `Building` (`StaticBody2D`) has `kind_id`, `requires` (kind_ids that must be finished; checked by `Placement` and the build menu), footprint, `accepts_kinds`, `cost`, `build_time`, `pop_cap_bonus`, Nav blocking, scaffold frame 1 and `BuildBar` while under construction, `Overlay` selection ellipse; groups `buildings` / `dropoffs`. `scripts/buildings/producer.gd` (`Producer`) is the shared paid production queue of `HQ`, `Shipyard` and `ColonyModule` (`enqueue()`, `_can_release()`, `_release_unit()`); `queue` and the training bar live in `Producer`; `HQ` keeps `enqueue_worker()` (wraps `enqueue()`) and spawns robots at an `approach_point` of its footprint, in `IDLE`.
- `scenes/rescue_ship.tscn` + `scripts/rescue_ship.gd` (`RescueShip`, group `ships`, `launch()`), `scenes/colonist.tscn` + `scripts/colonist.gd` (`Colonist`, group `colonists`: walks, wanders, boards; never gathers or builds).
- `scripts/victory.gd` (`Victory`, node in `Main`) plays the evacuation; `scenes/victory_screen.tscn` + `scripts/victory_screen.gd` (`VictoryScreen`). The screen also shows `Misiones: N/12` (`%MissionsLabel`; `Victory._show_screen()` reads `MissionTracker.index` when showing, after the tracker finished on victory; hidden without a tracker). `GameState.restart_game()` frees the scene, resets the autoloads and reloads `main.tscn`.
- `scenes/producer_panel.tscn` + `scripts/producer_panel.gd` (`ProducerPanel`): HUD production panel for the shipyard and colony module (`%ShipyardPanel`, `%ColonyPanel`).
- `scripts/missions.gd` (`Missions`: `LIST` of `{id, text, stat, target, reward}`; `stat` is a `GameState.stats` key, `"a|b"` for a sum, `"workers_alive"`, or arrays + `labels` for several conditions), `scripts/mission_tracker.gd` (`MissionTracker`, node in `Main`: advances in order, pays rewards with `GameState.add(kind, n)`, chains, finishes on `GameState.victory`), `scenes/mission_panel.tscn` + `scripts/mission_panel.gd` (`MissionPanel`, instanced in the HUD as `%MissionPanel`, bound with `HUD.bind_missions()`; hidden/shown state kept in a `static var` for the session).
- `GameState.stats` (cumulative, `stats_changed`, cleared by `reset()`): `gathered_crystal/ice` (only deliveries: `add(kind, n, true)`; rewards use plain `add`), `workers_trained` (HQ), `built_<kind_id>` (on construction completed), `colonists`, `ships`, `selected_worker`; helpers `stat()`, `add_stat()`, `set_stat()`.
- `scenes/hud.tscn` + `scripts/hud.gd` — resource bar, `PopLabel`, goal label (`%GoalLabel`), hover tooltip, `HQPanel` (train button / `Q`, signal `train_requested`), production panels, `BuildMenu` (`BUILDABLES`: habitat, crystal depot, ice depot, shipyard, colony module buttons; shortcuts `B`+`H`/`C`/`I`/`Y`/`M` handled by `_handle_build_keys`, which loops `BUILDABLES`; `build_hotkey_scene(keycode)` is a lookup helper; signals `build_requested(scene)`, `produce_requested(producer)`; visible with robots selected).
- `scripts/selection.gd` (`Selection`: units = robots + colonists, ships and buildings picked alone; no `_pick_at`, static `pick_at(p, nodes)` per group), `scripts/placement.gd` (`Placement`: grid ghost green/red, left click confirms, right click/Esc cancels, Shift keeps placing, signal `placed`), `scripts/resource_hints.gd` (`ResourceHints`), `scripts/formation.gd` (`Formation`), `scripts/order_marker.gd`, `scripts/camera_rts.gd`.
- Static helpers: `scripts/grid.gd` (`Grid`, 1 tile = 64 px, map 64x48), `scripts/res_kind.gd` (`ResKind`), `scripts/map_layout.gd` (`MapLayout`). Autoloads: `GameState` (`scripts/game_state.gd`: stock, population (cap 60), evacuation goals and counters, play time, gathered totals, cumulative `stats`, restart; `stock` indexed by `ResKind`, `add/can_afford/spend/reset/restart_game`, `stock_changed`, `goal_changed`, `victory`, population and cap clamped to `MAX_CAP`), `Nav` (`scripts/nav.gd`: `AStarGrid2D`; resources and buildings block cells; `find_path`, `approach_point`, `is_area_free`, `set_blocked`, `reset`).
- `art_src/make_*.gd` — sprite generators (worker, ground, resources, hq, habitat, depots, shipyard (+ launch pad), colony module, rescue ship, colonist) writing to `assets/`.
- `tests/` — headless `SceneTree` tests `test_<phase>_<topic>.gd` (`tests/.gdignore` keeps them out of the project), shared `sim_helpers.gd` (accelerated simulation: `Engine.time_scale` x8 with 480 physics ticks), `bench_07_depot_balance.gd` (balance bench, not part of the suite), `manual_NN_*.gd` manual launchers (e.g. `manual_09_missions.gd`; not run by `run_all.ps1`, which only runs `test_*.gd`), `run_all.ps1`.
- `tools/` — local, git-ignored tooling: portable Node (`tools/node`), the Godot MCP server (`tools/godot-mcp`), the `tools/godot.cmd` wrapper and `tools/serve_web.ps1`.
- `.mcp.json` — registers the `godot` MCP server; `GODOT_PATH` points at the Godot 4.7.2 console exe in `Downloads`.

## Art

Pixel art, three-quarter view (like Age of Empires: seen from front and above, selection ring drawn as a flattened ellipse at the feet; the worker's ground shadow is drawn in code, resource sprites bake theirs in), 32x32 sprites shown at 2x (mobile-friendly size), nearest-neighbour filtering (`default_texture_filter=0`). Sprites are generated by code, not drawn in an editor: `art_src/make_*.gd` (git-tracked, `.gdignore`d) writes PNGs to `assets/`. Regenerate with `.\tools\godot.cmd --headless --path . --script res://art_src/make_worker.gd -- <preview.png>` (the optional arg saves an 8x preview to view), then `.\tools\godot.cmd --headless --path . --import`. `assets/worker.png` is a 4x3 sheet (columns = walk phases, 0 and 2 are standing; rows = down, up, right; left is the right row with `flip_h`), used through `Sprite2D` `hframes`/`vframes`; `scripts/worker.gd` picks row/frame from the movement direction. `assets/hq.png` (104x132, baked shadow) is the HQ sprite. `art_src/make_habitat.gd` → `assets/habitat.png` (2 frames 80×80: finished, scaffold; origin pixel (32, 80)).

Buildings use `Sprite2D` with `centered = false` and an `offset` that puts the bottom edge of the footprint on the node origin; their baked shadow (black, alpha 0.35) falls down-right. Depot sheets (`art_src/make_depots.gd` → `assets/crystal_depot.png`, `assets/ice_depot.png`) are two 96×104 frames: 0 = finished, 1 = scaffolding.

Phase 8 sheets: `assets/shipyard.png` (two 144×144 frames, offset (-48, -136)), `assets/launch_pad.png` (64×64 flat pad), `assets/colony_module.png` (two 128×112 frames, offset (-48, -104)), `assets/rescue_ship.png` (three 104×104 frames: parked, engine firing, ground shadow only; offset (-32, -80)), `assets/colonist.png` (4×3 like `worker.png`, white/orange suit, gold visor).

`assets/ground_tiles.png` (from `art_src/make_ground.gd`) is a 4x4 atlas: row 0 sand x4, row 1 rock x2 + pebbles x2, rows 2-3 columns 0-1 a 2x2 crater split into four tiles.

## Engine configuration (from `project.godot`)

- Godot **4.7**, GL Compatibility renderer (also used on mobile).
- 3D physics: **Jolt Physics**.
- Windows rendering driver: d3d12.
- Stretch mode `canvas_items`, aspect `expand`.
- `.editorconfig` enforces UTF-8.

## Commands

`godot` is not on the system PATH. Use the wrapper `tools\godot.cmd` (forwards all arguments to the console exe):

```powershell
.\tools\godot.cmd --path . --quit-after 60 --headless
```

Run the game: `.\tools\godot.cmd --path .`. Run a specific scene: `.\tools\godot.cmd --path . res://scenes/worker.tscn`. Open the editor only if needed: `.\tools\godot.cmd --editor --path .`.

Validate a script: `.\tools\godot.cmd --headless --path . --check-only --script res://scripts/worker.gd`.

Tests: `powershell -ExecutionPolicy Bypass -File .\tests\run_all.ps1` runs every `tests/test_*.gd` (after `--import`); a single one: `.\tools\godot.cmd --headless --path . --script res://tests/test_07_depot_dropoff.gd` (prints `PASS`/`FAIL`, exit code 0/1). Tests are `extends SceneTree` scripts; autoloads are reached with `root.get_node("GameState")` / `root.get_node("Nav")` after `await process_frame`. Long simulations use `tests/sim_helpers.gd` (`const Sim := preload("res://tests/sim_helpers.gd")`, `Sim.accelerate()`, `Sim.run_for()`). Balance bench: `.\tools\godot.cmd --headless --path . --script res://tests/bench_07_depot_balance.gd`. After adding a script with a new `class_name`, run `.\tools\godot.cmd --headless --path . --import` so the class cache knows it. No test framework (GUT/gdUnit4) is installed.
Victory time bench: `.\tools\godot.cmd --headless --path . --script res://tests/bench_08_victory_time.gd` (greedy economy model, prints a table and `VICTORY_TIME_OK/SHORT/LONG`).
Manual missions walkthrough with extra stock and optional speed-up: `.\tools\godot.cmd --path . --script res://tests/manual_09_missions.gd -- 3`.

Web build: export templates (web only) are in `%APPDATA%\Godot\export_templates\4.7.2.stable`; `export_presets.cfg` has a "Web" preset. Export with `.\tools\godot.cmd --headless --path . --export-release Web build/web/index.html` (`build/` is git-ignored), then serve with `powershell -File .\tools\serve_web.ps1` and open `http://localhost:8060/`. Browsers need HTTP, not `file://`. In a HiDPI browser pane screenshots can crop the canvas: set the viewport to 800x600 for visual checks. `tools/.gdignore` keeps Godot from scanning/packing `tools/`.

The `godot` MCP tools (`run_project`, `get_debug_output`, `create_scene`, `add_node`, ...) need `projectPath` set to this directory.

## Notes

- `class_name` scripts (`Worker`, `ResourceNode`, `Building`, ...) must not use bare autoload identifiers (`Nav`, `GameState`): they compile before autoloads exist (e.g. in `--script` runs) and fail. Look the autoload up at runtime and type it via preload: `const NavScript := preload("res://scripts/nav.gd")` then `get_node_or_null("/root/Nav") as NavScript` (see `ResourceNode._set_nav_blocked`). Non-`class_name` scripts (`main.gd`, `hud.gd`) may use bare names. In `--script` tests use `root.get_node("Nav")` / `root.get_node("GameState")`.
- Headless `--script` test viewport is 64x64 with `canvas_items` stretch, so tests using `root.push_input` must set `root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED` first. HUD Controls (TopBar 44 px, MissionPanel Body) can swallow pushed clicks: hide them or click outside them (see `tests/test_01_camera_node.gd`).
- `.godot/` is the editor's generated cache; never edit it by hand.
- `project.godot` can be edited by hand for small changes (e.g. `run/main_scene`); the editor rewrites it on save.
- Git 2.56 is installed (`C:\Program Files\Git\cmd`), but it may not be on the PATH of already-open shells; call `& "C:\Program Files\Git\cmd\git.exe"` if `git` is not found. Remote: `origin` = `https://github.com/apergas/godot-example`. Commit the generated `.uid` files alongside their scripts.

## Git workflow (gitflow)

Never commit directly to `main` or `develop`.

- `main` — released versions only; every push to it deploys to GitHub Pages.
- `develop` — integration branch; default base for new work.
- `feature/<name>` — branched from `develop`, merged back into `develop` with `git merge --no-ff`.
- `release/<version>` — branched from `develop` when preparing a release; merged into `main` (tag `v<version>`) and back into `develop`.
- `hotfix/<name>` — branched from `main` for urgent fixes; merged into `main` (tag) and `develop`.

Once a branch is merged and pushed (`origin/develop`, or `origin/main` for release/hotfix), delete it locally and on the remote: `git branch -d <branch>` and `git push origin --delete <branch>`. Check first with `git branch -r --merged origin/develop`.

## Deploy (GitHub Pages)

`.github/workflows/deploy-pages.yml` downloads Godot 4.7.2 (Linux) and its web export templates, runs `--import`, exports the "Web" preset to `build/web/` and publishes it with `actions/deploy-pages`. It runs on push to `main` and manually (`workflow_dispatch`). One-time repo setting: Settings > Pages > Source = "GitHub Actions". The "Web" preset keeps `variant/thread_support=false`, because GitHub Pages cannot send the COOP/COEP headers a threaded build needs. When upgrading Godot, change `GODOT_VERSION` in the workflow too.
