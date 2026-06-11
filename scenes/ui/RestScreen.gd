extends Control

const MAP_SCENE = "res://scenes/MapScreen.tscn"
const CARD_SCENE = "res://scenes/ui/CardNode.tscn"
const CARD_SELECT_OVERLAY = "res://scenes/ui/CardSelectionOverlay.gd"
const CARD_W := 130.0
const CARD_H := 190.0
const REST_CARD_SCALE := 0.82
const GROUP_ENTRY_W := 452.0
const GROUP_ENTRY_H := 184.0

const C_BG   = Color(0.018, 0.014, 0.026)
const C_GOLD = Color(0.86, 0.72, 0.34)
const C_TEXT = Color(0.84, 0.78, 0.96)

var _result_label: Label
var _btn_rest: Button
var _btn_train: Button
var _btn_remove: Button
var _continue_btn: Button
var _choice_panel: Control
var _card_select_panel: Control
var _panel: Panel
var _card_scene: PackedScene
var _rested: bool = false


func _ready() -> void:
	_apply_screen_scale()
	_card_scene = load(CARD_SCENE)
	GameState.complete_map_node(GameState.map_current_node_id)
	_build_ui()

func _apply_screen_scale() -> void:
	var scaler = get_node_or_null("/root/ScreenScale")
	if scaler and scaler.has_method("apply"):
		scaler.apply(self)


func _build_ui() -> void:
	_add_background("shared_rest")

	var canvas = _CampfireCanvas.new()
	add_child(canvas)

	# Panel
	_panel = Panel.new()
	var panel = _panel
	panel.position = Vector2(360, 96)
	panel.size = Vector2(560, 500)
	preload("res://scenes/ui/UIStyle.gd").style_panel(panel, 0.78)
	add_child(panel)

	var header = Label.new()
	header.text = "休憩"
	header.position = Vector2(0, 14)
	header.size = Vector2(560, 26)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color(0.55, 0.20, 0.90, 0.80))
	panel.add_child(header)

	var title = Label.new()
	title.text = "束の間の安らぎ"
	title.position = Vector2(20, 46)
	title.size = Vector2(520, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", C_GOLD)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.80))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	panel.add_child(title)

	var desc = Label.new()
	desc.text = "暗闇の中でわずかな焚き火を見つけた。\n次の旅路に向けて、ひとつだけ準備を整えよう。"
	desc.position = Vector2(40, 98)
	desc.size = Vector2(480, 60)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", C_TEXT)
	panel.add_child(desc)

	var hp_bar_frame = Panel.new()
	hp_bar_frame.position = Vector2(78, 168)
	hp_bar_frame.size = Vector2(404, 20)
	var hp_frame_style = StyleBoxFlat.new()
	hp_frame_style.bg_color = Color(0.08, 0.06, 0.14)
	hp_frame_style.border_color = Color(0.62, 0.50, 0.28, 0.60)
	hp_frame_style.set_border_width_all(1)
	hp_frame_style.set_corner_radius_all(3)
	hp_bar_frame.add_theme_stylebox_override("panel", hp_frame_style)
	panel.add_child(hp_bar_frame)

	var hp_fill = ColorRect.new()
	var fill_pct = float(GameState.player_hp) / float(GameState.player_max_hp)
	hp_fill.position = Vector2(80, 170)
	hp_fill.size = Vector2(400.0 * fill_pct, 16)
	hp_fill.color = Color(0.55, 0.12, 0.12)
	panel.add_child(hp_fill)

	var hp_lbl = Label.new()
	hp_lbl.text = "HP  %d / %d" % [GameState.player_hp, GameState.player_max_hp]
	hp_lbl.position = Vector2(80, 190)
	hp_lbl.size = Vector2(400, 22)
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_lbl.add_theme_font_size_override("font_size", 14)
	hp_lbl.add_theme_color_override("font_color", Color(0.85, 0.55, 0.55))
	panel.add_child(hp_lbl)

	_result_label = Label.new()
	_result_label.position = Vector2(40, 225)
	_result_label.size = Vector2(480, 50)
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 15)
	_result_label.add_theme_color_override("font_color", Color(0.70, 0.90, 0.72))
	_result_label.visible = false
	panel.add_child(_result_label)

	_choice_panel = Control.new()
	_choice_panel.position = Vector2(80, 218)
	_choice_panel.size = Vector2(400, 190)
	panel.add_child(_choice_panel)

	_btn_rest = _make_choice_btn("休憩  HPを回復する", Vector2(200, 28))
	_btn_rest.pressed.connect(_on_rest)
	_choice_panel.add_child(_btn_rest)

	_btn_train = _make_choice_btn("鍛錬  カードを1枚強化する", Vector2(200, 84))
	_btn_train.disabled = GameState.get_upgradeable_deck_indices().is_empty()
	_btn_train.pressed.connect(_on_train)
	_choice_panel.add_child(_btn_train)

	_btn_remove = _make_choice_btn("整理  カードを1枚削除する", Vector2(200, 140))
	_btn_remove.disabled = GameState.get_removable_deck_indices().is_empty()
	_btn_remove.pressed.connect(_on_remove)
	_choice_panel.add_child(_btn_remove)

	_continue_btn = _make_action_btn("マップに戻る", Vector2(640, 536))
	_continue_btn.visible = false
	_continue_btn.pressed.connect(_on_continue)
	add_child(_continue_btn)

	modulate.a = 0.0
	var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "modulate:a", 1.0, 0.45)


