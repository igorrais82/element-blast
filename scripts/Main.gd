extends Control
## Element Blast — UI shell, HUD, overlays, sounds and debug helpers.

const PAUSE_ICON := preload("res://assets/icons/pause.svg")

var game: ElementGame
var board_view: BoardView
var sfx: SfxPlayer
var backdrop: AuroraBackdrop

var score_label: Label
var pips: Array[Panel] = []
var pip_style: StyleBoxFlat
var temp_value_label: Label
var _temp_tween: Tween
var event_hud_pill: PanelContainer
var event_hud_label: Label
var event_hud_style: StyleBoxFlat
var banner: Label
var banner_root: PanelContainer
var banner_sub: Label
var banner_style: StyleBoxFlat
var banner_tween: Tween

var charge_value := 1.0
var charge_time := 0.0
var display_score := 0.0
var play_button: Button

var menu_overlay: Control
var over_overlay: Control
var pause_overlay: Control
var tutorial_overlay: Control
var settings_overlay: Control
var store_overlay: Control
var store_products_box: VBoxContainer
var store_status_label: Label
var ad_overlay: Control
var ad_timer_label: Label
var ad_close_btn: Button
var ad_countdown := 0.0
var ad_active := false
var _ad_resume_game := false

static var _open_settings_after_reload := false
var menu_best: Label
var final_score: Label
var final_best: Label
var final_stats: Label
var pause_stats: Label
var new_record_label: Label
var sound_button: Button
var pause_btn: Button

var _display_font_res: Font

var session := 0
var reaction_cd := 0.0
var _score_tween: Tween
var _count_tween: Tween
var _overlay_tweens := {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	QualitySettings.configure()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--theme="):
			Profile.theme = "light" if arg.substr(8) == "light" else "dark"
		elif arg.begins_with("--size="):
			Profile.board_size = int(arg.substr(7))
	ThemeKit.mode = Profile.theme

	game = ElementGame.new()
	game.best = Profile.best
	game.set_board_size(Profile.board_size)
	game.game_event.connect(_on_game_event)

	var window_icon: Texture2D = load("res://assets/icon.svg")
	if window_icon != null:
		DisplayServer.set_icon(window_icon.get_image())

	sfx = SfxPlayer.new()
	add_child(sfx)

	backdrop = AuroraBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	_build_ui()
	_build_banner()
	_build_overlays()
	_build_tutorial_overlay()
	_build_settings_overlay()
	_build_store_overlay()
	_build_ad_overlay()
	Monetization.purchase_completed.connect(_on_purchase_completed)
	Monetization.purchase_failed.connect(_on_purchase_failed)
	Monetization.ad_requested.connect(_on_ad_requested)

	board_view.set_game(game)
	board_view.invalid_attempt.connect(_on_invalid_attempt)
	board_view.piece_picked.connect(_on_piece_picked)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--style="):
			board_view.visual_style = clampi(int(arg.substr(8)), 0, 2)

	_update_sound_button()
	_refresh_event_visuals()
	_update_hud()
	menu_best.text = "Рекорд: %d" % Profile.best
	_show_overlay(menu_overlay)
	_set_hud_visible(false)
	if _open_settings_after_reload:
		_open_settings_after_reload = false
		_show_overlay(settings_overlay)

	_handle_cli()


func _process(delta: float) -> void:
	reaction_cd = maxf(0.0, reaction_cd - delta)
	if game != null:
		game.update(delta)
		_update_live_scoring(delta)
		Monetization.tick(delta,
			game.mode == "playing" or game.mode == "awakening")
		if backdrop != null:
			backdrop.target_temperature = float(game.temperature_degrees)
	_update_ad_ui(delta)


func _update_live_scoring(delta: float) -> void:
	charge_time += delta

	var target_score := float(game.score)
	if display_score < target_score:
		display_score = minf(target_score,
			display_score + maxf(26.0, (target_score - display_score) * 9.0) * delta)
	elif display_score > target_score:
		display_score = target_score
	var shown := int(round(display_score))
	if score_label != null:
		var target_text := str(shown)
		if score_label.text != target_text:
			score_label.text = target_text
		var digits := target_text.length()
		var score_size := clampi(112 - maxi(0, digits - 4) * 12, 64, 112)
		if score_label.get_theme_font_size("font_size") != score_size:
			score_label.add_theme_font_size_override("font_size", score_size)

	for i in pips.size():
		var active := i < game.moves_left
		var alpha := 1.0 if active else 0.20
		if active and game.mode != "awakening" and game.moves_left == 1:
			alpha = 0.65 + 0.35 * (0.5 + 0.5 * sin(charge_time * 6.0))
		pips[i].modulate.a = alpha
	_update_event_hud()


func _update_event_hud() -> void:
	if event_hud_pill == null or event_hud_label == null or game == null:
		return
	if score_label != null and not score_label.visible:
		event_hud_pill.visible = false
		return
	if not game.event_active:
		event_hud_pill.visible = false
		return
	var accent: Color = game.event_accent()
	var moves_text := _plural_hod(game.event_moves_left)
	event_hud_label.text = "%s · %d %s" % [
		game.event_name(), game.event_moves_left, moves_text]
	event_hud_label.add_theme_color_override("font_color", ThemeKit.accent_text(accent))
	event_hud_style.bg_color = Color(accent.r, accent.g, accent.b,
		0.13 if ThemeKit.is_light() else 0.10)
	event_hud_style.border_color = Color(accent.r, accent.g, accent.b, 0.35)
	event_hud_pill.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if ad_overlay != null and ad_overlay.visible:
			if ad_close_btn != null and not ad_close_btn.disabled:
				_close_ad()
			return
		if settings_overlay != null and settings_overlay.visible:
			_hide_settings()
			return
		if tutorial_overlay != null and tutorial_overlay.visible:
			_hide_tutorial()
			return
		if menu_overlay.visible or over_overlay.visible:
			return
		_toggle_pause()
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------------------
# UI construction
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.name = "Layout"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	margin.add_child(column)

	# --- score header ------------------------------------------------------
	var header := VBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 204)
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 2)
	column.add_child(header)

	var score_row := HBoxContainer.new()
	score_row.alignment = BoxContainer.ALIGNMENT_CENTER
	score_row.add_theme_constant_override("separation", 12)
	header.add_child(score_row)

	# Balancing spacer keeps the score itself optically centred on screen.
	var balance := Control.new()
	balance.custom_minimum_size = Vector2(132, 0)
	score_row.add_child(balance)

	score_label = _label("0", 112, ThemeKit.text_primary())
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_override("font", _display_font())
	score_label.add_theme_color_override("font_shadow_color", ThemeKit.score_shadow(Color("#b9a8ff")))
	score_label.add_theme_constant_override("shadow_offset_x", 0)
	score_label.add_theme_constant_override("shadow_offset_y", 5)
	score_label.add_theme_constant_override("shadow_outline_size", 2)
	score_row.add_child(score_label)

	temp_value_label = _label("20°C", 42, Color("#b9a8ff"))
	temp_value_label.custom_minimum_size = Vector2(132, 0)
	temp_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	temp_value_label.add_theme_font_override("font", _display_font())
	temp_value_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.32))
	temp_value_label.add_theme_constant_override("shadow_offset_y", 3)
	score_row.add_child(temp_value_label)

	# --- awakening charge dots --------------------------------------------
	var pips_row := HBoxContainer.new()
	pips_row.alignment = BoxContainer.ALIGNMENT_CENTER
	pips_row.add_theme_constant_override("separation", 9)
	header.add_child(pips_row)
	pip_style = _flat(Color("#b9a8ff"), 5)
	pip_style.shadow_color = Color(0.72, 0.60, 1.0, 0.45)
	pip_style.shadow_size = 6
	for i in 2:
		var pip := Panel.new()
		pip.custom_minimum_size = Vector2(38, 9)
		pip.add_theme_stylebox_override("panel", pip_style)
		pips_row.add_child(pip)
		pips.append(pip)

	event_hud_pill = PanelContainer.new()
	event_hud_pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	event_hud_pill.custom_minimum_size = Vector2(0, 28)
	event_hud_style = _flat(Color(1, 1, 1, 0.06), 14,
		Color(1, 1, 1, 0.08), 1, 14, 3)
	event_hud_pill.add_theme_stylebox_override("panel", event_hud_style)
	event_hud_pill.visible = false
	header.add_child(event_hud_pill)
	event_hud_label = _label("", 15, ThemeKit.text_secondary())
	event_hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_hud_pill.add_child(event_hud_label)

	# --- board -------------------------------------------------------------
	var board_wrap := Control.new()
	board_wrap.name = "BoardWrap"
	board_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_wrap.custom_minimum_size = Vector2(0, 300)
	board_wrap.clip_contents = true
	board_wrap.mouse_filter = Control.MOUSE_FILTER_PASS
	column.add_child(board_wrap)

	board_view = BoardView.new()
	board_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_wrap.add_child(board_view)

	# --- floating pause button --------------------------------------------
	pause_btn = _icon_button(PAUSE_ICON, "Пауза")
	pause_btn.custom_minimum_size = Vector2(44, 44)
	pause_btn.modulate = ThemeKit.icon_button_tint()
	pause_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause_btn.offset_left = -62
	pause_btn.offset_top = 16
	pause_btn.offset_right = -18
	pause_btn.offset_bottom = 60
	pause_btn.pressed.connect(_toggle_pause)
	add_child(pause_btn)


