class_name SandSim
extends RefCounted
## Particle-level falling-sand simulation for the awakening phase.
##
## Every board cell (8x8) is blown up into an 8x8 block of particles, so the
## whole board is a 64x64 sandbox. Particles fall, liquids spread and level,
## lava is viscous, acid eats solids. After the show the field is quantized
## back into 8x8 board cells.

const SUB := 8
const DEFAULT_CELLS := 8
var cells := DEFAULT_CELLS
var w := DEFAULT_CELLS * SUB
var h := DEFAULT_CELLS * SUB

const EMPTY := 0
const STONE := 1
const SAND := 2
const WATER := 3
const LAVA := 4
const ACID := 5
const ICE := 6
const OBSIDIAN := 7
const STEAM := 8
const FIRE := 9
const OIL := 10
const PLANT := 11
const GUNPOWDER := 12
const SMOKE := 13
const GLASS := 14
const SEAWEED := 15
const SPONGE := 16
const COAL := 17
const ASH := 18
const SNOW := 19
const CRYSTAL := 20
const SPORE := 21
const FLOWER := 22
const IRON := 23
const COPPER := 24
const GOLD := 25
const SILVER := 26
const LEAD := 27
const TIN := 28
const MERCURY := 29
const TITANIUM := 30
const MUSHROOM := 31
const MOSS := 32
const VINE := 33
const POLLEN := 34
const SLIME := 35
const BONE := 36
const SHELL := 37
const FUNGUS := 38
const TYPE_COUNT := 39

const TICK_RATE := 45.0
const MAX_TICKS := 220

static var TYPE_NAMES := {
	STONE: "stone",
	SAND: "sand",
	WATER: "water",
	LAVA: "lava",
	ACID: "acid",
	ICE: "ice",
	OBSIDIAN: "obsidian",
	STEAM: "steam",
	FIRE: "fire",
	OIL: "oil",
	PLANT: "plant",
	GUNPOWDER: "gunpowder",
	SMOKE: "smoke",
	GLASS: "glass",
	SEAWEED: "seaweed",
	SPONGE: "sponge",
	COAL: "coal",
	ASH: "ash",
	SNOW: "snow",
	CRYSTAL: "crystal",
	SPORE: "spore",
	FLOWER: "flower",
	IRON: "iron",
	COPPER: "copper",
	GOLD: "gold",
	SILVER: "silver",
	LEAD: "lead",
	TIN: "tin",
	MERCURY: "mercury",
	TITANIUM: "titanium",
	MUSHROOM: "mushroom",
	MOSS: "moss",
	VINE: "vine",
	POLLEN: "pollen",
	SLIME: "slime",
	BONE: "bone",
	SHELL: "shell",
	FUNGUS: "fungus",
}
static var TYPE_IDS := {
	"stone": STONE,
	"sand": SAND,
	"water": WATER,
	"lava": LAVA,
	"acid": ACID,
	"ice": ICE,
	"obsidian": OBSIDIAN,
	"steam": STEAM,
	"fire": FIRE,
	"oil": OIL,
	"plant": PLANT,
	"gunpowder": GUNPOWDER,
	"smoke": SMOKE,
	"glass": GLASS,
	"seaweed": SEAWEED,
	"sponge": SPONGE,
	"coal": COAL,
	"ash": ASH,
	"snow": SNOW,
	"crystal": CRYSTAL,
	"spore": SPORE,
	"flower": FLOWER,
	"iron": IRON,
	"copper": COPPER,
	"gold": GOLD,
	"silver": SILVER,
	"lead": LEAD,
	"tin": TIN,
	"mercury": MERCURY,
	"titanium": TITANIUM,
	"mushroom": MUSHROOM,
	"moss": MOSS,
	"vine": VINE,
	"pollen": POLLEN,
	"slime": SLIME,
	"bone": BONE,
	"shell": SHELL,
	"fungus": FUNGUS,
}
static var NEIGHBORS := [
	Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0),
]
static var QUANT_ORDER := [
	STONE, ICE, OBSIDIAN, GLASS, CRYSTAL, COAL, SPONGE, ASH, SAND, SNOW,
	PLANT, SEAWEED, FLOWER, GUNPOWDER, SPORE, WATER, OIL, LAVA, ACID,
	IRON, COPPER, GOLD, SILVER, LEAD, TIN, MERCURY, TITANIUM,
	MUSHROOM, MOSS, VINE, POLLEN, SLIME, BONE, SHELL, FUNGUS,
]

var grid := PackedByteArray()
var life := PackedByteArray()

