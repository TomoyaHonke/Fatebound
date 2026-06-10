extends Control

const MAP_SCENE = "res://scenes/MapScreen.tscn"
const TITLE_ART = "res://assets/ui/title_fatebound.png"
const WINDOW_SIZE := Vector2i(2560, 1440)

const BG_COLOR = Color(0.018, 0.014, 0.026)
const GOLD = Color(0.86, 0.68, 0.36)
const GOLD_HOVER = Color(1.0, 0.82, 0.48)
const BTN_NORMAL = Color(0.045, 0.033, 0.062, 0.80)
const BTN_HOVER = Color(0.12, 0.075, 0.12, 0.92)
const MENU_WIDTH = 248.0
const STORY_PAGES := [
	{
		"image": "res://assets/backgrounds/story/story_01_hero_party.png",
		"text": "かつて、勇者一行には■■■という仲間がいた。"
	},
	{
		"image": "res://assets/backgrounds/story/story_02_betrayal.png",
		"text": "最後の戦いの果てに、■■■は仲間たちに裏切られ、奈落へ落とされた。"
	},
	{
		"image": "res://assets/backgrounds/story/story_03_fallen_angel_contract.png",
		"text": "死の淵で、■■■に手を差し伸べたのは堕天使だった。"
	},
	{
		"image": "res://assets/backgrounds/story/story_04_return_to_capital.png",
		"text": "奪われた名を取り戻すため、■■■は復讐者として王都へ戻る。"
	},
]

var _bg: ColorRect
var _title_art: TextureRect
var _overlay: ColorRect
var _bottom_scrim: ColorRect
var _mist: Control
var _menu_container: VBoxContainer
var _start_btn: Button
var _continue_btn: Button
var _story_btn: Button
var _settings_btn: Button
var _quit_btn: Button
var _settings_panel: Control = null
var _story_layer: Control
var _story_bg: TextureRect
var _story_text: Label
var _story_prev_btn: Button
var _story_next_btn: Button
var _story_return_btn: Button
var _story_page_index: int = 0
var _phase: float = 0.0

func _ready() -> void:
	_apply_window_size()
	_apply_screen_scale()
	GameState.reset_run()
	_build_ui()
	_animate_entrance()

func _apply_screen_scale() -> void:
	var scaler = get_node_or_null("/root/ScreenScale")
	if scaler and scaler.has_method("apply"):
		scaler.apply(self)

func _apply_window_size() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if GameSettings.fullscreen:
		return
	DisplayServer.window_set_size(WINDOW_SIZE)
	var usable_rect := DisplayServer.screen_get_usable_rect()
	DisplayServer.window_set_position(usable_rect.position + (usable_rect.size - WINDOW_SIZE) / 2)

func _build_ui() -> void:
	# Background
	_bg = ColorRect.new()
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.color = BG_COLOR
	add_child(_bg)

	_title_art = TextureRect.new()
	_title_art.name = "TitleArt"
	_title_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_title_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_title_art.texture = _load_title_texture()
	_title_art.modulate.a = 0.0
	add_child(_title_art)

	_overlay = ColorRect.new()
	_overlay.name = "ReadabilityOverlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.0, 0.0, 0.0, 0.16)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	_bottom_scrim = ColorRect.new()
	_bottom_scrim.name = "MenuScrim"
	_bottom_scrim.anchor_left = 0.0
	_bottom_scrim.anchor_top = 0.58
	_bottom_scrim.anchor_right = 1.0
	_bottom_scrim.anchor_bottom = 1.0
	_bottom_scrim.color = Color(0.0, 0.0, 0.0, 0.28)
	_bottom_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bottom_scrim)

	_mist = _MistLayer.new()
	_mist.name = "AmbientMist"
	_mist.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mist.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mist.modulate.a = 0.0
	add_child(_mist)

	_menu_container = VBoxContainer.new()
	_menu_container.name = "MenuContainer"
	_menu_container.anchor_left = 0.5
	_menu_container.anchor_top = 1.0
	_menu_container.anchor_right = 0.5
	_menu_container.anchor_bottom = 1.0
	_menu_container.offset_left = -MENU_WIDTH / 2.0
	_menu_container.offset_top = -322.0
	_menu_container.offset_right = MENU_WIDTH / 2.0
	_menu_container.offset_bottom = -34.0
	_menu_container.alignment = BoxContainer.ALIGNMENT_END
	_menu_container.add_theme_constant_override("separation", 10)
	_menu_container.modulate.a = 0.0
	add_child(_menu_container)

	_continue_btn = _make_button("続きから")
	_continue_btn.pressed.connect(_on_continue)
	_continue_btn.visible = SaveManager.has_run_save()
	_menu_container.add_child(_continue_btn)

	_start_btn = _make_button("ゲーム開始")
	_start_btn.pressed.connect(_on_start)
	_menu_container.add_child(_start_btn)

	_story_btn = _make_button("あらすじ")
	_story_btn.pressed.connect(_on_story)
	_menu_container.add_child(_story_btn)

	_settings_btn = _make_button("設定")
	_settings_btn.pressed.connect(_on_settings)
	_menu_container.add_child(_settings_btn)

	_quit_btn = _make_button("終了")
	_quit_btn.pressed.connect(_on_quit)
	_menu_container.add_child(_quit_btn)

	_build_story_layer()

