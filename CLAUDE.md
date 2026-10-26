# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

2D real-time-strategy prototype (`godot-example`): a StarCraft / Age of Empires style resource-gathering game set in the future, with "rare" resources and **no combat**. The work is done from Claude Code, not the Godot editor, so scenes (`.tscn`) and scripts (`.gd`) are written directly as text files.

Current state: a 64x48-tile Mars ground (decorative), an RTS camera (WASD/arrows, 20 px screen edges, middle-button drag, wheel zoom 0.5-2.0, clamped to the map), a 3x3 HQ at `MapLayout.HQ_CELL` (10,21) and 3 starting `Worker` units next to it, all inside a y-sorted `World` node. Left click / drag box selects (Shift adds); right click routes by target: a resource -> gather, the HQ with cargo -> return cargo, anything else -> move in formation with a fading order marker. Workers path around the HQ and resources with `Nav` (A*), gather 10 units (crystal 3 s, ice 4 s), carry them to the nearest HQ (the HUD stock rises 10 per delivery) and loop; when a node runs out they retarget to the same kind within 6 tiles, else go idle. A carried-resource icon floats above the worker. Crystal clusters and ice blocks are placed from `MapLayout` (400 / 250 units each); a top HUD bar shows the global stock (start 50 crystal, 0 ice) and hovering a resource shows what is left. Workers build buildings placed with a grid ghost (build menu or `B` + `H`; habitat costs 30 crystal + 60 ice, 12 s with one worker, 6 s with two); habitats raise the population cap by 5. The HQ trains workers (50 crystal, 8 s each, queue of 5, paid on enqueue) and gives +5 population cap; population (`pob X/Y`) is capped (`GameState.MAX_CAP` 50) and a full population pauses the queue. Clicking the HQ selects it and shows its panel in the HUD (button / key `Q` to train). Implementation plans live in `plans/` (local only, not versioned).

## Layout

- `scenes/main.tscn` — main scene (`run/main_scene`): `Ground` (`TileMapLayer`, scale 2, z_index -10, `scripts/ground.gd` paints it from `MapLayout` with `assets/ground_tiles.tres`), `World` (y-sorted parent of workers, resources and buildings), a `HUD` instance, `Selection`, `Camera2D` (`scripts/camera_rts.gd`). Script: `scripts/main.gd` spawns the HQ (`_spawn_hq`), the start workers and the resources from `MapLayout` under `World`, drives the hover tooltip (`_update_hover` / `_resource_at`) and routes mouse input (left = `Selection`, right = `_order_workers`: resource -> `gather`, HQ with cargo -> `return_cargo`, else `move_to` / `command_move`).
- `scripts/nav.gd` — autoload `Nav`: `AStarGrid2D` over the map; resources and buildings block their cells; `find_path`, `approach_point`, `is_area_free`, `set_blocked`, `reset`.
- `scripts/building.gd` (`Building`, `StaticBody2D`: footprint, Nav blocking, groups `buildings` / `dropoffs`, picking, `pop_cap_bonus`, `selected`, child `Overlay` node (z_index 1) that draws the selection ellipse via `_draw_overlay()`) and `scripts/buildings/hq.gd` (`HQ`: `queue`, `enqueue_worker()`, `TRAIN_SECONDS`, `queue_changed`, training bar over the building; the worker spawns at `Nav.approach_point` below the HQ and stays IDLE), scene `scenes/buildings/hq.tscn`, art `art_src/make_hq.gd` -> `assets/hq.png` (104x132).
- `scripts/placement.gd` — `Placement`: build ghost snapped to the grid (green/red), confirm with left click, cancel with right click/Esc, Shift keeps placing.
- `scenes/buildings/habitat.tscn` — 2×2 habitat (+5 population), built by workers; `scripts/building.gd` handles construction (`start_construction`, `add_build_progress`, scaffold frame 1, `BuildBar`).
- `scripts/grid.gd` — `Grid`: static cell/world helpers (1 tile = 64 px, map 64x48). `scripts/map_layout.gd` — `MapLayout`: fixed map data (rock patches, craters, seed).
- `tests/` — headless `SceneTree` tests (`test_<phase>_<topic>.gd`, print `PASS`/`FAIL`, exit code 0/1); `tests/.gdignore` keeps them out of the project. Run all with `powershell -ExecutionPolicy Bypass -File .\tests\run_all.ps1` (it runs `--import` first so new `class_name` scripts are known).
- `scenes/worker.tscn` — `CharacterBody2D` unit, origin at the feet (`Sprite2D` at `(0, -22)`, collision radius 10, layer 2 / mask 1), group `workers`. Script: `scripts/worker.gd`: state machine (`IDLE`, `MOVING`, `TO_RESOURCE`, `GATHERING`, `TO_DROPOFF`; `TO_BUILD`, `BUILDING`: `build(site)` walks to a construction site and adds progress to it), adds 1 to population on enter tree and removes it on exit, follows `Nav.find_path` waypoints; `move_to()`, `gather()`, `return_cargo()`, `contains_point()`, `selected`, static `separation_push()`.
- `scripts/game_state.gd` — autoload `GameState`: `stock` (indexed by `ResKind`, `scripts/res_kind.gd`), `add/can_afford/spend/reset`, signal `stock_changed`; population: `population`, `population_cap` (clamped to `MAX_CAP`), `add_population`, `add_cap`, `has_room`, signal `population_changed`. Tests reach it with `root.get_node("GameState")` after `await process_frame`, never by its global name.
- `scenes/resources/crystal.tscn`, `ice.tscn` — `ResourceNode` (`scripts/resource_node.gd`), origin at the ground contact point, placed by `main.gd` from `MapLayout.CRYSTAL_CELLS` / `ICE_CELLS` under `World`. Art: `art_src/make_resources.gd` → `assets/crystal.png`, `assets/ice.png` (4 frames of 32x48: 3 variants + almost depleted).
- `scenes/hud.tscn` — `CanvasLayer` HUD (`scripts/hud.gd`): resource bar, `PopLabel` (`pob X/Y`, red when full), hover tooltip, `HQPanel` (train button, queue count, progress bar, status), `show_for_selection()`, signal `train_requested` (button or `Q`; `main.gd` turns it into `HQ.enqueue_worker()`).
- `scripts/selection.gd` (`Selection`), `scripts/formation.gd` (`Formation`, static), `scripts/order_marker.gd` — selection box/click logic (a click on a building selects only it; the box selects only workers), group move targets, fading move marker.
- `tools/` — local, git-ignored tooling: portable Node (`tools/node`), the Godot MCP server (`tools/godot-mcp`) and the `tools/godot.cmd` wrapper.
- `.mcp.json` — registers the `godot` MCP server; `GODOT_PATH` points at the Godot 4.7.2 console exe in `Downloads`.