func _on_rest() -> void:
	if _rested:
		return
	_rested = true
	var heal_amount = int(GameState.player_max_hp * 0.30) + GameState.get_rest_heal_bonus()
	GameState.heal(heal_amount)
	_result_label.text = "体を休めた。HPが %d 回復した。\n(現在 %d / %d)" % [heal_amount, GameState.player_hp, GameState.player_max_hp]
	_result_label.visible = true
	_choice_panel.visible = false
	_continue_btn.visible = true


func _on_train() -> void:
	if _rested:
		return
	_show_card_selector("upgrade")


func _on_remove() -> void:
	if _rested:
		return
	_show_card_selector("remove")


func _show_card_selector(mode: String) -> void:
	_choice_panel.visible = false
	_result_label.visible = false
	if _card_select_panel and is_instance_valid(_card_select_panel):
		_card_select_panel.queue_free()
	var overlay_script = load(CARD_SELECT_OVERLAY)
	var overlay = overlay_script.new()
	_card_select_panel = overlay
	add_child(overlay)
	overlay.card_selected.connect(func(deck_index: int):
		_on_deck_group_selected(mode, [deck_index])
	)
	overlay.closed.connect(_back_to_choices)
	var title_text = "強化するカードを選択" if mode == "upgrade" else "削除するカードを選択"
	overlay.show_selection(mode, title_text, 1, true)


func _back_to_choices() -> void:
	if _card_select_panel and is_instance_valid(_card_select_panel):
		_card_select_panel.queue_free()
	_card_select_panel = null
	_choice_panel.visible = true


func _on_deck_group_selected(mode: String, indices: Array) -> void:
	if _rested:
		return
	if indices.is_empty():
		return
	var deck_index = int(indices[0])
	var before = GameState.get_card(GameState.deck[deck_index])
	var ok := false
	if mode == "upgrade":
		ok = GameState.upgrade_deck_card(deck_index)
		if ok:
			var after = GameState.get_card(GameState.deck[deck_index])
			_result_label.text = "「%s」を強化した。" % after.get("name", before.get("name", "カード"))
	else:
		ok = GameState.remove_deck_card(deck_index)
		if ok:
			_result_label.text = "「%s」を削除した。" % before.get("name", "カード")
	if not ok:
		_result_label.text = "このカードは選べない。"
		_result_label.visible = true
		return

	_rested = true
	if _card_select_panel and is_instance_valid(_card_select_panel):
		_card_select_panel.queue_free()
	_card_select_panel = null
	_result_label.visible = true
	_continue_btn.visible = true


func _on_continue() -> void:
	var t = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "modulate:a", 0.0, 0.35)
	t.tween_callback(func(): get_tree().change_scene_to_file(MAP_SCENE))


func _make_choice_btn(text: String, center: Vector2) -> Button:
	var btn = Button.new()
	btn.text = text
	var sz = Vector2(360, 46)
	btn.position = center - sz / 2.0
	btn.size = sz
	btn.add_theme_font_size_override("font_size", 16)
	preload("res://scenes/ui/UIStyle.gd").style_button(btn)
	return btn


func _make_small_btn(text: String, center: Vector2, size: Vector2) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.position = center - size / 2.0
	btn.size = size
	btn.add_theme_font_size_override("font_size", 13)
	preload("res://scenes/ui/UIStyle.gd").style_button(btn)
	return btn


func _add_background(background_key: String) -> void:
	var bg = TextureRect.new()
	bg.name = "RestBackground"
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


class _CampfireCanvas extends Node2D:
	var _phase: float = 0.0

	func _process(delta: float) -> void:
		_phase += delta
		queue_redraw()

	#func _draw() -> void:
		#_draw_fog()
		#_draw_campfire()

	func _draw_fog() -> void:
		for i in 4:
			var y = 150.0 + i * 120.0
			var drift = fmod(_phase * (6.0 + i * 2.0) + i * 100.0, 1400.0) - 700.0
			var pts = PackedVector2Array()
			for j in 8:
				pts.append(Vector2(j * 165.0 + drift, y + sin(_phase * 0.38 + j) * 16.0))
			for j in range(7, -1, -1):
				pts.append(Vector2(j * 165.0 + drift, y + 38.0 + cos(_phase * 0.32 + j) * 18.0))
			if pts.size() >= 3:
				draw_colored_polygon(pts, Color(0.12, 0.10, 0.20, 0.022))

	#func _draw_campfire() -> void:
		## Decorative campfire glow at bottom center
		#var cx = 640.0
		#var cy = 610.0
		#var flicker = sin(_phase * 4.2) * 0.15 + sin(_phase * 7.1) * 0.08
		#for i in range(6, 0, -1):
			#var a = (0.04 + flicker * 0.02) * float(i) * 0.5
			#draw_circle(Vector2(cx, cy), 18.0 + i * 10.0, Color(0.85, 0.45, 0.05, a))
		#draw_circle(Vector2(cx, cy), 14, Color(1.0, 0.75, 0.25, 0.60 + flicker * 0.2))
		#draw_circle(Vector2(cx, cy), 7, Color(1.0, 0.95, 0.65, 0.85))
		## Log cross
		#var gold = Color(0.60, 0.38, 0.14, 0.60)
		#draw_line(Vector2(cx - 24, cy + 12), Vector2(cx + 10, cy + 6), gold, 4.0)
		#draw_line(Vector2(cx + 24, cy + 12), Vector2(cx - 10, cy + 6), gold, 4.0)
