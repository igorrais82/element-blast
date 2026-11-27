class_name BoardView
extends Control
## Draws the board, tray and all juice (particles, popups, awakening aura).
## Also owns drag & drop / tap-to-place input for the play area.

signal invalid_attempt
signal piece_picked

var rows := 8
var cols := 8
const TEXT_WIDTH := 300.0

static var PALETTE := {
	"stone": {
		"base": Color("#77839a"), "light": Color("#b6c1d6"), "dark": Color("#4a5368"),
		"glow": Color(0.0, 0.0, 0.0, 0.0), "particle": Color("#b9c4d8"),
	},
	"sand": {
		"base": Color("#cf9f55"), "light": Color("#f3d08c"), "dark": Color("#8d6632"),
		"glow": Color(0.0, 0.0, 0.0, 0.0), "particle": Color("#f5d89c"),
	},
	"water": {
		"base": Color("#2f8fe8"), "light": Color("#83ccff"), "dark": Color("#1c5a9e"),
		"glow": Color(0.25, 0.62, 1.0, 0.16), "particle": Color("#9ad8ff"),
	},
	"lava": {
		"base": Color("#e9541c"), "light": Color("#ffb23c"), "dark": Color("#8c1f0c"),
		"glow": Color(1.0, 0.38, 0.10, 0.30), "particle": Color("#ffb056"),
	},
	"acid": {
		"base": Color("#83d62b"), "light": Color("#d0ff72"), "dark": Color("#4a8014"),
		"glow": Color(0.50, 1.0, 0.20, 0.25), "particle": Color("#c6ff6e"),
	},
	"ice": {
		"base": Color("#5fcbdf"), "light": Color("#c6f5ff"), "dark": Color("#27788d"),
		"glow": Color(0.35, 0.88, 1.0, 0.18), "particle": Color("#c8f8ff"),
	},
	"obsidian": {
		"base": Color("#5a4a92"), "light": Color("#a38be0"), "dark": Color("#2b2148"),
		"glow": Color(0.55, 0.40, 1.0, 0.24), "particle": Color("#b49cff"),
	},
	"steam": {
		"base": Color("#c3d0e6"), "light": Color("#ffffff"), "dark": Color("#7f8da5"),
		"glow": Color(0.75, 0.88, 1.0, 0.12), "particle": Color("#e8eeff"),
	},
	"fire": {
		"base": Color("#ff7a1a"), "light": Color("#ffe08a"), "dark": Color("#b52f00"),
		"glow": Color(1.0, 0.45, 0.10, 0.35), "particle": Color("#ffb056"),
	},
	"oil": {
		"base": Color("#3c3150"), "light": Color("#7f6a9e"), "dark": Color("#1b1526"),
		"glow": Color(0.55, 0.35, 0.90, 0.12), "particle": Color("#9b82c8"),
	},
	"plant": {
		"base": Color("#42b24b"), "light": Color("#9cf06a"), "dark": Color("#1f6a2c"),
		"glow": Color(0.30, 0.90, 0.40, 0.16), "particle": Color("#95ef7a"),
	},
	"gunpowder": {
		"base": Color("#4b4350"), "light": Color("#a3959f"), "dark": Color("#231d28"),
		"glow": Color(0.0, 0.0, 0.0, 0.0), "particle": Color("#d8c8bc"),
	},
	"smoke": {
		"base": Color("#6f7280"), "light": Color("#b6bac4"), "dark": Color("#3c3f48"),
		"glow": Color(0.50, 0.50, 0.60, 0.08), "particle": Color("#b6bac4"),
	},
	"glass": {
		"base": Color("#8fd8e8"), "light": Color("#efffff"), "dark": Color("#3c8392"),
		"glow": Color(0.55, 0.90, 1.0, 0.20), "particle": Color("#d5fbff"),
	},
	"seaweed": {
		"base": Color("#2f9b6a"), "light": Color("#9cf7b2"), "dark": Color("#145c46"),
		"glow": Color(0.30, 0.95, 0.60, 0.16), "particle": Color("#7fe8ad"),
	},
	"sponge": {
		"base": Color("#d8aa48"), "light": Color("#ffe28a"), "dark": Color("#8f651c"),
		"glow": Color(1.0, 0.82, 0.30, 0.12), "particle": Color("#ffd36e"),
	},
	"coal": {
		"base": Color("#3a3742"), "light": Color("#8d8899"), "dark": Color("#17151c"),
		"glow": Color(0.0, 0.0, 0.0, 0.0), "particle": Color("#a8a0b0"),
	},
	"ash": {
		"base": Color("#8c8791"), "light": Color("#d6d2d8"), "dark": Color("#4d4952"),
		"glow": Color(0.0, 0.0, 0.0, 0.0), "particle": Color("#cfc8d4"),
	},
	"snow": {
		"base": Color("#e8f7ff"), "light": Color("#ffffff"), "dark": Color("#9cc6df"),
		"glow": Color(0.75, 0.92, 1.0, 0.18), "particle": Color("#ffffff"),
	},
	"crystal": {
		"base": Color("#6f8cff"), "light": Color("#dbe4ff"), "dark": Color("#2d3c9e"),
		"glow": Color(0.55, 0.65, 1.0, 0.28), "particle": Color("#b9c8ff"),
	},
	"spore": {
		"base": Color("#d8e86a"), "light": Color("#f6ffb0"), "dark": Color("#7d8a24"),
		"glow": Color(0.80, 1.0, 0.35, 0.20), "particle": Color("#eaff8a"),
	},
	"flower": {
		"base": Color("#ff8ac4"), "light": Color("#ffd3e8"), "dark": Color("#b03a74"),
		"glow": Color(1.0, 0.55, 0.75, 0.18), "particle": Color("#ffb3da"),
	},
	"iron": {
		"base": Color("#8a96a8"), "light": Color("#d6dde8"), "dark": Color("#4a5364"),
		"glow": Color(0.7, 0.8, 0.95, 0.08), "particle": Color("#c6d2e2"),
	},
	"copper": {
		"base": Color("#c47b4e"), "light": Color("#ffc49a"), "dark": Color("#6e3d24"),
		"glow": Color(1.0, 0.55, 0.25, 0.12), "particle": Color("#f0a878"),
	},
	"gold": {
		"base": Color("#e0b64e"), "light": Color("#fff0a8"), "dark": Color("#8a6418"),
		"glow": Color(1.0, 0.85, 0.25, 0.16), "particle": Color("#ffe58a"),
	},
	"silver": {
		"base": Color("#c8d2dc"), "light": Color("#ffffff"), "dark": Color("#6d7886"),
		"glow": Color(0.8, 0.9, 1.0, 0.10), "particle": Color("#eef5ff"),
	},
	"lead": {
		"base": Color("#6f7580"), "light": Color("#b9c0ca"), "dark": Color("#343942"),
		"glow": Color(0.5, 0.55, 0.65, 0.05), "particle": Color("#a8b0bc"),
	},
	"tin": {
		"base": Color("#b8c0c8"), "light": Color("#eef2f5"), "dark": Color("#666f78"),
		"glow": Color(0.75, 0.82, 0.9, 0.08), "particle": Color("#dbe3ea"),
	},
	"mercury": {
		"base": Color("#9aa7b8"), "light": Color("#eef6ff"), "dark": Color("#465366"),
		"glow": Color(0.65, 0.8, 1.0, 0.18), "particle": Color("#d6e4f4"),
	},
	"titanium": {
		"base": Color("#7f8fa6"), "light": Color("#d1dceb"), "dark": Color("#3e4b60"),
		"glow": Color(0.55, 0.7, 0.95, 0.10), "particle": Color("#b8c8e0"),
	},
	"mushroom": {
		"base": Color("#e06a5a"), "light": Color("#ffc0a8"), "dark": Color("#85302a"),
		"glow": Color(1.0, 0.4, 0.3, 0.12), "particle": Color("#ff9a82"),
	},
	"moss": {
		"base": Color("#6aa84f"), "light": Color("#c8f08a"), "dark": Color("#315c2a"),
		"glow": Color(0.55, 0.9, 0.3, 0.12), "particle": Color("#a8e07a"),
	},
	"vine": {
		"base": Color("#4f9e5a"), "light": Color("#b8f0a8"), "dark": Color("#205830"),
		"glow": Color(0.35, 0.9, 0.4, 0.14), "particle": Color("#86d888"),
	},
	"pollen": {
		"base": Color("#ffe07a"), "light": Color("#fffbd0"), "dark": Color("#a88c22"),
		"glow": Color(1.0, 0.9, 0.3, 0.18), "particle": Color("#fff0a0"),
	},
	"slime": {
		"base": Color("#8fd65a"), "light": Color("#d8ff9a"), "dark": Color("#4d7a22"),
		"glow": Color(0.6, 1.0, 0.3, 0.20), "particle": Color("#c0f080"),
	},
	"bone": {
		"base": Color("#e8e0cc"), "light": Color("#fffaf0"), "dark": Color("#9b8f78"),
		"glow": Color(0.9, 0.85, 0.7, 0.06), "particle": Color("#f5edda"),
	},
	"shell": {
		"base": Color("#f0c9a0"), "light": Color("#fff0d8"), "dark": Color("#a47a50"),
		"glow": Color(1.0, 0.8, 0.5, 0.08), "particle": Color("#ffd8b0"),
	},
	"fungus": {
		"base": Color("#b07a5a"), "light": Color("#e8c0a0"), "dark": Color("#5c3a2a"),
		"glow": Color(0.8, 0.5, 0.3, 0.10), "particle": Color("#d0a080"),
	},
}

var game: ElementGame

var cell_size := 64.0
var cell_gap := 8.0
var mini := 36.0
var board_origin := Vector2.ZERO
var board_rect := Rect2()
var tray_rect := Rect2()

var drag := {}
var selected := -1
var ghost := {}
var hover_ghost := {}
var mouse_pos := Vector2.ZERO

var particles: Array = []
var texts: Array = []
var rings: Array = []
var beams: Array = []
var shake := 0.0
var flash := 0.0
var flash_color := Color(1, 1, 1)
var awaken_t := 99.0
var ambient_timer := 0.0
var reaction_label_cd := 0.0
var snow: Array = []
var snow_timer := 0.0
var heat_timer := 0.0

var draw_time := 0.0
var low_end := false
var sand_scale := 4
var texture_interval := 1.0 / 45.0
var texture_timer := 0.0
var visual_style := 0
var awaken_style_counter := 0
const STYLE_NAMES := ["КЛАССИКА", "ГЛЯНЕЦ", "НЕОН"]

const SAND_FADE_TIME := 0.35
const CELL_TEX_SIZE := 96
var cell_tex_size := CELL_TEX_SIZE
var cell_textures := {}
var beam_texture: ImageTexture
var sand_image: Image
var sand_scaled_image: Image
var sand_texture: ImageTexture
var sand_version := -1
var sand_active := false
var sand_showing := false
var sand_fade := 0.0
var _sand_base: Array[Color] = []
var _sand_light: Array[Color] = []
var _sand_dark: Array[Color] = []
var _obsidian_label_at := -10.0