func _load_title_texture() -> Texture2D:
	if ResourceLoader.exists(TITLE_ART):
		return load(TITLE_ART)

	var image := Image.load_from_file(TITLE_ART)
	if image:
		return ImageTexture.create_from_image(image)

	push_warning("Title art is missing or could not be loaded: %s" % TITLE_ART)
	return null

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)

	var image := Image.load_from_file(path)
	if image:
		return ImageTexture.create_from_image(image)

	push_warning("Image is missing or could not be loaded: %s" % path)
	return null

func _make_button(text: String) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(MENU_WIDTH, 46)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 19)
	btn.add_theme_color_override("font_color", Color(0.86, 0.80, 0.70))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.78))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.84, 0.58))
	btn.add_theme_color_override("font_focus_color", Color(1.0, 0.92, 0.78))

	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = BTN_NORMAL
	style_normal.border_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.48)
	style_normal.set_border_width_all(1)
	style_normal.set_corner_radius_all(4)
	style_normal.set_content_margin_all(10)
	btn.add_theme_stylebox_override("normal", style_normal)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = BTN_HOVER
	style_hover.border_color = GOLD_HOVER
	style_hover.set_border_width_all(2)
	style_hover.set_corner_radius_all(4)
	style_hover.set_content_margin_all(10)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_hover)
	btn.add_theme_stylebox_override("focus", style_hover)

	btn.mouse_entered.connect(func(): _tween_button_scale(btn, Vector2(1.03, 1.03)))
	btn.mouse_exited.connect(func(): _tween_button_scale(btn, Vector2.ONE))

	return btn

func _animate_entrance() -> void:
	var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.set_parallel(true)
	t.tween_property(_title_art, "modulate:a", 1.0, 1.0)
	t.tween_property(_mist, "modulate:a", 1.0, 1.4).set_delay(0.3)
	t.tween_property(_menu_container, "modulate:a", 1.0, 0.65).set_delay(0.45)
	t.tween_property(_menu_container, "position:y", -10.0, 0.65).as_relative().set_delay(0.45)

func _process(delta: float) -> void:
	_phase += delta
	if _mist:
		_mist.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not _story_layer or not _story_layer.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_close_story()
		get_viewport().set_input_as_handled()

func _on_start() -> void:
	SaveManager.delete_run_save()
	SaveManager.record_run_start()
	_go_to_map()

func _on_continue() -> void:
	if not SaveManager.load_run():
		# セーブが壊れていた場合は新規開始にフォールバック
		_continue_btn.visible = false
		GameState.reset_run()
		SaveManager.record_run_start()
	_go_to_map()

func _go_to_map() -> void:
	_start_btn.disabled = true
	_continue_btn.disabled = true
	_story_btn.disabled = true
	_settings_btn.disabled = true
	_quit_btn.disabled = true
	var t = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "modulate:a", 0.0, 0.5)
	t.tween_callback(func(): get_tree().change_scene_to_file(MAP_SCENE))

func _on_story() -> void:
	_story_page_index = 0
	_update_story_page()
	_story_layer.visible = true
	_story_layer.modulate.a = 0.0
	var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(_story_layer, "modulate:a", 1.0, 0.2)

func _on_settings() -> void:
	if _settings_panel == null:
		_settings_panel = preload("res://scenes/ui/SettingsPanel.gd").new()
		add_child(_settings_panel)
		_settings_panel.closed.connect(func(): _settings_panel.visible = false)
	else:
		_settings_panel.visible = true
		_settings_panel.move_to_front()

func _on_quit() -> void:
	get_tree().quit()

