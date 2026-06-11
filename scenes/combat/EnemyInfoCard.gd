extends Panel
## 画面上部の敵情報カード(名前/HP/状態異常/次の行動アイコン)。
## setup() で渡された EnemyNode を毎フレーム監視して表示を更新する。

const STATUS_ORDER := ["vulnerable", "weak", "poison"]
const STATUS_ICONS := {
	"vulnerable": {"symbol": "◇", "color": Color(1.0, 0.56, 0.24)},
	"weak": {"symbol": "↓", "color": Color(0.72, 0.46, 1.0)},
	"poison": {"symbol": "●", "color": Color(0.36, 0.86, 0.42)},
	"strength": {"symbol": "↑", "color": Color(1.0, 0.78, 0.25)},
	"block": {"symbol": "■", "color": Color(0.42, 0.68, 1.0)}
}
const TEMP_CARD_COLOR := Color(0.58, 0.46, 0.86)
const TEMP_CARD_NAMES := {
	"restraint": "拘束",
	"arrow_wound": "矢傷",
	"pressure": "重圧",
	"junk": "ガラクタ",
	"brand_of_sin": "罪の烙印",
	"judgement": "裁き",
	"guilt": "罪悪感",
	"poison_blade": "毒刃",
	"magic_disruption": "魔力乱れ",
	"petrified_shard": "石化の欠片",
	"dragon_burn": "竜の火傷",
	"fairy_mischief": "妖精の悪戯",
	"bleeding": "出血"
}
const ACTION_COLORS := {
	"attack": Color(1.0, 0.34, 0.28),
	"block": Color(0.42, 0.68, 1.0),
	"strength": Color(1.0, 0.78, 0.25),
	"status": Color(0.72, 0.46, 1.0),
	"heal": Color(0.36, 0.86, 0.42),
	"temp": Color(0.58, 0.46, 0.86)
}

var _enemy_node: Node
var _name_label: Label
var _hp_bar_bg: ColorRect
var _hp_bar_fill: ColorRect
var _hp_label: Label
var _status_icons: HBoxContainer
var _intent_prefix_label: Label
var _intent_icons: HBoxContainer
var _tooltip_panel: Panel
var _tooltip_label: Label
var _status_icon_signature := ""
var _intent_icon_signature := ""

const OrnateFrame = preload("res://scenes/ui/OrnateFrame.gd")

func setup(enemy_node: Node) -> void:
	_enemy_node = enemy_node
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	_build_ui()
	_update_from_enemy()

func _draw() -> void:
	OrnateFrame.draw_frame(self, Rect2(Vector2.ZERO, size), 0.55, 8.0)

func _build_ui() -> void:
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.030, 0.026, 0.060, 0.66)
	panel_style.set_border_width_all(0)
	panel_style.set_corner_radius_all(2)
	panel_style.set_content_margin_all(3)
	add_theme_stylebox_override("panel", panel_style)

	_name_label = Label.new()
	_name_label.position = Vector2(9, 4)
	_name_label.size = Vector2(154, 18)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_name_label.clip_text = true
	_name_label.add_theme_font_size_override("font_size", 13)
	_name_label.add_theme_color_override("font_color", Color(0.94, 0.82, 0.54))
	_name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.82))
	_name_label.add_theme_constant_override("shadow_offset_x", 1)
	_name_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_name_label)

	_hp_bar_bg = ColorRect.new()
	_hp_bar_bg.position = Vector2(9, 26)
	_hp_bar_bg.size = Vector2(242, 4)
	_hp_bar_bg.color = Color(0.08, 0.045, 0.075, 0.58)
	add_child(_hp_bar_bg)

	_hp_bar_fill = ColorRect.new()
	_hp_bar_fill.position = _hp_bar_bg.position
	_hp_bar_fill.size = _hp_bar_bg.size
	_hp_bar_fill.color = Color(0.58, 0.10, 0.10, 0.78)
	add_child(_hp_bar_fill)

	_hp_label = Label.new()
	_hp_label.position = Vector2(166, 4)
	_hp_label.size = Vector2(85, 18)
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hp_label.clip_text = true
	_hp_label.add_theme_font_size_override("font_size", 13)
	_hp_label.add_theme_color_override("font_color", Color(0.94, 0.78, 0.74))
	add_child(_hp_label)

	_status_icons = HBoxContainer.new()
	_status_icons.position = Vector2(9, 34)
	_status_icons.size = Vector2(108, 21)
	_status_icons.add_theme_constant_override("separation", 2)
	_status_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_status_icons)

	_intent_prefix_label = Label.new()
	_intent_prefix_label.text = "次"
	_intent_prefix_label.position = Vector2(196, 36)
	_intent_prefix_label.size = Vector2(18, 16)
	_intent_prefix_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_intent_prefix_label.add_theme_font_size_override("font_size", 14)
	_intent_prefix_label.add_theme_color_override("font_color", Color(0.78, 0.74, 0.88))
	_intent_prefix_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.82))
	_intent_prefix_label.add_theme_constant_override("shadow_offset_x", 1)
	_intent_prefix_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_intent_prefix_label)

	_intent_icons = HBoxContainer.new()
	_intent_icons.position = Vector2(141, 34)
	_intent_icons.size = Vector2(110, 21)
	_intent_icons.alignment = BoxContainer.ALIGNMENT_END
	_intent_icons.add_theme_constant_override("separation", 2)
	_intent_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_intent_icons)

	_ensure_tooltip()