func _build_banner() -> void:
	banner_root = PanelContainer.new()
	banner_root.name = "BannerRoot"
	banner_root.anchor_left = 0.06
	banner_root.anchor_right = 0.94
	banner_root.anchor_top = 0.49
	banner_root.anchor_bottom = 0.645
	banner_root.offset_left = 0.0
	banner_root.offset_right = 0.0
	banner_root.offset_top = 0.0
	banner_root.offset_bottom = 0.0
	banner_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_style = _banner_style()
	banner_root.add_theme_stylebox_override("panel", banner_style)
	banner_root.modulate.a = 0.0
	add_child(banner_root)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	banner_root.add_child(margin)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 0)
	margin.add_child(box)

	banner = Label.new()
	banner.name = "BannerText"
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 38)
	banner.add_theme_color_override("font_color", ThemeKit.banner_text())
	banner.add_theme_color_override("font_shadow_color",
		Color(0.20, 0.28, 0.45, 0.25) if ThemeKit.is_light() else Color(0.03, 0.10, 0.22, 0.85))
	banner.add_theme_constant_override("shadow_offset_x", 0)
	banner.add_theme_constant_override("shadow_offset_y", 3)
	banner.add_theme_constant_override("shadow_outline_size", 4)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(banner)

	banner_sub = Label.new()
	banner_sub.text = "жидкости • реакции • хаос"
	banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_sub.add_theme_font_size_override("font_size", 16)
	banner_sub.add_theme_color_override("font_color", ThemeKit.banner_sub())
	banner_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(banner_sub)


