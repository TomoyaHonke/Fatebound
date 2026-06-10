extends Control

signal closed

const C_GOLD := Color(0.86, 0.72, 0.34)
const C_TEXT := Color(0.88, 0.82, 1.00)

var _grid: GridContainer
var _empty_label: Label


func _ready() -> void:
	_build_ui()
	hide()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


func show_relics() -> void:
	_populate()
	show()
	grab_focus()


func close() -> void:
	hide()
	closed.emit()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL

	var overlay = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.70)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var panel = Panel.new()
	panel.anchor_left   = 0.10
	panel.anchor_top    = 0.08
	panel.anchor_right  = 0.90
	panel.anchor_bottom = 0.92
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.026, 0.022, 0.052, 0.98)
	ps.border_color = Color(C_GOLD, 0.56)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(8)
	ps.shadow_color = Color(0, 0, 0, 0.45)
	ps.shadow_size = 12
	panel.add_theme_stylebox_override("panel", ps)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)

	var title = Label.new()
	title.text = "レリック"
	title.position = Vector2(28, 20)
	title.size = Vector2(320, 42)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", C_GOLD)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.82))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	panel.add_child(title)

	var close_btn = _make_button("閉じる", Vector2(820, 40), Vector2(128, 42))
	close_btn.pressed.connect(close)
	panel.add_child(close_btn)

	var line = ColorRect.new()
	line.position = Vector2(26, 76)
	line.size = Vector2(922, 1)
	line.color = Color(C_GOLD, 0.35)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(line)

	var scroll = ScrollContainer.new()
	scroll.position = Vector2(26, 94)
	scroll.size = Vector2(922, 450)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	panel.add_child(scroll)

	_grid = GridContainer.new()
	_grid.columns = 1
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(_grid)

	_empty_label = Label.new()
	_empty_label.text = "まだレリックを持っていません。"
	_empty_label.position = Vector2(26, 104)
	_empty_label.size = Vector2(922, 80)
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.add_theme_font_size_override("font_size", 18)
	_empty_label.add_theme_color_override("font_color", C_TEXT)
	_empty_label.visible = false
	panel.add_child(_empty_label)


func _populate() -> void:
	for child in _grid.get_children():
		child.queue_free()
	var relics = GameState.get_owned_relics()
	_empty_label.visible = relics.is_empty()
	for relic in relics:
		var entry = _RelicEntry.new()
		entry.relic_data = relic
		_grid.add_child(entry)


func _make_button(text: String, center: Vector2, sz: Vector2) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.position = center - sz / 2.0
	btn.size = sz
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(0.94, 0.88, 1.0))
	var n = StyleBoxFlat.new()
	n.bg_color = Color(0.12, 0.04, 0.26)
	n.border_color = Color(0.55, 0.26, 0.86)
	n.set_border_width_all(2)
	n.set_corner_radius_all(7)
	btn.add_theme_stylebox_override("normal", n)
	var h = StyleBoxFlat.new()
	h.bg_color = Color(0.22, 0.08, 0.48)
	h.border_color = Color(0.78, 0.44, 1.0)
	h.set_border_width_all(2)
	h.set_corner_radius_all(7)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", h)
	return btn


