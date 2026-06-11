extends Control

signal reward_accepted

const C_GOLD := Color(0.90, 0.78, 0.25)
const CARD_W  := 720.0
const CARD_H  := 120.0

var _relic_id: String = ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	hide()


func show_reward(relic_id: String) -> void:
	_relic_id = relic_id
	_build()
	show()
	modulate.a = 0.0
	var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "modulate:a", 1.0, 0.45)


func _build() -> void:
	for c in get_children():
		c.queue_free()

	var bg = TextureRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.texture = _load_inherited_battle_background()
	add_child(bg)

	var ui_scrim = ColorRect.new()
	ui_scrim.position = Vector2(240, 64)
	ui_scrim.size = Vector2(800, 500)
	ui_scrim.color = Color(0.0, 0.0, 0.0, 0.30)
	ui_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui_scrim)

	var title = Label.new()
	title.text = "レリック獲得"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 80)
	title.size = Vector2(1280, 50)
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", C_GOLD)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.80))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	add_child(title)

	var sub = Label.new()
	sub.text = "強敵を倒し、遺物を手に入れた。"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(0, 136)
	sub.size = Vector2(1280, 32)
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color(0.72, 0.65, 0.86))
	add_child(sub)

	var relic = GameState.get_relic_definition(_relic_id)
	if not relic.is_empty():
		var card = _RelicDisplay.new()
		card.relic_data = relic
		card.position = Vector2((1280 - CARD_W) / 2.0, 250)
		card.custom_minimum_size = Vector2(CARD_W, CARD_H)
		add_child(card)
		# Animate
		card.modulate.a = 0.0
		card.position.y = 250 + 25
		var t2 = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		t2.tween_property(card, "modulate:a", 1.0, 0.35).set_delay(0.15)
		t2.parallel().tween_property(card, "position:y", 250.0, 0.35).set_delay(0.15)

	var accept_btn = _make_button("受け取る", Vector2(640, 555), Vector2(170, 46))
	accept_btn.pressed.connect(_on_accept)
	add_child(accept_btn)

func _load_inherited_battle_background() -> Texture2D:
	return GameState.load_background_texture(GameState.get_current_battle_background_path())

func _on_accept() -> void:
	GameState.add_relic(_relic_id)
	var t = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "modulate:a", 0.0, 0.35)
	t.tween_callback(func():
		hide()
		reward_accepted.emit()
	)


func _make_button(text: String, center: Vector2, sz: Vector2) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.position = center - sz / 2.0
	btn.size = sz
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color(0.94, 0.88, 1.0))
	var n = StyleBoxFlat.new()
	n.bg_color = Color(0.12, 0.04, 0.26)
	n.border_color = Color(0.55, 0.26, 0.86)
	n.set_border_width_all(2)
	n.set_corner_radius_all(9)
	btn.add_theme_stylebox_override("normal", n)
	var h = StyleBoxFlat.new()
	h.bg_color = Color(0.22, 0.08, 0.48)
	h.border_color = Color(0.78, 0.44, 1.0)
	h.set_border_width_all(2)
	h.set_corner_radius_all(9)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", h)
	return btn