var _box := StyleBoxFlat.new()
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	low_end = QualitySettings.low_end
	sand_scale = QualitySettings.sand_scale
	cell_tex_size = 64 if low_end else CELL_TEX_SIZE
	texture_interval = 1.0 / maxf(1.0, QualitySettings.texture_fps)
	_rng.randomize()
	_box.anti_aliasing = true
	_build_sand_colors()
	_build_cell_textures()
	_build_beam_texture()
	set_process(true)


func set_game(value: ElementGame) -> void:
	if game != null and game.game_event.is_connected(_on_game_event):
		game.game_event.disconnect(_on_game_event)
	game = value
	if game != null:
		rows = game.rows
		cols = game.cols
	if game != null and not game.game_event.is_connected(_on_game_event):
		game.game_event.connect(_on_game_event)
	queue_redraw()


func clear_fx() -> void:
	particles.clear()
	texts.clear()
	rings.clear()
	beams.clear()
	shake = 0.0
	flash = 0.0
	flash_color = Color(1, 1, 1)
	awaken_t = 99.0
	ambient_timer = 0.0
	reaction_label_cd = 0.0
	snow.clear()
	snow_timer = 0.0
	heat_timer = 0.0
	sand_fade = 0.0
	sand_active = false
	sand_showing = false
	sand_version = -1
	_obsidian_label_at = -10.0
	reset_interaction()


func reset_interaction() -> void:
	drag = {}
	selected = -1
	ghost = {}
	hover_ghost = {}
	queue_redraw()


# ---------------------------------------------------------------------------
# Layout
# ---------------------------------------------------------------------------

func _calc_layout() -> void:
	var w := size.x
	var h := size.y
	if w < 12.0 or h < 12.0:
		return
	cell_gap = w * 0.001
	cell_size = (w - cell_gap * (cols - 1.0)) / float(cols)
	var board_w := cell_size * cols + cell_gap * (cols - 1.0)
	var board_h := cell_size * rows + cell_gap * (rows - 1.0)
	mini = cell_size * 0.56
	var tray_height := mini * 4.0 + cell_size * 0.10
	var tray_gap := w * 0.032
	var total_height := board_h + tray_gap + tray_height

	if total_height > h:
		var factor := h / total_height
		cell_size *= factor
		cell_gap *= factor
		board_w *= factor
		board_h *= factor
		mini *= factor
		tray_height *= factor
		tray_gap *= factor
		total_height = h

	var ox := (w - board_w) * 0.5
	var oy := (h - total_height) * 0.5
	board_origin = Vector2(ox, oy)
	board_rect = Rect2(ox, oy, board_w, board_h)
	tray_rect = Rect2(ox, oy + board_h + tray_gap, board_w, tray_height)


func _cell_pos(r: int, c: int) -> Vector2:
	var step := cell_size + cell_gap
	return board_origin + Vector2(c * step, r * step)


func _cell_center(r: int, c: int) -> Vector2:
	return _cell_pos(r, c) + Vector2(cell_size, cell_size) * 0.5


func _piece_rect(index: int) -> Rect2:
	if game == null or index < 0 or index >= game.pieces.size():
		return Rect2()
	var shape: Dictionary = game.pieces[index]["shape"]
	var slot_width := tray_rect.size.x / 3.0
	var center := Vector2(
		tray_rect.position.x + slot_width * (index + 0.5),
		tray_rect.position.y + tray_rect.size.y * 0.5
	)
	var piece_size := Vector2(float(shape["w"]) * mini, float(shape["h"]) * mini)
	return Rect2(center - piece_size * 0.5, piece_size)


# ---------------------------------------------------------------------------
# Drawing
# ---------------------------------------------------------------------------

func _draw() -> void:
	if game == null:
		return
	_calc_layout()
	draw_time = _now()

	var offset := Vector2.ZERO
	if shake > 0.02:
		offset = Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * shake
	draw_set_transform(offset, 0.0, Vector2.ONE)

	_draw_board()
	_draw_beams()
	_draw_rings()
	_draw_temperature_overlay()
	_draw_snow()
	_draw_tray()
	_draw_ghost()
	_draw_dragged_piece()
	_draw_particles()
	_draw_texts()

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_awakening_aura()

	if flash > 0.01:
		draw_rect(Rect2(Vector2.ZERO, size),
			Color(flash_color.r, flash_color.g, flash_color.b, 0.10 * flash))


func _draw_board() -> void:
	var accent := _temp_accent()
	var panel := board_rect.grow(cell_gap * 0.85)
	_round_rect(panel, cell_size * 0.16, ThemeKit.board_panel(accent),
		ThemeKit.board_border(), 1)

	for r in rows:
		for c in cols:
			var rect := Rect2(_cell_pos(r, c), Vector2(cell_size, cell_size))
			_round_rect(rect, cell_size * 0.06, ThemeKit.board_cell(accent))
			_round_rect(rect.grow(-cell_size * 0.045), cell_size * 0.05,
				ThemeKit.board_cell_inner())
			if not sand_active:
				var cell = game.board[r][c]
				if cell != null:
					_draw_cell(rect, cell, r, c)

	if sand_showing and sand_texture != null:
		var sand_alpha := 1.0
		if not sand_active:
			sand_alpha = clampf(sand_fade / SAND_FADE_TIME, 0.0, 1.0)
		if sand_alpha > 0.0:
			draw_texture_rect(sand_texture, board_rect, false, Color(1, 1, 1, sand_alpha))


func _build_sand_colors() -> void:
	_sand_base.resize(SandSim.TYPE_COUNT)
	_sand_light.resize(SandSim.TYPE_COUNT)
	_sand_dark.resize(SandSim.TYPE_COUNT)
	for type in range(1, SandSim.TYPE_COUNT):
		var element_name := str(SandSim.TYPE_NAMES[type])
		var palette: Dictionary = PALETTE[element_name]
		_sand_base[type] = palette["base"]
		_sand_light[type] = palette["light"]
		_sand_dark[type] = palette["dark"]


func _build_beam_texture() -> void:
	var width := 32
	var height := 128
	var buffer := PackedByteArray()
	buffer.resize(width * height * 4)
	for y in height:
		var v := float(y) / float(height - 1)
		var vertical := pow(1.0 - v, 1.6)
		for x in width:
			var u := (float(x) + 0.5) / float(width)
			var horizontal := pow(maxf(0.0, 1.0 - absf(u - 0.5) * 2.0), 2.2)
			var alpha := vertical * horizontal
			var offset := (y * width + x) * 4
			buffer[offset] = 255
			buffer[offset + 1] = 255
			buffer[offset + 2] = 255
			buffer[offset + 3] = int(clampf(alpha, 0.0, 1.0) * 255.0)
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.set_data(width, height, false, Image.FORMAT_RGBA8, buffer)
	beam_texture = ImageTexture.create_from_image(image)


func _build_cell_textures() -> void:
	for element in ["stone", "sand", "water", "lava", "acid", "ice", "obsidian",
			"fire", "oil", "plant", "gunpowder", "glass",
			"seaweed", "sponge", "coal", "ash", "snow", "crystal", "spore", "flower",
			"iron", "copper", "gold", "silver", "lead", "tin", "mercury", "titanium",
			"mushroom", "moss", "vine", "pollen", "slime", "bone", "shell", "fungus"]:
		var variants: Array = []
		var variants_count := 2 if low_end else 3
		for variant in variants_count:
			variants.append(_make_cell_texture(element, variant))
		cell_textures[element] = variants


func _make_cell_texture(element: String, variant: int) -> ImageTexture:
	var size := cell_tex_size
	var el: Dictionary = PALETTE[element]
	var light: Color = el["light"]
	var base: Color = el["base"]
	var dark: Color = el["dark"]
	var buffer := PackedByteArray()
	buffer.resize(size * size * 4)
	var radius := 0.06
	var inv := 1.0 / float(size)
	var white := Color(1, 1, 1)

	for py in size:
		var v := (float(py) + 0.5) * inv
		for px in size:
			var u := (float(px) + 0.5) * inv
			var qx := absf(u - 0.5) - (0.5 - radius)
			var qy := absf(v - 0.5) - (0.5 - radius)
			var dist := Vector2(maxf(qx, 0.0), maxf(qy, 0.0)).length() + minf(maxf(qx, qy), 0.0) - radius
			var coverage := clampf(0.5 - dist * float(size), 0.0, 1.0)
			if coverage <= 0.0:
				continue

			var gradient_t := clampf((v - 0.04) / 0.92, 0.0, 1.0)
			var color: Color
			if gradient_t < 0.34:
				color = light.lerp(base, gradient_t / 0.34)
			else:
				color = base.lerp(dark, (gradient_t - 0.34) / 0.66)

			var gloss_d := Vector2(u - 0.33, v - 0.24).length()
			var gloss := clampf(1.0 - gloss_d / 0.42, 0.0, 1.0)
			color = color.lerp(white, gloss * gloss * 0.22)

			if v < 0.10:
				color = color.lerp(white, (1.0 - v / 0.10) * 0.17)
			if v > 0.88:
				color = color.lerp(Color(0, 0, 0), (v - 0.88) / 0.12 * 0.20)
			if u < 0.06:
				color = color.lerp(white, (1.0 - u / 0.06) * 0.07)
			if u > 0.94:
				color = color.lerp(Color(0, 0, 0), (u - 0.94) / 0.06 * 0.09)

			var rim := clampf((dist + 0.018) * float(size) * 0.5, 0.0, 1.0)
			color = color.lerp(white, rim * 0.16)
			color = _apply_cell_pattern(element, color, u, v, px, py, variant)

			var offset := (py * size + px) * 4
			buffer[offset] = int(clampf(color.r, 0.0, 1.0) * 255.0)
			buffer[offset + 1] = int(clampf(color.g, 0.0, 1.0) * 255.0)
			buffer[offset + 2] = int(clampf(color.b, 0.0, 1.0) * 255.0)
			buffer[offset + 3] = int(clampf(coverage, 0.0, 1.0) * 255.0)

	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.set_data(size, size, false, Image.FORMAT_RGBA8, buffer)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