func _process(_delta: float) -> void:
	_update_from_enemy()

func _update_from_enemy() -> void:
	if not is_instance_valid(_enemy_node):
		visible = false
		return
	var data: Dictionary = _enemy_node.enemy_data
	var current_hp := int(_enemy_node.current_hp)
	var max_hp := maxi(1, int(_enemy_node.max_hp))
	visible = true
	_name_label.text = data.get("display_name", data.get("name_jp", data.get("name", "敵")))
	var hp_ratio := clampf(float(current_hp) / float(max_hp), 0.0, 1.0)
	_hp_bar_fill.size = Vector2(_hp_bar_bg.size.x * hp_ratio, _hp_bar_bg.size.y)
	_hp_label.text = "%d/%d" % [current_hp, max_hp]
	_status_icon_signature = _set_icon_row(_status_icons, _status_icon_specs(), _status_icon_signature)
	if current_hp <= 0:
		modulate = Color(0.72, 0.72, 0.72, 0.72)
		_intent_icon_signature = _set_icon_row(_intent_icons, [{"text": "撃", "color": Color(0.70, 0.70, 0.76), "tooltip": "撃破"}], _intent_icon_signature)
	else:
		modulate = Color.WHITE
		_intent_icon_signature = _set_icon_row(_intent_icons, _action_icon_specs(_enemy_node.next_action), _intent_icon_signature)

func _status_icon_specs() -> Array:
	var specs: Array = []
	if int(_enemy_node.block) > 0:
		specs.append(_icon_spec("block", int(_enemy_node.block)))
	var statuses: Dictionary = _enemy_node.statuses
	for status_id in STATUS_ORDER:
		var value := int(statuses.get(status_id, 0))
		if value > 0:
			specs.append(_icon_spec(status_id, value))
	for status_id in statuses.keys():
		if STATUS_ORDER.has(status_id):
			continue
		var value := int(statuses.get(status_id, 0))
		if value > 0:
			specs.append(_icon_spec(status_id, value))
	if _enemy_node.has_method("get_strength_bonus"):
		var strength := int(_enemy_node.get_strength_bonus())
		if strength > 0:
			specs.append(_icon_spec("strength", strength))
	return specs

func _action_icon_specs(action: Dictionary) -> Array:
	if action.is_empty():
		return []
	var specs: Array = []
	match action.get("type", ""):
		"attack":
			var value = action.get("value", 0)
			specs.append(_action_spec("▲", value, ACTION_COLORS["attack"], "攻撃：%sダメージ" % str(value)))
		"attack_buff":
			var value = action.get("value", 0)
			var buff = action.get("buff", 1)
			specs.append(_action_spec("▲", value, ACTION_COLORS["attack"], "攻撃：%sダメージ" % str(value)))
			specs.append(_action_spec("↑", buff, ACTION_COLORS["strength"], "強化：筋力%sを得る" % str(buff)))
		"attack_multi":
			var value = action.get("value", 0)
			var times = action.get("times", 2)
			specs.append(_action_spec("▲", "%sx%s" % [value, times], ACTION_COLORS["attack"], "連続攻撃：%sダメージを%s回" % [str(value), str(times)]))
		"attack_add_temp_discard":
			var value = action.get("value", 0)
			specs.append(_action_spec("▲", value, ACTION_COLORS["attack"], "攻撃：%sダメージ" % str(value)))
			specs.append(_temp_card_spec(action.get("card_id", ""), action.get("amount", 1)))
		"attack_status":
			var value = action.get("value", 0)
			specs.append(_action_spec("▲", value, ACTION_COLORS["attack"], "攻撃：%sダメージ" % str(value)))
			specs.append(_icon_spec(action.get("status", "weak"), action.get("amount", 1)))
		"block":
			var value = action.get("value", 0)
			specs.append(_action_spec("■", value, ACTION_COLORS["block"], "防御：ブロック%sを得る" % str(value)))
		"strength":
			var buff = action.get("buff", 1)
			specs.append(_action_spec("↑", buff, ACTION_COLORS["strength"], "強化：筋力%sを得る" % str(buff)))
		"block_strength":
			var value = action.get("value", 0)
			var buff = action.get("buff", 1)
			specs.append(_action_spec("■", value, ACTION_COLORS["block"], "防御：ブロック%sを得る" % str(value)))
			specs.append(_action_spec("↑", buff, ACTION_COLORS["strength"], "強化：筋力%sを得る" % str(buff)))
		"heal", "heal_strength":
			var value = action.get("value", 0)
			specs.append(_action_spec("＋", value, ACTION_COLORS["heal"], "回復：HPを%s回復" % str(value)))
			if action.get("type", "") == "heal_strength":
				var buff = action.get("buff", 1)
				specs.append(_action_spec("↑", buff, ACTION_COLORS["strength"], "強化：筋力%sを得る" % str(buff)))
		"apply_status":
			specs.append(_icon_spec(action.get("status", "weak"), action.get("amount", 1)))
		"add_temp_draw", "add_temp_discard":
			specs.append(_temp_card_spec(action.get("card_id", ""), action.get("amount", 1)))
		"add_temp_cards":
			for item in action.get("draw", []):
				specs.append(_temp_card_spec(item.get("id", ""), item.get("amount", 1)))
			for item in action.get("discard", []):
				specs.append(_temp_card_spec(item.get("id", ""), item.get("amount", 1)))
	return specs