var version := 0
var tick := 0
var idle_ticks := 0
var temperature := 0
var tick_rate := TICK_RATE
var max_ticks := MAX_TICKS
var event_rule := ""
var growth_boost := 1.0

var rng := RandomNumberGenerator.new()
var _moved := PackedByteArray()
var _events := {}
var _moved_any := false
var _scan_left := false
var _explosion_budget := 0
var _flood_done := false


func _init(board_cells := DEFAULT_CELLS) -> void:
	cells = board_cells
	w = cells * SUB
	h = cells * SUB
	rng.randomize()
	grid.resize(w * h)
	grid.fill(EMPTY)
	life.resize(w * h)
	life.fill(0)
	_moved.resize(w * h)
	_moved.fill(0)


func spawn_block(block_r: int, block_c: int, element: String) -> void:
	var type: int = int(TYPE_IDS.get(element, STONE))
	var y0 := block_r * SUB
	var x0 := block_c * SUB
	for y in SUB:
		var row := (y0 + y) * w + x0
		for x in SUB:
			var i := row + x
			grid[i] = type
			if type == FIRE:
				life[i] = 30 + rng.randi_range(0, 24)
			elif type == SPORE or type == POLLEN:
				life[i] = 90 + rng.randi_range(0, 60)
			elif type == COAL:
				life[i] = 60 + rng.randi_range(0, 40)


func count_type(type: int) -> int:
	var total := 0
	for value in grid:
		if int(value) == type:
			total += 1
	return total


func top_is_free(column: int) -> bool:
	if column < 0 or column >= w:
		return false
	return int(grid[column]) == EMPTY


func inject_column(element: String, start_col: int, width: int, height: int) -> bool:
	var type: int = int(TYPE_IDS.get(element, WATER))
	var placed := false
	for x in range(start_col, start_col + maxi(width, 1)):
		if x < 0 or x >= w:
			continue
		if int(grid[x]) != EMPTY:
			continue
		for y in range(0, mini(height, h)):
			var i := y * w + x
			if int(grid[i]) != EMPTY:
				break
			grid[i] = type
			life[i] = 0
			placed = true
	return placed


# ---------------------------------------------------------------------------
# One simulation tick
# ---------------------------------------------------------------------------

func step() -> Dictionary:
	tick += 1
	_moved.fill(0)
	_events = {}
	_moved_any = false
	_scan_left = not _scan_left
	_explosion_budget = 0

	if event_rule != "":
		_apply_event_rule()
	if temperature != 0:
		_apply_temperature()
	_react()

	var left_first := _scan_left
	for y in range(h - 1, -1, -1):
		var row := y * w
		for k in w:
			var x: int = k if left_first else w - 1 - k
			var i := row + x
			if _moved[i] == 1:
				continue
			var type := int(grid[i])
			if type == EMPTY or type == STONE or type == ICE or type == OBSIDIAN \
					or type == PLANT or type == GLASS or type == COAL \
					or type == SPONGE or type == SEAWEED or type == CRYSTAL \
					or type == FLOWER or (type >= IRON and type != MERCURY \
					and type != SLIME and type != POLLEN):
				continue
			match type:
				SAND:
					_step_sand(x, y, i)
				ASH:
					_step_ash(x, y, i)
				SNOW:
					_step_snow(x, y, i)
				WATER:
					_step_liquid(x, y, i, 0.90)
				ACID:
					_step_liquid(x, y, i, 0.45)
				LAVA:
					if tick % 2 == 0:
						_step_liquid(x, y, i, 0.10)
				OIL:
					_step_oil(x, y, i)
				GUNPOWDER:
					_step_sand(x, y, i)
				FIRE:
					_step_fire(x, y, i)
				STEAM:
					_step_steam(x, y, i)
				SMOKE:
					_step_steam(x, y, i)
				SPORE:
					_step_spore(x, y, i)
				MERCURY:
					_step_liquid(x, y, i, 0.85)
				SLIME:
					_step_liquid(x, y, i, 0.30)
				POLLEN:
					_step_spore(x, y, i)

	if _moved_any or not _events.is_empty():
		idle_ticks = 0
	else:
		idle_ticks += 1
	version += 1
	return _events


func is_finished(ticks_done: int) -> bool:
	return ticks_done >= max_ticks or (ticks_done >= 16 and idle_ticks >= 10)


# ---------------------------------------------------------------------------
# Chemistry
# ---------------------------------------------------------------------------

