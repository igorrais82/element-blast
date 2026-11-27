extends Node
## Headless smoke test for ElementGame + SandSim.
## Run: godot --headless --path . res://tools/LogicTest.tscn

var failures := 0
var valid_types := [
	"stone", "sand", "water", "lava", "acid", "ice", "obsidian", "steam",
	"fire", "oil", "plant", "gunpowder", "smoke", "glass",
	"seaweed", "sponge", "coal", "ash", "snow", "crystal", "spore", "flower",
	"iron", "copper", "gold", "silver", "lead", "tin", "mercury", "titanium",
	"mushroom", "moss", "vine", "pollen", "slime", "bone", "shell", "fungus",
]


func _ready() -> void:
	print("=== Element Blast logic test ===")
	test_line_clear()
	test_shape_geometry()
	test_sand_falls()
	test_water_levels()
	test_lava_water()
	test_acid_dissolve()
	test_oil_fire()
	test_plant_growth()
	test_gunpowder()
	test_glass()
	test_temperature()
	test_temperature_shift()
	test_events()
	test_event_elements()
	test_packs()
	test_board_sizes()
	test_quantize()
	test_new_quantize()
	test_awakening_integration()
	test_random_games()

	if failures == 0:
		print("ALL TESTS PASSED")
		get_tree().quit(0)
	else:
		print("FAILURES: ", failures)
		get_tree().quit(1)


func _cell(type: String) -> Dictionary:
	return {"t": type, "born": 0.0, "flash": 0.0}


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		print("  FAIL: ", message)
	else:
		print("  ok: ", message)


func test_line_clear() -> void:
	var game := ElementGame.new()
	game.start()
	for c in game.cols:
		game.board[7][c] = _cell("stone")
	var before := game.score
	var result := game.clear_lines()
	_check(int(result["lines"]) == 1, "one full row should clear")
	_check(int(result["points"]) == 80, "row clear should give 80 points")
	_check(game.board[7][0] == null, "cleared row should be empty")
	_check(game.score == before + 80, "score should include clear points")


func test_shape_geometry() -> void:
	var before := failures
	for shape in ElementGame.SHAPES:
		var shape_id := str(shape["id"])
		var max_row := 0
		var max_col := 0
		for cell in shape["cells"]:
			max_row = maxi(max_row, int(cell.x))
			max_col = maxi(max_col, int(cell.y))
		if max_row + 1 != int(shape["h"]):
			_fail("%s: height does not match cell rows" % shape_id)
		if max_col + 1 != int(shape["w"]):
			_fail("%s: width does not match cell columns" % shape_id)

		var game := ElementGame.new()
		game.start()
		if not game.can_place(shape, 0, game.cols - int(shape["w"])):
			_fail("%s: cannot fit at the right edge" % shape_id)
		if not game.can_place(shape, game.rows - int(shape["h"]), 0):
			_fail("%s: cannot fit at the bottom edge" % shape_id)

		var probe := ElementGame.new()
		probe.start()
		probe.pieces[0] = {"shape": shape, "element": "stone", "used": false}
		var score_before := probe.score
		if not probe.place_at(0, 0, 0):
			_fail("%s: cannot place at 0,0" % shape_id)
			continue
		var occupied := 0
		for r in game.rows:
			for c in game.cols:
				if probe.board[r][c] != null:
					occupied += 1
		if occupied != int(shape["cells"].size()):
			_fail("%s: placed %d cells instead of %d" % [shape_id, occupied, shape["cells"].size()])
		for cell in shape["cells"]:
			if probe.board[int(cell.x)][int(cell.y)] == null:
				_fail("%s: expected cell row=%d col=%d is empty" % [shape_id, cell.x, cell.y])
		if probe.score != score_before + int(shape["cells"].size()):
			_fail("%s: score does not match placed cells" % shape_id)
	if failures == before:
		print("  shape geometry: ok")


