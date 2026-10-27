class_name MapLayout
extends RefCounted
## Fixed map data, defined in code. Phase 1: decorative ground only; every cell is walkable.

## Seed of the deterministic sand/rock/pebble variation painted by scripts/ground.gd.
const SEED := 7

## Patches of rocky ground, in cells.
const ROCK_PATCHES: Array[Rect2i] = [
	Rect2i(3, 4, 6, 4),
	Rect2i(24, 6, 5, 3),
	Rect2i(56, 2, 5, 3),
	Rect2i(40, 22, 4, 6),
	Rect2i(5, 36, 7, 4),
	Rect2i(52, 34, 6, 5),
	Rect2i(22, 42, 5, 3),
]

## Top-left cell of each 2x2 crater.
const CRATERS: Array[Vector2i] = [
	Vector2i(14, 8),
	Vector2i(44, 4),
	Vector2i(33, 16),
	Vector2i(58, 20),
	Vector2i(4, 26),
	Vector2i(26, 28),
	Vector2i(46, 40),
]

# Near crystal field (indices 0..7), then far field around (50, 10) (indices 8..15).
const CRYSTAL_CELLS: Array[Vector2i] = [
	Vector2i(17, 19), Vector2i(18, 20), Vector2i(17, 21), Vector2i(18, 22),
	Vector2i(17, 23), Vector2i(18, 24), Vector2i(19, 21), Vector2i(19, 23),
	Vector2i(49, 8), Vector2i(50, 8), Vector2i(51, 9), Vector2i(48, 10),
	Vector2i(52, 10), Vector2i(49, 11), Vector2i(51, 11), Vector2i(50, 12),
]

# Ice blocks, far from the base on purpose (a depot there pays off in phase 7).
const ICE_CELLS: Array[Vector2i] = [
	Vector2i(30, 33), Vector2i(31, 32), Vector2i(32, 34), Vector2i(33, 33),
	Vector2i(34, 32), Vector2i(35, 34), Vector2i(36, 33), Vector2i(37, 35),
	Vector2i(30, 36), Vector2i(31, 37), Vector2i(33, 36), Vector2i(34, 38),
	Vector2i(35, 37), Vector2i(36, 39), Vector2i(37, 38), Vector2i(31, 40),
	Vector2i(32, 39), Vector2i(33, 40), Vector2i(35, 40), Vector2i(30, 39),
]

const HQ_CELL := Vector2i(10, 21)
const START_WORKERS := 3