func _apply_event_rule() -> void:
	match event_rule:
		"flood":
			if _flood_done:
				return
			for y in h:
				var row := y * w
				for x in w:
					var i := row + x
					if int(grid[i]) == LAVA:
						grid[i] = STONE
						life[i] = 0
						_event("solidify", x, y)
			_flood_done = true
		"inferno":
			for y in h:
				var row := y * w
				for x in w:
					var i := row + x
					var type := int(grid[i])
					if type == WATER and rng.randf() < 0.0018:
						grid[i] = STEAM
						life[i] = 24 + rng.randi_range(0, 16)
						_event("boil", x, y)
					elif (type == PLANT or type == SEAWEED or type == FLOWER) \
							and rng.randf() < 0.0008:
						grid[i] = FIRE
						life[i] = 30 + rng.randi_range(0, 20)
						_event("ignite", x, y)
		"deep_freeze":
			for y in h:
				var row := y * w
				for x in w:
					var i := row + x
					var type := int(grid[i])
					if type == WATER and rng.randf() < 0.0040:
						grid[i] = ICE
						life[i] = 0
						_event("freeze", x, y)
					elif type == LAVA and rng.randf() < 0.0120:
						grid[i] = STONE
						life[i] = 0
						_event("solidify", x, y)
		"bloom":
			pass


func _apply_temperature() -> void:
	for y in h:
		var row := y * w
		for x in w:
			var i := row + x
			var type := int(grid[i])
			match temperature:
				2:
					if type == SNOW:
						grid[i] = WATER
						life[i] = 0
						_event("melt", x, y)
					elif type == ICE:
						grid[i] = WATER
						life[i] = 0
						_event("melt", x, y)
					elif type == WATER and rng.randf() < 0.0030:
						grid[i] = STEAM
						life[i] = 24 + rng.randi_range(0, 16)
						_event("boil", x, y)
					elif type == STONE and rng.randf() < 0.00025:
						grid[i] = LAVA
						life[i] = 0
						_event("melt_stone", x, y)
				1:
					if type == SNOW and rng.randf() < 0.0120:
						grid[i] = WATER
						life[i] = 0
						_event("melt", x, y)
					elif type == ICE and rng.randf() < 0.0060:
						grid[i] = WATER
						life[i] = 0
						_event("melt", x, y)
					elif type == LAVA and rng.randf() < 0.0010:
						grid[i] = STONE
						life[i] = 0
						_event("solidify", x, y)
				-1:
					if type == SNOW and rng.randf() < 0.0010:
						grid[i] = ICE
						life[i] = 0
						_event("freeze", x, y)
					elif type == WATER and event_rule != "flood" and rng.randf() < 0.0008:
						grid[i] = ICE
						life[i] = 0
						_event("freeze", x, y)
					elif type == LAVA and rng.randf() < 0.0025:
						grid[i] = STONE
						life[i] = 0
						_event("solidify", x, y)
				-2:
					if type == SNOW and rng.randf() < 0.0040:
						grid[i] = ICE
						life[i] = 0
						_event("freeze", x, y)
					elif type == WATER and event_rule != "flood" and rng.randf() < 0.0080:
						grid[i] = ICE
						life[i] = 0
						_event("freeze", x, y)
					elif type == LAVA and rng.randf() < 0.0100:
						grid[i] = STONE
						life[i] = 0
						_event("solidify", x, y)
					elif type == STEAM and rng.randf() < 0.0060:
						grid[i] = WATER
						life[i] = 0
						_event("condense", x, y)


func _react() -> void:
	for y in h:
		var row := y * w
		for x in w:
			var i := row + x
			var type := int(grid[i])
			if type == LAVA:
				_react_lava(x, y, i)
			elif type == ACID:
				_react_acid(x, y, i)
			elif type == FIRE:
				_react_fire(x, y, i)
			elif type == PLANT:
				_react_plant(x, y, i)
			elif type == GUNPOWDER:
				_react_gunpowder(x, y, i)
			elif type == SEAWEED:
				_react_seaweed(x, y, i)
			elif type == SPONGE:
				_react_sponge(x, y, i)
			elif type == COAL:
				_react_coal(x, y, i)
			elif type == SPORE:
				_react_spore(x, y, i)
			elif type == FLOWER:
				_react_flower(x, y, i)
			elif type == CRYSTAL:
				_react_crystal(x, y, i)
			elif type == POLLEN:
				_react_pollen(x, y, i)
			elif type == SLIME:
				_react_slime(x, y, i)
			elif type == MUSHROOM or type == MOSS or type == VINE or type == FUNGUS:
				_react_pack_plant(x, y, i, type)