func _build_overlays() -> void:
	# --- main menu ---------------------------------------------------------
	menu_overlay = _make_overlay(0.64)
	var menu_panel := _make_panel(520)
	(menu_overlay.get_node("Center") as CenterContainer).add_child(menu_panel)
	var menu_body: VBoxContainer = menu_panel.get_node("Margin/Body")

	menu_body.add_child(_centered_label("ELEMENT", 24, ThemeKit.accent_text(Color("#b9a8ff"))))

	var title := _centered_label("BLAST", 110, ThemeKit.text_primary())
	title.add_theme_font_override("font", _display_font())
	title.add_theme_color_override("font_shadow_color",
		Color(0.22, 0.30, 0.55, 0.18) if ThemeKit.is_light() else Color(0.55, 0.42, 1.0, 0.38))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 6)
	menu_body.add_child(title)

	play_button = _make_button("ИГРАТЬ", true, 96)
	play_button.add_theme_font_size_override("font_size", 34)
	play_button.pressed.connect(start_game)
	menu_body.add_child(play_button)

	var pulse := create_tween().set_loops()
	pulse.tween_property(play_button, "modulate", Color(1.06, 1.08, 1.14, 1.0), 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(play_button, "modulate", Color(1, 1, 1, 1), 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var tutorial_btn := _make_button("ОБУЧЕНИЕ", false, 66)
	tutorial_btn.add_theme_font_size_override("font_size", 22)
	tutorial_btn.pressed.connect(_show_tutorial)
	menu_body.add_child(tutorial_btn)

	var settings_btn := _make_button("НАСТРОЙКИ", false, 66)
	settings_btn.add_theme_font_size_override("font_size", 22)
	settings_btn.pressed.connect(_show_settings)
	menu_body.add_child(settings_btn)

	var shop_btn := _make_button("МАГАЗИН", false, 66)
	shop_btn.add_theme_font_size_override("font_size", 22)
	shop_btn.pressed.connect(_show_store)
	menu_body.add_child(shop_btn)

	menu_best = _centered_label("Рекорд: 0", 24, ThemeKit.text_secondary())
	menu_body.add_child(menu_best)

	# --- game over ---------------------------------------------------------
	over_overlay = _make_overlay()
	var over_panel := _make_panel(540)
	(over_overlay.get_node("Center") as CenterContainer).add_child(over_panel)
	var over_body: VBoxContainer = over_panel.get_node("Margin/Body")

	over_body.add_child(_centered_label("ПОЛЕ ЗАПОЛНЕНО", 24, ThemeKit.text_secondary()))
	final_score = _centered_label("0", 100, ThemeKit.text_primary())
	final_score.add_theme_font_override("font", _display_font())
	final_score.add_theme_color_override("font_shadow_color", ThemeKit.score_shadow(Color("#b9a8ff")))
	final_score.add_theme_constant_override("shadow_offset_y", 5)
	over_body.add_child(final_score)

	final_best = _centered_label("Рекорд: 0", 24, ThemeKit.text_secondary())
	over_body.add_child(final_best)

	final_stats = _centered_label("", 21, ThemeKit.text_secondary())
	over_body.add_child(final_stats)

	new_record_label = _centered_label("НОВЫЙ РЕКОРД!", 24,
		ThemeKit.accent_text(Color("#ffca63")))
	new_record_label.visible = false
	over_body.add_child(new_record_label)

	var over_buttons := HBoxContainer.new()
	over_buttons.add_theme_constant_override("separation", 12)
	over_body.add_child(over_buttons)
	var again := _make_button("ЕЩЁ РАЗ", true, 70)
	again.pressed.connect(start_game)
	over_buttons.add_child(again)
	var to_menu := _make_button("В МЕНЮ", false, 70)
	to_menu.pressed.connect(go_to_menu)
	over_buttons.add_child(to_menu)

	# --- pause -------------------------------------------------------------
	pause_overlay = _make_overlay()
	var pause_panel := _make_panel(460)
	(pause_overlay.get_node("Center") as CenterContainer).add_child(pause_panel)
	var pause_body: VBoxContainer = pause_panel.get_node("Margin/Body")

	pause_body.add_child(_centered_label("ПАУЗА", 24, ThemeKit.text_secondary()))
	var pause_title := _centered_label("Стихии ждут", 56, ThemeKit.text_primary())
	pause_title.add_theme_color_override("font_shadow_color", Color(0.25, 0.65, 1.0, 0.3))
	pause_title.add_theme_constant_override("shadow_offset_y", 4)
	pause_body.add_child(pause_title)
	pause_stats = _centered_label("", 22, ThemeKit.text_secondary())
	pause_body.add_child(pause_stats)

	var resume_btn := _make_button("ПРОДОЛЖИТЬ", true, 70)
	resume_btn.pressed.connect(_toggle_pause)
	pause_body.add_child(resume_btn)
	var restart_btn := _make_button("ЗАНОВО", false, 62)
	restart_btn.pressed.connect(start_game)
	pause_body.add_child(restart_btn)
	sound_button = _make_button("ЗВУК", false, 62)
	sound_button.pressed.connect(_toggle_sound)
	pause_body.add_child(sound_button)
	var pause_menu_btn := _make_button("В МЕНЮ", false, 62)
	pause_menu_btn.pressed.connect(go_to_menu)
	pause_body.add_child(pause_menu_btn)


# ---------------------------------------------------------------------------
# Tutorial
# ---------------------------------------------------------------------------

func _build_tutorial_overlay() -> void:
	tutorial_overlay = _make_overlay(0.82)
	var panel := _make_panel(620)
	(tutorial_overlay.get_node("Center") as CenterContainer).add_child(panel)
	var body: VBoxContainer = panel.get_node("Margin/Body")

	body.add_child(_centered_label("ОБУЧЕНИЕ", 24, ThemeKit.text_secondary()))
	var title := _centered_label("КАК ИГРАТЬ", 48, ThemeKit.text_primary())
	title.add_theme_font_override("font", _display_font())
	body.add_child(title)

	var intro := _centered_label(
		"Ставь фигуры на поле и собирай полные линии. Каждые 2 хода стихии пробуждаются: клетки рассыпаются на частицы, текут, горят и реагируют, а затем собираются обратно.\n\nСобытия приходят сами: событие живёт несколько ходов, меняет погоду, фон и стихии, потом уходит. Между событиями — затишье.",
		18, ThemeKit.text_secondary())
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size = Vector2(520, 0)
	body.add_child(intro)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 470)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)

	var last_group := ""
	for entry in ElementInfo.ELEMENTS:
		var group := str(entry.get("group", ""))
		if group != last_group:
			var header := _centered_label(group.to_upper(), 15,
				ThemeKit.text_muted())
			header.custom_minimum_size = Vector2(0, 26)
			list.add_child(header)
			last_group = group
		list.add_child(_tutorial_row(entry))

	var close_btn := _make_button("ПОНЯТНО", true, 64)
	close_btn.pressed.connect(_hide_tutorial)
	body.add_child(close_btn)