## Art

Pixel art, three-quarter view (like Age of Empires: seen from front and above, selection ring drawn as a flattened ellipse at the feet; the worker's ground shadow is drawn in code, resource sprites bake theirs in), 32x32 sprites shown at 2x (mobile-friendly size), nearest-neighbour filtering (`default_texture_filter=0`). Sprites are generated by code, not drawn in an editor: `art_src/make_*.gd` (git-tracked, `.gdignore`d) writes PNGs to `assets/`. Regenerate with `.\tools\godot.cmd --headless --path . --script res://art_src/make_worker.gd -- <preview.png>` (the optional arg saves an 8x preview to view), then `.\tools\godot.cmd --headless --path . --import`. `assets/worker.png` is a 4x3 sheet (columns = walk phases, 0 and 2 are standing; rows = down, up, right; left is the right row with `flip_h`), used through `Sprite2D` `hframes`/`vframes`; `scripts/worker.gd` picks row/frame from the movement direction. `assets/hq.png` (104x132, baked shadow) is the HQ sprite. `art_src/make_habitat.gd` → `assets/habitat.png` (2 frames 80×80: finished, scaffold; origin pixel (32, 80)).

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

Behaviour checks without a window: write a `SceneTree` script (`extends SceneTree`, `_initialize()`, `await physics_frame`, `print`, `quit()`) outside the project (e.g. in the scratchpad) and run it with `--headless --script <path>`. No test framework (GUT/gdUnit4) is installed.

Web build: export templates (web only) are in `%APPDATA%\Godot\export_templates\4.7.2.stable`; `export_presets.cfg` has a "Web" preset. Export with `.\tools\godot.cmd --headless --path . --export-release Web build/web/index.html` (`build/` is git-ignored), then serve with `powershell -File .\tools\serve_web.ps1` and open `http://localhost:8060/`. Browsers need HTTP, not `file://`. In a HiDPI browser pane screenshots can crop the canvas: set the viewport to 800x600 for visual checks. `tools/.gdignore` keeps Godot from scanning/packing `tools/`.

The `godot` MCP tools (`run_project`, `get_debug_output`, `create_scene`, `add_node`, ...) need `projectPath` set to this directory.

## Notes

- `class_name` scripts (`Worker`, `ResourceNode`, `Building`, ...) must not use bare autoload identifiers (`Nav`, `GameState`): they compile before autoloads exist (e.g. in `--script` runs) and fail. Look the autoload up at runtime and type it via preload: `const NavScript := preload("res://scripts/nav.gd")` then `get_node_or_null("/root/Nav") as NavScript` (see `ResourceNode._set_nav_blocked`). Non-`class_name` scripts (`main.gd`, `hud.gd`) may use bare names. In `--script` tests use `root.get_node("Nav")` / `root.get_node("GameState")`.
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
