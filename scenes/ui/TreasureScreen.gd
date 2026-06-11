extends Control

const MAP_SCENE  = "res://scenes/MapScreen.tscn"
const CARD_SCENE = "res://scenes/ui/CardNode.tscn"

const C_BG   = Color(0.02, 0.016, 0.027, 0.0)
const C_GOLD = Color(0.86, 0.72, 0.34)
const C_TEXT = Color(0.84, 0.78, 0.96)

var _reward_card_id: String = ""
var _card_node: Control
var _result_label: Label
var _take_btn: Button
var _skip_btn: Button
var _continue_btn: Button
var _choice_panel: Control


func _ready() -> void:
	_apply_screen_scale()
	GameState.complete_map_node(GameState.map_current_node_id)
	var pool = GameState.get_reward_options()
	_reward_card_id = pool[0] if not pool.is_empty() else ""
	_build_ui()

func _apply_screen_scale() -> void:
	var scaler = get_node_or_null("/root/ScreenScale")
	if scaler and scaler.has_method("apply"):
		scaler.apply(self)


func _build_ui() -> void:
	_add_background("shared_treasure")

	var canvas = _GlowCanvas.new()
	add_child(canvas)

	# Panel
	var panel = Panel.new()
	panel.position = Vector2(300, 100)
	panel.size = Vector2(680, 500)
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.030, 0.024, 0.055, 0.0)
	ps.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.0)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", ps)
	add_child(panel)

	var header = Label.new()
	header.text = "宝箱"
	header.position = Vector2(0, 14)
	header.size = Vector2(680, 26)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color(0.55, 0.20, 0.90, 0.80))
	panel.add_child(header)

	var title = Label.new()
	title.text = "封印された宝"
	title.position = Vector2(20, 46)
	title.size = Vector2(640, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", C_GOLD)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.80))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	panel.add_child(title)

	var desc = Label.new()
	desc.text = "古い宝箱の中に一枚のカードが眠っていた。"
	desc.position = Vector2(40, 96)
	desc.size = Vector2(600, 30)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", C_TEXT)
	panel.add_child(desc)

	# Card preview
	if not _reward_card_id.is_empty():
		var card_data = GameState.get_card(_reward_card_id)
		if not card_data.is_empty():
			var card_scene = load(CARD_SCENE)
			_card_node = card_scene.instantiate()
			_card_node.position = Vector2(275, 134)
			_card_node.setup(card_data, 0, false)
			_card_node.set_base_y(134)
			panel.add_child(_card_node)

	_result_label = Label.new()
	_result_label.position = Vector2(40, 355)
	_result_label.size = Vector2(600, 50)
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 15)
	_result_label.add_theme_color_override("font_color", Color(0.70, 0.90, 0.72))
	_result_label.visible = false
	panel.add_child(_result_label)

	_choice_panel = Control.new()
	_choice_panel.position = Vector2(90, 356)
	_choice_panel.size = Vector2(500, 110)
	panel.add_child(_choice_panel)

	_take_btn = _make_btn("カードを受け取る", Vector2(250, 28))
	_take_btn.pressed.connect(_on_take)
	_choice_panel.add_child(_take_btn)

	_skip_btn = _make_btn("立ち去る", Vector2(250, 82))
	_skip_btn.pressed.connect(_on_skip)
	_choice_panel.add_child(_skip_btn)

	_continue_btn = _make_action_btn("マップに戻る", Vector2(640, 550))
	_continue_btn.visible = false
	_continue_btn.pressed.connect(_on_continue)
	add_child(_continue_btn)

	modulate.a = 0.0
	var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "modulate:a", 1.0, 0.45)
	if _card_node:
		_card_node.modulate.a = 0.0
		t.parallel().tween_property(_card_node, "modulate:a", 1.0, 0.55).set_delay(0.18)


func _on_take() -> void:
	if not _reward_card_id.is_empty():
		GameState.add_card_to_deck(_reward_card_id)
		var card_data = GameState.get_card(_reward_card_id)
		_result_label.text = "「%s」をデッキに加えた。" % card_data.get("name", _reward_card_id)
	else:
		_result_label.text = "宝箱の中は空だった。"
	_result_label.visible = true
	_choice_panel.visible = false
	_continue_btn.visible = true


func _on_skip() -> void:
	_result_label.text = "あなたは宝を残して立ち去った。"
	_result_label.visible = true
	_choice_panel.visible = false
	_continue_btn.visible = true


func _on_continue() -> void:
	var t = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "modulate:a", 0.0, 0.35)
	t.tween_callback(func(): get_tree().change_scene_to_file(MAP_SCENE))


func _make_btn(text: String, center: Vector2) -> Button:
	var btn = Button.new()
	btn.text = text
	var sz = Vector2(380, 46)
	btn.position = center - sz / 2.0
	btn.size = sz
	btn.add_theme_font_size_override("font_size", 16)
	preload("res://scenes/ui/UIStyle.gd").style_button(btn)
	return btn


func _add_background(background_key: String) -> void:
	var bg = TextureRect.new()
	bg.name = "TreasureBackground"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.offset_left = -42
	bg.offset_top = -24
	bg.offset_right = 42
	bg.offset_bottom = 24
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.texture = GameState.load_background_texture(GameState.get_background_path(background_key))
	if bg.texture == null:
		bg.modulate = C_BG
	add_child(bg)


func _make_action_btn(text: String, center: Vector2) -> Button:
	var btn = Button.new()
	btn.text = text
	var sz = Vector2(220, 52)
	btn.position = center - sz / 2.0
	btn.size = sz
	btn.add_theme_font_size_override("font_size", 18)
	preload("res://scenes/ui/UIStyle.gd").style_button(btn, 5.0, true)
	return btn


class _GlowCanvas extends Node2D:
	var _phase: float = 0.0

	func _process(delta: float) -> void:
		_phase += delta
		queue_redraw()

	func _draw() -> void:
		# Atmospheric gold glow behind chest center
		var cx = 640.0
		var cy = 360.0
		var pulse = sin(_phase * 1.1) * 0.05
		for i in range(7, 0, -1):
			var a = (0.025 + pulse * 0.01) * float(i) * 0.5
			draw_circle(Vector2(cx, cy), 60.0 + i * 28.0, Color(0.75, 0.55, 0.10, a))
		# Fog
		for i in 3:
			var y = 200.0 + i * 140.0
			var drift = fmod(_phase * (5.0 + i * 2.0) + i * 90.0, 1400.0) - 700.0
			var pts = PackedVector2Array()
			for j in 8:
				pts.append(Vector2(j * 165.0 + drift, y + sin(_phase * 0.35 + j) * 15.0))
			for j in range(7, -1, -1):
				pts.append(Vector2(j * 165.0 + drift, y + 36.0 + cos(_phase * 0.30 + j) * 17.0))
			if pts.size() >= 3:
				draw_colored_polygon(pts, Color(0.12, 0.10, 0.20, 0.020))
