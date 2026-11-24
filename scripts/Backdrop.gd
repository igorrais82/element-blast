class_name AuroraBackdrop
extends Control
## Dark background: temperature/event tint, soft glows, stars and event decor.

var t := 0.0
var stars: Array = []
var fish: Array = []
var petals: Array = []
var embers: Array = []
var glow: Texture2D

var target_temperature := 20.0
var shown_temperature := 20.0
var event_active := false
var event_theme := ""
var event_accent := Color.TRANSPARENT
var event_bg := Color.TRANSPARENT
var shown_bg := Color("#141a38")
var shown_accent := Color("#b9a8ff")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow = _make_glow()

	var rng := RandomNumberGenerator.new()
	rng.seed = 20261124
	for i in 54:
		stars.append({
			"x": rng.randf(),
			"y": rng.randf(),
			"s": rng.randf_range(0.7, 2.0),
			"p": rng.randf_range(0.0, TAU),
			"v": rng.randf_range(0.25, 1.2),
		})
	for i in 6:
		fish.append({
			"y": rng.randf_range(0.16, 0.78),
			"size": rng.randf_range(7.0, 15.0),
			"speed": rng.randf_range(9.0, 24.0),
			"offset": rng.randf_range(0.0, 1200.0),
			"phase": rng.randf_range(0.0, TAU),
			"dir": -1 if rng.randi() % 2 == 0 else 1,
			"alpha": rng.randf_range(0.05, 0.13),
		})
	for i in 22:
		petals.append({
			"x": rng.randf(),
			"y": rng.randf(),
			"size": rng.randf_range(3.0, 7.0),
			"speed": rng.randf_range(0.010, 0.030),
			"sway": rng.randf_range(10.0, 34.0),
			"phase": rng.randf_range(0.0, TAU),
			"warm": rng.randf() < 0.55,
		})
	for i in 34:
		embers.append({
			"x": rng.randf(),
			"size": rng.randf_range(1.2, 3.2),
			"speed": rng.randf_range(0.020, 0.065),
			"offset": rng.randf_range(0.0, 1.0),
			"sway": rng.randf_range(6.0, 18.0),
			"phase": rng.randf_range(0.0, TAU),
		})
	set_process(true)


func set_event(theme: String, accent: Color, background: Color) -> void:
	event_theme = theme
	event_accent = accent
	event_bg = background
	event_active = true


func clear_event() -> void:
	event_active = false
	event_theme = ""
	event_accent = Color.TRANSPARENT
	event_bg = Color.TRANSPARENT


func _process(delta: float) -> void:
	t += delta
	shown_temperature = lerpf(shown_temperature, target_temperature,
		minf(1.0, delta * 2.4))
	var degrees := int(round(shown_temperature))
	var target_bg: Color = event_bg if event_active else ElementGame.temperature_background(degrees)
	var target_accent: Color = event_accent if event_active else ElementGame.temperature_accent(degrees)
	shown_bg = shown_bg.lerp(target_bg, minf(1.0, delta * 3.0))
	shown_accent = shown_accent.lerp(target_accent, minf(1.0, delta * 3.0))
	queue_redraw()