func test_sand_falls() -> void:
	var sim := SandSim.new()
	sim.spawn_block(0, 0, "sand")
	var before := sim.count_type(SandSim.SAND)
	for i in 85:
		sim.step()
	_check(sim.count_type(SandSim.SAND) == before, "sand should be conserved")
	var bottom := 0
	for x in sim.w:
		if int(sim.grid[(sim.h - 1) * sim.w + x]) == SandSim.SAND:
			bottom += 1
	_check(bottom > 0, "sand should reach the bottom row")
	var cells := sim.quantize()
	var sand_cells := 0
	for cell in cells:
		if str(cell) == "sand":
			sand_cells += 1
	_check(sand_cells == 1, "quantization should keep one sand cell (got %d)" % sand_cells)
	print("  sand: ok")


func test_water_levels() -> void:
	var sim := SandSim.new()
	sim.spawn_block(2, 4, "water")
	var before := sim.count_type(SandSim.WATER)
	for i in 80:
		sim.step()
	_check(sim.count_type(SandSim.WATER) == before, "water should be conserved")

	var min_x := 999
	var max_x := -1
	var bottom := 0
	for y in sim.h:
		for x in sim.w:
			if int(sim.grid[y * sim.w + x]) == SandSim.WATER:
				min_x = mini(min_x, x)
				max_x = maxi(max_x, x)
				if y == sim.h - 1:
					bottom += 1
	_check(bottom > 0, "water should reach the bottom")
	_check(max_x - min_x > 8, "water should spread sideways (width=%d)" % (max_x - min_x))

	var cells := sim.quantize()
	var water_cells := 0
	for cell in cells:
		if str(cell) == "water":
			water_cells += 1
	_check(water_cells == 1, "quantization should keep one water cell (got %d)" % water_cells)
	print("  water: ok")


func test_lava_water() -> void:
	var sim := SandSim.new()
	sim.spawn_block(7, 3, "lava")
	sim.spawn_block(7, 4, "water")
	var lava_before := sim.count_type(SandSim.LAVA)
	for i in 8:
		sim.step()
	_check(sim.count_type(SandSim.OBSIDIAN) > 0, "lava + water should create obsidian")
	_check(sim.count_type(SandSim.STEAM) > 0, "lava + water should create steam")
	_check(sim.count_type(SandSim.LAVA) < lava_before, "some lava should be consumed")
	print("  lava + water: ok")


func test_acid_dissolve() -> void:
	var sim := SandSim.new()
	sim.spawn_block(4, 4, "acid")
	sim.spawn_block(5, 4, "stone")
	var stone_before := sim.count_type(SandSim.STONE)
	var acid_before := sim.count_type(SandSim.ACID)
	for i in 6:
		sim.step()
	_check(sim.count_type(SandSim.STONE) < stone_before, "acid should dissolve stone")
	_check(sim.count_type(SandSim.ACID) < acid_before, "acid should be consumed")
	print("  acid: ok")


func test_oil_fire() -> void:
	var sim := SandSim.new()
	sim.spawn_block(6, 3, "oil")
	sim.spawn_block(6, 4, "fire")
	var oil_before := sim.count_type(SandSim.OIL)
	for i in 8:
		sim.step()
	_check(sim.count_type(SandSim.OIL) < oil_before, "fire should ignite oil")
	_check(sim.count_type(SandSim.FIRE) > 0 or sim.count_type(SandSim.SMOKE) > 0,
		"burning oil should leave fire/smoke")
	print("  oil + fire: ok")


func test_plant_growth() -> void:
	var sim := SandSim.new()
	sim.spawn_block(7, 3, "plant")
	sim.spawn_block(7, 4, "water")
	var plant_before := sim.count_type(SandSim.PLANT)
	var water_before := sim.count_type(SandSim.WATER)
	for i in 320:
		sim.step()
	_check(sim.count_type(SandSim.PLANT) > plant_before, "plant should grow into water")
	_check(sim.count_type(SandSim.WATER) < water_before, "growth should consume water")
	print("  plant growth: ok")


func test_gunpowder() -> void:
	var sim := SandSim.new()
	sim.spawn_block(7, 3, "gunpowder")
	sim.spawn_block(6, 3, "fire")
	var before := sim.count_type(SandSim.GUNPOWDER)
	var events := sim.step()
	_check(events.has("explode"), "gunpowder should explode next to fire")
	_check(sim.count_type(SandSim.GUNPOWDER) < before,
		"explosion should consume gunpowder")
	print("  gunpowder: ok")