func _tutorial_row(entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var color := Color(str(entry.get("color", "#ffffff")))
	var dot := Panel.new()
	dot.custom_minimum_size = Vector2(14, 14)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var dot_style := _flat(color, 7)
	dot_style.shadow_color = Color(color.r, color.g, color.b, 0.45)
	dot_style.shadow_size = 4
	dot.add_theme_stylebox_override("panel", dot_style)
	row.add_child(dot)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", -2)
	var name_label := _label(str(entry.get("name", "")), 18,
		ThemeKit.chip_text(color))
	col.add_child(name_label)
	var desc := _label(str(entry.get("desc", "")), 15, ThemeKit.text_secondary())
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(470, 0)
	col.add_child(desc)
	row.add_child(col)
	return row


func _show_tutorial() -> void:
	sfx.play("ui")
	_show_overlay(tutorial_overlay)


func _hide_tutorial() -> void:
	sfx.play("ui")
	_hide_overlay(tutorial_overlay)


# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------

func _build_settings_overlay() -> void:
	settings_overlay = _make_overlay(0.80)
	var panel := _make_panel(520)
	(settings_overlay.get_node("Center") as CenterContainer).add_child(panel)
	var body: VBoxContainer = panel.get_node("Margin/Body")

	body.add_child(_centered_label("НАСТРОЙКИ", 24, ThemeKit.text_secondary()))
	var title := _centered_label("НАСТРОЙКИ", 48, ThemeKit.text_primary())
	title.add_theme_font_override("font", _display_font())
	body.add_child(title)

	body.add_child(_label("ТЕМА", 20, ThemeKit.text_secondary()))
	var theme_row := HBoxContainer.new()
	theme_row.add_theme_constant_override("separation", 10)
	body.add_child(theme_row)
	var dark_btn := _make_button("ТЁМНАЯ", not ThemeKit.is_light(), 62)
	dark_btn.add_theme_font_size_override("font_size", 20)
	dark_btn.pressed.connect(_set_theme.bind("dark"))
	theme_row.add_child(dark_btn)
	var light_btn := _make_button("СВЕТЛАЯ", ThemeKit.is_light(), 62)
	light_btn.add_theme_font_size_override("font_size", 20)
	light_btn.pressed.connect(_set_theme.bind("light"))
	theme_row.add_child(light_btn)

	body.add_child(_label("РАЗМЕР ПОЛЯ", 20, ThemeKit.text_secondary()))
	var size_row := HBoxContainer.new()
	size_row.add_theme_constant_override("separation", 10)
	body.add_child(size_row)
	for size in [6, 8, 10]:
		var size_btn := _make_button("%d×%d" % [size, size], size == game.rows, 62)
		size_btn.add_theme_font_size_override("font_size", 22)
		size_btn.pressed.connect(_set_board_size.bind(size))
		size_row.add_child(size_btn)

	var back_btn := _make_button("НАЗАД", false, 62)
	back_btn.pressed.connect(_hide_settings)
	body.add_child(back_btn)


func _show_settings() -> void:
	sfx.play("ui")
	_show_overlay(settings_overlay)


func _hide_settings() -> void:
	sfx.play("ui")
	_hide_overlay(settings_overlay)


# ---------------------------------------------------------------------------
# Store and ads
# ---------------------------------------------------------------------------

func _build_store_overlay() -> void:
	store_overlay = _make_overlay(0.82)
	var panel := _make_panel(620)
	(store_overlay.get_node("Center") as CenterContainer).add_child(panel)
	var body: VBoxContainer = panel.get_node("Margin/Body")

	body.add_child(_centered_label("МАГАЗИН", 24, ThemeKit.text_secondary()))
	var title := _centered_label("ПОДДЕРЖИ ИГРУ", 46, ThemeKit.text_primary())
	title.add_theme_font_override("font", _display_font())
	body.add_child(title)

	store_status_label = _centered_label("", 18, Color("#ffca63"))
	body.add_child(store_status_label)

	store_products_box = VBoxContainer.new()
	store_products_box.add_theme_constant_override("separation", 9)
	body.add_child(store_products_box)

	if Monetization.TEST_MODE:
		var note := _centered_label(
			"Тестовый режим: покупки работают локально. Для реальных платежей подключите RuStore Billing.",
			14, ThemeKit.text_muted())
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.custom_minimum_size = Vector2(500, 0)
		body.add_child(note)

	var back_btn := _make_button("НАЗАД", false, 62)
	back_btn.pressed.connect(_hide_store)
	body.add_child(back_btn)
	_refresh_store()


func _refresh_store() -> void:
	if store_products_box == null:
		return
	for child in store_products_box.get_children():
		store_products_box.remove_child(child)
		child.queue_free()
	for entry in Monetization.PRODUCTS:
		var id := str(entry["id"])
		var owned := Monetization.is_owned(id)
		var row := PanelContainer.new()
		var bg := ThemeKit.button_secondary_bg()
		row.add_theme_stylebox_override("panel",
			_flat(bg, 18, ThemeKit.panel_border(), 1, 14, 10))
		store_products_box.add_child(row)

		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		row.add_child(col)
		col.add_child(_label(str(entry["title"]), 22, ThemeKit.text_primary()))
		var desc := _label(str(entry["desc"]), 15, ThemeKit.text_secondary())
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size = Vector2(500, 0)
		col.add_child(desc)

		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 10)
		col.add_child(line)
		var price := _label(str(entry["price"]), 22, ThemeKit.accent_text(Color("#ffca63")))
		price.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(price)
		var buy := _make_button("КУПЛЕНО" if owned else "КУПИТЬ", not owned, 48)
		buy.add_theme_font_size_override("font_size", 18)
		buy.disabled = owned
		buy.custom_minimum_size = Vector2(180, 48)
		buy.pressed.connect(_buy_product.bind(id))
		line.add_child(buy)


func _show_store() -> void:
	sfx.play("ui")
	store_status_label.text = ""
	_refresh_store()
	_show_overlay(store_overlay)


func _hide_store() -> void:
	sfx.play("ui")
	_hide_overlay(store_overlay)


func _buy_product(id: String) -> void:
	sfx.play("ui")
	store_status_label.text = "Обработка покупки…"
	await Monetization.purchase(id)


func _on_purchase_completed(id: String) -> void:
	sfx.play("combo")
	store_status_label.text = "Покупка открыта: " + str(Monetization.product(id).get("title", id))
	_refresh_store()
	_update_hud()


func _on_purchase_failed(_id: String, message: String) -> void:
	store_status_label.text = message


func _build_ad_overlay() -> void:
	ad_overlay = _make_overlay(0.94)
	var panel := _make_panel(560)
	(ad_overlay.get_node("Center") as CenterContainer).add_child(panel)
	var body: VBoxContainer = panel.get_node("Margin/Body")
	body.add_child(_centered_label("РЕКЛАМА", 24, Color("#ffca63")))
	var title := _centered_label("ТЕСТОВОЕ ОБЪЯВЛЕНИЕ", 40, ThemeKit.text_primary())
	title.add_theme_font_override("font", _display_font())
	body.add_child(title)
	var desc := _centered_label(
		"Здесь будет реальный interstitial от рекламной сети. Показ можно закрыть после короткой задержки.",
		18, ThemeKit.text_secondary())
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(460, 0)
	body.add_child(desc)
	ad_timer_label = _centered_label("", 20, ThemeKit.text_muted())
	body.add_child(ad_timer_label)
	ad_close_btn = _make_button("ЗАКРЫТЬ", true, 62)
	ad_close_btn.disabled = true
	ad_close_btn.pressed.connect(_close_ad)
	body.add_child(ad_close_btn)