func _icon_spec(id: String, value) -> Dictionary:
	var meta: Dictionary = STATUS_ICONS.get(id, {"symbol": "?", "color": Color(0.82, 0.82, 0.88)})
	var tooltip := ""
	match id:
		"block":
			tooltip = "防御：ブロック%s" % str(value)
		"strength":
			tooltip = "強化：筋力%s" % str(value)
		"weak":
			tooltip = "弱体：攻撃ダメージが下がる"
		"vulnerable":
			tooltip = "脆弱：受けるダメージが増える"
		"poison":
			tooltip = "毒：ターンごとにダメージを受ける"
		_:
			tooltip = "%s：%s" % [id, str(value)]
	return _action_spec(meta.get("symbol", "?"), value, meta.get("color", Color.WHITE), tooltip)

func _temp_card_spec(card_id: String, value) -> Dictionary:
	var card_name: String = TEMP_CARD_NAMES.get(card_id, "お邪魔")
	var amount := int(value)
	var tooltip := "%sカードを%d枚追加" % [card_name, amount]
	return {"text": "札%d" % amount, "color": TEMP_CARD_COLOR, "tooltip": tooltip}

func _action_spec(symbol: String, value, color: Color, tooltip: String = "") -> Dictionary:
	return {"text": "%s%s" % [symbol, str(value)], "color": color, "tooltip": tooltip}

func _set_icon_row(row: HBoxContainer, specs: Array, previous_signature: String) -> String:
	var signature := _icon_signature(specs)
	if signature == previous_signature:
		return previous_signature
	_hide_icon_tooltip()
	for child in row.get_children():
		child.queue_free()
	for spec in specs:
		row.add_child(_make_icon_label(spec))
	return signature

func _icon_signature(specs: Array) -> String:
	var parts: Array[String] = []
	for spec in specs:
		parts.append("%s:%s" % [spec.get("text", ""), spec.get("tooltip", "")])
	return "|".join(parts)

func _make_icon_label(spec: Dictionary) -> Label:
	var accent: Color = spec.get("color", Color.WHITE)
	var label = Label.new()
	label.text = spec.get("text", "")
	label.custom_minimum_size = Vector2(34, 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.98, 0.96, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.86))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(accent.r, accent.g, accent.b, 0.24)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.50)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(2)
	label.add_theme_stylebox_override("normal", style)
	var tooltip_text: String = spec.get("tooltip", "")
	label.mouse_entered.connect(func(): _show_icon_tooltip(label, tooltip_text))
	label.mouse_exited.connect(_hide_icon_tooltip)
	return label

func _ensure_tooltip() -> void:
	if _tooltip_panel:
		return
	_tooltip_panel = Panel.new()
	_tooltip_panel.visible = false
	_tooltip_panel.z_index = 1000
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.024, 0.020, 0.050, 0.90)
	style.border_color = Color(0.58, 0.48, 0.72, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.set_content_margin_all(6)
	_tooltip_panel.add_theme_stylebox_override("panel", style)
	add_child(_tooltip_panel)

	_tooltip_label = Label.new()
	_tooltip_label.position = Vector2(8, 5)
	_tooltip_label.add_theme_font_size_override("font_size", 12)
	_tooltip_label.add_theme_color_override("font_color", Color(0.94, 0.91, 1.0))
	_tooltip_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.86))
	_tooltip_label.add_theme_constant_override("shadow_offset_x", 1)
	_tooltip_label.add_theme_constant_override("shadow_offset_y", 1)
	_tooltip_panel.add_child(_tooltip_label)

func _show_icon_tooltip(source: Control, text: String) -> void:
	if text.is_empty():
		return
	_ensure_tooltip()
	_tooltip_label.text = text
	var panel_w = clampf(float(text.length()) * 12.0 + 18.0, 110.0, 250.0)
	_tooltip_panel.size = Vector2(panel_w, 28)
	_tooltip_label.size = _tooltip_panel.size - Vector2(16, 8)
	var global_pos = source.global_position + Vector2(0, source.size.y + 5)
	var viewport_size = get_viewport_rect().size
	global_pos.x = clampf(global_pos.x, 8.0, maxf(8.0, viewport_size.x - _tooltip_panel.size.x - 8.0))
	global_pos.y = clampf(global_pos.y, 8.0, maxf(8.0, viewport_size.y - _tooltip_panel.size.y - 8.0))
	_tooltip_panel.position = global_pos - global_position
	_tooltip_panel.visible = true

func _hide_icon_tooltip() -> void:
	if _tooltip_panel:
		_tooltip_panel.visible = false
