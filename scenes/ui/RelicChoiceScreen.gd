extends Control

signal choice_made

const STARTER_RELIC_BACKGROUND := "res://assets/backgrounds/story/starter_relic_background.png"
const C_GOLD := Color(0.90, 0.78, 0.25)
const CARD_W  := 720.0
const CARD_H  := 82.0
const CARD_GAP := 12.0

var _relic_ids: Array = []
var _choice_locked: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	hide()


func show_choice() -> void:
	_choice_locked = false
	_relic_ids = GameState.roll_relic_choices(3, "start")
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
	bg.texture = GameState.load_background_texture(STARTER_RELIC_BACKGROUND)
	add_child(bg)

	var overlay = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.010, 0.006, 0.014, 0.18)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var title = Label.new()
	title.text = "契約の贈り物"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 34)
	title.size = Vector2(1280, 50)
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", C_GOLD)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.80))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	add_child(title)

	var speech_panel = Panel.new()
	speech_panel.position = Vector2(220, 316)
	speech_panel.size = Vector2(840, 68)
	var speech_style = StyleBoxFlat.new()
	speech_style.bg_color = Color(0.02, 0.012, 0.030, 0.58)
	speech_style.border_color = Color(0.80, 0.62, 0.28, 0.48)
	speech_style.set_border_width_all(1)
	speech_style.set_corner_radius_all(8)
	speech_panel.add_theme_stylebox_override("panel", speech_style)
	add_child(speech_panel)

	var speech = Label.new()
	speech.text = "「復讐を望むなら、この力を受け取れ。」"
	speech.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speech.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	speech.position = Vector2(18, 0)
	speech.size = Vector2(804, 68)
	speech.add_theme_font_size_override("font_size", 25)
	speech.add_theme_color_override("font_color", Color(0.96, 0.90, 1.0))
	speech.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	speech.add_theme_constant_override("shadow_offset_x", 2)
	speech.add_theme_constant_override("shadow_offset_y", 2)
	speech_panel.add_child(speech)

	var count = _relic_ids.size()
	var start_x = (1280 - CARD_W) / 2.0
	var row_y = 410.0

	for i in count:
		var relic_id = _relic_ids[i]
		var relic = GameState.get_relic_definition(relic_id)
		if relic.is_empty():
			continue
		var card = _RelicCard.new()
		card.relic_data = relic
		card.position = Vector2(start_x, row_y + i * (CARD_H + CARD_GAP))
		card.size = Vector2(CARD_W, CARD_H)
		card.custom_minimum_size = Vector2(CARD_W, CARD_H)
		card.relic_selected.connect(_on_relic_selected)
		add_child(card)
		# Animate in
		card.modulate.a = 0.0
		card.position.y = row_y + i * (CARD_H + CARD_GAP) + 18
		var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		t.tween_property(card, "modulate:a", 1.0, 0.30).set_delay(i * 0.08)
		t.parallel().tween_property(card, "position:y", row_y + i * (CARD_H + CARD_GAP), 0.30).set_delay(i * 0.08)

func _on_relic_selected(relic_id: String) -> void:
	if _choice_locked or relic_id.is_empty():
		return
	_choice_locked = true
	GameState.add_relic(relic_id)
	GameState.initial_relic_chosen = true
	GameState.relic_choice_done = true
	var t = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "modulate:a", 0.0, 0.35)
	t.tween_callback(func():
		hide()
		choice_made.emit()
	)