func _react_lava(x: int, y: int, i: int) -> void:
	for offset in NEIGHBORS:
		var nx: int = x + offset.x
		var ny: int = y + offset.y
		if nx < 0 or nx >= w or ny < 0 or ny >= h:
			continue
		var j := ny * w + nx
		var other := int(grid[j])
		if other == WATER:
			grid[i] = OBSIDIAN
			grid[j] = STEAM
			life[j] = 40 + rng.randi_range(0, 24)
			_moved[i] = 1
			_moved[j] = 1
			_event("obsidian", nx, ny)
			return
		elif other == ICE:
			grid[j] = WATER
			life[j] = 0
			_moved[j] = 1
			_event("melt", nx, ny)
			return
		elif other == ACID:
			grid[j] = STEAM
			life[j] = 36
			_moved[j] = 1
			_event("burn", nx, ny)
			return
		elif other == OIL:
			grid[j] = FIRE
			life[j] = 32 + rng.randi_range(0, 20)
			_moved[j] = 1
			_event("ignite", nx, ny)
			return
		elif other == PLANT:
			grid[j] = FIRE
			life[j] = 28 + rng.randi_range(0, 16)
			_moved[j] = 1
			_event("ignite", nx, ny)
			return
		elif other == SEAWEED or other == FLOWER:
			grid[j] = FIRE
			life[j] = 28 + rng.randi_range(0, 16)
			_moved[j] = 1
			_event("ignite", nx, ny)
			return
		elif other == MUSHROOM or other == MOSS or other == VINE \
				or other == FUNGUS or other == POLLEN:
			grid[j] = FIRE
			life[j] = 24 + rng.randi_range(0, 16)
			_moved[j] = 1
			_event("ignite", nx, ny)
			return
		elif other == MERCURY:
			grid[j] = STEAM
			life[j] = 24 + rng.randi_range(0, 16)
			_moved[j] = 1
			_event("boil", nx, ny)
			return
		elif other == COAL:
			grid[j] = FIRE
			life[j] = maxi(60, int(life[j])) + rng.randi_range(0, 30)
			_moved[j] = 1
			_event("ignite", nx, ny)
			return
		elif other == SNOW:
			grid[j] = WATER
			life[j] = 0
			_moved[j] = 1
			_event("melt", nx, ny)
			return
		elif other == SPONGE:
			grid[j] = STEAM
			life[j] = 30 + rng.randi_range(0, 16)
			_moved[j] = 1
			_event("release", nx, ny)
			return
		elif other == SAND:
			if rng.randf() < 0.045:
				grid[j] = GLASS
				_moved[j] = 1
				_event("glass", nx, ny)
				return


func _react_fire(x: int, y: int, i: int) -> void:
	for offset in NEIGHBORS:
		var nx: int = x + offset.x
		var ny: int = y + offset.y
		if nx < 0 or nx >= w or ny < 0 or ny >= h:
			continue
		var j := ny * w + nx
		var other := int(grid[j])
		if other == WATER:
			grid[i] = STEAM
			life[i] = 20 + rng.randi_range(0, 12)
			_event("extinguish", x, y)
			return
		elif other == ICE:
			grid[j] = WATER
			grid[i] = STEAM
			life[i] = 22
			_event("melt", nx, ny)
			return
		elif other == OIL:
			grid[j] = FIRE
			life[j] = 34 + rng.randi_range(0, 18)
			_event("ignite", nx, ny)
			return
		elif other == PLANT:
			grid[j] = FIRE
			life[j] = 28 + rng.randi_range(0, 16)
			_event("ignite", nx, ny)
			return
		elif other == SEAWEED or other == FLOWER or other == SPORE:
			grid[j] = FIRE
			life[j] = 24 + rng.randi_range(0, 16)
			_event("ignite", nx, ny)
			return
		elif other == MUSHROOM or other == MOSS or other == VINE \
				or other == FUNGUS or other == POLLEN:
			grid[j] = FIRE
			life[j] = 22 + rng.randi_range(0, 14)
			_event("ignite", nx, ny)
			return
		elif other == COAL:
			grid[j] = FIRE
			life[j] = maxi(60, int(life[j])) + rng.randi_range(0, 30)
			_event("ignite", nx, ny)
			return
		elif other == SNOW:
			grid[j] = WATER
			_event("melt", nx, ny)
			return
		elif other == ACID:
			grid[j] = SMOKE
			life[j] = 36
			grid[i] = EMPTY
			_moved[i] = 1
			_event("burn", nx, ny)
			return
		elif other == LAVA:
			grid[i] = EMPTY
			_moved[i] = 1
			return


func _react_plant(x: int, y: int, i: int) -> void:
	if rng.randf() > 0.003 * growth_boost:
		return
	for offset in NEIGHBORS:
		var nx: int = x + offset.x
		var ny: int = y + offset.y
		if nx < 0 or nx >= w or ny < 0 or ny >= h:
			continue
		var j := ny * w + nx
		if int(grid[j]) == WATER:
			grid[j] = PLANT
			_moved[j] = 1
			_event("grow", nx, ny)
			return


