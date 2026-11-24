class_name ElementGame
extends RefCounted
## Element Blast — core rules.
##
## Placement works on the classic 8x8 board. During an awakening the board is
## blown up into a 64x64 falling-sand simulation (SandSim), and afterwards the
## particle field is quantized back into 8x8 cells.

signal game_event(kind: String, data: Dictionary)

const ROWS := 8
const COLS := 8
const DEFAULT_SIZE := 8
const AWAKEN_EVERY := 2
const AWAKEN_DELAY := 0.35
const MAX_STEPS_PER_FRAME := 3
const TEMP_MIN_DEG := -40
const TEMP_MAX_DEG := 100
const TEMP_START_DEG := 20
const TEMP_STEP_MIN := 8
const TEMP_STEP_MAX := 30
const EVENT_FIRST_MIN := 2
const EVENT_FIRST_MAX := 5
const EVENT_DURATION_MIN := 4
const EVENT_DURATION_MAX := 7
const EVENT_COOLDOWN_MIN := 3
const EVENT_COOLDOWN_MAX := 6
static var TEMP_NAMES := {
	-2: "ЛЮТЫЙ ХОЛОД",
	-1: "ХОЛОД",
	0: "НОРМА",
	1: "ЖАРА",
	2: "ПЕКЛО",
}


static func temperature_background(degrees: int) -> Color:
	var stops := [
		[-40, Color("#0a2f57")],
		[-10, Color("#0d3560")],
		[10, Color("#141a38")],
		[30, Color("#221331")],
		[50, Color("#3a1326")],
		[70, Color("#4a120f")],
		[100, Color("#5c1405")],
	]
	if ThemeKit.is_light():
		stops = [
			[-40, Color("#d8ecff")],
			[-10, Color("#e1f1ff")],
			[10, Color("#eceeff")],
			[30, Color("#f6eeff")],
			[50, Color("#ffe9ef")],
			[70, Color("#ffe2d6")],
			[100, Color("#ffd4c4")],
		]
	return _temperature_lerp(stops, degrees)


static func temperature_accent(degrees: int) -> Color:
	var stops := [
		[-40, Color("#9fe8ff")],
		[-10, Color("#4aa3ff")],
		[10, Color("#b9a8ff")],
		[30, Color("#d9a6ff")],
		[50, Color("#ffb066")],
		[70, Color("#ff7a45")],
		[100, Color("#ffd166")],
	]
	if ThemeKit.is_light():
		stops = [
			[-40, Color("#2c7ec4")],
			[-10, Color("#2478d0")],
			[10, Color("#6f5bd8")],
			[30, Color("#9b55c8")],
			[50, Color("#d36a1f")],
			[70, Color("#d14b1c")],
			[100, Color("#c88a10")],
		]
	return _temperature_lerp(stops, degrees)


static func _temperature_lerp(stops: Array, degrees: int) -> Color:
	if degrees <= int(stops[0][0]):
		var first: Color = stops[0][1]
		return first
	for i in range(1, stops.size()):
		if degrees <= int(stops[i][0]):
			var t := inverse_lerp(float(stops[i - 1][0]), float(stops[i][0]), float(degrees))
			var from: Color = stops[i - 1][1]
			var to: Color = stops[i][1]
			return from.lerp(to, t)
	var last: Color = stops[stops.size() - 1][1]
	return last
const SURGE_TICKS := [30, 78, 126, 174]
const SURGE_POOL := [
	{"element": "water", "label": "ПРИЛИВ"},
	{"element": "lava", "label": "ИЗВЕРЖЕНИЕ"},
	{"element": "acid", "label": "КИСЛОТНЫЙ ДОЖДЬ"},
	{"element": "sand", "label": "ПЕСЧАНАЯ БУРЯ"},
	{"element": "oil", "label": "НЕФТЯНОЙ ДОЖДЬ"},
	{"element": "gunpowder", "label": "ПОРОХОВОЙ ЗАЛП"},
]