func _draw() -> void:
	var bg := shown_bg
	var accent := shown_accent
	var effect_accent := accent.darkened(0.18) if ThemeKit.is_light() else accent
	draw_rect(Rect2(Vector2.ZERO, size), bg)

	if glow != null:
		var blue_pos := Vector2(size.x * 0.08 + sin(t * 0.07) * 30.0, size.y * 0.06)
		var purple_pos := Vector2(size.x * 0.95, size.y * 0.32 + cos(t * 0.05) * 40.0)
		var orange_pos := Vector2(size.x * 0.5, size.y * 0.98)
		var score_pos := Vector2(size.x * 0.5, size.y * 0.015)
		var blue_r := size.x * 0.95
		var purple_r := size.x * 0.9
		var orange_r := size.x * 1.0
		var score_r := size.x * 0.46
		var light_scale := 0.45 if ThemeKit.is_light() else 1.0

		var first := Color(effect_accent.r, effect_accent.g, effect_accent.b, 0.20 * light_scale)
		var second := effect_accent.lerp(Color.WHITE, 0.28)
		second.a = 0.11 * light_scale
		var third := effect_accent.lerp(bg, 0.35)
		third.a = 0.12 * light_scale
		var score_glow := effect_accent.lerp(Color.WHITE, 0.18)
		score_glow.a = (0.10 + 0.035 * (0.5 + 0.5 * sin(t * 0.9))) * light_scale

		draw_texture_rect(glow,
			Rect2(blue_pos - Vector2(blue_r, blue_r), Vector2(blue_r, blue_r) * 2.0),
			false, first)
		draw_texture_rect(glow,
			Rect2(purple_pos - Vector2(purple_r, purple_r), Vector2(purple_r, purple_r) * 2.0),
			false, second)
		draw_texture_rect(glow,
			Rect2(orange_pos - Vector2(orange_r, orange_r), Vector2(orange_r, orange_r) * 2.0),
			false, third)
		draw_texture_rect(glow,
			Rect2(score_pos - Vector2(score_r, score_r), Vector2(score_r, score_r) * 2.0),
			false, score_glow)

	for star in stars:
		var twinkle: float = 0.12 + 0.16 * (0.5 + 0.5 * sin(t * float(star["v"]) + float(star["p"])))
		var pos := Vector2(float(star["x"]) * size.x, float(star["y"]) * size.y)
		var star_color := effect_accent.lerp(Color.WHITE, 0.55)
		star_color.a = twinkle
		draw_circle(pos, float(star["s"]), star_color)

	match event_theme:
		"flood":
			_draw_flood(effect_accent)
		"firestorm":
			_draw_firestorm(effect_accent)
		"ice_age":
			_draw_aurora(effect_accent)
		"bloom":
			_draw_bloom(effect_accent)


# ---------------------------------------------------------------------------
# Event decorations
# ---------------------------------------------------------------------------

func _draw_flood(accent: Color) -> void:
	for layer in 3:
		var base_y := size.y * (0.78 + layer * 0.075)
		var points := PackedVector2Array([Vector2(0.0, size.y)])
		var step := 16.0
		var x := 0.0
		while x <= size.x + step:
			var y := base_y + sin(x * 0.012 + t * (0.8 + layer * 0.25) + layer * 1.7) \
				* size.y * 0.018
			points.append(Vector2(x, y))
			x += step
		points.append(Vector2(size.x, size.y))
		var color := accent
		color.a = 0.045 + layer * 0.028
		draw_colored_polygon(points, color)

	for f in fish:
		var span := size.x + 240.0
		var x_pos := fmod(float(f["offset"]) + t * float(f["speed"]), span) - 120.0
		if int(f["dir"]) < 0:
			x_pos = size.x - x_pos
		var y_pos := float(f["y"]) * size.y + sin(t * 0.6 + float(f["phase"])) * 9.0
		var color := accent.lerp(Color.WHITE, 0.22)
		color.a = float(f["alpha"])
		_draw_fish(Vector2(x_pos, y_pos), float(f["size"]), color, int(f["dir"]))

	for i in 4:
		var bubble_x := fmod(120.0 * (i + 1) + t * (5.0 + i), size.x + 60.0) - 30.0
		var bubble_y := size.y * 0.86 - fmod(t * (12.0 + i * 4.0) + i * 130.0,
			size.y * 0.26)
		var bubble_color := accent.lerp(Color.WHITE, 0.5)
		bubble_color.a = 0.10
		draw_circle(Vector2(bubble_x, bubble_y), 3.0 + i, bubble_color)