func _tween_button_scale(btn: Button, target_scale: Vector2) -> void:
	btn.pivot_offset = btn.size / 2.0
	var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	t.tween_property(btn, "scale", target_scale, 0.12)

func _build_story_layer() -> void:
	_story_layer = Control.new()
	_story_layer.name = "StoryLayer"
	_story_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_story_layer.visible = false
	add_child(_story_layer)

	_story_bg = TextureRect.new()
	_story_bg.name = "StoryBackground"
	_story_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_story_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_story_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_story_layer.add_child(_story_bg)

	var overlay = ColorRect.new()
	overlay.name = "StoryReadabilityOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.26)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_story_layer.add_child(overlay)

	var text_panel = PanelContainer.new()
	text_panel.name = "StoryTextPanel"
	text_panel.anchor_left = 0.5
	text_panel.anchor_top = 1.0
	text_panel.anchor_right = 0.5
	text_panel.anchor_bottom = 1.0
	text_panel.offset_left = -500.0
	text_panel.offset_top = -270.0
	text_panel.offset_right = 500.0
	text_panel.offset_bottom = -96.0
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.0, 0.0, 0.0, 0.62)
	panel_style.border_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.38)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(24)
	text_panel.add_theme_stylebox_override("panel", panel_style)
	_story_layer.add_child(text_panel)

	_story_text = Label.new()
	_story_text.name = "StoryText"
	_story_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_story_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_story_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_story_text.add_theme_font_size_override("font_size", 25)
	_story_text.add_theme_color_override("font_color", Color(0.92, 0.88, 0.80))
	_story_text.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_story_text.add_theme_constant_override("shadow_offset_x", 2)
	_story_text.add_theme_constant_override("shadow_offset_y", 2)
	text_panel.add_child(_story_text)

	var button_row = HBoxContainer.new()
	button_row.name = "StoryButtons"
	button_row.anchor_left = 0.5
	button_row.anchor_top = 1.0
	button_row.anchor_right = 0.5
	button_row.anchor_bottom = 1.0
	button_row.offset_left = -250.0
	button_row.offset_top = -78.0
	button_row.offset_right = 250.0
	button_row.offset_bottom = -30.0
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 12)
	_story_layer.add_child(button_row)

	_story_prev_btn = _make_button("戻る")
	_story_prev_btn.custom_minimum_size = Vector2(150, 46)
	_story_prev_btn.pressed.connect(_on_story_prev)
	button_row.add_child(_story_prev_btn)

	_story_next_btn = _make_button("次へ")
	_story_next_btn.custom_minimum_size = Vector2(150, 46)
	_story_next_btn.pressed.connect(_on_story_next)
	button_row.add_child(_story_next_btn)

	_story_return_btn = _make_button("タイトルへ戻る")
	_story_return_btn.custom_minimum_size = Vector2(190, 46)
	_story_return_btn.pressed.connect(_close_story)
	button_row.add_child(_story_return_btn)

func _update_story_page() -> void:
	if STORY_PAGES.is_empty():
		return
	_story_page_index = clampi(_story_page_index, 0, STORY_PAGES.size() - 1)
	var page: Dictionary = STORY_PAGES[_story_page_index]
	_story_bg.texture = _load_texture(page.get("image", ""))
	_story_text.text = page.get("text", "")
	_story_prev_btn.visible = _story_page_index > 0
	_story_next_btn.visible = _story_page_index < STORY_PAGES.size() - 1
	_story_return_btn.visible = _story_page_index == STORY_PAGES.size() - 1

func _on_story_prev() -> void:
	if _story_page_index <= 0:
		return
	_story_page_index -= 1
	_update_story_page()

func _on_story_next() -> void:
	if _story_page_index >= STORY_PAGES.size() - 1:
		return
	_story_page_index += 1
	_update_story_page()

func _close_story() -> void:
	if not _story_layer:
		return
	_story_layer.visible = false

class _MistLayer:
	extends Control

	func _draw() -> void:
		var time = Time.get_ticks_msec() / 1000.0
		var base_y = size.y * 0.80
		for i in 6:
			var drift = fmod(time * (12.0 + i * 2.5) + i * 117.0, size.x + 260.0) - 130.0
			var y = base_y + sin(time * 0.45 + i) * 18.0 + i * 9.0
			var alpha = 0.030 + float(i % 3) * 0.010
			draw_circle(Vector2(drift, y), 92.0 + i * 18.0, Color(0.50, 0.42, 0.58, alpha))