func test_glass() -> void:
	var sim := SandSim.new()
	sim.rng.seed = 202603
	sim.spawn_block(7, 3, "lava")
	sim.spawn_block(7, 4, "sand")
	for i in 160:
		sim.step()
	_check(sim.count_type(SandSim.GLASS) > 0, "lava + sand should produce glass")
	print("  glass: ok")


func test_temperature() -> void:
	var hot := SandSim.new()
	hot.temperature = 2
	hot.spawn_block(6, 2, "ice")
	hot.spawn_block(6, 5, "lava")
	var water_before := hot.count_type(SandSim.WATER)
	var lava_before := hot.count_type(SandSim.LAVA)
	hot.step()
	_check(hot.count_type(SandSim.ICE) == 0, "very hot should instantly melt ice")
	_check(hot.count_type(SandSim.WATER) > water_before,
		"melted ice should become water")
	_check(hot.count_type(SandSim.LAVA) == lava_before,
		"lava should not freeze at very hot")

	var boiling := SandSim.new()
	boiling.temperature = 2
	boiling.spawn_block(7, 3, "water")
	var water_start := boiling.count_type(SandSim.WATER)
	for i in 200:
		boiling.step()
	_check(boiling.count_type(SandSim.WATER) < water_start,
		"water should boil at very hot")

	var cold := SandSim.new()
	cold.temperature = -2
	cold.spawn_block(7, 2, "water")
	cold.spawn_block(7, 5, "lava")
	for i in 200:
		cold.step()
	_check(cold.count_type(SandSim.ICE) > 0, "water should freeze at very cold")
	_check(cold.count_type(SandSim.STONE) > 0, "lava should solidify at very cold")
	print("  temperature: ok")


func test_temperature_shift() -> void:
	var game := ElementGame.new()
	game.start()
	# Events lock the temperature; test the normal endless rules explicitly.
	game.current_event = {}
	game.set_temperature_degrees(ElementGame.TEMP_START_DEG)
	var old := game.temperature_degrees
	var index := _first_unused(game)
	if index >= 0:
		var spot := _find_spot(game, index)
		if spot.x >= 0:
			game.place_at(index, spot.y, spot.x)
	var delta := absi(game.temperature_degrees - old)
	_check(delta >= ElementGame.TEMP_STEP_MIN,
		"temperature should change by degrees (delta=%d)" % delta)
	_check(delta <= ElementGame.TEMP_STEP_MAX,
		"temperature step should stay in range (delta=%d)" % delta)
	_check(game.temperature == game._temperature_level(game.temperature_degrees),
		"temperature band should match the degrees")
	print("  temperature shift: ok")