func _draw_firestorm(accent: Color) -> void:
	for e in embers:
		var y := size.y - fmod(t * float(e["speed"]) * size.y + float(e["offset"]) * size.y,
			size.y * 1.04)
		var x := float(e["x"]) * size.x + sin(t * 0.9 + float(e["phase"])) * float(e["sway"])
		var color := accent.lerp(Color(1.0, 0.85, 0.4), 0.35)
		color.a = 0.10 + 0.20 * clampf(1.0 - y / size.y, 0.0, 1.0)
		draw_circle(Vector2(x, y), float(e["size"]), color)

	if glow != null:
		var heat := accent
		heat.a = 0.10 + 0.03 * (0.5 + 0.5 * sin(t * 1.4))
		draw_texture_rect(glow,
			Rect2(Vector2(size.x * 0.5 - size.x * 0.7, size.y * 0.93 - size.x * 0.35),
				Vector2(size.x * 1.4, size.x * 0.7)),
			false, heat)


func _draw_aurora(accent: Color) -> void:
	var colors := [
		accent.lerp(Color("#64ffd8"), 0.35),
		accent.lerp(Color("#b98cff"), 0.35),
		accent.lerp(Color("#7fe8ff"), 0.20),
	]
	for band in 3:
		var points := PackedVector2Array()
		var x := 0.0
		while x <= size.x + 20.0:
			var y := size.y * (0.09 + band * 0.045) \
				+ sin(x * 0.005 + t * 0.35 + band * 2.1) * size.y * 0.035
			points.append(Vector2(x, y))
			x += 18.0
		var color: Color = colors[band]
		color.a = 0.14 - band * 0.025
		draw_polyline(points, color, size.y * (0.030 - band * 0.006), true)

	for i in 7:
		var x_pos := fmod(i * 97.0 + t * (3.0 + i * 0.6), size.x + 20.0)
		var y_pos := fmod(i * 53.0 + t * (6.0 + i), size.y * 0.5)
		var flake := accent.lerp(Color.WHITE, 0.7)
		flake.a = 0.18
		draw_circle(Vector2(x_pos, y_pos), 1.5 + i % 3, flake)


func _draw_bloom(accent: Color) -> void:
	for p in petals:
		var y := size.y * (1.0 - fmod(float(p["y"]) + t * float(p["speed"]), 1.0))
		var x := float(p["x"]) * size.x + sin(t * 0.7 + float(p["phase"])) * float(p["sway"])
		var color := accent.lerp(Color("#ff9ed0"), 0.55) if bool(p["warm"]) \
			else accent.lerp(Color.WHITE, 0.25)
		color.a = 0.18
		var s := float(p["size"])
		draw_set_transform(Vector2(x, y), t * 0.5 + float(p["phase"]), Vector2(1.0, 0.55))
		draw_circle(Vector2.ZERO, s, color)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	for i in 3:
		var points := PackedVector2Array()
		var x := 0.0
		while x <= size.x + 20.0:
			var y := size.y * (0.92 - i * 0.045) \
				+ sin(x * 0.010 + t * 0.4 + i * 1.9) * size.y * 0.014
			points.append(Vector2(x, y))
			x += 20.0
		var color := accent
		color.a = 0.05 - i * 0.01
		draw_polyline(points, color, size.y * 0.012, true)


func _draw_fish(pos: Vector2, fish_size: float, color: Color, direction: int) -> void:
	var dir := 1.0 if direction >= 0 else -1.0
	var body := PackedVector2Array()
	for i in 12:
		var angle := TAU * float(i) / 12.0
		body.append(pos + Vector2(cos(angle) * fish_size * 1.55,
			sin(angle) * fish_size * 0.78))
	draw_colored_polygon(body, color)

	var tail := PackedVector2Array([
		pos + Vector2(-dir * fish_size * 1.25, 0.0),
		pos + Vector2(-dir * fish_size * 2.15, -fish_size * 0.82),
		pos + Vector2(-dir * fish_size * 2.15, fish_size * 0.82),
	])
	draw_colored_polygon(tail, color)

	var eye := Color(1.0, 1.0, 1.0, color.a * 1.6)
	draw_circle(pos + Vector2(dir * fish_size * 0.78, -fish_size * 0.16),
		maxf(1.0, fish_size * 0.12), eye)


func _make_glow() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color(1, 1, 1, 0.20),
		Color(1, 1, 1, 0.07),
		Color(1, 1, 1, 0.0),
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 512
	texture.height = 512
	return texture
