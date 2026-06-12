extends Control

const MAP_SCENE  = "res://scenes/MapScreen.tscn"
const CARD_SCENE = "res://scenes/ui/CardNode.tscn"

const C_BG   = Color(0.02, 0.016, 0.027, 0.0)
const C_GOLD = Color(0.86, 0.72, 0.34)
const C_TEXT = Color(0.84, 0.78, 0.96)

const CURSED_CHANCE := 0.33

var _relic_id: String = ""
var _is_cursed: bool = false
var _is_empty_chest: bool = false
var _result_label: Label
var _take_btn: Button
var _skip_btn: Button
var _continue_btn: Button
var _choice_panel: Control


func _ready() -> void:
	_apply_screen_scale()
	GameState.complete_map_node(GameState.map_current_node_id)
	# 呪われた宝: エピック確定+呪いカード混入。通常: 強敵相当のレリック
	_is_cursed = randf() < CURSED_CHANCE
	if _is_cursed:
		_relic_id = GameState.roll_relic_reward_of_rarity("epic")
		if _relic_id.is_empty():
			_is_cursed = false
	if _relic_id.is_empty():
		_relic_id = GameState.roll_relic_reward("elite")
	_is_empty_chest = _relic_id.is_empty()
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
	title.text = "呪われた宝" if _is_cursed else "封印された宝"
	title.position = Vector2(20, 46)
	title.size = Vector2(640, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.92, 0.36, 0.40) if _is_cursed else C_GOLD)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.80))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	panel.add_child(title)

	var desc = Label.new()
	if _is_empty_chest:
		desc.text = "宝はすでに持ち去られていた。底に薬瓶だけが残っている。"
	elif _is_cursed:
		desc.text = "箱には黒い鎖が巻かれている。──開けば、対価を求められる。"
	else:
		desc.text = "古い宝箱の中で、何かが鈍く光っている。"
	desc.position = Vector2(40, 96)
	desc.size = Vector2(600, 30)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", C_TEXT)
	panel.add_child(desc)

	# レリックのお披露目
	if not _is_empty_chest:
		var relic = GameState.get_relic_definition(_relic_id)

		# 明るい宝箱アートの上でも読めるように、文字の背面に薄い暗幕を敷く
		var scrim = Panel.new()
		scrim.position = Vector2(110, 216)
		scrim.size = Vector2(460, 124 if _is_cursed else 94)
		var scrim_style = StyleBoxFlat.new()
		scrim_style.bg_color = Color(0.02, 0.015, 0.04, 0.62)
		scrim_style.set_border_width_all(0)
		scrim_style.set_corner_radius_all(8)
		scrim.add_theme_stylebox_override("panel", scrim_style)
		panel.add_child(scrim)

		var medallion = preload("res://scenes/ui/RelicMedallion.gd").new()
		medallion.position = Vector2((680.0 - 72.0) / 2.0, 138)
		panel.add_child(medallion)
		medallion.setup(_relic_id, 72.0, false, true)

		var name_lbl = Label.new()
		name_lbl.text = relic.get("name_jp", "")
		name_lbl.position = Vector2(40, 224)
		name_lbl.size = Vector2(600, 30)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 21)
		name_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.62))
		name_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
		name_lbl.add_theme_constant_override("shadow_offset_x", 1)
		name_lbl.add_theme_constant_override("shadow_offset_y", 1)
		panel.add_child(name_lbl)

		var effect_lbl = Label.new()
		effect_lbl.text = relic.get("effect_jp", "")
		effect_lbl.position = Vector2(60, 258)
		effect_lbl.size = Vector2(560, 46)
		effect_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		effect_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		effect_lbl.add_theme_font_size_override("font_size", 15)
		effect_lbl.add_theme_color_override("font_color", Color(0.88, 0.86, 0.96))
		effect_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
		effect_lbl.add_theme_constant_override("shadow_offset_x", 1)
		effect_lbl.add_theme_constant_override("shadow_offset_y", 1)
		panel.add_child(effect_lbl)

		if _is_cursed:
			var warn_lbl = Label.new()
			warn_lbl.text = "※ 開けると「強欲の代償」がデッキに混ざる(休憩で除去可能)"
			warn_lbl.position = Vector2(60, 308)
			warn_lbl.size = Vector2(560, 26)
			warn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			warn_lbl.add_theme_font_size_override("font_size", 13)
			warn_lbl.add_theme_color_override("font_color", Color(0.92, 0.46, 0.46))
			panel.add_child(warn_lbl)

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

	var take_text = "薬瓶を取る(HP10回復)" if _is_empty_chest else ("鎖を解いて開ける" if _is_cursed else "宝を受け取る")
	_take_btn = _make_btn(take_text, Vector2(250, 28))
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


func _on_take() -> void:
	if _is_empty_chest:
		GameState.heal(10)
		_result_label.text = "薬を飲み干した。HPが10回復した。"
	else:
		GameState.add_relic(_relic_id)
		var relic = GameState.get_relic_definition(_relic_id)
		if _is_cursed:
			GameState.add_card_to_deck("greed_price")
			_result_label.text = "「%s」を手に入れた。──「強欲の代償」がデッキに混ざった。" % relic.get("name_jp", "")
		else:
			_result_label.text = "「%s」を手に入れた。" % relic.get("name_jp", "")
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