static var SHAPES := [
	{"id": "dot", "cells": [Vector2i(0, 0)], "w": 1, "h": 1, "weight": 1.2},
	{"id": "i2h", "cells": [Vector2i(0, 0), Vector2i(0, 1)], "w": 2, "h": 1, "weight": 4.0},
	{"id": "i2v", "cells": [Vector2i(0, 0), Vector2i(1, 0)], "w": 1, "h": 2, "weight": 4.0},
	{"id": "i3h", "cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)], "w": 3, "h": 1, "weight": 3.4},
	{"id": "i3v", "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], "w": 1, "h": 3, "weight": 3.4},
	{"id": "i4h", "cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)], "w": 4, "h": 1, "weight": 1.1},
	{"id": "i4v", "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)], "w": 1, "h": 4, "weight": 1.1},
	{"id": "o2", "cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1)], "w": 2, "h": 2, "weight": 3.0},
	{"id": "l3a", "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)], "w": 2, "h": 2, "weight": 2.2},
	{"id": "l3b", "cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0)], "w": 2, "h": 2, "weight": 2.2},
	{"id": "l3c", "cells": [Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1)], "w": 2, "h": 2, "weight": 2.2},
	{"id": "l3d", "cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)], "w": 2, "h": 2, "weight": 2.2},
	{"id": "t4a", "cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 1)], "w": 3, "h": 2, "weight": 1.5},
	{"id": "t4b", "cells": [Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)], "w": 3, "h": 2, "weight": 1.5},
	{"id": "s4a", "cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)], "w": 3, "h": 2, "weight": 1.3},
	{"id": "s4b", "cells": [Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 0), Vector2i(1, 1)], "w": 3, "h": 2, "weight": 1.3},
	{"id": "l4a", "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)], "w": 2, "h": 3, "weight": 1.4},
	{"id": "l4b", "cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 0)], "w": 3, "h": 2, "weight": 1.4},
	{"id": "l4c", "cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)], "w": 2, "h": 3, "weight": 1.4},
	{"id": "l4d", "cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)], "w": 3, "h": 2, "weight": 1.4},
]

static var ELEMENT_WEIGHTS := {
	"stone": 2.8,
	"sand": 3.0,
	"water": 3.0,
	"lava": 1.9,
	"acid": 1.8,
	"ice": 1.2,
	"fire": 1.4,
	"oil": 1.5,
	"plant": 1.4,
	"gunpowder": 1.2,
}

var board: Array = []
var rows := DEFAULT_SIZE
var cols := DEFAULT_SIZE
var pieces: Array = []
var score := 0
var best := 0
var moves_left := AWAKEN_EVERY
var mode := "menu"  # menu | playing | awakening | paused | gameover
var new_record := false
var stats := {"placements": 0, "lines": 0, "reactions": 0}

var sand: SandSim = null
var awaken_timer := 0.0
var awaken_ticks := 0
var surge_index := 0
var surge_plan: Array = []
var surge_scale := 1.0
var temperature_degrees := TEMP_START_DEG
var temperature := 0  # band: -2..2
var current_event: Dictionary = {}
var event_active := false
var event_moves_left := 0
var event_cooldown_moves := 0
var last_event: Dictionary = {}

var rng := RandomNumberGenerator.new()
var _mode_before_pause := "playing"
var _first_refill := true


func _init() -> void:
	rng.randomize()
	reset()


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func set_board_size(size: int) -> void:
	if size != 6 and size != 8 and size != 10:
		size = DEFAULT_SIZE
	rows = size
	cols = size
	reset()


func reset() -> void:
	board = []
	for r in rows:
		var row: Array = []
		row.resize(cols)
		board.append(row)
	pieces = []
	score = 0
	moves_left = AWAKEN_EVERY
	mode = "menu"
	new_record = false
	stats = {"placements": 0, "lines": 0, "reactions": 0}
	sand = null
	awaken_timer = 0.0
	awaken_ticks = 0
	surge_index = 0
	surge_plan = []
	current_event = {}
	event_active = false
	event_moves_left = 0
	event_cooldown_moves = rng.randi_range(EVENT_FIRST_MIN, EVENT_FIRST_MAX)
	last_event = {}
	set_temperature_degrees(TEMP_START_DEG)
	_first_refill = true
	_refill()


func start() -> void:
	reset()
	mode = "playing"
	game_event.emit("start", {"event": current_event})
	check_game_over()


func pause() -> void:
	if mode != "playing" and mode != "awakening":
		return
	_mode_before_pause = mode
	mode = "paused"
	game_event.emit("pause", {})


func resume() -> void:
	if mode != "paused":
		return
	mode = _mode_before_pause
	game_event.emit("resume", {})


func is_idle() -> bool:
	return mode == "menu" or mode == "gameover"


# ---------------------------------------------------------------------------
# Events
# ---------------------------------------------------------------------------

func event_id() -> String:
	return str(current_event.get("id", ""))


func event_name() -> String:
	return str(current_event.get("name", ""))


func event_tagline() -> String:
	return str(current_event.get("tagline", ""))


func last_event_name() -> String:
	return str(last_event.get("name", ""))


func event_background() -> Color:
	if event_active and current_event.has("bg"):
		if ThemeKit.is_light() and current_event.has("bg_light"):
			return Color(str(current_event["bg_light"]))
		return Color(str(current_event["bg"]))
	return temperature_background(temperature_degrees)


func event_accent() -> Color:
	if event_active and current_event.has("accent"):
		return Color(str(current_event["accent"]))
	return temperature_accent(temperature_degrees)


func temperature_locked() -> bool:
	return event_active and current_event.has("temp_degrees")


func force_event(id: String, moves := -1) -> void:
	var event := EventDefs.get_event(id)
	if event.is_empty():
		return
	_begin_event(event, moves)


func _begin_event(event: Dictionary, moves := -1) -> void:
	current_event = event
	last_event = event
	event_active = true
	event_moves_left = moves
	if event_moves_left < 0:
		event_moves_left = rng.randi_range(EVENT_DURATION_MIN, EVENT_DURATION_MAX)
	set_temperature_degrees(int(event.get("temp_degrees", TEMP_START_DEG)))
	game_event.emit("event_start", {
		"event": event,
		"moves": event_moves_left,
	})


func _end_event() -> void:
	if not event_active:
		return
	var ended := current_event
	event_active = false
	event_moves_left = 0
	current_event = {}
	event_cooldown_moves = rng.randi_range(EVENT_COOLDOWN_MIN, EVENT_COOLDOWN_MAX)
	set_temperature_degrees(TEMP_START_DEG)
	game_event.emit("event_end", {
		"event": ended,
		"next_in": event_cooldown_moves,
	})


func _tick_event_state(will_awaken: bool) -> bool:
	if event_active:
		event_moves_left -= 1
		if event_moves_left <= 0 and not will_awaken:
			_end_event()
			return true
		return false

	event_cooldown_moves -= 1
	if event_cooldown_moves <= 0:
		_start_random_event()
		return true
	return false


func _start_random_event() -> void:
	var previous := str(last_event.get("id", ""))
	var event := EventDefs.pick(rng, previous)
	if event.is_empty():
		return
	_begin_event(event)


# ---------------------------------------------------------------------------
# Tray / pieces
# ---------------------------------------------------------------------------

func make_piece(force_element := "") -> Dictionary:
	var element := force_element if force_element != "" else _pick_element()
	return {
		"shape": _pick_shape(),
		"element": element,
		"used": false,
	}


func _refill() -> void:
	var fresh: Array = []
	var forced := ["stone", "water", "lava"] if _first_refill else ["", "", ""]
	for i in 3:
		fresh.append(make_piece(str(forced[i])))
	_first_refill = false

	if fresh[0]["element"] == fresh[1]["element"] and fresh[1]["element"] == fresh[2]["element"]:
		fresh[2]["element"] = _pick_element_excluding(fresh[0]["element"])

	var event_elements: Array = current_event.get("event_elements", []) if event_active else []
	if not event_elements.is_empty():
		var has_event_element := false
		for piece in fresh:
			if event_elements.has(piece["element"]):
				has_event_element = true
				break
		if not has_event_element:
			var slot := rng.randi_range(0, fresh.size() - 1)
			fresh[slot]["element"] = str(
				event_elements[rng.randi_range(0, event_elements.size() - 1)])

	pieces = fresh
	game_event.emit("refill", {})


func _pick_shape() -> Dictionary:
	var total := 0.0
	for shape in SHAPES:
		total += float(shape["weight"])
	var roll := rng.randf() * total
	for shape in SHAPES:
		roll -= float(shape["weight"])
		if roll <= 0.0:
			return shape
	return SHAPES[SHAPES.size() - 1]


func _active_weights() -> Dictionary:
	if event_active and current_event.has("weights"):
		return current_event["weights"]
	return ELEMENT_WEIGHTS


func _pick_element() -> String:
	var weights := _active_weights()
	var keys: Array = weights.keys()
	var total := 0.0
	for key in keys:
		total += float(weights[key])
	var roll := rng.randf() * total
	for key in keys:
		roll -= float(weights[key])
		if roll <= 0.0:
			return str(key)
	return "stone" if not weights.has("water") else "water"


func _pick_element_excluding(element: String) -> String:
	for i in 16:
		var candidate := _pick_element()
		if candidate != element:
			return candidate
	return "stone"


func all_used() -> bool:
	for piece in pieces:
		if not piece["used"]:
			return false
	return true


# ---------------------------------------------------------------------------
# Placement
# ---------------------------------------------------------------------------

func can_place(shape: Dictionary, r0: int, c0: int) -> bool:
	# Shape cells are authored as Vector2i(row, column).
	for offset in shape["cells"]:
		var r: int = r0 + offset.x
		var c: int = c0 + offset.y
		if r < 0 or r >= rows or c < 0 or c >= cols:
			return false
		if board[r][c] != null:
			return false
	return true


func find_any_placement(shape: Dictionary) -> Vector2i:
	var max_r: int = rows - int(shape["h"])
	var max_c: int = cols - int(shape["w"])
	for r0 in max_r + 1:
		for c0 in max_c + 1:
			if can_place(shape, r0, c0):
				return Vector2i(c0, r0)
	return Vector2i(-1, -1)


func place_at(index: int, r0: int, c0: int) -> bool:
	if index < 0 or index >= pieces.size() or mode != "playing":
		return false
	var piece: Dictionary = pieces[index]
	if bool(piece["used"]):
		return false
	var shape: Dictionary = piece["shape"]
	if not can_place(shape, r0, c0):
		game_event.emit("invalid", {})
		return false

	var element: String = piece["element"]
	var now := _now()
	var placed: Array = []
	for offset in shape["cells"]:
		var r: int = r0 + offset.x
		var c: int = c0 + offset.y
		board[r][c] = {"t": element, "born": now, "flash": 0.0}
		placed.append({"r": r, "c": c, "t": element})

	piece["used"] = true
	score += placed.size()
	stats["placements"] += 1
	game_event.emit("place", {"cells": placed, "element": element})
	var will_awaken := moves_left == 1
	if not _tick_event_state(will_awaken):
		_shift_temperature()

	clear_lines()

	if all_used():
		_refill()

	moves_left -= 1
	if moves_left <= 0:
		begin_awakening()
	else:
		check_game_over()
	return true


# ---------------------------------------------------------------------------
# Line clears
# ---------------------------------------------------------------------------

func clear_lines() -> Dictionary:
	var full_rows: Array = []
	var full_cols: Array = []
	for r in rows:
		var full := true
		for c in cols:
			if board[r][c] == null:
				full = false
				break
		if full:
			full_rows.append(r)
	for c in cols:
		var full := true
		for r in rows:
			if board[r][c] == null:
				full = false
				break
		if full:
			full_cols.append(c)

	var lines: int = full_rows.size() + full_cols.size()
	if lines == 0:
		return {"lines": 0, "points": 0, "cells": []}

	var seen := {}
	var cleared: Array = []
	for r in full_rows:
		for c in cols:
			var key: int = r * cols + c
			if seen.has(key):
				continue
			seen[key] = true
			var cell = board[r][c]
			if cell != null:
				cleared.append({"r": r, "c": c, "t": cell["t"]})
				board[r][c] = null
	for c in full_cols:
		for r in rows:
			var key: int = r * cols + c
			if seen.has(key):
				continue
			seen[key] = true
			var cell = board[r][c]
			if cell != null:
				cleared.append({"r": r, "c": c, "t": cell["t"]})
				board[r][c] = null

	var points: int = cleared.size() * 10 * lines
	score += points
	stats["lines"] += lines
	game_event.emit("clear", {
		"cells": cleared,
		"rows": full_rows,
		"cols": full_cols,
		"lines": lines,
		"points": points,
	})
	return {"lines": lines, "points": points, "cells": cleared}


# ---------------------------------------------------------------------------
# Awakening: 8x8 board -> 64x64 particles -> 8x8 board
# ---------------------------------------------------------------------------

func begin_awakening() -> void:
	mode = "awakening"
	sand = SandSim.new(rows)
	sand.temperature = temperature
	sand.event_rule = str(current_event.get("rule", "")) if event_active else ""
	sand.growth_boost = 4.0 if sand.event_rule == "bloom" else 1.0
	for r in rows:
		for c in cols:
			var cell = board[r][c]
			if cell != null:
				sand.spawn_block(r, c, str(cell["t"]))
	awaken_timer = 0.0
	awaken_ticks = 0
	surge_index = 0
	surge_scale = float(current_event.get("surge_multiplier", 1.0)) if event_active else 1.0
	if event_active and current_event.has("surge_element"):
		var entry := {
			"element": str(current_event["surge_element"]),
			"label": str(current_event.get("surge_label", "СТИХИЯ")),
		}
		surge_plan = []
		for i in SURGE_TICKS.size():
			surge_plan.append(entry)
	else:
		surge_plan = SURGE_POOL.duplicate()
		for i in range(surge_plan.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var tmp = surge_plan[i]
			surge_plan[i] = surge_plan[j]
			surge_plan[j] = tmp
		surge_plan = surge_plan.slice(0, SURGE_TICKS.size())
	game_event.emit("awaken_start", {})


func update(delta: float) -> void:
	if mode != "awakening" or sand == null:
		return

	awaken_timer += delta
	if awaken_timer < AWAKEN_DELAY:
		return

	var due := int((awaken_timer - AWAKEN_DELAY) * SandSim.TICK_RATE) - awaken_ticks
	var steps := 0
	while due > 0 and awaken_ticks < SandSim.MAX_TICKS and steps < MAX_STEPS_PER_FRAME:
		var events := sand.step()
		awaken_ticks += 1
		steps += 1
		due -= 1

		if not events.is_empty():
			var points := _apply_sand_events(events)
			game_event.emit("sand_reactions", {"events": events, "points": points})

		while surge_index < SURGE_TICKS.size() and awaken_ticks >= int(SURGE_TICKS[surge_index]):
			_trigger_surge()

	if surge_index >= SURGE_TICKS.size() and sand.is_finished(awaken_ticks):
		finish_awakening()


func _trigger_surge() -> void:
	if surge_index >= surge_plan.size():
		return
	var data: Dictionary = surge_plan[surge_index]
	var element := str(data["element"])
	var label := str(data["label"])

	var free_columns: Array = []
	for c in sand.w:
		if sand.top_is_free(c):
			free_columns.append(c)

	var placed := false
	var start_col := 0
	var width := maxi(3, int(round(3.0 * surge_scale)))
	var height := maxi(8, int(round(float(rng.randi_range(10, 18)) * surge_scale)))
	if not free_columns.is_empty():
		start_col = int(free_columns[rng.randi() % free_columns.size()])
		start_col = clampi(start_col - int(width * 0.5), 0, sand.w - width)
		placed = sand.inject_column(element, start_col, width, height)
		sand.idle_ticks = 0

	surge_index += 1
	game_event.emit("awaken_surge", {
		"index": surge_index,
		"kind": element,
		"label": label,
		"x": start_col,
		"width": width,
		"placed": placed,
	})


func finish_awakening() -> void:
	if mode != "awakening":
		return

	var result: Array = sand.quantize() if sand != null else []
	var now := _now()
	var new_board: Array = []
	for r in rows:
		var row: Array = []
		row.resize(cols)
		for c in cols:
			var index: int = r * cols + c
			var element: String = str(result[index]) if index < result.size() else ""
			if element != "":
				# Diagonal wave: tiles crystallize from the top-left corner.
				var delay := float(r + c) * 0.012
				row[c] = {"t": element, "born": now + delay, "flash": 0.0}
		new_board.append(row)
	board = new_board

	mode = "playing"
	moves_left = AWAKEN_EVERY
	game_event.emit("awaken_end", {})
	clear_lines()
	if event_active and event_moves_left <= 0:
		_end_event()
	check_game_over()


func _temperature_level(degrees: int) -> int:
	if degrees <= -10:
		return -2
	elif degrees <= 10:
		return -1
	elif degrees <= 30:
		return 0
	elif degrees <= 60:
		return 1
	return 2


func set_temperature_degrees(value: int) -> void:
	temperature_degrees = clampi(value, TEMP_MIN_DEG, TEMP_MAX_DEG)
	temperature = _temperature_level(temperature_degrees)


func _shift_temperature() -> void:
	if temperature_locked():
		return
	var old_degrees := temperature_degrees
	var old_level := temperature
	var magnitude := rng.randi_range(TEMP_STEP_MIN, TEMP_STEP_MAX)
	var direction := 1 if rng.randi() % 2 == 0 else -1
	if temperature_degrees >= TEMP_MAX_DEG:
		direction = -1
	elif temperature_degrees <= TEMP_MIN_DEG:
		direction = 1
	set_temperature_degrees(temperature_degrees + direction * magnitude)
	var delta := temperature_degrees - old_degrees
	game_event.emit("temperature", {
		"value": temperature_degrees,
		"old": old_degrees,
		"delta": delta,
		"level": temperature,
		"old_level": old_level,
	})


func _apply_sand_events(events: Dictionary) -> int:
	var points := 0
	for kind in events:
		var count := int(events[kind]["count"])
		match str(kind):
			"obsidian":
				points += maxi(1, int(count / 2.0))
			"dissolve":
				points += maxi(1, int(count / 4.0))
			"melt":
				points += maxi(1, int(count / 4.0))
			"burn", "dilute", "extinguish":
				points += maxi(1, int(count / 6.0))
			"explode":
				points += 12 * count
			"glass":
				points += 4 * count
			"ignite", "grow", "absorb", "release", "spore":
				points += count
			"freeze", "condense", "solidify":
				points += maxi(1, int(count / 3.0))
			"shatter":
				points += 2 * count
		stats["reactions"] += count
	score += points
	return points


# ---------------------------------------------------------------------------
# Game over
# ---------------------------------------------------------------------------

func check_game_over() -> void:
	if mode != "playing":
		return
	var has_move := false
	for piece in pieces:
		if piece["used"]:
			continue
		if find_any_placement(piece["shape"]) != Vector2i(-1, -1):
			has_move = true
			break
	if has_move:
		return

	mode = "gameover"
	new_record = score > best
	if new_record:
		best = score
	game_event.emit("game_over", {
		"score": score,
		"best": best,
		"new_record": new_record,
	})


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