func _on_ad_requested(reason: String) -> void:
	if ad_active or Profile.ads_removed:
		return
	ad_active = true
	ad_countdown = 4.0
	ad_close_btn.disabled = true
	ad_timer_label.text = "Закрыть можно через 4…"
	_ad_resume_game = game.mode == "playing" or game.mode == "awakening"
	if _ad_resume_game:
		game.pause()
		pause_btn.disabled = true
	sfx.play("ui")
	_show_overlay(ad_overlay)


func _close_ad() -> void:
	if not ad_active:
		return
	ad_active = false
	_hide_overlay(ad_overlay)
	if _ad_resume_game and game.mode == "paused":
		game.resume()
		pause_btn.disabled = false
	_ad_resume_game = false
	Monetization.on_ad_closed()
	sfx.play("ui")


func _update_ad_ui(delta: float) -> void:
	if not ad_active:
		return
	ad_countdown = maxf(0.0, ad_countdown - delta)
	if ad_countdown > 0.0:
		ad_timer_label.text = "Закрыть можно через %d…" % int(ceil(ad_countdown))
	else:
		ad_timer_label.text = "Можно закрыть"
		ad_close_btn.disabled = false


# ---------------------------------------------------------------------------
# Event card
# ---------------------------------------------------------------------------

func _refresh_event_visuals() -> void:
	if game == null or backdrop == null:
		return
	if game.event_active:
		backdrop.set_event(game.event_id(), game.event_accent(), game.event_background())
	else:
		backdrop.clear_event()
	if board_view != null:
		board_view.queue_redraw()


func _set_board_size(size: int) -> void:
	if game == null or size == game.rows:
		return
	sfx.play("ui")
	Profile.set_board_size(size)
	_open_settings_after_reload = true
	get_tree().reload_current_scene()


func _set_theme(value: String) -> void:
	if Profile.theme == value:
		return
	sfx.play("ui")
	Profile.set_theme(value)
	_open_settings_after_reload = true
	get_tree().reload_current_scene()


# ---------------------------------------------------------------------------
# UI helpers
# ---------------------------------------------------------------------------

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _centered_label(text: String, font_size: int, color: Color) -> Label:
	var label := _label(text, font_size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _display_font() -> Font:
	if _display_font_res == null:
		var font := SystemFont.new()
		font.font_names = PackedStringArray([
			"Arial Rounded MT Bold", "Segoe UI Black", "Arial Black", "Verdana",
		])
		font.font_weight = 700
		_display_font_res = font
	return _display_font_res


func _flat(bg: Color, radius: int, border := Color(0, 0, 0, 0), border_width := 0,
		pad_h := 0, pad_v := 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.border_color = border
	style.content_margin_left = pad_h
	style.content_margin_right = pad_h
	style.content_margin_top = pad_v
	style.content_margin_bottom = pad_v
	style.anti_aliasing = true
	return style


func _icon_button(icon: Texture2D, tooltip: String) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.icon = icon
	button.expand_icon = true
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(54, 54)
	button.add_theme_stylebox_override("normal",
		_flat(ThemeKit.button_secondary_bg(), 15, ThemeKit.button_secondary_border(), 1, 7, 7))
	button.add_theme_stylebox_override("hover",
		_flat(ThemeKit.button_secondary_hover(), 15, ThemeKit.button_secondary_border(), 1, 7, 7))
	button.add_theme_stylebox_override("pressed",
		_flat(ThemeKit.button_secondary_pressed(), 15, ThemeKit.button_secondary_border(), 1, 7, 7))
	button.add_theme_stylebox_override("focus", _flat(Color(0, 0, 0, 0), 15))
	return button


func _banner_style() -> StyleBoxFlat:
	var style := _flat(ThemeKit.banner_bg(Color("#8fa8ff")), 22,
		Color(0.35, 0.75, 1.0, 0.22), 1)
	style.shadow_color = Color(0.10, 0.50, 1.0, 0.10 if ThemeKit.is_light() else 0.18)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 6)
	return style


func _make_button(text: String, primary: bool, height: int) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 24)

	var normal: StyleBoxFlat
	var hover: StyleBoxFlat
	var pressed: StyleBoxFlat
	if primary:
		normal = _flat(ThemeKit.button_primary(), 19, Color(0, 0, 0, 0), 0, 24, 14)
		normal.shadow_color = Color(0.25, 0.70, 1.0, 0.28)
		normal.shadow_size = 10
		normal.shadow_offset = Vector2(0, 5)
		hover = _flat(ThemeKit.button_primary_hover(), 19, Color(0, 0, 0, 0), 0, 24, 14)
		hover.shadow_color = Color(0.25, 0.70, 1.0, 0.38)
		hover.shadow_size = 12
		hover.shadow_offset = Vector2(0, 5)
		pressed = _flat(ThemeKit.button_primary_pressed(), 19, Color(0, 0, 0, 0), 0, 24, 14)
		button.add_theme_color_override("font_color", ThemeKit.button_primary_text())
		button.add_theme_color_override("font_hover_color", ThemeKit.button_primary_text())
		button.add_theme_color_override("font_pressed_color", ThemeKit.button_primary_text())
	else:
		normal = _flat(ThemeKit.button_secondary_bg(), 17,
			ThemeKit.button_secondary_border(), 1, 20, 12)
		hover = _flat(ThemeKit.button_secondary_hover(), 17,
			ThemeKit.button_secondary_border(), 1, 20, 12)
		pressed = _flat(ThemeKit.button_secondary_pressed(), 17,
			ThemeKit.button_secondary_border(), 1, 20, 12)
		button.add_theme_color_override("font_color", ThemeKit.button_secondary_text())
		button.add_theme_color_override("font_hover_color", ThemeKit.button_secondary_text())
		button.add_theme_color_override("font_pressed_color", ThemeKit.button_secondary_text())

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", _flat(Color(0, 0, 0, 0), 17))
	button.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.28))
	return button