func _react_seaweed(x: int, y: int, i: int) -> void:
	if rng.randf() > 0.010 * growth_boost:
		return
	var above := i - w
	if y > 0 and int(grid[above]) == WATER:
		grid[above] = SEAWEED
		_moved[above] = 1
		_event("grow", x, y - 1)
		return
	var side := -1 if rng.randi() % 2 == 0 else 1
	if x + side >= 0 and x + side < w and int(grid[i + side]) == WATER:
		grid[i + side] = SEAWEED
		_moved[i + side] = 1
		_event("grow", x + side, y)


func _react_flower(x: int, y: int, i: int) -> void:
	if rng.randf() > 0.0035 * growth_boost:
		return
	if y <= 0:
		return
	var above := i - w
	var type := int(grid[above])
	if type == EMPTY or type == WATER or type == SMOKE:
		grid[above] = SPORE
		life[above] = 90 + rng.randi_range(0, 60)
		_moved[above] = 1
		_event("spore", x, y - 1)


func _react_spore(x: int, y: int, i: int) -> void:
	for offset in NEIGHBORS:
		var nx: int = x + offset.x
		var ny: int = y + offset.y
		if nx < 0 or nx >= w or ny < 0 or ny >= h:
			continue
		var j := ny * w + nx
		if int(grid[j]) == WATER and rng.randf() < 0.020 * growth_boost:
			grid[j] = FLOWER if rng.randf() < 0.22 else PLANT
			_moved[j] = 1
			grid[i] = EMPTY
			_moved[i] = 1
			_event("grow", nx, ny)
			return


func _react_sponge(x: int, y: int, i: int) -> void:
	var absorbed := int(life[i])
	if absorbed > 0:
		for offset in NEIGHBORS:
			var nx: int = x + offset.x
			var ny: int = y + offset.y
			if nx < 0 or nx >= w or ny < 0 or ny >= h:
				continue
			var j := ny * w + nx
			var other := int(grid[j])
			if other == FIRE or other == LAVA:
				life[i] = absorbed - 1
				_moved[i] = 1
				_event("release", x, y)
				for empty_offset in NEIGHBORS:
					var ex: int = x + empty_offset.x
					var ey: int = y + empty_offset.y
					if ex < 0 or ex >= w or ey < 0 or ey >= h:
						continue
					var k := ey * w + ex
					if int(grid[k]) == EMPTY:
						grid[k] = STEAM
						life[k] = 30 + rng.randi_range(0, 16)
						_moved[k] = 1
						break
				return
	if absorbed < 6 and rng.randf() < 0.10:
		for offset in NEIGHBORS:
			var nx: int = x + offset.x
			var ny: int = y + offset.y
			if nx < 0 or nx >= w or ny < 0 or ny >= h:
				continue
			var j := ny * w + nx
			if int(grid[j]) == WATER:
				grid[j] = EMPTY
				life[i] = absorbed + 1
				_moved[j] = 1
				_event("absorb", x, y)
				return


func _react_coal(x: int, y: int, i: int) -> void:
	if rng.randf() > 0.012:
		return
	for offset in NEIGHBORS:
		var nx: int = x + offset.x
		var ny: int = y + offset.y
		if nx < 0 or nx >= w or ny < 0 or ny >= h:
			continue
		var other := int(grid[ny * w + nx])
		if other == FIRE or other == LAVA:
			var fuel := maxi(60, int(life[i]))
			grid[i] = FIRE
			life[i] = fuel + rng.randi_range(0, 30)
			_moved[i] = 1
			_event("ignite", x, y)
			return


func _react_crystal(x: int, y: int, i: int) -> void:
	if temperature > 0 or rng.randf() > 0.0040:
		return
	for offset in NEIGHBORS:
		var nx: int = x + offset.x
		var ny: int = y + offset.y
		if nx < 0 or nx >= w or ny < 0 or ny >= h:
			continue
		var j := ny * w + nx
		var other := int(grid[j])
		if other == WATER or other == ICE:
			grid[j] = CRYSTAL
			_moved[j] = 1
			_event("grow", nx, ny)
			return


func _react_gunpowder(x: int, y: int, i: int) -> void:
	if _explosion_budget >= 2:
		return
	var hot := false
	for offset in NEIGHBORS:
		var nx: int = x + offset.x
		var ny: int = y + offset.y
		if nx < 0 or nx >= w or ny < 0 or ny >= h:
			continue
		var other := int(grid[ny * w + nx])
		if other == FIRE or other == LAVA:
			hot = true
			break
	if not hot:
		return
	_explosion_budget += 1
	_explode(x, y, 5)