func test_events() -> void:
	_check(EventDefs.all().size() >= 4, "there should be several events")
	var flood := EventDefs.get_event("flood")
	_check(str(flood.get("id", "")) == "flood", "flood event exists")
	_check(flood.get("event_elements", []).size() == 2,
		"flood should have two event elements")

	var game := ElementGame.new()
	game.start()
	_check(not game.event_active, "game should start between events")
	_check(game.event_cooldown_moves > 0, "first event should have a delay")
	_check(game.temperature_degrees == ElementGame.TEMP_START_DEG,
		"normal temperature at the start")

	game.event_cooldown_moves = 1
	var index := _first_unused(game)
	if index >= 0:
		var spot := _find_spot(game, index)
		if spot.x >= 0:
			game.place_at(index, spot.y, spot.x)
	_check(game.event_active, "event should start during play")
	_check(not EventDefs.get_event(game.event_id()).is_empty(),
		"started event should be known")
	_check(game.temperature_locked(), "active event should lock temperature")
	_check(game.event_moves_left >= ElementGame.EVENT_DURATION_MIN,
		"event should get a duration")

	var old_temp := game.temperature_degrees
	game.event_moves_left = 1
	index = _first_unused(game)
	if index >= 0:
		var spot2 := _find_spot(game, index)
		if spot2.x >= 0:
			game.place_at(index, spot2.y, spot2.x)
	_check(game.temperature_degrees == old_temp,
		"locked event temperature should not change after a move")
	_finish_awakening(game)
	_check(not game.event_active, "event should end after its last awakening")
	_check(game.last_event_name() != "", "last event should be remembered")
	_check(game.temperature_degrees == ElementGame.TEMP_START_DEG,
		"temperature should return to normal after the event")
	_check(game.event_cooldown_moves > 0, "event end should start a calm period")

	var sim := SandSim.new()
	sim.event_rule = "flood"
	sim.spawn_block(7, 3, "lava")
	sim.step()
	_check(sim.count_type(SandSim.LAVA) == 0, "flood should turn lava into stone")
	_check(sim.count_type(SandSim.STONE) > 0, "flood should leave stone")

	var awakening := ElementGame.new()
	awakening.start()
	awakening.force_event("flood")
	awakening.begin_awakening()
	_check(awakening.sand.event_rule == "flood", "flood rule should reach the sandbox")
	_check(awakening.surge_plan.size() == ElementGame.SURGE_TICKS.size(),
		"event should schedule all surges")
	var all_water := true
	for entry in awakening.surge_plan:
		if str(entry["element"]) != "water":
			all_water = false
	_check(all_water, "flood should drop only water")
	_check(awakening.surge_scale > 1.0, "flood surges should be doubled")

	var old_max := QualitySettings.sand_max_ticks
	QualitySettings.sand_max_ticks = 150
	var low := ElementGame.new()
	low.start()
	low.begin_awakening()
	_check(int(low.surge_ticks[low.surge_ticks.size() - 1]) < low.sand.max_ticks,
		"low quality surges should fit into the shorter phase")
	_finish_awakening(low)
	QualitySettings.sand_max_ticks = old_max
	print("  events: ok")


func test_event_elements() -> void:
	var seaweed := SandSim.new()
	seaweed.spawn_block(7, 3, "seaweed")
	seaweed.spawn_block(6, 3, "water")
	seaweed.spawn_block(6, 4, "water")
	seaweed.spawn_block(7, 4, "water")
	var seaweed_before := seaweed.count_type(SandSim.SEAWEED)
	var seaweed_water := seaweed.count_type(SandSim.WATER)
	for i in 220:
		seaweed.step()
	_check(seaweed.count_type(SandSim.SEAWEED) > seaweed_before,
		"seaweed should grow into water")
	_check(seaweed.count_type(SandSim.WATER) < seaweed_water,
		"seaweed growth should consume water")

	var sponge := SandSim.new()
	sponge.spawn_block(7, 3, "sponge")
	sponge.spawn_block(6, 3, "water")
	var sponge_water := sponge.count_type(SandSim.WATER)
	for i in 160:
		sponge.step()
	_check(sponge.count_type(SandSim.WATER) < sponge_water,
		"sponge should absorb water")
	_check(sponge.count_type(SandSim.SPONGE) > 0, "sponge should remain after absorbing")

	var coal := SandSim.new()
	coal.spawn_block(7, 3, "coal")
	coal.spawn_block(7, 4, "fire")
	var coal_before := coal.count_type(SandSim.COAL)
	for i in 20:
		coal.step()
	_check(coal.count_type(SandSim.COAL) < coal_before, "coal should ignite near fire")

	var snow := SandSim.new()
	snow.temperature = 2
	snow.spawn_block(7, 3, "snow")
	for i in 3:
		snow.step()
	_check(snow.count_type(SandSim.SNOW) == 0, "snow should melt in extreme heat")
	_check(snow.count_type(SandSim.WATER) > 0, "melting snow should become water")

	var crystal := SandSim.new()
	crystal.temperature = -2
	crystal.spawn_block(7, 3, "crystal")
	crystal.spawn_block(6, 3, "water")
	crystal.spawn_block(6, 4, "water")
	var crystal_before := crystal.count_type(SandSim.CRYSTAL)
	for i in 260:
		crystal.step()
	_check(crystal.count_type(SandSim.CRYSTAL) > crystal_before,
		"crystal should grow through cold water")

	var spore := SandSim.new()
	spore.growth_boost = 4.0
	spore.spawn_block(7, 3, "spore")
	spore.spawn_block(7, 4, "water")
	for i in 120:
		spore.step()
	_check(spore.count_type(SandSim.PLANT) > 0 or spore.count_type(SandSim.FLOWER) > 0,
		"spore should grow into a plant or flower")

	var flower := SandSim.new()
	flower.growth_boost = 4.0
	flower.spawn_block(7, 3, "flower")
	for i in 120:
		flower.step()
	_check(flower.count_type(SandSim.SPORE) > 0, "flower should release spores")

	var quant := SandSim.new()
	for i in 8:
		quant.spawn_block(7, i, [
			"seaweed", "sponge", "coal", "ash", "snow", "crystal", "spore", "flower",
		][i])
	var cells := quant.quantize()
	var found := {}
	for cell in cells:
		found[str(cell)] = true
	for name in ["seaweed", "sponge", "coal", "ash", "snow", "crystal", "spore", "flower"]:
		_check(found.has(name), "quantization should keep %s" % name)
	print("  event elements: ok")


