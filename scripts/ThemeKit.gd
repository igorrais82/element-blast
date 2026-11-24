class_name ThemeKit
extends RefCounted
## Shared colors for the dark and light interface themes.

static var mode := "dark"


static func is_light() -> bool:
	return mode == "light"


static func text_primary() -> Color:
	return Color("#17203a") if is_light() else Color("#f4f8ff")


static func text_secondary() -> Color:
	return Color("#52607c") if is_light() else Color("#9aaad0")


static func text_muted() -> Color:
	return Color("#7a879e") if is_light() else Color("#6f80a4")


static func accent_text(accent: Color) -> Color:
	if not is_light():
		return accent.lerp(Color.WHITE, 0.18)
	return accent.darkened(0.28).lerp(Color("#1b2440"), 0.18)


static func score_color(accent: Color) -> Color:
	return Color("#18213a") if is_light() else Color.WHITE.lerp(accent, 0.12)


static func score_shadow(accent: Color) -> Color:
	if is_light():
		return Color(0.20, 0.28, 0.45, 0.18)
	return Color(accent.r, accent.g, accent.b, 0.32)


static func panel_bg() -> Color:
	return Color(0.97, 0.98, 1.0, 0.97) if is_light() else Color(0.055, 0.075, 0.145, 0.985)


static func panel_border() -> Color:
	return Color(0.18, 0.25, 0.42, 0.16) if is_light() else Color(1, 1, 1, 0.09)


static func panel_shadow() -> Color:
	return Color(0.18, 0.26, 0.42, 0.20) if is_light() else Color(0, 0, 0, 0.45)


static func overlay_dim() -> Color:
	return Color(0.90, 0.94, 1.0, 0.72) if is_light() else Color(0.012, 0.02, 0.05, 0.76)


static func banner_bg(accent: Color) -> Color:
	if is_light():
		var bg := accent.lerp(Color.WHITE, 0.80)
		bg.a = 0.96
		return bg
	var dark := accent.darkened(0.80)
	dark.a = 0.90
	return dark


static func banner_text() -> Color:
	return Color("#17203a") if is_light() else Color("#eef8ff")


static func banner_sub() -> Color:
	return Color("#465570") if is_light() else Color(0.58, 0.78, 1.0, 0.75)


static func button_primary() -> Color:
	return Color("#2f8fe8") if is_light() else Color("#59c8ff")


static func button_primary_hover() -> Color:
	return Color("#43a3f2") if is_light() else Color("#7cd6ff")


static func button_primary_pressed() -> Color:
	return Color("#2378c9") if is_light() else Color("#40b4ef")


static func button_primary_text() -> Color:
	return Color("#ffffff") if is_light() else Color("#07101f")


static func button_secondary_bg() -> Color:
	return Color(0.14, 0.22, 0.38, 0.08) if is_light() else Color(1, 1, 1, 0.065)


static func button_secondary_hover() -> Color:
	return Color(0.14, 0.22, 0.38, 0.14) if is_light() else Color(1, 1, 1, 0.11)


static func button_secondary_pressed() -> Color:
	return Color(0.14, 0.22, 0.38, 0.05) if is_light() else Color(1, 1, 1, 0.04)


static func button_secondary_border() -> Color:
	return Color(0.14, 0.22, 0.38, 0.16) if is_light() else Color(1, 1, 1, 0.10)


static func button_secondary_text() -> Color:
	return Color("#1e2a44") if is_light() else Color("#e6eeff")


static func chip_bg(color: Color) -> Color:
	return Color(color.r, color.g, color.b, 0.13) if is_light() \
		else Color(color.r, color.g, color.b, 0.11)


static func chip_border(color: Color) -> Color:
	return Color(color.r, color.g, color.b, 0.38) if is_light() \
		else Color(color.r, color.g, color.b, 0.32)


static func chip_text(color: Color) -> Color:
	return color.darkened(0.30) if is_light() else color.lightened(0.18)


static func board_panel(accent: Color) -> Color:
	if is_light():
		return Color(1, 1, 1, 0.42)
	return Color(accent.r, accent.g, accent.b, 0.026)


static func board_cell(accent: Color) -> Color:
	if is_light():
		return Color(1, 1, 1, 0.62)
	return Color(accent.r, accent.g, accent.b, 0.050)


static func board_cell_inner() -> Color:
	return Color(0, 0, 0, 0.055) if is_light() else Color(0, 0, 0, 0.045)


static func board_border() -> Color:
	return Color(0.15, 0.22, 0.40, 0.10) if is_light() else Color(1, 1, 1, 0.040)


static func icon_button_tint() -> Color:
	return Color(0.10, 0.16, 0.30, 0.72) if is_light() else Color(1, 1, 1, 0.55)