func _explode(cx: int, cy: int, radius: int) -> void:
	var r2 := radius * radius
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if dx * dx + dy * dy > r2:
				continue
			var nx := cx + dx
			var ny := cy + dy
			if nx < 0 or nx >= w or ny < 0 or ny >= h:
				continue
			var j := ny * w + nx
			var other := int(grid[j])
			if other == EMPTY:
				if rng.randf() < 0.08:
					grid[j] = SMOKE
					life[j] = 40 + rng.randi_range(0, 30)
				continue
			if other == STONE or other == OBSIDIAN or other == LAVA:
				continue
			if other == WATER:
				if rng.randf() < 0.55:
					grid[j] = STEAM
					life[j] = 30 + rng.randi_range(0, 20)
				continue
			if other == ICE:
				grid[j] = WATER
				continue
			if other == OIL:
				grid[j] = FIRE
				life[j] = 30 + rng.randi_range(0, 18)
				continue
			if other == GUNPOWDER:
				grid[j] = FIRE
				life[j] = 24 + rng.randi_range(0, 16)
				continue
			if other == CRYSTAL:
				grid[j] = ICE
				_event("shatter", nx, ny)
				continue
			if other == COAL:
				grid[j] = FIRE
				life[j] = 70 + rng.randi_range(0, 30)
				continue
			if other == SNOW:
				grid[j] = WATER
				continue
			if other == SPORE:
				grid[j] = FIRE
				life[j] = 18 + rng.randi_range(0, 10)
				continue
			if other == ASH or other == SPONGE or other == SEAWEED or other == FLOWER \
					or other >= IRON:
				grid[j] = EMPTY
				continue
			if other == FIRE or other == SMOKE or other == STEAM:
				continue
			grid[j] = EMPTY

	grid[cy * w + cx] = FIRE
	life[cy * w + cx] = 36 + rng.randi_range(0, 20)
	_event("explode", cx, cy)


func _react_acid(x: int, y: int, i: int) -> void:
	for offset in NEIGHBORS:
		var nx: int = x + offset.x
		var ny: int = y + offset.y
		if nx < 0 or nx >= w or ny < 0 or ny >= h:
			continue
		if int(grid[ny * w + nx]) == WATER:
			grid[i] = WATER
			_event("dilute", x, y)
			return

	for offset in NEIGHBORS:
		var nx: int = x + offset.x
		var ny: int = y + offset.y
		if nx < 0 or nx >= w or ny < 0 or ny >= h:
			continue
		var j := ny * w + nx
		var other := int(grid[j])
		if other == STONE or other == SAND or other == ICE or other == OBSIDIAN \
				or other == PLANT or other == GLASS or other == SEAWEED \
				or other == SPONGE or other == COAL or other == ASH \
				or other == SNOW or other == CRYSTAL or other == FLOWER \
				or other >= IRON:
			grid[j] = EMPTY
			grid[i] = EMPTY
			_moved[i] = 1
			_moved[j] = 1
			_event("dissolve", nx, ny)
			return


func _react_pollen(x: int, y: int, i: int) -> void:
	if rng.randf() > 0.020:
		return
	for offset in NEIGHBORS:
		var nx: int = x + offset.x
		var ny: int = y + offset.y
		if nx < 0 or nx >= w or ny < 0 or ny >= h:
			continue
		var j := ny * w + nx
		if int(grid[j]) == WATER:
			grid[j] = FUNGUS if rng.randf() < 0.3 else MUSHROOM
			_moved[j] = 1
			grid[i] = EMPTY
			_moved[i] = 1
			_event("grow", nx, ny)
			return


func _react_slime(x: int, y: int, i: int) -> void:
	for offset in NEIGHBORS:
		var nx: int = x + offset.x
		var ny: int = y + offset.y
		if nx < 0 or nx >= w or ny < 0 or ny >= h:
			continue
		var j := ny * w + nx
		var other := int(grid[j])
		if other == FIRE or other == LAVA:
			grid[i] = WATER
			_moved[i] = 1
			_event("extinguish", x, y)
			return


func _react_pack_plant(x: int, y: int, i: int, type: int) -> void:
	if rng.randf() > 0.0035 * growth_boost:
		return
	for offset in NEIGHBORS:
		var nx: int = x + offset.x
		var ny: int = y + offset.y
		if nx < 0 or nx >= w or ny < 0 or ny >= h:
			continue
		var j := ny * w + nx
		if int(grid[j]) == WATER:
			grid[j] = type
			_moved[j] = 1
			_event("grow", nx, ny)
			return


