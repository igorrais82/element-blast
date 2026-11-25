class_name QualitySettings
extends RefCounted
## Adaptive quality presets. Mobile devices get a lighter simulation and fewer
## decorative effects; desktop keeps the full look.

static var mobile := false
static var low_end := false
static var max_fps := 60
static var sand_tick_rate := 45.0
static var sand_max_ticks := 220
static var sand_max_steps := 3
static var texture_fps := 45.0
static var sand_scale := 4
static var effect_scale := 1.0
static var star_count := 54
static var ambient_min := 0.12
static var ambient_max := 0.24
static var snow_cap := 160
static var snow_min := 0.025
static var snow_max := 0.06
static var heat_min := 0.10
static var heat_max := 0.20


static func configure() -> void:
	var args := OS.get_cmdline_user_args()
	var forced_low := false
	var forced_high := false
	for arg in args:
		if arg == "--quality=low":
			forced_low = true
		elif arg == "--quality=high":
			forced_high = true
	mobile = OS.has_feature("mobile")
	low_end = forced_low or (mobile and not forced_high)
	if low_end:
		max_fps = 45
		sand_tick_rate = 30.0
		sand_max_ticks = 150
		sand_max_steps = 2
		texture_fps = 20.0
		sand_scale = 3
		effect_scale = 0.45
		star_count = 28
		ambient_min = 0.42
		ambient_max = 0.78
		snow_cap = 64
		snow_min = 0.08
		snow_max = 0.15
		heat_min = 0.30
		heat_max = 0.48
	else:
		max_fps = 60
		sand_tick_rate = 45.0
		sand_max_ticks = 220
		sand_max_steps = 3
		texture_fps = 45.0
		sand_scale = 4
		effect_scale = 1.0
		star_count = 54
		ambient_min = 0.12
		ambient_max = 0.24
		snow_cap = 160
		snow_min = 0.025
		snow_max = 0.06
		heat_min = 0.10
		heat_max = 0.20
	Engine.max_fps = max_fps