func test_new_quantize() -> void:
	var sim := SandSim.new()
	sim.spawn_block(7, 0, "oil")
	sim.spawn_block(7, 1, "plant")
	sim.spawn_block(7, 2, "gunpowder")
	sim.spawn_block(7, 3, "glass")
	var cells := sim.quantize()
	var counts := {"oil": 0, "plant": 0, "gunpowder": 0, "glass": 0}
	for cell in cells:
		if counts.has(str(cell)):
			counts[str(cell)] += 1
	_check(counts["oil"] == 1, "oil block should quantize to one cell")
	_check(counts["plant"] == 1, "plant block should quantize to one cell")
	_check(counts["gunpowder"] == 1, "gunpowder block should quantize to one cell")
	_check(counts["glass"] == 1, "glass block should quantize to one cell")
	print("  new quantize: ok")


func test_packs() -> void:
	_check(ElementGame.PACK_WEIGHTS.has("pack_metals"), "metals pack exists")
	_check(ElementGame.PACK_WEIGHTS.has("pack_flora"), "flora pack exists")
	_check(ElementGame.PACK_WEIGHTS["pack_metals"].size() >= 8,
		"metals pack should have 8 elements")
	_check(ElementGame.PACK_WEIGHTS["pack_flora"].size() >= 8,
		"flora pack should have 8 elements")
	var sim := SandSim.new()
	var names := [
		"iron", "copper", "gold", "silver", "lead", "tin", "mercury", "titanium",
		"mushroom", "moss", "vine", "pollen", "slime", "bone", "shell", "fungus",
	]
	for i in names.size():
		sim.spawn_block(i / 8, i % 8, str(names[i]))
	var cells := sim.quantize()
	var found := {}
	for cell in cells:
		found[str(cell)] = true
	for name in names:
		_check(found.has(name), "quantization should keep %s" % name)
	print("  packs: ok")


func test_board_sizes() -> void:
	for size in [6, 10]:
		var game := ElementGame.new()
		game.set_board_size(size)
		game.start()
		_check(game.rows == size and game.cols == size,
			"board size %d should be applied" % size)
		_check(game.board.size() == size and game.board[0].size() == size,
			"board array %d should match" % size)
		var placed := 0
		for n in 2:
			var index := _first_unused(game)
			if index < 0:
				break
			var spot := _find_spot(game, index)
			if spot.x < 0:
				break
			if game.place_at(index, spot.y, spot.x):
				placed += 1
		_check(placed == 2, "two pieces should fit on %d×%d" % [size, size])
		if game.mode == "awakening":
			_check(game.sand.w == size * SandSim.SUB and game.sand.h == size * SandSim.SUB,
				"particle sandbox should scale with %d×%d" % [size, size])
			_finish_awakening(game)
			_check(game.board.size() == size and game.board[0].size() == size,
				"quantized board %d should keep its size" % size)
	print("  board sizes: ok")