func _event(kind: String, x: int, y: int) -> void:
	var entry = _events.get(kind)
	if entry == null:
		_events[kind] = {"count": 1, "x": x, "y": y}
	else:
		entry["count"] = int(entry["count"]) + 1


# ---------------------------------------------------------------------------
# Movement
# ---------------------------------------------------------------------------

func _step_sand(x: int, y: int, i: int) -> void:
	if y + 1 < h:
		var below := i + w
		var below_type := int(grid[below])
		if below_type == EMPTY or below_type == WATER or below_type == ACID:
			_swap(i, below)
			return

		var dir := -1 if rng.randi() % 2 == 0 else 1
		for k in 2:
			var nx := x + dir
			if nx >= 0 and nx < w:
				var j := below + dir
				var other := int(grid[j])
				if other == EMPTY or other == WATER or other == ACID:
					_swap(i, j)
					return
			dir = -dir


func _step_ash(x: int, y: int, i: int) -> void:
	# Ash is lighter than water: it floats and slowly rises through it.
	if y > 0 and int(grid[i - w]) == WATER and rng.randf() < 0.25:
		_swap(i, i - w)
		return
	if y + 1 < h:
		var below := int(grid[i + w])
		if below == EMPTY or below == ACID:
			_swap(i, i + w)
			return
		if below == WATER:
			return
		var dir := -1 if rng.randi() % 2 == 0 else 1
		for k in 2:
			var nx := x + dir
			if nx >= 0 and nx < w:
				var j := i + w + dir
				var other := int(grid[j])
				if other == EMPTY or other == ACID:
					_swap(i, j)
					return
			dir = -dir


func _step_snow(x: int, y: int, i: int) -> void:
	_step_sand(x, y, i)


func _step_spore(x: int, y: int, i: int) -> void:
	var current_life := int(life[i]) - 1
	life[i] = current_life
	if current_life <= 0:
		grid[i] = EMPTY
		_moved[i] = 1
		_moved_any = true
		return
	var dir := 1 if rng.randi() % 3 == 0 else -1
	if y > 0 and rng.randf() < 0.35:
		var nx := x + dir
		if nx >= 0 and nx < w and int(grid[i - w + dir]) == EMPTY:
			_swap(i, i - w + dir)
			return
		if int(grid[i - w]) == EMPTY:
			_swap(i, i - w)
			return
	if rng.randf() < 0.55:
		var nx2 := x + dir
		if nx2 >= 0 and nx2 < w and int(grid[i + dir]) == EMPTY:
			_swap(i, i + dir)


func _step_liquid(x: int, y: int, i: int, horizontal_chance: float) -> void:
	if int(grid[i]) == WATER and y + 1 < h and int(grid[i + w]) == OIL \
			and rng.randf() < 0.5:
		_swap(i, i + w)
		return

	if y + 1 < h:
		var below := i + w
		if int(grid[below]) == EMPTY:
			_swap(i, below)
			return

		var dir := -1 if rng.randi() % 2 == 0 else 1
		for k in 2:
			var nx := x + dir
			if nx >= 0 and nx < w:
				var j := below + dir
				if int(grid[j]) == EMPTY:
					_swap(i, j)
					return
			dir = -dir

	if rng.randf() > horizontal_chance:
		return

	var side := -1 if rng.randi() % 2 == 0 else 1
	for k in 2:
		var nx := x + side
		if nx >= 0 and nx < w:
			var j := i + side
			if int(grid[j]) == EMPTY:
				_swap(i, j)
				return
		side = -side


func _step_oil(x: int, y: int, i: int) -> void:
	# Oil is lighter than water: percolate upward through it.
	if y > 0:
		var above := i - w
		if int(grid[above]) == WATER and rng.randf() < 0.40:
			_swap(i, above)
			return

	if y + 1 < h:
		var below := i + w
		if int(grid[below]) == EMPTY:
			_swap(i, below)
			return

		var dir := -1 if rng.randi() % 2 == 0 else 1
		for k in 2:
			var nx := x + dir
			if nx >= 0 and nx < w and int(grid[below + dir]) == EMPTY:
				_swap(i, below + dir)
				return
			dir = -dir

	if rng.randf() > 0.65:
		return

	var side := -1 if rng.randi() % 2 == 0 else 1
	for k in 2:
		var nx := x + side
		if nx >= 0 and nx < w and int(grid[i + side]) == EMPTY:
			_swap(i, i + side)
			return
		side = -side


