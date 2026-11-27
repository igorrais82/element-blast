extends Node
## Small persistent profile: personal best + mute flag.

const SAVE_PATH := "user://element_blast.cfg"

var best := 0
var muted := false
var theme := "dark"
var board_size := 8
var ads_removed := false
var owned_packs: Array[String] = []


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
	ads_removed = bool(cfg.get_value("store", "ads_removed", false))
	owned_packs.clear()
	for pack in cfg.get_value("store", "owned_packs", PackedStringArray()):
		owned_packs.append(str(pack))
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
	cfg.set_value("store", "ads_removed", ads_removed)
	cfg.set_value("store", "owned_packs", PackedStringArray(owned_packs))
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


func owns_pack(pack_id: String) -> bool:
	return owned_packs.has(pack_id)


func unlock_pack(pack_id: String) -> void:
	if owned_packs.has(pack_id):
		return
	owned_packs.append(pack_id)
	save()


func set_ads_removed(value: bool) -> void:
	ads_removed = value
	save()