func _apply_cell_pattern(element: String, color: Color, u: float, v: float,
		px: int, py: int, variant: int) -> Color:
	var offset := float(variant) * 0.018
	match element:
		"stone":
			if Vector2(u - (0.31 + offset), v - (0.42 - offset)).length() < 0.033:
				color = color.darkened(0.15)
			if Vector2(u - (0.63 - offset), v - (0.57 + offset)).length() < 0.028:
				color = color.darkened(0.12)
			if Vector2(u - (0.45 + offset * 0.5), v - (0.74 - offset * 0.5)).length() < 0.024:
				color = color.darkened(0.10)
			if Vector2(u - (0.70 - offset), v - (0.30 + offset)).length() < 0.020:
				color = color.lightened(0.10)
		"sand":
			var noise := sin(float(px) * 12.9898 + float(py) * 78.233 + float(variant) * 17.17) * 43758.5453
			noise = noise - floor(noise)
			if noise > 0.87:
				color = color.darkened(0.06)
			elif noise < 0.10:
				color = color.lightened(0.05)
		"water":
			var wave_one := 0.61 + 0.045 * sin(u * 9.0 + 0.8 + float(variant) * 1.4)
			if absf(v - wave_one) < 0.016:
				color = color.lerp(Color.WHITE, 0.26)
			var wave_two := 0.78 + 0.030 * sin(u * 12.0 + 2.1 + float(variant) * 2.2)
			if absf(v - wave_two) < 0.012:
				color = color.lerp(Color.WHITE, 0.15)
		"lava":
			var vein := absf(sin(u * 9.0 + sin(v * 7.0) * 2.2 + float(variant) * 0.8))
			if vein > 0.95:
				color = color.lerp(Color(1.0, 0.85, 0.45), 0.55)
			var blob_one := Vector2(u - (0.34 + offset), v - (0.63 - offset)).length()
			if blob_one < 0.070:
				color = color.lerp(Color(1.0, 0.88, 0.50), (1.0 - blob_one / 0.070) * 0.45)
			var blob_two := Vector2(u - (0.66 - offset), v - (0.44 + offset)).length()
			if blob_two < 0.055:
				color = color.lerp(Color(1.0, 0.88, 0.50), (1.0 - blob_two / 0.055) * 0.35)
		"acid":
			var bubble_one := Vector2(u - (0.34 + offset), v - (0.62 - offset)).length()
			var bubble_two := Vector2(u - (0.63 - offset), v - (0.38 + offset)).length()
			var bubble_three := Vector2(u - (0.57 + offset * 0.5), v - (0.74 - offset * 0.5)).length()
			if absf(bubble_one - 0.042) < 0.010:
				color = color.lerp(Color.WHITE, 0.35)
			if absf(bubble_two - 0.032) < 0.009:
				color = color.lerp(Color.WHITE, 0.30)
			if absf(bubble_three - 0.024) < 0.007:
				color = color.lerp(Color.WHITE, 0.28)
		"ice":
			if absf((u + v) - (0.92 + float(variant) * 0.02)) < 0.012 \
					or absf((u - v) + (0.18 - float(variant) * 0.02)) < 0.009:
				color = color.lerp(Color.WHITE, 0.28)
		"obsidian":
			var star_x := absf(u - (0.63 + offset * 0.6))
			var star_y := absf(v - (0.33 - offset * 0.6))
			if (star_x < 0.010 and star_y < 0.075) or (star_y < 0.010 and star_x < 0.075):
				color = color.lerp(Color(0.96, 0.90, 1.0), 0.60)
		"fire":
			var flame := absf(sin(u * 11.0 + sin(v * 8.0) * 2.4 + float(variant) * 0.9))
			if flame > 0.86:
				color = color.lerp(Color(1.0, 0.92, 0.45), 0.55)
			var core := Vector2(u - (0.35 + offset), v - (0.72 - offset)).length()
			if core < 0.12:
				color = color.lerp(Color(1.0, 0.96, 0.65), (1.0 - core / 0.12) * 0.45)
		"oil":
			var swirl := sin(u * 7.0 + v * 9.0 + float(variant) * 1.3)
			if swirl > 0.75:
				color = color.lightened(0.08)
			elif swirl < -0.80:
				color = color.darkened(0.08)
			if absf((u + v) - 0.5) < 0.025:
				color = color.lerp(Color(0.55, 0.40, 0.80, 0.35), 0.18)
		"plant":
			if absf(u - 0.5) < 0.014:
				color = color.lerp(Color(0.75, 1.0, 0.55), 0.28)
			var leaf := absf(v - (0.34 + 0.22 * sin(u * 10.0 + float(variant))))
			if leaf < 0.012:
				color = color.lerp(Color(0.70, 1.0, 0.50), 0.22)
		"gunpowder":
			if Vector2(u - (0.27 + offset), v - 0.33).length() < 0.020 \
					or Vector2(u - (0.66 - offset), v - 0.57).length() < 0.018 \
					or Vector2(u - (0.44 + offset), v - 0.72).length() < 0.016 \
					or Vector2(u - (0.74 - offset), v - 0.27).length() < 0.014:
				color = color.lerp(Color(1.0, 0.52, 0.18), 0.62)
			var grain := sin(float(px) * 9.7 + float(py) * 5.3) * 0.5 + 0.5
			if grain > 0.82:
				color = color.darkened(0.08)
		"glass":
			if absf((u + v) - (0.78 + offset)) < 0.011 \
					or absf((u - v) + (0.24 - offset)) < 0.008:
				color = color.lerp(Color.WHITE, 0.42)
		"seaweed":
			var strand := absf(u - (0.5 + 0.10 * sin(v * 13.0 + float(variant) * 1.7)))
			if strand < 0.020:
				color = color.lerp(Color(0.75, 1.0, 0.60), 0.35)
			var leaf := absf(v - (0.40 + 0.12 * sin(u * 12.0 + float(variant))))
			if leaf < 0.011:
				color = color.lerp(Color(0.60, 1.0, 0.55), 0.22)
		"sponge":
			var hole_a := Vector2(u - (0.32 + offset), v - (0.38 - offset)).length()
			var hole_b := Vector2(u - (0.66 - offset), v - (0.58 + offset)).length()
			var hole_c := Vector2(u - (0.45 + offset * 0.4), v - (0.74 - offset * 0.4)).length()
			if hole_a < 0.070 or hole_b < 0.055 or hole_c < 0.040:
				color = color.darkened(0.22)
			if absf(hole_a - 0.080) < 0.010 or absf(hole_b - 0.065) < 0.009:
				color = color.lightened(0.10)
		"coal":
			var facet := sin(u * 11.0 + v * 7.0 + float(variant) * 2.1)
			if facet > 0.75:
				color = color.lightened(0.10)
			elif facet < -0.82:
				color = color.darkened(0.10)
			if Vector2(u - (0.37 + offset), v - (0.62 - offset)).length() < 0.030:
				color = color.lerp(Color(1.0, 0.55, 0.18), 0.22)
		"ash":
			var grain := sin(float(px) * 17.3 + float(py) * 9.1 + float(variant)) * 0.5 + 0.5
			if grain > 0.86:
				color = color.lightened(0.10)
			elif grain < 0.12:
				color = color.darkened(0.08)
		"snow":
			var glint := sin(float(px) * 21.0 + float(py) * 13.0 + float(variant) * 2.0) * 0.5 + 0.5
			if glint > 0.92:
				color = color.lerp(Color.WHITE, 0.55)
			elif glint < 0.08:
				color = color.lerp(Color(0.55, 0.75, 0.90), 0.22)
		"crystal":
			if absf((u + v) - (0.62 + offset)) < 0.014 \
					or absf((u - v) + (0.10 - offset)) < 0.010 \
					or absf(u - 0.50) < 0.008:
				color = color.lerp(Color.WHITE, 0.45)
			if Vector2(u - 0.5, v - 0.5).length() < 0.065:
				color = color.lerp(Color.WHITE, 0.35)
		"spore":
			var dot_a := Vector2(u - (0.32 + offset), v - (0.36 - offset)).length()
			var dot_b := Vector2(u - (0.68 - offset), v - (0.54 + offset)).length()
			var dot_c := Vector2(u - (0.48 + offset), v - (0.70 - offset)).length()
			if dot_a < 0.028 or dot_b < 0.024 or dot_c < 0.020:
				color = color.lerp(Color(0.92, 1.0, 0.55), 0.55)
		"flower":
			var center := Vector2(u - 0.5, v - 0.5)
			for k in 5:
				var angle := float(k) * TAU / 5.0 + float(variant) * 0.35
				var petal := Vector2(0.5 + cos(angle) * 0.18, 0.5 + sin(angle) * 0.18)
				if Vector2(u, v).distance_to(petal) < 0.095:
					color = color.lerp(Color(1.0, 0.78, 0.90), 0.38)
			if center.length() < 0.055:
				color = color.lerp(Color(1.0, 0.95, 0.55), 0.65)
		"iron", "copper", "gold", "silver", "lead", "tin", "titanium":
			var brushed := sin((u * 18.0 + v * 5.0 + float(variant) * 2.0) * PI)
			if brushed > 0.82:
				color = color.lightened(0.12)
			elif brushed < -0.84:
				color = color.darkened(0.08)
			if absf((u + v) - 0.68) < 0.010:
				color = color.lerp(Color.WHITE, 0.30)
		"mercury":
			var wave := absf(v - (0.5 + 0.05 * sin(u * 9.0 + float(variant))))
			if wave < 0.018:
				color = color.lerp(Color.WHITE, 0.36)
		"mushroom":
			var cap := Vector2(u - 0.5, v - 0.38).length()
			if cap < 0.20:
				color = color.lerp(Color(1.0, 0.75, 0.65), 0.20)
			if Vector2(u - (0.34 + offset), v - 0.34).length() < 0.025 \
					or Vector2(u - (0.64 - offset), v - 0.40).length() < 0.020:
				color = color.lightened(0.18)
			if absf(u - 0.5) < 0.018 and v > 0.55:
				color = color.darkened(0.18)
		"moss", "vine", "fungus":
			var strand := absf(u - (0.5 + 0.12 * sin(v * 10.0 + float(variant))))
			if strand < 0.018 and (v + float(variant) * 0.2) < 0.84:
				color = color.lerp(Color(0.75, 1.0, 0.55), 0.30)
			if Vector2(u - (0.28 + offset), v - 0.62).length() < 0.030 \
					or Vector2(u - (0.70 - offset), v - 0.38).length() < 0.026:
				color = color.lightened(0.10)
		"pollen":
			if Vector2(u - (0.32 + offset), v - 0.38).length() < 0.028 \
					or Vector2(u - (0.66 - offset), v - 0.56).length() < 0.024 \
					or Vector2(u - (0.46 + offset), v - 0.72).length() < 0.020:
				color = color.lerp(Color(1.0, 1.0, 0.7), 0.55)
		"slime":
			var bubble := Vector2(u - (0.36 + offset), v - (0.60 - offset)).length()
			if absf(bubble - 0.05) < 0.012:
				color = color.lerp(Color.WHITE, 0.28)
			var bubble2 := Vector2(u - (0.66 - offset), v - (0.36 + offset)).length()
			if bubble2 < 0.035:
				color = color.darkened(0.10)
		"bone":
			if absf((u + v) - (0.52 + offset)) < 0.012 \
					or absf((u - v) + (0.16 - offset)) < 0.010:
				color = color.lerp(Color.WHITE, 0.32)
		"shell":
			var ring := Vector2(u - 0.5, v - 0.5).length()
			if absf(ring - 0.17) < 0.012 or absf(ring - 0.28) < 0.010:
				color = color.lerp(Color.WHITE, 0.32)
	return color


