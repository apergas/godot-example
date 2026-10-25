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