func _make_overlay(dim_alpha := -1.0) -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.visible = false
	add_child(root)

	var dim := ColorRect.new()
	var dim_color := ThemeKit.overlay_dim()
	dim_color.a = 0.64 if ThemeKit.is_light() else 0.76
	if dim_alpha >= 0.0:
		dim_color.a = dim_alpha
	dim.color = dim_color
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	return root


func _make_panel(width: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, 0)
	var style := _flat(ThemeKit.panel_bg(), 28, ThemeKit.panel_border(), 1)
	style.shadow_color = ThemeKit.panel_shadow()
	style.shadow_size = 24
	style.shadow_offset = Vector2(0, 12)
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)

	var body := VBoxContainer.new()
	body.name = "Body"
	body.add_theme_constant_override("separation", 14)
	margin.add_child(body)
	return panel


func _show_overlay(overlay: Control) -> void:
	if overlay == null:
		return
	if _overlay_tweens.has(overlay):
		var old: Tween = _overlay_tweens[overlay]
		if old != null and old.is_valid():
			old.kill()
	overlay.visible = true
	overlay.modulate.a = 0.0
	var tween := create_tween()
	_overlay_tweens[overlay] = tween
	tween.tween_property(overlay, "modulate:a", 1.0, 0.16)


func _hide_overlay(overlay: Control) -> void:
	if overlay == null or not overlay.visible:
		return
	if _overlay_tweens.has(overlay):
		var old: Tween = _overlay_tweens[overlay]
		if old != null and old.is_valid():
			old.kill()
	var tween := create_tween()
	_overlay_tweens[overlay] = tween
	tween.tween_property(overlay, "modulate:a", 0.0, 0.12)
	tween.tween_callback(func() -> void: overlay.visible = false)


# ---------------------------------------------------------------------------
# Game flow
# ---------------------------------------------------------------------------

func start_game() -> void:
	session += 1
	sfx.play("ui")
	_hide_overlay(menu_overlay)
	_hide_overlay(over_overlay)
	_hide_overlay(pause_overlay)
	_set_hud_visible(true)
	pause_btn.disabled = false
	board_view.clear_fx()
	game.start()
	_refresh_event_visuals()
	display_score = 0.0
	score_label.text = "0"
	charge_value = 1.0
	_update_hud()


func go_to_menu() -> void:
	session += 1
	sfx.play("ui")
	game.reset()
	game.best = Profile.best
	board_view.clear_fx()
	_refresh_event_visuals()
	_hide_overlay(over_overlay)
	_hide_overlay(pause_overlay)
	menu_best.text = "Рекорд: %d" % Profile.best
	display_score = 0.0
	score_label.text = "0"
	charge_value = 1.0
	_update_hud()
	_set_hud_visible(false)
	_show_overlay(menu_overlay)


func _set_hud_visible(value: bool) -> void:
	if score_label != null:
		score_label.visible = value
	if temp_value_label != null:
		temp_value_label.visible = value
	for pip in pips:
		pip.visible = value
	if event_hud_pill != null:
		event_hud_pill.visible = value and game != null and game.event_active
	if pause_btn != null:
		pause_btn.visible = value


func _toggle_pause() -> void:
	if game.mode == "playing" or game.mode == "awakening":
		pause_stats.text = "Счёт %d   •   Рекорд %d" % [game.score, Profile.best]
		if game.event_active:
			pause_stats.text += "\n%s · ещё %d %s" % [
				game.event_name(), game.event_moves_left,
				_plural_hod(game.event_moves_left)]
		game.pause()
		pause_btn.disabled = true
		_show_overlay(pause_overlay)
		sfx.play("ui")
	elif game.mode == "paused":
		game.resume()
		pause_btn.disabled = false
		_hide_overlay(pause_overlay)
		sfx.play("ui")


func _toggle_sound() -> void:
	Profile.set_muted(not Profile.muted)
	_update_sound_button()
	if not Profile.muted:
		sfx.play("ui")


func _update_sound_button() -> void:
	if sound_button == null:
		return
	sound_button.text = "ЗВУК: ВЫКЛ" if Profile.muted else "ЗВУК: ВКЛ"


func _temperature_name(value: int) -> String:
	return str(ElementGame.TEMP_NAMES.get(value, "НОРМА"))


func _plural_hod(value: int) -> String:
	var mod100 := value % 100
	if mod100 >= 11 and mod100 <= 14:
		return "ходов"
	match value % 10:
		1:
			return "ход"
		2, 3, 4:
			return "хода"
	return "ходов"


func _update_temperature_ui(animate: bool) -> void:
	if temp_value_label == null or game == null:
		return
	var accent: Color = game.event_accent()
	temp_value_label.text = "%d°C" % game.temperature_degrees
	temp_value_label.add_theme_color_override("font_color", ThemeKit.accent_text(accent))
	if score_label != null:
		score_label.add_theme_color_override("font_color", ThemeKit.score_color(accent))
		score_label.add_theme_color_override("font_shadow_color", ThemeKit.score_shadow(accent))
	if pip_style != null:
		pip_style.bg_color = accent
		pip_style.shadow_color = Color(accent.r, accent.g, accent.b, 0.45)
	if banner_style != null:
		banner_style.bg_color = ThemeKit.banner_bg(accent)
		banner_style.border_color = Color(accent.r, accent.g, accent.b, 0.50)
		banner_style.shadow_color = Color(accent.r, accent.g, accent.b,
			0.12 if ThemeKit.is_light() else 0.22)
	if animate:
		if _temp_tween != null and _temp_tween.is_valid():
			_temp_tween.kill()
		temp_value_label.pivot_offset = temp_value_label.size * 0.5
		temp_value_label.scale = Vector2(1.28, 1.28)
		_temp_tween = create_tween()
		_temp_tween.tween_property(temp_value_label, "scale", Vector2.ONE, 0.26) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _update_hud() -> void:
	if game == null:
		return
	_update_temperature_ui(false)
	var left := game.moves_left
	for i in pips.size():
		pips[i].modulate.a = 1.0 if i < left else 0.22
	_update_event_hud()


