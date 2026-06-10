extends Control
## 設定モーダル(音量スライダー3種+フルスクリーン切替)。
## タイトル画面とポーズメニューの両方からインスタンス化して使う。

signal closed

const GOLD = Color(0.86, 0.68, 0.36)
const GOLD_HOVER = Color(1.0, 0.82, 0.48)
const PANEL_SIZE = Vector2(560, 432)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()

func _build_ui() -> void:
	var dim = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.62)
	add_child(dim)

	var panel = Panel.new()
	panel.position = (Vector2(1280, 720) - PANEL_SIZE) / 2.0
	panel.size = PANEL_SIZE
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.028, 0.062, 0.97)
	style.border_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var title = Label.new()
	title.text = "設定"
	title.position = Vector2(0, 22)
	title.size = Vector2(PANEL_SIZE.x, 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color(0.92, 0.84, 0.66))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	panel.add_child(title)

	var sep = ColorRect.new()
	sep.position = Vector2(40, 70)
	sep.size = Vector2(PANEL_SIZE.x - 80, 1)
	sep.color = Color(GOLD.r, GOLD.g, GOLD.b, 0.30)
	panel.add_child(sep)

	_add_volume_row(panel, "全体音量", 96, GameSettings.master_volume, GameSettings.set_master_volume)
	_add_volume_row(panel, "BGM音量", 156, GameSettings.bgm_volume, GameSettings.set_bgm_volume)
	_add_volume_row(panel, "効果音音量", 216, GameSettings.sfx_volume, GameSettings.set_sfx_volume)

	# フルスクリーン切替
	var fs_label = Label.new()
	fs_label.text = "フルスクリーン"
	fs_label.position = Vector2(48, 278)
	fs_label.size = Vector2(160, 30)
	fs_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fs_label.add_theme_font_size_override("font_size", 17)
	fs_label.add_theme_color_override("font_color", Color(0.86, 0.80, 0.70))
	panel.add_child(fs_label)

	var fs_check = CheckButton.new()
	fs_check.position = Vector2(228, 276)
	fs_check.button_pressed = GameSettings.fullscreen
	fs_check.toggled.connect(func(on: bool): GameSettings.set_fullscreen(on))
	panel.add_child(fs_check)

	var close_btn = _make_button("閉じる")
	close_btn.position = Vector2((PANEL_SIZE.x - 220) / 2.0, PANEL_SIZE.y - 84)
	close_btn.pressed.connect(_on_close)
	panel.add_child(close_btn)

func _add_volume_row(parent: Control, label_text: String, y: float, initial: float, setter: Callable) -> void:
	var label = Label.new()
	label.text = label_text
	label.position = Vector2(48, y)
	label.size = Vector2(160, 30)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color(0.86, 0.80, 0.70))
	parent.add_child(label)

	var value_label = Label.new()
	value_label.position = Vector2(PANEL_SIZE.x - 110, y)
	value_label.size = Vector2(62, 30)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.text = "%d%%" % roundi(initial * 100.0)
	value_label.add_theme_font_size_override("font_size", 16)
	value_label.add_theme_color_override("font_color", Color(0.92, 0.86, 0.72))
	parent.add_child(value_label)

	var slider = HSlider.new()
	slider.position = Vector2(228, y + 4)
	slider.size = Vector2(290, 24)
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = roundi(initial * 100.0)
	var groove = StyleBoxFlat.new()
	groove.bg_color = Color(0.10, 0.08, 0.16)
	groove.border_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.25)
	groove.set_border_width_all(1)
	groove.set_corner_radius_all(4)
	groove.content_margin_top = 6
	groove.content_margin_bottom = 6
	slider.add_theme_stylebox_override("slider", groove)
	var filled = StyleBoxFlat.new()
	filled.bg_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.45)
	filled.set_corner_radius_all(4)
	slider.add_theme_stylebox_override("grabber_area", filled)
	slider.add_theme_stylebox_override("grabber_area_highlight", filled)
	slider.value_changed.connect(func(v: float):
		setter.call(v / 100.0)
		value_label.text = "%d%%" % roundi(v)
	)
	parent.add_child(slider)

func _make_button(text: String) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.size = Vector2(220, 46)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color(0.86, 0.80, 0.70))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.78))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.84, 0.58))

	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.045, 0.033, 0.062, 0.85)
	style_normal.border_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.48)
	style_normal.set_border_width_all(1)
	style_normal.set_corner_radius_all(4)
	style_normal.set_content_margin_all(10)
	btn.add_theme_stylebox_override("normal", style_normal)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.12, 0.075, 0.12, 0.94)
	style_hover.border_color = GOLD_HOVER
	style_hover.set_border_width_all(2)
	style_hover.set_corner_radius_all(4)
	style_hover.set_content_margin_all(10)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_hover)
	btn.add_theme_stylebox_override("focus", style_hover)
	return btn

func _on_close() -> void:
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_close()