class _RelicDisplay extends Control:
	const W := 720.0
	const H := 120.0
	const PAD_X := 18.0
	const LEFT_W := 188.0
	const DIVIDER_X := 212.0
	const TEXT_X := 232.0
	const TEXT_W := 468.0
	const NAME_Y := 28.0
	const NAME_H := 28.0
	const RARITY_Y := 60.0
	const RARITY_H := 18.0
	const EFFECT_Y := 22.0
	const EFFECT_H := 32.0
	const MEMORY_Y := 62.0
	const MEMORY_H := 34.0

	var relic_data: Dictionary = {}

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not relic_data.is_empty():
			_build_labels()

	func _build_labels() -> void:
		var rarity = relic_data.get("rarity", "common")

		var medallion = preload("res://scenes/ui/RelicMedallion.gd").new()
		medallion.position = Vector2(PAD_X, (H - 68.0) / 2.0)
		add_child(medallion)
		medallion.setup(relic_data.get("id", ""), 68.0, false)

		var name_lbl = Label.new()
		name_lbl.text = relic_data.get("name_jp", "")
		name_lbl.position = Vector2(PAD_X + 76.0, NAME_Y)
		name_lbl.size = Vector2(LEFT_W - 76.0, NAME_H)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.add_theme_color_override("font_color", Color(0.92, 0.86, 1.0))
		add_child(name_lbl)

		var rar_lbl = Label.new()
		rar_lbl.text = _rarity_text(rarity)
		rar_lbl.position = Vector2(PAD_X + 76.0, RARITY_Y)
		rar_lbl.size = Vector2(LEFT_W - 76.0, RARITY_H)
		rar_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rar_lbl.add_theme_font_size_override("font_size", 11)
		rar_lbl.add_theme_color_override("font_color", _rarity_label_color(rarity))
		add_child(rar_lbl)

		var divider = ColorRect.new()
		divider.position = Vector2(DIVIDER_X, 18)
		divider.size = Vector2(1, H - 36)
		divider.color = Color(_border_color(rarity), 0.34)
		divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(divider)

		_add_section_label("効果: " + _effect_text(), Vector2(TEXT_X, EFFECT_Y), Vector2(TEXT_W, EFFECT_H), 13, Color(0.86, 0.84, 0.96), true, 2)
		_add_section_label("記憶: " + _memory_text(), Vector2(TEXT_X, MEMORY_Y), Vector2(TEXT_W, MEMORY_H), 11, Color(0.66, 0.62, 0.78), true, 2)

	func _add_section_label(text: String, pos: Vector2, label_size: Vector2, font_size: int, color: Color, wrap: bool, max_lines: int = 1) -> void:
		var lbl = Label.new()
		lbl.text = text
		lbl.position = pos
		lbl.size = label_size
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", font_size)
		lbl.add_theme_color_override("font_color", color)
		lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		lbl.clip_text = true
		lbl.max_lines_visible = max_lines
		if wrap:
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(lbl)

	func _effect_text() -> String:
		return relic_data.get("effect_jp", _split_description_text()[0])

	func _memory_text() -> String:
		return relic_data.get("memory_jp", _split_description_text()[1])

	func _split_description_text() -> Array[String]:
		var lines = String(relic_data.get("description_jp", "")).split("\n", false, 1)
		var effect = lines[0] if lines.size() > 0 else ""
		var memory = lines[1] if lines.size() > 1 else ""
		return [effect, memory]

	func _draw() -> void:
		var w := W
		var h := H
		var rarity = relic_data.get("rarity", "common")
		match rarity:
			"epic":
				for i in range(4, 0, -1):
					var pad = float(i) * 3.5
					draw_rect(Rect2(-pad,-pad,w+pad*2,h+pad*2),
						Color(0.65, 0.22, 0.90, 0.06 * float(i)), true)
				draw_rect(Rect2(0,0,w,h), Color(0.048,0.028,0.082,0.97), true)
				draw_rect(Rect2(0,0,w,h), Color(0.72,0.32,0.95,0.90), false, 2.5)
				var gold = Color(0.78, 0.52, 0.92, 0.60)
				var cs := 14.0
				for corner in [Vector2(0,0), Vector2(w,0), Vector2(0,h), Vector2(w,h)]:
					var dx := cs if corner.x == 0.0 else -cs
					var dy := cs if corner.y == 0.0 else -cs
					draw_line(corner, corner + Vector2(dx,0), gold, 2.0)
					draw_line(corner, corner + Vector2(0,dy), gold, 2.0)
					draw_circle(corner, 3.5, gold)
			"rare":
				for i in range(3, 0, -1):
					var pad = float(i) * 3.0
					draw_rect(Rect2(-pad,-pad,w+pad*2,h+pad*2),
						Color(0.30, 0.55, 1.0, 0.06 * float(i)), true)
				draw_rect(Rect2(0,0,w,h), Color(0.032,0.040,0.075,0.97), true)
				draw_rect(Rect2(0,0,w,h), Color(0.40,0.65,1.0,0.88), false, 2.5)
				var blue = Color(0.38, 0.62, 1.0, 0.55)
				var cs2 := 12.0
				for corner2 in [Vector2(0,0), Vector2(w,0), Vector2(0,h), Vector2(w,h)]:
					var dx2 := cs2 if corner2.x == 0.0 else -cs2
					var dy2 := cs2 if corner2.y == 0.0 else -cs2
					draw_line(corner2, corner2 + Vector2(dx2,0), blue, 1.5)
					draw_line(corner2, corner2 + Vector2(0,dy2), blue, 1.5)
			_:
				draw_rect(Rect2(0,0,w,h), Color(0.042,0.036,0.068,0.97), true)
				draw_rect(Rect2(0,0,w,h), Color(0.42,0.38,0.50,0.75), false, 2.0)

	func _border_color(rarity: String) -> Color:
		match rarity:
			"rare":  return Color(0.40, 0.65, 1.0)
			"epic":  return Color(0.72, 0.32, 0.95)
			_:       return Color(0.42, 0.38, 0.50)

	func _icon_color(rarity: String) -> Color:
		match rarity:
			"rare":  return Color(0.65, 0.88, 1.0)
			"epic":  return Color(0.90, 0.65, 1.0)
			_:       return Color(0.82, 0.76, 0.90)

	func _rarity_text(rarity: String) -> String:
		match rarity:
			"rare":  return "◆ レア"
			"epic":  return "◆ エピック"
			_:       return "◇ コモン"

	func _rarity_label_color(rarity: String) -> Color:
		match rarity:
			"rare":  return Color(0.45, 0.70, 1.0, 0.80)
			"epic":  return Color(0.80, 0.45, 1.0, 0.90)
			_:       return Color(0.60, 0.56, 0.70, 0.65)
