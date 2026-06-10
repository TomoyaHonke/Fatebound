extends Control

signal closed

const CARD_SCENE = "res://scenes/ui/CardNode.tscn"
const CARD_W := 130.0
const CARD_H := 190.0
const DECK_CARD_SCALE := 1.12
const ENTRY_W := 284.0
const ENTRY_H := 252.0
const SCROLL_TOP_PADDING := 28.0

const C_GOLD := Color(0.86, 0.72, 0.34)
const C_TEXT := Color(0.88, 0.82, 1.00)

var _scroll: ScrollContainer
var _scroll_content: VBoxContainer
var _grid: GridContainer
var _empty_label: Label
var _card_scene: PackedScene


func _ready() -> void:
	_card_scene = load(CARD_SCENE)
	_build_ui()
	hide()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


func show_deck(card_ids: Array) -> void:
	_populate(card_ids)
	show()
	call_deferred("_reset_scroll_top")
	grab_focus()


func close() -> void:
	hide()
	closed.emit()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL

	var overlay = ColorRect.new()
	overlay.name = "入力ブロック"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.68)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var panel = Panel.new()
	panel.name = "デッキパネル"
	panel.anchor_left = 0.12
	panel.anchor_top = 0.10
	panel.anchor_right = 0.88
	panel.anchor_bottom = 0.88
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
	title.text = "デッキ"
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
	_scroll = scroll
	scroll.position = Vector2(26, 94)
	scroll.size = Vector2(922, 450)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	panel.add_child(scroll)

	_scroll_content = VBoxContainer.new()
	_scroll_content.name = "DeckScrollContent"
	_scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_content.add_theme_constant_override("separation", 0)
	scroll.add_child(_scroll_content)

	var top_padding = Control.new()
	top_padding.name = "TopPadding"
	top_padding.custom_minimum_size = Vector2(0, SCROLL_TOP_PADDING)
	_scroll_content.add_child(top_padding)

	_grid = GridContainer.new()
	_grid.name = "DeckGrid"
	_grid.columns = 3
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 18)
	_grid.add_theme_constant_override("v_separation", 18)
	_scroll_content.add_child(_grid)

	_empty_label = Label.new()
	_empty_label.text = "デッキにカードがありません。"
	_empty_label.position = Vector2(26, 104)
	_empty_label.size = Vector2(922, 80)
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.add_theme_font_size_override("font_size", 18)
	_empty_label.add_theme_color_override("font_color", C_TEXT)
	_empty_label.visible = false
	panel.add_child(_empty_label)


func _populate(card_ids: Array) -> void:
	for child in _grid.get_children():
		child.queue_free()

	var entries := _build_entries(card_ids)
	_empty_label.visible = entries.is_empty()
	for entry in entries:
		_grid.add_child(_make_card_entry(entry))


func _reset_scroll_top() -> void:
	if _scroll:
		_scroll.scroll_vertical = 0


func _build_entries(card_ids: Array) -> Array:
	var result: Array = []
	for item in card_ids:
		var card_ref = item
		var zone := ""
		if item is Dictionary and item.has("card_ref"):
			card_ref = item.get("card_ref")
			zone = item.get("zone", "")

		var card = GameState.get_card(card_ref)
		if card.is_empty():
			continue
		result.append({"card": card, "zone": zone})
	return result


func _make_card_entry(entry_data: Dictionary) -> Control:
	var card: Dictionary = entry_data["card"]
	var zone: String = entry_data.get("zone", "")

	var entry = Control.new()
	entry.custom_minimum_size = Vector2(ENTRY_W, ENTRY_H)
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var card_node = _card_scene.instantiate()
	card_node.setup(card, 0, true, true)
	card_node.scale = Vector2(DECK_CARD_SCALE, DECK_CARD_SCALE)
	card_node.position = Vector2(
		(ENTRY_W - CARD_W * DECK_CARD_SCALE) * 0.5,
		6
	)
	entry.add_child(card_node)

	var meta = _make_meta_label(card, zone)
	if not meta.is_empty():
		var meta_label = Label.new()
		meta_label.text = meta
		meta_label.position = Vector2(18, 222)
		meta_label.size = Vector2(ENTRY_W - 36, 24)
		meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		meta_label.add_theme_font_size_override("font_size", 13)
		meta_label.add_theme_color_override("font_color", Color(0.82, 0.76, 0.94))
		meta_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.82))
		meta_label.add_theme_constant_override("shadow_offset_x", 1)
		meta_label.add_theme_constant_override("shadow_offset_y", 1)
		entry.add_child(meta_label)

	return entry


func _make_meta_label(card: Dictionary, zone: String) -> String:
	var parts: Array[String] = []
	if not zone.is_empty():
		parts.append(zone)
	return " / ".join(parts)


func _make_button(text: String, center: Vector2, size: Vector2) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.position = center - size / 2.0
	btn.size = size
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(0.94, 0.88, 1.0))

	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.12, 0.04, 0.26)
	normal.border_color = Color(0.55, 0.26, 0.86)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(7)
	btn.add_theme_stylebox_override("normal", normal)

	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(0.22, 0.08, 0.48)
	hover.border_color = Color(0.78, 0.44, 1.0)
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(7)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	return btn