func test_quantize() -> void:
	var sim := SandSim.new()
	sim.spawn_block(7, 0, "stone")
	sim.spawn_block(7, 1, "water")
	sim.spawn_block(7, 2, "water")
	for i in 50:
		sim.step()
	var cells := sim.quantize()
	var stone_cells := 0
	var water_cells := 0
	var filled := 0
	for cell in cells:
		if str(cell) == "stone":
			stone_cells += 1
			filled += 1
		elif str(cell) == "water":
			water_cells += 1
			filled += 1
	_check(stone_cells == 1, "stone block should become one stone cell (got %d)" % stone_cells)
	_check(water_cells == 2, "two water blocks should become two cells (got %d)" % water_cells)
	_check(filled == 3, "total quantized cells should be three (got %d)" % filled)
	print("  quantize: ok")


func test_awakening_integration() -> void:
	var game := ElementGame.new()
	game.start()
	var placed := 0
	for n in 2:
		var index := _first_unused(game)
		if index < 0:
			break
		var spot := _find_spot(game, index)
		if spot.x < 0:
			break
		if game.place_at(index, spot.y, spot.x):
			placed += 1
	_check(placed == 2, "two pieces should be placed")
	_check(game.mode == "awakening", "second placement should start an awakening")
	_check(game.sand != null, "awakening should create a sand simulation")
	_finish_awakening(game)
	_check(game.mode == "playing" or game.mode == "gameover", "awakening should finish")
	_check(game.moves_left == 2 or game.mode == "gameover", "moves should reset after awakening")
	print("  awakening integration: ok")


func test_random_games() -> void:
	for game_index in 1:
		var game := ElementGame.new()
		game.start()
		var moves := 0
		while moves < 10 and game.mode != "gameover":
			var index := _first_unused(game)
			var placed := false
			# try every remaining piece with a few random spots
			for attempt in 24:
				if index < 0:
					break
				var spot := _find_spot(game, index)
				if spot.x >= 0:
					if game.place_at(index, spot.y, spot.x):
						placed = true
						break
				index = _next_unused(game, index)
			if not placed:
				break
			moves += 1
			_finish_awakening(game)
			_validate(game)
		print("  game %d: moves=%d score=%d mode=%s" % [game_index, moves, game.score, game.mode])
		_validate(game)
	if failures == 0:
		print("  random games: ok")


func _first_unused(game: ElementGame) -> int:
	for i in game.pieces.size():
		if not bool(game.pieces[i]["used"]):
			return i
	return -1


func _next_unused(game: ElementGame, from: int) -> int:
	for i in range(from + 1, game.pieces.size()):
		if not bool(game.pieces[i]["used"]):
			return i
	return -1


func _find_spot(game: ElementGame, index: int) -> Vector2i:
	var shape: Dictionary = game.pieces[index]["shape"]
	var spots: Array = []
	for r0 in game.rows - int(shape["h"]) + 1:
		for c0 in game.cols - int(shape["w"]) + 1:
			if game.can_place(shape, r0, c0):
				spots.append(Vector2i(c0, r0))
	if spots.is_empty():
		return Vector2i(-1, -1)
	return spots[randi() % spots.size()]


func _finish_awakening(game: ElementGame) -> void:
	var guard := 0
	while game.mode == "awakening" and guard < 260:
		game.update(0.25)
		guard += 1
	if game.mode == "awakening":
		_fail("awakening did not finish")


func _validate(game: ElementGame) -> void:
	if game.board.size() != game.rows:
		_fail("board row count")
	for r in game.rows:
		if game.board[r].size() != game.cols:
			_fail("board column count")
		for c in game.cols:
			var cell = game.board[r][c]
			if cell != null:
				if not cell.has("t"):
					_fail("cell has no type")
				elif not valid_types.has(cell["t"]):
					_fail("unknown cell type: %s" % cell["t"])
	if game.score < 0:
		_fail("score is negative")


func _fail(message: String) -> void:
	failures += 1
	print("  FAIL: ", message)