func _build_sand_texture() -> void:
	if game == null or game.sand == null:
		return
	var sim: SandSim = game.sand
	var w := sim.w
	var h := sim.h
	var grid := sim.grid
	var buffer := PackedByteArray()
	buffer.resize(w * h * 4)
	var tick := sim.tick

	for y in h:
		var row := y * w
		var above_row := row - w
		for x in w:
			var i := row + x
			var type := int(grid[i])
			if type == SandSim.EMPTY:
				continue

			var color: Color = _sand_base[type]
			if type == SandSim.STEAM:
				color = _sand_light[type].lerp(_temp_accent(), 0.30)
				color.a = 0.60
			elif type == SandSim.SMOKE:
				color = _sand_base[type]
				color.a = 0.58
			elif type == SandSim.SPORE:
				color = _sand_light[type]
				color.a = 0.72
			elif y > 0 and int(grid[above_row + x]) == SandSim.EMPTY:
				color = _sand_light[type]

			if type == SandSim.WATER or type == SandSim.LAVA \
					or type == SandSim.ACID or type == SandSim.OIL:
				var shimmer := (x * 3 + y * 5 + tick) % 19
				if shimmer == 0:
					color = color.lightened(0.10)
				elif shimmer == 1:
					color = color.darkened(0.05)
			elif type == SandSim.FIRE:
				var flicker := 0.5 + 0.5 * sin(tick * 0.8 + x * 0.9 + y * 0.5)
				color = color.lerp(_sand_light[type], 0.2 + flicker * 0.55)
			elif type == SandSim.GUNPOWDER:
				if (x * 7 + y * 11 + tick) % 17 == 0:
					color = Color(1.0, 0.55, 0.20)
				elif (x * 5 + y * 3) % 13 == 0:
					color = color.darkened(0.05)
			elif type == SandSim.GLASS:
				if (x + y + tick) % 23 == 0:
					color = Color(0.95, 1.0, 1.0)
			elif type != SandSim.STEAM and type != SandSim.SMOKE:
				var grain := (x * 7 + y * 3) % 13
				if grain == 0:
					color = color.darkened(0.04)

			if game != null:
				if game.temperature >= 2:
					if type == SandSim.STONE:
						color = color.lerp(Color(1.0, 0.55, 0.22), 0.16)
					else:
						color = color.lerp(Color(1.0, 0.55, 0.20), 0.07)
				elif game.temperature <= -2:
					if type == SandSim.WATER or type == SandSim.ICE:
						color = color.lerp(Color(0.55, 0.85, 1.0), 0.11)
					else:
						color = color.lerp(Color(0.55, 0.82, 1.0), 0.06)

			var offset := i * 4
			buffer[offset] = int(clampf(color.r, 0.0, 1.0) * 255.0)
			buffer[offset + 1] = int(clampf(color.g, 0.0, 1.0) * 255.0)
			buffer[offset + 2] = int(clampf(color.b, 0.0, 1.0) * 255.0)
			buffer[offset + 3] = int(clampf(color.a, 0.0, 1.0) * 255.0)

	if sand_image == null:
		sand_image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	sand_image.set_data(w, h, false, Image.FORMAT_RGBA8, buffer)

	# Upscale with nearest so the fluid still reads as chunky sand under
	# the linear filtering used by the nicer cell sprites.
	var scaled := w * sand_scale
	if sand_scaled_image == null:
		sand_scaled_image = Image.create(scaled, scaled, false, Image.FORMAT_RGBA8)
	sand_scaled_image.copy_from(sand_image)
	sand_scaled_image.resize(scaled, scaled, Image.INTERPOLATE_NEAREST)
	if sand_texture == null:
		sand_texture = ImageTexture.create_from_image(sand_scaled_image)
	else:
		sand_texture.update(sand_scaled_image)
	sand_version = sim.version


func _cell_texture(element: String, r: int, c: int) -> Texture2D:
	var variants = cell_textures.get(element)
	if variants == null or variants.is_empty():
		return null
	return variants[(r * 7 + c * 13) % variants.size()]


func _sand_position(x: int, y: int) -> Vector2:
	var unit := Vector2(
		board_rect.size.x / float(game.sand.w),
		board_rect.size.y / float(game.sand.h)
	)
	return board_rect.position + (Vector2(x, y) + Vector2(0.5, 0.5)) * unit


func _draw_cell(rect: Rect2, cell: Dictionary, r: int, c: int, mini_mode := false) -> void:
	var element: String = cell.get("t", "stone")
	var el: Dictionary = PALETTE.get(element, PALETTE["stone"])
	var born := float(cell.get("born", -100.0))
	var age := draw_time - born
	if age < 0.0:
		return
	var pop := 1.0
	if age < 0.24:
		pop = _ease_out_back(clampf(age / 0.24, 0.0, 1.0))

	var cell_px := rect.size.x * pop
	var center := rect.get_center()
	var rr := Rect2(center - Vector2(cell_px, cell_px) * 0.5, Vector2(cell_px, cell_px))
	var radius := cell_px * 0.06

	if game != null and game.temperature >= 2 and element == "stone":
		_round_rect(rr.grow(cell_px * 0.06), radius * 1.20,
			Color(1.0, 0.42, 0.12, 0.12))

	if not mini_mode and not low_end:
		var glow: Color = el["glow"]
		if glow.a > 0.001:
			var pulse := 1.0
			if element == "lava":
				pulse = 0.80 + 0.20 * sin(draw_time * 3.2 + r * 0.8 + c * 0.6)
			_round_rect(rr.grow(cell_px * 0.055), radius * 1.18,
				_alpha(glow, glow.a * 0.55 * pulse))

	_round_rect(Rect2(rr.position + Vector2(0.0, cell_px * 0.06), rr.size), radius,
		Color(0, 0, 0, 0.20 if mini_mode else 0.28))

	var texture := _cell_texture(element, r, c)
	if texture != null:
		var tint := 1.0
		if element != "water" and element != "ice" and element != "acid":
			tint = 0.96 + 0.08 * _hash01(r, c, 3)
		var tint_color := Color(tint, tint, tint, 1.0)
		if game != null and game.temperature >= 2 and element == "stone":
			tint_color = Color(1.14, 0.93, 0.80, 1.0)
		elif game != null and game.temperature <= -2 \
				and (element == "water" or element == "ice"):
			tint_color = Color(0.82, 0.93, 1.10, 1.0)
		if visual_style == 1:
			tint_color = Color(tint_color.r * 1.06, tint_color.g * 1.06,
				tint_color.b * 1.06, 1.0)
		elif visual_style == 2:
			tint_color = Color(tint_color.r * 0.93, tint_color.g * 0.98,
				tint_color.b * 1.10, 1.0)
		draw_texture_rect(texture, rr, false, tint_color)
	else:
		_round_rect(rr, radius, el["base"])

	if visual_style == 1:
		var gloss_start := rr.position + Vector2(rr.size.x * 0.10, rr.size.y * 0.34)
		var gloss_end := rr.position + Vector2(rr.size.x * 0.78, rr.size.y * 0.06)
		draw_line(gloss_start, gloss_end, Color(1, 1, 1, 0.16),
			maxf(1.0, cell_px * 0.085), true)
		draw_line(gloss_start + Vector2(0, cell_px * 0.10),
			gloss_end + Vector2(0, cell_px * 0.10),
			Color(1, 1, 1, 0.07), maxf(1.0, cell_px * 0.035), true)
	elif visual_style == 2:
		var neon: Color = el["light"]
		neon.a = 0.62 if not mini_mode else 0.45
		_round_outline(rr.grow(-cell_px * 0.012), radius, neon,
			maxf(1.5, cell_px * 0.026))

	var flash_at := float(cell.get("flash", 0.0))
	if flash_at > 0.0:
		var fa := clampf(1.0 - (draw_time - flash_at) / 0.34, 0.0, 1.0)
		if fa > 0.0:
			_round_rect(rr, radius, Color(1, 1, 1, 0.55 * fa))


func _draw_pattern(element: String, rect: Rect2, r: int, c: int) -> void:
	var s := rect.size.x
	var px := rect.position.x
	var py := rect.position.y

	match element:
		"stone":
			for i in 3:
				var x := px + s * (0.22 + 0.56 * _hash01(r, c, i + 10))
				var y := py + s * (0.24 + 0.52 * _hash01(r, c, i + 20))
				draw_circle(Vector2(x, y), s * 0.034, Color(0, 0, 0, 0.18))
			draw_circle(Vector2(px + s * 0.38, py + s * 0.44), s * 0.021, Color(1, 1, 1, 0.18))
		"sand":
			for i in 5:
				var x := px + s * (0.18 + 0.64 * _hash01(r, c, i + 30))
				var y := py + s * (0.28 + 0.52 * _hash01(r, c, i + 40))
				draw_circle(Vector2(x, y), s * 0.017, Color(0.35, 0.22, 0.08, 0.35))
		"water":
			for k in 2:
				var points := PackedVector2Array()
				for i in 5:
					var x := px + s * (0.16 + 0.17 * i)
					var y := py + s * (0.56 + 0.17 * k) + sin(draw_time * 2.2 + i * 0.9 + c + k) * s * 0.022
					points.append(Vector2(x, y))
				draw_polyline(points, Color(1, 1, 1, 0.20), maxf(1.0, s * 0.025), true)
		"lava":
			for i in 2:
				var x := px + s * (0.30 + 0.34 * i)
				var y := py + s * (0.62 - 0.14 * i) + sin(draw_time * 2.4 + i * 1.7 + r) * s * 0.03
				draw_circle(Vector2(x, y), s * 0.07, Color(1.0, 0.78, 0.34, 0.50))
				draw_circle(Vector2(x - s * 0.01, y - s * 0.012), s * 0.034, Color(1.0, 0.95, 0.70, 0.65))
		"acid":
			for i in 3:
				var x := px + s * (0.28 + 0.20 * i)
				var y := py + s * (0.50 + 0.12 * sin(draw_time * 2.0 + i + c))
				draw_arc(Vector2(x, y), s * (0.045 + 0.014 * i), 0.0, TAU, 14,
					Color(1, 1, 1, 0.22), maxf(1.0, s * 0.018), true)
		"ice":
			draw_line(Vector2(px + s * 0.22, py + s * 0.78), Vector2(px + s * 0.66, py + s * 0.20),
				Color(1, 1, 1, 0.22), maxf(1.0, s * 0.026), true)
			draw_line(Vector2(px + s * 0.34, py + s * 0.84), Vector2(px + s * 0.78, py + s * 0.28),
				Color(1, 1, 1, 0.12), maxf(1.0, s * 0.020), true)
		"obsidian":
			var x := px + s * 0.60
			var y := py + s * 0.35
			var arm := s * 0.09 * (0.8 + 0.2 * sin(draw_time * 3.0 + r + c))
			draw_line(Vector2(x - arm, y), Vector2(x + arm, y),
				Color(0.85, 0.75, 1.0, 0.60), maxf(1.0, s * 0.018), true)
			draw_line(Vector2(x, y - arm), Vector2(x, y + arm),
				Color(0.85, 0.75, 1.0, 0.60), maxf(1.0, s * 0.018), true)
		"steam":
			draw_circle(Vector2(px + s * 0.42, py + s * 0.46), s * 0.13, Color(1, 1, 1, 0.13))
			draw_circle(Vector2(px + s * 0.62, py + s * 0.62), s * 0.09, Color(1, 1, 1, 0.10))


