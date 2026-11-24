extends Node
## Small persistent profile: personal best + mute flag.

const SAVE_PATH := "user://element_blast.cfg"

var best := 0
var muted := false
var theme := "dark"
var board_size := 8


func _ready() -> void:
	load_data()


func load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		ThemeKit.mode = theme
		return
	best = int(cfg.get_value("game", "best", 0))
	muted = bool(cfg.get_value("settings", "muted", false))
	theme = str(cfg.get_value("settings", "theme", "dark"))
	board_size = int(cfg.get_value("settings", "board_size", 8))
	if theme != "light":
		theme = "dark"
	if board_size != 6 and board_size != 8 and board_size != 10:
		board_size = 8
	ThemeKit.mode = theme
	AudioServer.set_bus_mute(0, muted)


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "best", best)
	cfg.set_value("settings", "muted", muted)
	cfg.set_value("settings", "theme", theme)
	cfg.set_value("settings", "board_size", board_size)
	cfg.save(SAVE_PATH)


func set_best(value: int) -> void:
	if value <= best:
		return
	best = value
	save()


func set_muted(value: bool) -> void:
	muted = value
	AudioServer.set_bus_mute(0, muted)
	save()


func set_theme(value: String) -> void:
	theme = "light" if value == "light" else "dark"
	ThemeKit.mode = theme
	save()


func set_board_size(value: int) -> void:
	if value != 6 and value != 8 and value != 10:
		return
	board_size = value
	save()