func _bump_score() -> void:
	if _score_tween != null and _score_tween.is_valid():
		_score_tween.kill()
	score_label.pivot_offset = score_label.size * 0.5
	score_label.scale = Vector2(1.16, 1.16)
	_score_tween = create_tween()
	_score_tween.tween_property(score_label, "scale", Vector2.ONE, 0.20) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _show_banner(text: String, subtitle := "") -> void:
	if banner_tween != null and banner_tween.is_valid():
		banner_tween.kill()
	banner.text = text
	if subtitle != "":
		banner_sub.text = subtitle
	banner_root.modulate.a = 0.0
	banner_tween = create_tween()
	banner_tween.tween_property(banner_root, "modulate:a", 1.0, 0.16)
	banner_tween.tween_interval(1.35)
	banner_tween.tween_property(banner_root, "modulate:a", 0.0, 0.42)


func _play_place_element(element: String) -> void:
	match element:
		"water", "oil":
			sfx.play("drop", 1.18)
		"acid":
			sfx.play("acid", 1.35)
		"fire", "lava":
			sfx.play("fire", 1.22)
		"ice", "snow", "crystal":
			sfx.play("freeze", 1.18)


func _play_surge_sound(kind: String) -> void:
	match kind:
		"water":
			sfx.play("water", 0.95)
		"acid":
			sfx.play("acid", 0.92)
		"lava":
			sfx.play("lava", 0.90)
		"fire":
			sfx.play("fire", 0.94)
		"snow", "ice":
			sfx.play("freeze", 0.92)
		"plant", "seaweed", "spore", "flower":
			sfx.play("grow", 0.90)
		"gunpowder":
			sfx.play("explosion", 1.02)
		"oil":
			sfx.play("water", 1.22)
		_:
			sfx.play("surge")


func _on_invalid_attempt() -> void:
	sfx.play("invalid")


func _on_piece_picked() -> void:
	sfx.play("pickup")