func _draw_tray() -> void:
	var accent := _temp_accent()
	_round_rect(tray_rect, cell_size * 0.15, ThemeKit.board_panel(accent),
		ThemeKit.board_border(), 1)

	var slot_width := tray_rect.size.x / 3.0
	for i in 3:
		var well := Rect2(
			tray_rect.position.x + i * slot_width + cell_gap,
			tray_rect.position.y + cell_gap,
			slot_width - cell_gap * 2.0,
			tray_rect.size.y - cell_gap * 2.0
		)
		_round_rect(well, mini * 0.42, ThemeKit.board_cell(accent))
		_round_rect(well.grow(-mini * 0.09), mini * 0.36, ThemeKit.board_cell_inner())

	if game.pieces.is_empty():
		return

	for i in game.pieces.size():
		var piece: Dictionary = game.pieces[i]
		if bool(piece["used"]):
			continue
		if not drag.is_empty() and int(drag["index"]) == i:
			continue

		var rect := _piece_rect(i)
		if selected == i:
			var lift := mini * 0.18 + sin(draw_time * 4.0) * mini * 0.035
			rect.position.y -= lift
			_round_rect(rect.grow(mini * 0.20), mini * 0.30, Color(0.35, 0.68, 1.0, 0.10))
		else:
			rect.position.y += sin(draw_time * 2.2 + i * 1.25) * mini * 0.03
		_draw_piece(piece, rect.position, mini)


func _draw_piece(piece: Dictionary, origin: Vector2, unit: float) -> void:
	var shape: Dictionary = piece["shape"]
	var element: String = piece["element"]
	for offset in shape["cells"]:
		var rect := Rect2(
			origin + Vector2(offset.y, offset.x) * unit + Vector2(unit * 0.007, unit * 0.007),
			Vector2(unit * 0.986, unit * 0.986)
		)
		_draw_cell(rect, {"t": element, "born": -999.0, "flash": 0.0}, offset.x + 1, offset.y + 2, true)


func _draw_ghost() -> void:
	var active := ghost
	if active.is_empty():
		active = hover_ghost
	if active.is_empty():
		return
	var index := int(active.get("index", -1))
	if index < 0 or index >= game.pieces.size():
		return
	var piece: Dictionary = game.pieces[index]
	if bool(piece["used"]):
		return

	var shape: Dictionary = piece["shape"]
	var valid := bool(active["valid"])
	var ghost_color: Color = PALETTE[piece["element"]]["base"]
	ghost_color.a = 0.34 if valid else 0.22
	var modulate := Color(1, 1, 1, 0.38) if valid else Color(1.0, 0.45, 0.45, 0.38)
	var outline := Color(0.15, 0.22, 0.40, 0.65) if ThemeKit.is_light() \
		else Color(1, 1, 1, 0.55)
	if not valid:
		outline = Color(0.85, 0.20, 0.28, 0.85)

	for offset in shape["cells"]:
		var r: int = int(active["r"]) + offset.x
		var c: int = int(active["c"]) + offset.y
		if r < 0 or r >= rows or c < 0 or c >= cols:
			continue
		var rect := Rect2(_cell_pos(r, c), Vector2(cell_size, cell_size))
		var texture := _cell_texture(piece["element"], r, c)
		if texture != null:
			draw_texture_rect(texture, rect, false, modulate)
		else:
			_round_rect(rect, cell_size * 0.06, ghost_color)
		_round_outline(rect, cell_size * 0.06, outline, 2.0)


func _draw_dragged_piece() -> void:
	if drag.is_empty():
		return
	var index := int(drag["index"])
	if index < 0 or index >= game.pieces.size():
		return
	var grab: Vector2i = drag["grab"]
	var unit := float(drag.get("unit", mini))
	var origin := mouse_pos - Vector2(grab) * unit - Vector2(unit, unit) * 0.5
	_draw_piece(game.pieces[index], origin, unit)


func _draw_particles() -> void:
	for p in particles:
		var life := float(p["life"])
		var max_life := float(p["max"])
		var alpha := clampf(life / max_life, 0.0, 1.0)
		var color: Color = p["color"]
		color.a *= alpha
		var size_px := float(p["size"]) * (0.45 + 0.55 * alpha)
		draw_circle(p["pos"], size_px, color)


func _draw_texts() -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	for entry in texts:
		var alpha := clampf(float(entry["life"]) / float(entry["max"]), 0.0, 1.0)
		var color: Color = entry["color"]
		color.a *= alpha
		var shadow := Color(0, 0, 0, 0.45 * alpha)
		var pos: Vector2 = entry["pos"]
		draw_string(font, pos + Vector2(1, 2), str(entry["text"]),
			HORIZONTAL_ALIGNMENT_CENTER, TEXT_WIDTH, int(entry["size"]), shadow)
		draw_string(font, pos, str(entry["text"]),
			HORIZONTAL_ALIGNMENT_CENTER, TEXT_WIDTH, int(entry["size"]), color)


func _draw_awakening_aura() -> void:
	if not sand_active and sand_fade <= 0.0:
		return
	var accent := _temp_accent()
	var cycle := 2.0
	var progress := fmod(awaken_t, cycle) / cycle
	var center := board_rect.get_center()
	var arc_count := 2 if low_end else 3
	for i in arc_count:
		var k := fmod(progress + i * 0.333, 1.0)
		var radius := board_rect.size.x * 0.44 * (0.35 + 0.75 * k)
		draw_arc(center, radius, 0.0, TAU, 72,
			Color(accent.r, accent.g, accent.b, (1.0 - k) * 0.18), 3.0, true)
	var pulse := 0.5 + 0.5 * sin(awaken_t * 4.0)
	_round_outline(board_rect.grow(cell_gap * 0.85), cell_size * 0.16,
		Color(accent.r, accent.g, accent.b, 0.18 + pulse * 0.14), 3.0)


# ---------------------------------------------------------------------------
# Helpers for drawing
# ---------------------------------------------------------------------------

func _round_rect(rect: Rect2, radius: float, color: Color,
		border_color := Color(0, 0, 0, 0), border_width := 0) -> void:
	var r := int(round(maxf(radius, 0.0)))
	var bw := int(round(maxf(border_width, 0.0)))
	_box.bg_color = color
	_box.corner_radius_top_left = r
	_box.corner_radius_top_right = r
	_box.corner_radius_bottom_right = r
	_box.corner_radius_bottom_left = r
	_box.border_width_left = bw
	_box.border_width_top = bw
	_box.border_width_right = bw
	_box.border_width_bottom = bw
	_box.border_color = border_color
	_box.shadow_size = 0
	draw_style_box(_box, rect)


func _round_outline(rect: Rect2, radius: float, color: Color, width: float) -> void:
	var r := int(round(maxf(radius, 0.0)))
	var bw := int(round(maxf(width, 1.0)))
	_box.bg_color = Color(0, 0, 0, 0)
	_box.corner_radius_top_left = r
	_box.corner_radius_top_right = r
	_box.corner_radius_bottom_right = r
	_box.corner_radius_bottom_left = r
	_box.border_width_left = bw
	_box.border_width_top = bw
	_box.border_width_right = bw
	_box.border_width_bottom = bw
	_box.border_color = color
	_box.shadow_size = 0
	draw_style_box(_box, rect)


func _alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)


func _hash01(a: int, b: int, i: int) -> float:
	var v := sin(float(a) * 12.9898 + float(b) * 78.233 + float(i) * 37.719) * 43758.5453
	return v - floor(v)