func _step_fire(x: int, y: int, i: int) -> void:
	var current_life := int(life[i]) - 1
	life[i] = current_life
	if current_life <= 0:
		if rng.randf() < 0.35:
			grid[i] = SMOKE
			life[i] = 30 + rng.randi_range(0, 24)
		else:
			grid[i] = EMPTY
		_moved[i] = 1
		_moved_any = true
		return

	if y > 0:
		var above := i - w
		if int(grid[above]) == EMPTY:
			_swap(i, above)
			return

		var dir := -1 if rng.randi() % 2 == 0 else 1
		for k in 2:
			var nx := x + dir
			if nx >= 0 and nx < w and int(grid[above + dir]) == EMPTY:
				_swap(i, above + dir)
				return
			dir = -dir

	var side := -1 if rng.randi() % 2 == 0 else 1
	for k in 2:
		var nx := x + side
		if nx >= 0 and nx < w and int(grid[i + side]) == EMPTY:
			_swap(i, i + side)
			return
		side = -side


func _step_steam(x: int, y: int, i: int) -> void:
	var current_life := int(life[i]) - 1
	life[i] = current_life
	if current_life <= 0:
		grid[i] = EMPTY
		_moved[i] = 1
		_moved_any = true
		return

	if y > 0:
		var above := i - w
		if int(grid[above]) == EMPTY:
			_swap(i, above)
			return

		var dir := -1 if rng.randi() % 2 == 0 else 1
		for k in 2:
			var nx := x + dir
			if nx >= 0 and nx < w:
				var j := above + dir
				if int(grid[j]) == EMPTY:
					_swap(i, j)
					return
			dir = -dir

	var side := -1 if rng.randi() % 2 == 0 else 1
	var j2 := i + side
	var nx2 := x + side
	if nx2 >= 0 and nx2 < w and int(grid[j2]) == EMPTY:
		_swap(i, j2)


func _swap(a: int, b: int) -> void:
	var type_a := grid[a]
	grid[a] = grid[b]
	grid[b] = type_a
	var life_a := life[a]
	life[a] = life[b]
	life[b] = life_a
	_moved[a] = 1
	_moved[b] = 1
	_moved_any = true


# ---------------------------------------------------------------------------
# Back to the 8x8 board
# ---------------------------------------------------------------------------

func quantize() -> Array:
	var count_cells := cells * cells
	var block_counts := PackedInt32Array()
	block_counts.resize(count_cells * TYPE_COUNT)
	var totals := PackedInt32Array()
	totals.resize(TYPE_COUNT)

	for by in cells:
		for bx in cells:
			var base := (by * cells + bx) * TYPE_COUNT
			for py in SUB:
				var row := (by * SUB + py) * w + bx * SUB
				for px in SUB:
					var type := int(grid[row + px])
					if type != EMPTY and type != STEAM and type != FIRE and type != SMOKE:
						block_counts[base + type] += 1
						totals[type] += 1

	var dominant := PackedInt32Array()
	dominant.resize(count_cells)
	dominant.fill(0)
	var dominant_count := PackedInt32Array()
	dominant_count.resize(count_cells)

	for bi in count_cells:
		var best_type := 0
		var best_count := 0
		for type in QUANT_ORDER:
			var count := block_counts[bi * TYPE_COUNT + type]
			if count > best_count:
				best_count = count
				best_type = type
		dominant[bi] = best_type
		dominant_count[bi] = best_count

	var assigned := PackedInt32Array()
	assigned.resize(count_cells)
	assigned.fill(-1)

	for type in QUANT_ORDER:
		var total := totals[type]
		var minimum := 16 if type == STONE or type == ICE or type == OBSIDIAN \
			or type == GLASS or type == PLANT or type == CRYSTAL or type == COAL \
			or type == SPONGE or type == SEAWEED or type == FLOWER \
			or (type >= IRON and type != MERCURY and type != SLIME and type != POLLEN) else 24
		if total < minimum:
			continue
		var budget := maxi(1, int(round(float(total) / 64.0)))
		var candidates: Array = []
		for bi in count_cells:
			if assigned[bi] == -1 and dominant[bi] == type and dominant_count[bi] >= 8:
				candidates.append(bi)
		candidates.sort_custom(func(a: int, b: int) -> bool:
			return dominant_count[a] > dominant_count[b]
		)
		for bi in candidates:
			if budget <= 0:
				break
			assigned[bi] = type
			budget -= 1

	var result: Array = []
	result.resize(count_cells)
	for bi in count_cells:
		var type := assigned[bi]
		result[bi] = "" if type == -1 else str(TYPE_NAMES[type])
	return result
