extends Node
## Headless input smoke test: tap-to-place and drag-to-place through BoardView.
## Run: godot --headless --path . res://tools/InputTest.tscn

var failures := 0


func _ready() -> void:
	print("=== Element Blast input test ===")
	var main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	main.start_game()
	await get_tree().process_frame

	var game: ElementGame = main.game
	var view: BoardView = main.board_view
	view._calc_layout()
	_check(view.size.x > 10.0, "BoardView has a size")
	_check(view.board_rect.size.x > 10.0, "board rect is computed")

	# --- tap piece, then tap board ---------------------------------------
	var first_rect := view._piece_rect(0)
	view._press(first_rect.get_center())
	view._release(first_rect.get_center())
	_check(view.selected == 0, "tap on a tray piece selects it")

	var before_count := _count_cells(game)
	var shape0: Dictionary = game.pieces[0]["shape"]
	var expected0 := int(shape0["cells"].size())
	view._press(view._cell_center(4, 4))
	await get_tree().process_frame
	_check(bool(game.pieces[0]["used"]), "tap placement consumes the piece")
	var after_count := _count_cells(game)
	_check(after_count == before_count + expected0,
		"tap placement adds %d cells (got %d)" % [expected0, after_count - before_count])

	# --- drag piece onto the board ---------------------------------------
	view._calc_layout()
	var second_index := _first_unused(game)
	_check(second_index >= 0, "there is a second piece")
	if second_index >= 0:
		var second_rect := view._piece_rect(second_index)
		view._press(second_rect.get_center())
		_check(not view.drag.is_empty(), "press starts a drag")
		var grab: Vector2i = view.drag["grab"]
		var shape1: Dictionary = game.pieces[second_index]["shape"]
		var spot := _find_anchor(game, shape1, grab)
		_check(spot.x >= 0, "found a free spot for drag")
		if spot.x >= 0:
			view.drag["moved"] = true
			var release_at := view._cell_center(spot.y + grab.y, spot.x + grab.x)
			view._release(release_at)
			_check(bool(game.pieces[second_index]["used"]), "drag placement consumes the piece")

	# --- sanity -----------------------------------------------------------
	_check(game.mode == "awakening" or game.mode == "playing",
		"game is in a valid state after two moves (mode=%s)" % game.mode)
	_check(game.score > 0, "score increased")

	main.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

	if failures == 0:
		print("ALL INPUT TESTS PASSED")
		get_tree().quit(0)
	else:
		print("FAILURES: ", failures)
		get_tree().quit(1)


func _first_unused(game: ElementGame) -> int:
	for i in game.pieces.size():
		if not bool(game.pieces[i]["used"]):
			return i
	return -1


func _count_cells(game: ElementGame) -> int:
	var count := 0
	for r in game.rows:
		for c in game.cols:
			if game.board[r][c] != null:
				count += 1
	return count


func _find_anchor(game: ElementGame, shape: Dictionary, grab: Vector2i) -> Vector2i:
	for r0 in game.rows - int(shape["h"]) + 1:
		for c0 in game.cols - int(shape["w"]) + 1:
			if not game.can_place(shape, r0, c0):
				continue
			if r0 + grab.y >= game.rows or c0 + grab.x >= game.cols:
				continue
			return Vector2i(c0, r0)
	return Vector2i(-1, -1)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		print("  FAIL: ", message)