func _ease_out_back(t: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(t - 1.0, 3.0) + c1 * pow(t - 1.0, 2.0)


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if game == null or game.mode != "playing" or sand_fade > 0.0:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			mouse_pos = mb.position
			if mb.pressed:
				_press(mb.position)
			else:
				_release(mb.position)
			accept_event()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		mouse_pos = mm.position
		if not drag.is_empty():
			if mouse_pos.distance_to(drag["start"]) > 10.0:
				drag["moved"] = true
			_update_ghost()
			queue_redraw()
		elif selected >= 0:
			_update_hover_ghost()
			queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and drag.is_empty():
		hover_ghost = {}
		queue_redraw()


func _press(pos: Vector2) -> void:
	_calc_layout()
	var index := _piece_at(pos)
	if index >= 0:
		selected = index
		var piece: Dictionary = game.pieces[index]
		var shape: Dictionary = piece["shape"]
		var rect := _piece_rect(index)
		var gx := clampi(int((pos.x - rect.position.x) / mini), 0, int(shape["w"]) - 1)
		var gy := clampi(int((pos.y - rect.position.y) / mini), 0, int(shape["h"]) - 1)
		drag = {"index": index, "grab": Vector2i(gx, gy), "start": pos,
			"moved": false, "unit": mini}
		ghost = {}
		hover_ghost = {}
		piece_picked.emit()
	else:
		var cell_info := _cell_at(pos)
		if selected >= 0 and bool(cell_info["inside"]):
			_place_selected(cell_info)
	queue_redraw()


func _release(pos: Vector2) -> void:
	if drag.is_empty():
		return

	var index := int(drag["index"])
	var moved := bool(drag["moved"])
	var over := _over_board(pos)
	var placed := false

	if over:
		var target := _ghost_for(pos, drag)
		if not target.is_empty() and bool(target["valid"]):
			placed = game.place_at(index, int(target["r"]), int(target["c"]))
		if placed:
			selected = -1
		else:
			if selected < 0:
				selected = index
			if target.is_empty() or not bool(target["valid"]):
				invalid_attempt.emit()
	else:
		selected = index if not moved else -1

	drag = {}
	ghost = {}
	hover_ghost = {}
	queue_redraw()


func _place_selected(cell_info: Dictionary) -> void:
	if selected < 0 or selected >= game.pieces.size():
		return
	var piece: Dictionary = game.pieces[selected]
	if bool(piece["used"]):
		return
	var shape: Dictionary = piece["shape"]
	var h := int(shape["h"])
	var w := int(shape["w"])
	var r0 := clampi(int(cell_info["r"]) - int(h / 2.0), 0, rows - h)
	var c0 := clampi(int(cell_info["c"]) - int(w / 2.0), 0, cols - w)
	if game.can_place(shape, r0, c0):
		if game.place_at(selected, r0, c0):
			selected = -1
	else:
		invalid_attempt.emit()
	ghost = {}
	hover_ghost = {}
	queue_redraw()


func _update_ghost() -> void:
	if drag.is_empty():
		ghost = {}
		return
	if not _over_board(mouse_pos):
		ghost = {}
		return
	ghost = _ghost_for(mouse_pos, drag)


func _update_hover_ghost() -> void:
	hover_ghost = {}
	if drag.size() > 0 or selected < 0 or selected >= game.pieces.size():
		return
	if not _over_board(mouse_pos):
		return
	var cell_info := _cell_at(mouse_pos)
	if not bool(cell_info["inside"]):
		return
	var piece: Dictionary = game.pieces[selected]
	if bool(piece["used"]):
		return
	var shape: Dictionary = piece["shape"]
	var h := int(shape["h"])
	var w := int(shape["w"])
	var r0 := clampi(int(cell_info["r"]) - int(h / 2.0), 0, rows - h)
	var c0 := clampi(int(cell_info["c"]) - int(w / 2.0), 0, cols - w)
	hover_ghost = {
		"r": r0, "c": c0, "index": selected,
		"valid": game.can_place(shape, r0, c0),
	}


func _ghost_for(pos: Vector2, drag_state: Dictionary) -> Dictionary:
	var index := int(drag_state["index"])
	if index < 0 or index >= game.pieces.size():
		return {}
	var piece: Dictionary = game.pieces[index]
	if bool(piece["used"]):
		return {}
	var cell_info := _cell_at(pos)
	if not bool(cell_info["inside"]):
		return {}
	var shape: Dictionary = piece["shape"]
	var grab: Vector2i = drag_state["grab"]
	var h := int(shape["h"])
	var w := int(shape["w"])
	var r0 := clampi(int(cell_info["r"]) - grab.y, 0, rows - h)
	var c0 := clampi(int(cell_info["c"]) - grab.x, 0, cols - w)
	return {
		"r": r0, "c": c0, "index": index,
		"valid": game.can_place(shape, r0, c0),
	}


func _piece_at(pos: Vector2) -> int:
	if game == null:
		return -1
	for i in game.pieces.size():
		if bool(game.pieces[i]["used"]):
			continue
		if _piece_rect(i).grow(8.0).has_point(pos):
			return i
	return -1


func _over_board(pos: Vector2) -> bool:
	return board_rect.grow(cell_gap * 1.1).has_point(pos)


func _cell_at(pos: Vector2) -> Dictionary:
	var local := pos - board_origin
	var step := cell_size + cell_gap
	var c := int(floor(local.x / step))
	var r := int(floor(local.y / step))
	var inside := (
		local.x >= 0.0 and local.y >= 0.0
		and local.x < board_rect.size.x and local.y < board_rect.size.y
		and r >= 0 and r < rows and c >= 0 and c < cols
	)
	return {"r": r, "c": c, "inside": inside}


# ---------------------------------------------------------------------------
# Events, particles, popups
# ---------------------------------------------------------------------------

func _on_game_event(kind: String, data: Dictionary) -> void:
	match kind:
		"place":
			drag = {}
			selected = -1
			ghost = {}
			hover_ghost = {}
			var placed_cells: Array = data.get("cells", [])
			var placed_element := str(data.get("element", "stone"))
			var placed_center := Vector2.ZERO
			for cell in placed_cells:
				var pos := _cell_center(int(cell["r"]), int(cell["c"]))
				placed_center += pos
				_burst(pos, PALETTE[cell["t"]]["particle"], 4, 0.55)
			if not placed_cells.is_empty():
				placed_center /= placed_cells.size()
				_add_ring(placed_center, PALETTE[placed_element]["particle"],
					cell_size * 0.2, cell_size * 1.35, 0.35, 3.0)
				_add_text(placed_center - Vector2(0, cell_size * 0.25),
					"+%d" % placed_cells.size(), PALETTE[placed_element]["light"],
					cell_size * 0.30)
				shake = maxf(shake, 1.5)
		"clear":
			drag = {}
			selected = -1
			ghost = {}
			hover_ghost = {}
			var cells: Array = data.get("cells", [])
			if cells.is_empty():
				return
			var avg := Vector2.ZERO
			for cell in cells:
				var pos := _cell_center(int(cell["r"]), int(cell["c"]))
				avg += pos
				_burst(pos, PALETTE[cell["t"]]["particle"], 7, 1.0)
			avg /= cells.size()
			var lines := int(data.get("lines", 1))
			shake = maxf(shake, 11.0 + lines * 2.2)
			flash = 1.0
			flash_color = Color(0.55, 0.90, 1.0)
			_add_ring(avg, Color(0.65, 0.95, 1.0), cell_size * 0.4,
				board_rect.size.x * 0.42, 0.5, 4.5)
			_add_ring(avg, Color(1.0, 0.86, 0.40), cell_size * 0.25,
				board_rect.size.x * 0.28, 0.65, 3.0)
			_burst(avg, Color(1, 1, 1), 8 + lines * 4, 1.7)
			_burst(avg, Color(1.0, 0.86, 0.40), 6 + lines * 2, 1.3)
			_burst(avg, _temp_accent(), 6 + lines * 2, 1.5)
			_burst(avg, Color(0.55, 0.85, 1.0), 5 + lines, 1.1)
			_add_text(avg - Vector2(0, cell_size * 0.15), "+%d" % int(data.get("points", 0)),
				Color(0.85, 0.96, 1.0), cell_size * (0.66 + lines * 0.03))
			if lines > 1:
				_add_text(avg - Vector2(0, cell_size * 0.95), "КОМБО x%d" % lines,
					Color(1.0, 0.86, 0.40), cell_size * 0.50)
		"sand_reactions":
			var events: Dictionary = data.get("events", {})
			if events.has("explode"):
				var exp_pos := _sand_position(int(events["explode"]["x"]), int(events["explode"]["y"]))
				_add_ring(exp_pos, Color(1.0, 0.55, 0.20), cell_size * 0.3,
					cell_size * 3.2, 0.55, 5.0)
				_add_ring(exp_pos, Color(1.0, 0.90, 0.50), cell_size * 0.15,
					cell_size * 1.4, 0.4, 3.0)
				_burst(exp_pos, Color(1.0, 0.55, 0.20), 22, 1.8)
				_burst(exp_pos, Color(1.0, 0.92, 0.60), 12, 1.3)
				_burst(exp_pos, Color(1.0, 0.28, 0.16), 14, 2.1)
				_burst(exp_pos, Color(0.55, 0.78, 1.0), 7, 1.5)
				_add_ring(exp_pos, Color(1.0, 0.35, 0.18), cell_size * 0.4,
					cell_size * 4.0, 0.65, 3.5)
				if reaction_label_cd <= 0.0:
					_add_text(exp_pos - Vector2(0, cell_size * 0.4), "ВЗРЫВ",
						Color(1.0, 0.82, 0.35), cell_size * 0.48)
					reaction_label_cd = 1.2
				shake = maxf(shake, 9.0)
				flash = maxf(flash, 0.5)
				flash_color = Color(1.0, 0.55, 0.20)

			var label_text := ""
			var label_color := Color(1, 1, 1)
			var label_pos := Vector2.ZERO
			if events.has("obsidian"):
				label_pos = _sand_position(int(events["obsidian"]["x"]), int(events["obsidian"]["y"]))
				label_text = "ОБСИДИАН"
				label_color = PALETTE["obsidian"]["particle"]
			elif events.has("ignite"):
				label_pos = _sand_position(int(events["ignite"]["x"]), int(events["ignite"]["y"]))
				label_text = "ОГОНЬ"
				label_color = PALETTE["fire"]["light"]
			elif events.has("glass"):
				label_pos = _sand_position(int(events["glass"]["x"]), int(events["glass"]["y"]))
				label_text = "СТЕКЛО"
				label_color = PALETTE["glass"]["light"]
			elif events.has("dissolve"):
				label_pos = _sand_position(int(events["dissolve"]["x"]), int(events["dissolve"]["y"]))
				label_text = "РАСТВОРЕНО"
				label_color = PALETTE["acid"]["light"]
			elif events.has("melt"):
				label_pos = _sand_position(int(events["melt"]["x"]), int(events["melt"]["y"]))
				label_text = "ТАЯНИЕ"
				label_color = PALETTE["water"]["light"]
			elif events.has("burn"):
				label_pos = _sand_position(int(events["burn"]["x"]), int(events["burn"]["y"]))
				label_text = "ИСПАРЕНИЕ"
				label_color = PALETTE["lava"]["light"]
			elif events.has("dilute"):
				label_pos = _sand_position(int(events["dilute"]["x"]), int(events["dilute"]["y"]))
				label_text = "НЕЙТРАЛИЗАЦИЯ"
				label_color = PALETTE["water"]["light"]
			elif events.has("grow"):
				label_pos = _sand_position(int(events["grow"]["x"]), int(events["grow"]["y"]))
				label_text = "РОСТ"
				label_color = PALETTE["plant"]["light"]
			elif events.has("absorb"):
				label_pos = _sand_position(int(events["absorb"]["x"]), int(events["absorb"]["y"]))
				label_text = "ВПИТАНО"
				label_color = PALETTE["sponge"]["light"]
			elif events.has("release"):
				label_pos = _sand_position(int(events["release"]["x"]), int(events["release"]["y"]))
				label_text = "ПАР"
				label_color = PALETTE["steam"]["light"]
			elif events.has("freeze"):
				label_pos = _sand_position(int(events["freeze"]["x"]), int(events["freeze"]["y"]))
				label_text = "ЗАМЕРЗЛО"
				label_color = PALETTE["ice"]["light"]
			elif events.has("solidify"):
				label_pos = _sand_position(int(events["solidify"]["x"]), int(events["solidify"]["y"]))
				label_text = "ЗАСТЫЛО"
				label_color = PALETTE["stone"]["light"]
			elif events.has("shatter"):
				label_pos = _sand_position(int(events["shatter"]["x"]), int(events["shatter"]["y"]))
				label_text = "ОСКОЛКИ"
				label_color = PALETTE["crystal"]["light"]
			elif events.has("spore"):
				label_pos = _sand_position(int(events["spore"]["x"]), int(events["spore"]["y"]))
				label_text = "СПОРЫ"
				label_color = PALETTE["spore"]["light"]
			elif events.has("extinguish"):
				label_pos = _sand_position(int(events["extinguish"]["x"]), int(events["extinguish"]["y"]))
				label_text = "ПОТУШЕНО"
				label_color = PALETTE["steam"]["light"]

			if label_text != "" and reaction_label_cd <= 0.0:
				_add_text(label_pos - Vector2(0, cell_size * 0.95), label_text,
					label_color, cell_size * 0.27)
				reaction_label_cd = 1.1

			for kind_name in events:
				var entry: Dictionary = events[kind_name]
				var pos := _sand_position(int(entry["x"]), int(entry["y"]))
				var color := Color(1, 1, 1)
				match str(kind_name):
					"obsidian":
						color = PALETTE["obsidian"]["particle"]
						_add_ring(pos, color, cell_size * 0.2, cell_size * 1.2, 0.45, 2.5)
						shake = maxf(shake, 2.5)
					"explode":
						color = Color(1.0, 0.62, 0.25)
					"ignite":
						color = PALETTE["fire"]["particle"]
					"glass":
						color = PALETTE["glass"]["particle"]
					"grow":
						color = PALETTE["plant"]["particle"]
					"absorb":
						color = PALETTE["sponge"]["particle"]
					"release":
						color = PALETTE["steam"]["particle"]
						_add_ring(pos, color, cell_size * 0.1, cell_size * 0.8, 0.35, 2.0)
						_burst(pos, color, 4, 0.9)
					"freeze":
						color = PALETTE["ice"]["particle"]
						_add_ring(pos, color, cell_size * 0.1, cell_size * 0.75, 0.35, 2.0)
						_burst(pos, Color(0.75, 0.95, 1.0), 3, 0.9)
					"solidify":
						color = PALETTE["stone"]["particle"]
					"spore":
						color = PALETTE["spore"]["particle"]
						_burst(pos, PALETTE["plant"]["particle"], 3, 0.9)
					"shatter":
						color = PALETTE["crystal"]["particle"]
						_add_ring(pos, color, cell_size * 0.1, cell_size * 1.0, 0.4, 2.0)
						_burst(pos, Color(0.8, 0.9, 1.0), 5, 1.2)
					"extinguish":
						color = PALETTE["steam"]["particle"]
					"dissolve":
						color = PALETTE["acid"]["particle"]
					"melt":
						color = PALETTE["water"]["particle"]
					"burn":
						color = PALETTE["lava"]["particle"]
					"dilute":
						color = PALETTE["water"]["particle"]
				_burst(pos, color, 2, 0.7)
		"temperature":
			var temp_level := int(data.get("level", game.temperature if game != null else 0))
			var temp_delta := int(data.get("delta", 0))
			var temp_name := str(ElementGame.TEMP_NAMES.get(temp_level, "НОРМА"))
			var temp_color := _temperature_color(temp_level)
			var temp_pos := board_rect.position + Vector2(
				board_rect.size.x * 0.5, cell_size * 1.1)
			var temp_sign := "+" if temp_delta > 0 else ""
			_add_text(temp_pos, "%s%d°C  %s" % [temp_sign, temp_delta, temp_name],
				temp_color, cell_size * 0.34)
			_add_ring(board_rect.get_center(), temp_color,
				cell_size * 0.25, cell_size * 2.0, 0.5, 3.0)
			flash = maxf(flash, 0.22)
			flash_color = temp_color
			shake = maxf(shake, 2.0)
		"awaken_surge":
			var surge_kind := str(data.get("kind", "water"))
			var surge_label := str(data.get("label", "СТИХИЯ"))
			var surge_x := int(data.get("x", 0))
			var surge_width := int(data.get("width", 3))
			var surge_color: Color = PALETTE[surge_kind]["particle"]
			var surge_pos := _sand_position(surge_x + surge_width * 0.5, 0)
			_add_ring(surge_pos, surge_color, cell_size * 0.2, cell_size * 2.4, 0.55, 4.0)
			_add_beam(surge_pos.x, surge_color, 0.5)
			_burst(surge_pos, surge_color, 14, 1.4)
			_add_text(surge_pos + Vector2(0, cell_size * 1.0), surge_label,
				PALETTE[surge_kind]["light"], cell_size * 0.34)
			shake = maxf(shake, 3.0)
			flash = maxf(flash, 0.2)
			flash_color = surge_color
		"awaken_start":
			drag = {}
			selected = -1
			ghost = {}
			hover_ghost = {}
			awaken_t = 0.0
			shake = maxf(shake, 4.5)
			var awaken_accent := _temp_accent()
			flash = maxf(flash, 0.55)
			flash_color = awaken_accent
			_add_ring(board_rect.get_center(), awaken_accent,
				cell_size, board_rect.size.x * 0.45, 0.8, 5.0)
			sand_active = true
			sand_showing = true
			sand_fade = 0.0
			sand_version = -1
			_build_sand_texture()
		"awaken_end":
			sand_active = false
			sand_fade = SAND_FADE_TIME
			var end_accent := _temp_accent().lerp(Color.WHITE, 0.35)
			flash = maxf(flash, 0.3)
			flash_color = end_accent
			_add_ring(board_rect.get_center(), end_accent,
				cell_size * 0.5, board_rect.size.x * 0.38, 0.55, 3.0)
			awaken_style_counter += 1
			if awaken_style_counter % 2 == 0:
				visual_style = (visual_style + 1) % STYLE_NAMES.size()
				_add_text(board_rect.get_center() - Vector2(0, cell_size * 2.2),
					"СТИЛЬ: " + str(STYLE_NAMES[visual_style]),
					end_accent, cell_size * 0.42)
		"start":
			sand_active = false
			sand_showing = false
			sand_fade = 0.0
			sand_version = -1
			visual_style = 0
			awaken_style_counter = 0
		"game_over":
			drag = {}
			selected = -1
			ghost = {}
			hover_ghost = {}
			shake = maxf(shake, 7.0)
	queue_redraw()


func _add_ring(pos: Vector2, color: Color, start_radius: float, end_radius: float,
		life := 0.45, width := 3.0) -> void:
	rings.append({
		"pos": pos,
		"color": color,
		"r0": start_radius,
		"r1": end_radius,
		"life": life,
		"max": life,
		"width": width,
	})
	if rings.size() > 36:
		rings.pop_front()


func _add_beam(x: float, color: Color, life := 0.45) -> void:
	beams.append({"x": x, "color": color, "life": life, "max": life})
	if beams.size() > 12:
		beams.pop_front()


func _draw_rings() -> void:
	for ring in rings:
		var t := 1.0 - float(ring["life"]) / float(ring["max"])
		var radius := lerpf(float(ring["r0"]), float(ring["r1"]), 1.0 - pow(1.0 - t, 2.0))
		var color: Color = ring["color"]
		color.a *= (1.0 - t)
		draw_arc(ring["pos"], radius, 0.0, TAU, 56, color,
			maxf(1.0, float(ring["width"]) * (1.0 - t * 0.6)), true)


func _draw_beams() -> void:
	if beam_texture == null:
		return
	for beam in beams:
		var t := float(beam["life"]) / float(beam["max"])
		var color: Color = beam["color"]
		var x: float = float(beam["x"])
		var width := cell_size * 1.8
		var height := board_rect.size.y * 0.55
		color.a = t * 0.75
		draw_texture_rect(beam_texture,
			Rect2(x - width * 0.5, board_rect.position.y, width, height),
			false, color)
		color.a = t * 0.9
		draw_texture_rect(beam_texture,
			Rect2(x - width * 0.24, board_rect.position.y, width * 0.48, height * 0.8),
			false, color)


func _temp_accent() -> Color:
	if game == null:
		return Color("#b9a8ff")
	return game.event_accent()


func _temperature_color(value: int) -> Color:
	match value:
		-2:
			return Color("#9fe8ff")
		-1:
			return Color("#6fc4ff")
		0:
			return Color("#9fb0cc")
		1:
			return Color("#ffb066")
		2:
			return Color("#ff6a3d")
	return Color("#9fb0cc")


func _draw_temperature_overlay() -> void:
	if game == null:
		return
	var accent := _temp_accent()
	var strength := clampf(absf(float(game.temperature_degrees)) / 100.0, 0.0, 1.0)
	_round_rect(board_rect, cell_size * 0.16,
		Color(accent.r, accent.g, accent.b,
			(0.008 + 0.020 * strength) if ThemeKit.is_light() else (0.012 + 0.040 * strength)))


func _spawn_snow() -> void:
	var x := board_rect.position.x + _rng.randf_range(0.0, board_rect.size.x)
	var y := board_rect.position.y + _rng.randf_range(-cell_size * 0.6, cell_size * 0.25)
	snow.append({
		"pos": Vector2(x, y),
		"vel": Vector2(_rng.randf_range(-14.0, 14.0), _rng.randf_range(30.0, 72.0)),
		"life": _rng.randf_range(2.6, 4.8),
		"size": _rng.randf_range(1.2, 3.0),
		"phase": _rng.randf_range(0.0, TAU),
	})
	if snow.size() > QualitySettings.snow_cap:
		snow.pop_front()


func _draw_snow() -> void:
	var flake_color := Color(0.22, 0.48, 0.72) if ThemeKit.is_light() \
		else Color(0.86, 0.95, 1.0)
	for flake in snow:
		var alpha := minf(1.0, float(flake["life"])) * (0.55 if ThemeKit.is_light() else 0.85)
		draw_circle(flake["pos"], float(flake["size"]),
			Color(flake_color.r, flake_color.g, flake_color.b, alpha))


func _spawn_heat() -> void:
	var x := board_rect.position.x + _rng.randf_range(0.0, board_rect.size.x)
	var y := board_rect.position.y + board_rect.size.y * _rng.randf_range(0.5, 0.96)
	var life := _rng.randf_range(0.5, 1.0)
	particles.append({
		"pos": Vector2(x, y),
		"vel": Vector2(_rng.randf_range(-12.0, 12.0), _rng.randf_range(-52.0, -22.0)),
		"grav": -18.0,
		"drag": 0.8,
		"life": life,
		"max": life,
		"size": _rng.randf_range(1.2, 3.0),
		"color": Color(1.0, 0.55, 0.15, 0.8),
	})


func _spawn_ambient() -> void:
	if game == null or game.mode != "playing" or sand_active:
		return
	if game.board.is_empty():
		return

	var occupied: Array = []
	for r in rows:
		for c in cols:
			var cell = game.board[r][c]
			if cell != null and float(cell.get("born", 0.0)) <= draw_time:
				occupied.append(Vector2i(c, r))
	if occupied.is_empty():
		return

	var pick: Vector2i = occupied[_rng.randi() % occupied.size()]
	var element := str(game.board[pick.y][pick.x]["t"])
	var center := _cell_center(pick.y, pick.x)
	var pos := center + Vector2(
		_rng.randf_range(-0.32, 0.32),
		_rng.randf_range(-0.28, 0.22)) * cell_size
	var color: Color = PALETTE[element]["particle"]
	var velocity := Vector2(_rng.randf_range(-10.0, 10.0), _rng.randf_range(-20.0, -8.0))
	var gravity := 18.0
	var life := 0.55
	var size := 2.0

	match element:
		"lava":
			velocity = Vector2(_rng.randf_range(-16.0, 16.0), _rng.randf_range(-70.0, -30.0))
			gravity = -16.0
			life = _rng.randf_range(0.55, 0.95)
			size = _rng.randf_range(2.0, 3.8)
			color = Color(1.0, _rng.randf_range(0.55, 0.82), 0.18)
		"water":
			velocity = Vector2(_rng.randf_range(-8.0, 8.0), _rng.randf_range(-42.0, -18.0))
			gravity = -8.0
			life = _rng.randf_range(0.35, 0.7)
			size = _rng.randf_range(1.6, 2.8)
			color = Color(0.58, 0.86, 1.0, 0.85)
		"acid":
			velocity = Vector2(_rng.randf_range(-10.0, 10.0), _rng.randf_range(-50.0, -22.0))
			gravity = -10.0
			life = _rng.randf_range(0.4, 0.8)
			size = _rng.randf_range(1.6, 3.0)
			color = Color(0.7, 1.0, 0.35, 0.85)
		"ice":
			velocity = Vector2(_rng.randf_range(-12.0, 12.0), _rng.randf_range(-24.0, -4.0))
			gravity = 6.0
			life = _rng.randf_range(0.3, 0.55)
			size = _rng.randf_range(1.4, 2.6)
			color = Color(0.8, 0.98, 1.0, 0.9)
		"obsidian":
			velocity = Vector2(_rng.randf_range(-8.0, 8.0), _rng.randf_range(-30.0, -10.0))
			gravity = -4.0
			life = _rng.randf_range(0.35, 0.65)
			size = _rng.randf_range(1.5, 2.8)
			color = Color(0.78, 0.62, 1.0, 0.9)
		"fire":
			velocity = Vector2(_rng.randf_range(-14.0, 14.0), _rng.randf_range(-65.0, -25.0))
			gravity = -18.0
			life = _rng.randf_range(0.4, 0.8)
			size = _rng.randf_range(1.8, 3.4)
			color = Color(1.0, _rng.randf_range(0.55, 0.85), 0.16, 0.9)
		"oil":
			velocity = Vector2(_rng.randf_range(-6.0, 6.0), _rng.randf_range(-22.0, -8.0))
			gravity = -4.0
			life = _rng.randf_range(0.35, 0.65)
			size = _rng.randf_range(1.4, 2.5)
			color = Color(0.62, 0.45, 0.85, 0.7)
		"plant":
			velocity = Vector2(_rng.randf_range(-10.0, 10.0), _rng.randf_range(-28.0, -8.0))
			gravity = -2.0
			life = _rng.randf_range(0.4, 0.7)
			size = _rng.randf_range(1.4, 2.6)
			color = Color(0.62, 1.0, 0.45, 0.85)
		"gunpowder":
			velocity = Vector2(_rng.randf_range(-4.0, 4.0), _rng.randf_range(-10.0, 4.0))
			gravity = 26.0
			life = _rng.randf_range(0.25, 0.5)
			size = _rng.randf_range(1.2, 2.0)
			color = Color(0.86, 0.90, 1.0, 0.7)
		"glass":
			velocity = Vector2(_rng.randf_range(-10.0, 10.0), _rng.randf_range(-25.0, -5.0))
			gravity = 4.0
			life = _rng.randf_range(0.25, 0.5)
			size = _rng.randf_range(1.2, 2.4)
			color = Color(0.85, 1.0, 1.0, 0.9)
		"seaweed":
			velocity = Vector2(_rng.randf_range(-6.0, 6.0), _rng.randf_range(-30.0, -12.0))
			gravity = -3.0
			life = _rng.randf_range(0.5, 0.9)
			size = _rng.randf_range(1.4, 2.6)
			color = Color(0.55, 1.0, 0.68, 0.8)
		"sponge":
			velocity = Vector2(_rng.randf_range(-8.0, 8.0), _rng.randf_range(-18.0, 2.0))
			gravity = 10.0
			life = _rng.randf_range(0.3, 0.6)
			size = _rng.randf_range(1.4, 2.6)
			color = Color(1.0, 0.84, 0.42, 0.8)
		"coal":
			velocity = Vector2(_rng.randf_range(-4.0, 4.0), _rng.randf_range(-8.0, 4.0))
			gravity = 20.0
			life = _rng.randf_range(0.25, 0.5)
			size = _rng.randf_range(1.2, 2.0)
			color = Color(0.62, 0.58, 0.68, 0.6)
		"ash":
			velocity = Vector2(_rng.randf_range(-10.0, 10.0), _rng.randf_range(-20.0, 4.0))
			gravity = 12.0
			life = _rng.randf_range(0.3, 0.7)
			size = _rng.randf_range(1.0, 2.0)
			color = Color(0.82, 0.80, 0.86, 0.65)
		"snow":
			velocity = Vector2(_rng.randf_range(-12.0, 12.0), _rng.randf_range(-6.0, 18.0))
			gravity = 22.0
			life = _rng.randf_range(0.4, 0.9)
			size = _rng.randf_range(1.2, 2.6)
			color = Color(1.0, 1.0, 1.0, 0.85)
		"crystal":
			velocity = Vector2(_rng.randf_range(-8.0, 8.0), _rng.randf_range(-24.0, -6.0))
			gravity = 0.0
			life = _rng.randf_range(0.35, 0.75)
			size = _rng.randf_range(1.4, 2.8)
			color = Color(0.72, 0.80, 1.0, 0.9)
		"spore":
			velocity = Vector2(_rng.randf_range(-14.0, 14.0), _rng.randf_range(-30.0, -8.0))
			gravity = -6.0
			life = _rng.randf_range(0.5, 1.0)
			size = _rng.randf_range(1.2, 2.4)
			color = Color(0.90, 1.0, 0.50, 0.75)
		"flower":
			velocity = Vector2(_rng.randf_range(-10.0, 10.0), _rng.randf_range(-22.0, -4.0))
			gravity = -2.0
			life = _rng.randf_range(0.45, 0.85)
			size = _rng.randf_range(1.4, 2.8)
			color = Color(1.0, 0.62, 0.80, 0.8)
		_:
			velocity = Vector2(_rng.randf_range(-6.0, 6.0), _rng.randf_range(-12.0, 6.0))
			gravity = 24.0
			life = _rng.randf_range(0.35, 0.6)
			size = _rng.randf_range(1.2, 2.2)

	particles.append({
		"pos": pos,
		"vel": velocity,
		"grav": gravity,
		"drag": 0.9,
		"life": life,
		"max": life,
		"size": size,
		"color": color,
	})


func _burst(pos: Vector2, color: Color, count: int, power: float) -> void:
	for i in count:
		var angle := _rng.randf_range(0.0, TAU)
		var speed := _rng.randf_range(70.0, 280.0) * power
		var life := _rng.randf_range(0.35, 0.80)
		particles.append({
			"pos": pos,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"grav": 640.0,
			"drag": 1.5,
			"life": life,
			"max": life,
			"size": _rng.randf_range(2.0, 5.4),
			"color": color,
		})
		if particles.size() > 260:
			particles.pop_front()


func _add_text(pos: Vector2, text: String, color: Color, font_size: float) -> void:
	if ThemeKit.is_light():
		color = color.darkened(0.35)
	var center_x := clampf(pos.x, TEXT_WIDTH * 0.5 + 4.0, size.x - TEXT_WIDTH * 0.5 - 4.0)
	var top_y := clampf(pos.y, font_size, size.y - font_size * 1.2)
	texts.append({
		"pos": Vector2(center_x, top_y) - Vector2(TEXT_WIDTH * 0.5, 0.0),
		"text": text,
		"color": color,
		"size": maxf(16.0, font_size),
		"life": 1.15,
		"max": 1.15,
	})


func _process(delta: float) -> void:
	if not drag.is_empty():
		var target_unit := cell_size if _over_board(mouse_pos) else mini
		drag["unit"] = lerpf(float(drag.get("unit", mini)), target_unit,
			minf(1.0, delta * 14.0))
	var i := particles.size() - 1
	while i >= 0:
		var p: Dictionary = particles[i]
		p["life"] = float(p["life"]) - delta
		if float(p["life"]) <= 0.0:
			particles.remove_at(i)
		else:
			var vel: Vector2 = p["vel"]
			vel.y += float(p["grav"]) * delta
			vel *= maxf(0.0, 1.0 - float(p["drag"]) * delta)
			p["vel"] = vel
			p["pos"] = p["pos"] + vel * delta
		i -= 1

	i = texts.size() - 1
	while i >= 0:
		var entry: Dictionary = texts[i]
		entry["life"] = float(entry["life"]) - delta
		if float(entry["life"]) <= 0.0:
			texts.remove_at(i)
		else:
			entry["pos"] = entry["pos"] - Vector2(0.0, 34.0 * delta)
		i -= 1

	texture_timer -= delta
	if game != null and game.sand != null and sand_showing \
			and game.sand.version != sand_version and texture_timer <= 0.0:
		_build_sand_texture()
		texture_timer = texture_interval

	sand_fade = maxf(0.0, sand_fade - delta)
	if not sand_active and sand_fade <= 0.0:
		sand_showing = false

	i = rings.size() - 1
	while i >= 0:
		rings[i]["life"] = float(rings[i]["life"]) - delta
		if float(rings[i]["life"]) <= 0.0:
			rings.remove_at(i)
		i -= 1

	i = beams.size() - 1
	while i >= 0:
		beams[i]["life"] = float(beams[i]["life"]) - delta
		if float(beams[i]["life"]) <= 0.0:
			beams.remove_at(i)
		i -= 1

	reaction_label_cd = maxf(0.0, reaction_label_cd - delta)
	ambient_timer -= delta
	if ambient_timer <= 0.0:
		_spawn_ambient()
		ambient_timer = _rng.randf_range(QualitySettings.ambient_min, QualitySettings.ambient_max)

	if game != null and game.temperature <= -2:
		snow_timer -= delta
		if snow_timer <= 0.0:
			_spawn_snow()
			snow_timer = _rng.randf_range(QualitySettings.snow_min, QualitySettings.snow_max)

	var snow_index := snow.size() - 1
	while snow_index >= 0:
		var flake: Dictionary = snow[snow_index]
		flake["life"] = float(flake["life"]) - delta
		if float(flake["life"]) <= 0.0:
			snow.remove_at(snow_index)
		else:
			var velocity: Vector2 = flake["vel"]
			var drift := sin(draw_time * 1.6 + float(flake["phase"])) * 10.0
			flake["pos"] = flake["pos"] + Vector2(velocity.x + drift, velocity.y) * delta
		snow_index -= 1

	if game != null and game.temperature >= 2:
		heat_timer -= delta
		if heat_timer <= 0.0:
			_spawn_heat()
			heat_timer = _rng.randf_range(QualitySettings.heat_min, QualitySettings.heat_max)

	var particle_cap := 80 if low_end else 180
	while particles.size() > particle_cap:
		particles.pop_front()
	var snow_limit := QualitySettings.snow_cap
	while snow.size() > snow_limit:
		snow.pop_front()

	shake = maxf(0.0, shake - delta * (18.0 + shake * 9.0))
	flash = maxf(0.0, flash - delta * 2.6)
	awaken_t += delta
	queue_redraw()