class _RelicEntry extends Control:
	const W := 884.0
	const H := 96.0
	const PAD_X := 18.0
	const LEFT_W := 180.0
	const DIVIDER_X := 216.0
	const TEXT_X := 236.0
	const TEXT_W := 628.0
	const NAME_Y := 20.0
	const NAME_H := 24.0
	const RARITY_Y := 48.0
	const RARITY_H := 14.0
	const EFFECT_Y := 16.0
	const EFFECT_H := 28.0
	const MEMORY_Y := 50.0
	const MEMORY_H := 30.0

	var relic_data: Dictionary = {}

	func _ready() -> void:
		custom_minimum_size = Vector2(W, H)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not relic_data.is_empty():
			_build()

	func _build() -> void:
		var rarity = relic_data.get("rarity", "common")

		var name_lbl = Label.new()
		name_lbl.text = relic_data.get("name_jp", "")
		name_lbl.position = Vector2(PAD_X, NAME_Y)
		name_lbl.size = Vector2(LEFT_W, NAME_H)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.add_theme_color_override("font_color", Color(0.92, 0.86, 1.0))
		add_child(name_lbl)

		var rar_lbl = Label.new()
		rar_lbl.text = _rarity_text(rarity)
		rar_lbl.position = Vector2(PAD_X, RARITY_Y)
		rar_lbl.size = Vector2(LEFT_W, RARITY_H)
		rar_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rar_lbl.add_theme_font_size_override("font_size", 9)
		rar_lbl.add_theme_color_override("font_color", _rarity_label_color(rarity))
		add_child(rar_lbl)

		var divider = ColorRect.new()
		divider.position = Vector2(DIVIDER_X, 14)
		divider.size = Vector2(1, H - 28)
		divider.color = Color(_border_color(rarity), 0.32)
		divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(divider)

		_add_section_label("効果: " + _effect_text(), Vector2(TEXT_X, EFFECT_Y), Vector2(TEXT_W, EFFECT_H), 11, Color(0.84, 0.82, 0.95), true, 2)
		_add_section_label("記憶: " + _memory_text(), Vector2(TEXT_X, MEMORY_Y), Vector2(TEXT_W, MEMORY_H), 10, Color(0.62, 0.58, 0.74), true, 2)

	func _add_section_label(text: String, pos: Vector2, label_size: Vector2, font_size: int, color: Color, wrap: bool, max_lines: int = 1) -> void:
		var lbl = Label.new()
		lbl.text = text
		lbl.position = pos
		lbl.size = label_size
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
					var pad = float(i) * 2.5
					draw_rect(Rect2(-pad, -pad, w + pad * 2, h + pad * 2),
						Color(0.65, 0.22, 0.90, 0.05 * float(i)), true)
				draw_rect(Rect2(0, 0, w, h), Color(0.048, 0.028, 0.082, 0.97), true)
				draw_rect(Rect2(0, 0, w, h), Color(0.72, 0.32, 0.95, 0.90), false, 2.0)
				var gold = Color(0.78, 0.52, 0.92, 0.55)
				var cs := 9.0
				for corner in [Vector2(0,0), Vector2(w,0), Vector2(0,h), Vector2(w,h)]:
					var dx := cs if corner.x == 0.0 else -cs
					var dy := cs if corner.y == 0.0 else -cs
					draw_line(corner, corner + Vector2(dx, 0), gold, 1.5)
					draw_line(corner, corner + Vector2(0, dy), gold, 1.5)
					draw_circle(corner, 2.2, gold)
			"rare":
				for i in range(2, 0, -1):
					var pad = float(i) * 2.0
					draw_rect(Rect2(-pad, -pad, w + pad * 2, h + pad * 2),
						Color(0.30, 0.55, 1.0, 0.06 * float(i)), true)
				draw_rect(Rect2(0, 0, w, h), Color(0.032, 0.040, 0.075, 0.97), true)
				draw_rect(Rect2(0, 0, w, h), Color(0.40, 0.65, 1.0, 0.88), false, 2.0)
				var blue = Color(0.38, 0.62, 1.0, 0.55)
				var cs2 := 7.0
				draw_line(Vector2(0,0), Vector2(cs2,0), blue, 1.5)
				draw_line(Vector2(0,0), Vector2(0,cs2), blue, 1.5)
				draw_line(Vector2(w,0), Vector2(w-cs2,0), blue, 1.5)
				draw_line(Vector2(w,0), Vector2(w,cs2), blue, 1.5)
			_:
				draw_rect(Rect2(0, 0, w, h), Color(0.042, 0.036, 0.068, 0.97), true)
				draw_rect(Rect2(0, 0, w, h), Color(0.42, 0.38, 0.50, 0.75), false, 1.5)

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