func _count_label(label: Label, target: int, duration: float) -> void:
	if _count_tween != null and _count_tween.is_valid():
		_count_tween.kill()
	label.text = "0"
	_count_tween = create_tween()
	_count_tween.tween_method(
		func(value: float) -> void: label.text = str(int(round(value))),
		0.0, float(target), duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _on_game_event(kind: String, data: Dictionary) -> void:
	match kind:
		"start":
			pause_btn.disabled = false
			_update_hud()
		"event_start":
			_refresh_event_visuals()
			_update_hud()
			_update_temperature_ui(true)
			sfx.play("surge")
			_show_banner(game.event_name(), "СОБЫТИЕ · " + game.event_tagline())
		"event_end":
			_refresh_event_visuals()
			_update_hud()
			_update_temperature_ui(true)
			sfx.play("crystallize")
			_show_banner("ЗАТИШЬЕ", "%s · событие ушло" % str(data.get("event", {}).get("name", "")))
		"place":
			sfx.play("place")
			_play_place_element(str(data.get("element", "")))
			_update_hud()
			_bump_score()
		"clear":
			if int(data.get("lines", 1)) > 1:
				sfx.play("combo")
			else:
				sfx.play("clear")
			_update_hud()
			_bump_score()
		"sand_reactions":
			_update_hud()
			var events: Dictionary = data.get("events", {})
			if events.has("explode"):
				sfx.play("explosion", 0.96)
				reaction_cd = 0.24
			elif reaction_cd <= 0.0:
				if events.has("boil") or events.has("release") or events.has("extinguish"):
					sfx.play("steam", 0.95)
				elif events.has("freeze") or events.has("condense") or events.has("solidify"):
					sfx.play("freeze", 0.98)
				elif events.has("grow") or events.has("spore") or events.has("absorb"):
					sfx.play("grow", 0.95)
				elif events.has("ignite") or events.has("burn"):
					sfx.play("fire", 1.05)
				elif events.has("obsidian"):
					sfx.play("obsidian")
				elif events.has("dissolve") or events.has("melt") or events.has("dilute"):
					sfx.play("dissolve")
				reaction_cd = 0.20
		"temperature":
			var temp_delta := int(data.get("delta", 0))
			_update_hud()
			_update_temperature_ui(true)
			if temp_delta > 0:
				sfx.play("heat", 0.90 + minf(absf(float(temp_delta)), 30.0) * 0.01)
			else:
				sfx.play("cold", 0.95 + minf(absf(float(temp_delta)), 30.0) * 0.01)
		"awaken_surge":
			_play_surge_sound(str(data.get("kind", "")))
		"awaken_start":
			sfx.play("awaken")
			if game.event_active:
				banner_sub.text = "%s · %d°C · %s" % [
					game.event_name(), game.temperature_degrees, game.event_tagline()]
			else:
				banner_sub.text = "%s · %d°C · жидкости · реакции" % [
					_temperature_name(game.temperature), game.temperature_degrees]
			_show_banner("СТИХИИ ПРОБУЖДАЮТСЯ")
			_update_hud()
		"awaken_end":
			sfx.play("crystallize")
			_update_hud()
		"game_over":
			sfx.play("game_over")
			Profile.set_best(int(data.get("best", game.best)))
			game.best = Profile.best
			pause_btn.disabled = true
			session += 1
			var guard := session
			_update_hud()
			await get_tree().create_timer(0.65).timeout
			if guard != session or game.mode != "gameover":
				return
			final_best.text = "Рекорд: %d" % Profile.best
			final_stats.text = "Линий: %d   •   Реакций: %d\nСобытие: %s" % [
				int(game.stats["lines"]), int(game.stats["reactions"]),
				game.last_event_name() if game.last_event_name() != "" else "—"]
			new_record_label.visible = bool(data.get("new_record", false))
			_show_overlay(over_overlay)
			_set_hud_visible(false)
			_count_label(final_score, int(data.get("score", game.score)), 0.8)
			Monetization.request_interstitial("game_over")
		"invalid":
			sfx.play("invalid")


# ---------------------------------------------------------------------------
# Debug / CLI helpers (used for automated screenshots and play-testing)
# ---------------------------------------------------------------------------

func _handle_cli() -> void:
	var args := OS.get_cmdline_user_args()
	var shot_path := ""
	var demo := false
	var delay := -1.0
	var screen := ""
	var event_id := ""
	var style_id := -1
	for arg in args:
		if arg.begins_with("--shot="):
			shot_path = arg.substr(7)
		elif arg.begins_with("--delay="):
			delay = maxf(0.5, arg.substr(8).to_float())
		elif arg.begins_with("--screen="):
			screen = arg.substr(9)
		elif arg.begins_with("--event="):
			event_id = arg.substr(8)
		elif arg.begins_with("--style="):
			style_id = clampi(int(arg.substr(8)), 0, 2)
		elif arg == "--demo":
			demo = true

	if delay < 0.0:
		delay = 3.8 if demo else 1.2

	if demo:
		_run_demo()
	elif screen == "start":
		start_game()
		if event_id != "":
			game.force_event(event_id)
			_refresh_event_visuals()
			_update_hud()
	elif screen == "boom":
		start_game()
		await get_tree().create_timer(0.25).timeout
		game.board[7][3] = {"t": "gunpowder", "born": 0.0, "flash": 0.0}
		game.board[7][4] = {"t": "fire", "born": 0.0, "flash": 0.0}
		game.begin_awakening()
	elif screen == "elements":
		start_game()
		await get_tree().create_timer(0.3).timeout
		var showcase := [
			{"r": 7, "c": 0, "t": "fire"},
			{"r": 7, "c": 2, "t": "oil"},
			{"r": 7, "c": 4, "t": "plant"},
			{"r": 7, "c": 6, "t": "gunpowder"},
			{"r": 6, "c": 3, "t": "glass"},
		]
		for entry in showcase:
			game.board[int(entry["r"])][int(entry["c"])] = {
				"t": entry["t"], "born": 0.0, "flash": 0.0,
			}
		var demo_elements := ["fire", "oil", "plant"]
		for i in 3:
			game.pieces[i]["element"] = demo_elements[i]
		_update_hud()
	elif screen == "flood" or screen == "firestorm" \
			or screen == "ice_age" or screen == "bloom":
		start_game()
		game.force_event(event_id if event_id != "" else screen)
		await get_tree().create_timer(0.25).timeout
		_debug_event_board(event_id if event_id != "" else screen)
		game.begin_awakening()
		_update_hud()
	elif screen == "hot" or screen == "cold":
		start_game()
		await get_tree().create_timer(0.25).timeout
		game.set_temperature_degrees(90 if screen == "hot" else -30)
		game.board[7][2] = {"t": "ice", "born": 0.0, "flash": 0.0}
		game.board[7][3] = {"t": "water", "born": 0.0, "flash": 0.0}
		game.board[7][4] = {"t": "lava", "born": 0.0, "flash": 0.0}
		game.board[6][3] = {"t": "stone", "born": 0.0, "flash": 0.0}
		game.begin_awakening()
		_update_hud()
		_update_temperature_ui(true)
	elif screen == "pause":
		start_game()
		await get_tree().create_timer(0.25).timeout
		_toggle_pause()
	elif screen == "tutorial":
		_show_tutorial()
	elif screen == "settings":
		_show_settings()
	elif screen == "store":
		_show_store()
	elif screen == "ad":
		_on_ad_requested("debug")
	elif screen == "gameover":
		start_game()
		game.force_event(event_id if event_id != "" else "flood")
		await get_tree().create_timer(0.25).timeout
		final_best.text = "Рекорд: 1280"
		final_stats.text = "Линий: 12   •   Реакций: 845\nСобытие: %s" % game.last_event_name()
		new_record_label.visible = true
		_show_overlay(over_overlay)
		_set_hud_visible(false)
		_count_label(final_score, 1280, 0.8)

	if style_id >= 0 and board_view != null:
		board_view.visual_style = style_id

	if shot_path != "":
		await get_tree().create_timer(delay).timeout
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		var error := image.save_png(shot_path)
		print("SCREENSHOT ", error, " -> ", shot_path)
		get_tree().quit()


func _debug_event_board(id: String) -> void:
	var cells: Array = []
	var tray: Array = []
	match id:
		"flood":
			cells = [
				[7, 0, "water"], [7, 2, "water"], [7, 4, "seaweed"],
				[7, 6, "sponge"], [6, 1, "lava"], [6, 3, "water"],
				[6, 5, "water"], [5, 2, "seaweed"],
			]
			tray = ["water", "seaweed", "sponge"]
		"firestorm":
			cells = [
				[7, 0, "lava"], [7, 2, "fire"], [7, 4, "coal"],
				[7, 6, "ash"], [6, 1, "oil"], [6, 3, "lava"],
				[6, 5, "coal"], [5, 3, "fire"],
			]
			tray = ["fire", "coal", "ash"]
		"ice_age":
			cells = [
				[7, 0, "ice"], [7, 2, "snow"], [7, 4, "crystal"],
				[7, 6, "water"], [6, 1, "lava"], [6, 3, "ice"],
				[6, 5, "snow"], [5, 3, "crystal"],
			]
			tray = ["ice", "snow", "crystal"]
		"bloom":
			cells = [
				[7, 0, "plant"], [7, 2, "water"], [7, 4, "flower"],
				[7, 6, "spore"], [6, 1, "water"], [6, 3, "plant"],
				[6, 5, "flower"], [5, 3, "spore"],
			]
			tray = ["plant", "spore", "flower"]
	for entry in cells:
		game.board[int(entry[0])][int(entry[1])] = {
			"t": entry[2], "born": 0.0, "flash": 0.0,
		}
	for i in 3:
		game.pieces[i]["element"] = tray[i]


func _run_demo() -> void:
	await get_tree().create_timer(0.4).timeout
	start_game()
	for step in 28:
		if game.mode == "gameover":
			break
		if game.mode != "playing":
			await get_tree().create_timer(0.2).timeout
			continue
		var index := -1
		for i in game.pieces.size():
			if not bool(game.pieces[i]["used"]):
				index = i
				break
		if index < 0:
			break
		var shape: Dictionary = game.pieces[index]["shape"]
		var spots: Array = []
		for r0 in game.rows - int(shape["h"]) + 1:
			for c0 in game.cols - int(shape["w"]) + 1:
				if game.can_place(shape, r0, c0):
					spots.append(Vector2i(c0, r0))
		if spots.is_empty():
			break
		var spot: Vector2i = spots[randi() % spots.size()]
		game.place_at(index, spot.y, spot.x)
		await get_tree().create_timer(0.30).timeout