class _RelicCard extends Control:
	signal relic_selected(relic_id: String)

	const W := 720.0
	const H := 82.0
	const PAD_X := 18.0
	const LEFT_W := 188.0
	const DIVIDER_X := 212.0
	const TEXT_X := 232.0
	const TEXT_W := 468.0
	const NAME_Y := 17.0
	const NAME_H := 26.0
	const RARITY_Y := 46.0
	const RARITY_H := 16.0
	const EFFECT_Y := 14.0
	const EFFECT_H := 26.0
	const MEMORY_Y := 45.0
	const MEMORY_H := 26.0

	var relic_data: Dictionary = {}
	var _hovered: bool = false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		focus_mode = Control.FOCUS_ALL
		if not relic_data.is_empty():
			_build_labels()

	func _build_labels() -> void:
		var rarity = relic_data.get("rarity", "common")

		var medallion = preload("res://scenes/ui/RelicMedallion.gd").new()
		medallion.position = Vector2(PAD_X, (H - 52.0) / 2.0)
		add_child(medallion)
		medallion.setup(relic_data.get("id", ""), 52.0, false, true)

		var name_lbl = Label.new()
		name_lbl.text = relic_data.get("name_jp", "")
		name_lbl.position = Vector2(PAD_X + 60.0, NAME_Y)
		name_lbl.size = Vector2(LEFT_W - 60.0, NAME_H)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", Color(0.96, 0.91, 1.0))
		add_child(name_lbl)

		var rar_lbl = Label.new()
		rar_lbl.text = _rarity_text(rarity)
		rar_lbl.position = Vector2(PAD_X + 60.0, RARITY_Y)
		rar_lbl.size = Vector2(LEFT_W - 60.0, RARITY_H)
		rar_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rar_lbl.add_theme_font_size_override("font_size", 11)
		rar_lbl.add_theme_color_override("font_color", _rarity_label_color(rarity))
		add_child(rar_lbl)

		var divider = ColorRect.new()
		divider.position = Vector2(DIVIDER_X, 14)
		divider.size = Vector2(1, H - 28)
		divider.color = Color(_border_color(rarity), 0.34)
		divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(divider)

		_add_section_label("効果: " + _effect_text(), Vector2(TEXT_X, EFFECT_Y), Vector2(TEXT_W, EFFECT_H), 12, Color(0.86, 0.84, 0.96), true, 2)
		_add_section_label("記憶: " + _memory_text(), Vector2(TEXT_X, MEMORY_Y), Vector2(TEXT_W, MEMORY_H), 10, Color(0.66, 0.62, 0.78), true, 2)

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
				for i in range(3, 0, -1):
					var pad = float(i) * 2.0
					draw_rect(Rect2(-pad, -pad, w + pad*2, h + pad*2),
						Color(0.65, 0.22, 0.90, 0.035 * float(i)), true)
				draw_rect(Rect2(0,0,w,h), Color(0.048,0.028,0.082,0.62), true)
				var bc = Color(0.85, 0.45, 1.0, 0.92) if _hovered else Color(0.72, 0.32, 0.95, 0.72)
				draw_rect(Rect2(0,0,w,h), bc, false, 2.0)
				var gold = Color(0.78, 0.52, 0.92, 0.60)
				var cs := 9.0
				for corner in [Vector2(0,0), Vector2(w,0), Vector2(0,h), Vector2(w,h)]:
					var dx := cs if corner.x == 0.0 else -cs
					var dy := cs if corner.y == 0.0 else -cs
					draw_line(corner, corner + Vector2(dx,0), gold, 1.5)
					draw_line(corner, corner + Vector2(0,dy), gold, 1.5)
			"rare":
				for i in range(3, 0, -1):
					var pad = float(i) * 2.0
					draw_rect(Rect2(-pad,-pad,w+pad*2,h+pad*2),
						Color(0.30, 0.55, 1.0, 0.035 * float(i)), true)
				draw_rect(Rect2(0,0,w,h), Color(0.032,0.040,0.075,0.62), true)
				var rc = Color(0.55, 0.80, 1.0, 0.92) if _hovered else Color(0.40, 0.65, 1.0, 0.72)
				draw_rect(Rect2(0,0,w,h), rc, false, 2.0)
				var blue = Color(0.38, 0.62, 1.0, 0.55)
				var cs2 := 8.0
				for corner2 in [Vector2(0,0), Vector2(w,0), Vector2(0,h), Vector2(w,h)]:
					var dx2 := cs2 if corner2.x == 0.0 else -cs2
					var dy2 := cs2 if corner2.y == 0.0 else -cs2
					draw_line(corner2, corner2 + Vector2(dx2,0), blue, 1.2)
					draw_line(corner2, corner2 + Vector2(0,dy2), blue, 1.2)
			_:
				draw_rect(Rect2(0,0,w,h), Color(0.042,0.036,0.068,0.60), true)
				var nc = Color(0.60, 0.55, 0.70, 0.82) if _hovered else Color(0.42, 0.38, 0.50, 0.62)
				draw_rect(Rect2(0,0,w,h), nc, false, 1.6)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			relic_selected.emit(relic_data.get("id", ""))

	func _mouse_entered_handler() -> void:
		_hovered = true
		queue_redraw()

	func _mouse_exited_handler() -> void:
		_hovered = false
		queue_redraw()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_ENTER:
			_hovered = true
			queue_redraw()
		elif what == NOTIFICATION_MOUSE_EXIT:
			_hovered = false
			queue_redraw()

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
