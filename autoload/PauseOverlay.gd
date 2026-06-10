extends CanvasLayer
## ESCで開くポーズメニュー(autoload)。タイトル画面以外のどのシーンでも動く。
## ポーズ中は get_tree().paused でゲーム全体を停止する(本レイヤーのみ常時動作)。

const MAIN_SCENE_PATH = "res://scenes/Main.tscn"
const SettingsPanelScript = preload("res://scenes/ui/SettingsPanel.gd")

const GOLD = Color(0.86, 0.68, 0.36)
const GOLD_HOVER = Color(1.0, 0.82, 0.48)

var _root: Control
var _menu_box: Panel
var _confirm_box: Panel
var _settings: Control = null

func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _settings and _settings.visible:
		return  # SettingsPanel が自分で閉じる
	if _confirm_box.visible:
		_confirm_box.visible = false
		_menu_box.visible = true
		get_viewport().set_input_as_handled()
	elif _root.visible:
		_resume()
		get_viewport().set_input_as_handled()
	elif _can_pause():
		_open()
		get_viewport().set_input_as_handled()

func _can_pause() -> bool:
	var scene = get_tree().current_scene
	if scene == null:
		return false
	return scene.scene_file_path != MAIN_SCENE_PATH

func _open() -> void:
	get_tree().paused = true
	_menu_box.visible = true
	_confirm_box.visible = false
	_root.visible = true

func _resume() -> void:
	_root.visible = false
	get_tree().paused = false

func _return_to_title() -> void:
	_root.visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)

# ── UI構築 ────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	_root = Control.new()
	_root.name = "PauseRoot"
	_root.visible = false
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var scaler = get_node_or_null("/root/ScreenScale")
	if scaler and scaler.has_method("apply"):
		scaler.apply(_root)

	var dim = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.58)
	_root.add_child(dim)

	_menu_box = _make_box(Vector2(340, 300))
	_root.add_child(_menu_box)

	var title = Label.new()
	title.text = "一時停止"
	title.position = Vector2(0, 24)
	title.size = Vector2(340, 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color(0.92, 0.84, 0.66))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	_menu_box.add_child(title)

	var resume_btn = _make_button("再開")
	resume_btn.position = Vector2(60, 84)
	resume_btn.pressed.connect(_resume)
	_menu_box.add_child(resume_btn)

	var settings_btn = _make_button("設定")
	settings_btn.position = Vector2(60, 146)
	settings_btn.pressed.connect(_show_settings)
	_menu_box.add_child(settings_btn)

	var title_btn = _make_button("タイトルへ戻る")
	title_btn.position = Vector2(60, 208)
	title_btn.pressed.connect(_show_confirm)
	_menu_box.add_child(title_btn)

	_build_confirm_box()

func _build_confirm_box() -> void:
	_confirm_box = _make_box(Vector2(480, 220))
	_confirm_box.visible = false
	_root.add_child(_confirm_box)

	var msg = Label.new()
	msg.text = "タイトルへ戻りますか?\n進行は直前のマップ地点まで保存されています。"
	msg.position = Vector2(20, 30)
	msg.size = Vector2(440, 80)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.add_theme_font_size_override("font_size", 17)
	msg.add_theme_color_override("font_color", Color(0.88, 0.84, 0.74))
	_confirm_box.add_child(msg)

	var yes_btn = _make_button("戻る")
	yes_btn.size = Vector2(180, 46)
	yes_btn.position = Vector2(48, 140)
	yes_btn.pressed.connect(_return_to_title)
	_confirm_box.add_child(yes_btn)

	var no_btn = _make_button("キャンセル")
	no_btn.size = Vector2(180, 46)
	no_btn.position = Vector2(252, 140)
	no_btn.pressed.connect(func():
		_confirm_box.visible = false
		_menu_box.visible = true
	)
	_confirm_box.add_child(no_btn)

func _show_confirm() -> void:
	_menu_box.visible = false
	_confirm_box.visible = true

func _show_settings() -> void:
	if _settings == null:
		_settings = SettingsPanelScript.new()
		_root.add_child(_settings)
		_settings.closed.connect(func(): _settings.visible = false)
	else:
		_settings.visible = true
		_settings.move_to_front()

func _make_box(box_size: Vector2) -> Panel:
	var box = Panel.new()
	box.position = (Vector2(1280, 720) - box_size) / 2.0
	box.size = box_size
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.028, 0.062, 0.97)
	style.border_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	box.add_theme_stylebox_override("panel", style)
	return box

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
