extends Control

signal reward_chosen

const CARD_SCENE = "res://scenes/ui/CardNode.tscn"
const CARD_W = 130.0
const CARD_H = 190.0

const GLOW_COL  = Color(0.5, 0.15, 0.85)
const GOLD_COL  = Color(0.9, 0.78, 0.25)

var _options: Array = []
var _card_nodes: Array = []
var _skip_btn: Button

func show_reward(options: Array) -> void:
	_options = options
	visible = true
	_build()
	_animate_in()

func _build() -> void:
	# Clear previous
	for c in get_children():
		c.queue_free()
	_card_nodes = []

	# Backdrop
	var bg = TextureRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.texture = _load_inherited_battle_background()
	add_child(bg)

	var ui_scrim = ColorRect.new()
	ui_scrim.position = Vector2(258, 112)
	ui_scrim.size = Vector2(764, 460)
	ui_scrim.color = Color(0.0, 0.0, 0.0, 0.28)
	ui_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui_scrim)

	# Title
	var title = Label.new()
	title.text = "報酬を選択"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	title.position.y = 130
	title.size = Vector2(640, 48)
	title.position.x = -320
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", GOLD_COL)
	add_child(title)

	# Subtitle
	var sub = Label.new()
	sub.text = "デッキに加えるカードを1枚選ぶ"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	sub.position.y = 174
	sub.size = Vector2(640, 28)
	sub.position.x = -320
	sub.add_theme_font_size_override("font_size", 17)
	sub.add_theme_color_override("font_color", Color(0.72, 0.65, 0.86))
	add_child(sub)

	# Card row
	var total_w = _options.size() * (CARD_W + 36) - 36
	var start_x = (1280 - total_w) / 2.0
	var row_y   = 245.0

	for i in _options.size():
		var card_data = GameState.get_card(_options[i])
		if card_data.is_empty():
			continue
		var card_scene = load(CARD_SCENE)
		var card_node = card_scene.instantiate()
		add_child(card_node)
		card_node.position = Vector2(start_x + i * (CARD_W + 36), row_y)
		card_node.setup(card_data, i, true)
		card_node.set_base_y(row_y)
		card_node.card_clicked.connect(_on_card_chosen)
		_card_nodes.append(card_node)

	# Skip button
	_skip_btn = _make_skip_btn()
	add_child(_skip_btn)

func _load_inherited_battle_background() -> Texture2D:
	return GameState.load_background_texture(GameState.get_current_battle_background_path())

func _make_skip_btn() -> Button:
	var btn = Button.new()
	btn.text = "スキップ"
	btn.size = Vector2(150, 44)
	btn.position = Vector2(640 - 75, 510)
	btn.add_theme_font_size_override("font_size", 17)
	btn.add_theme_color_override("font_color", Color(0.6, 0.5, 0.75))

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.07, 0.0)
	style.border_color = Color(0.3, 0.2, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.pressed.connect(_on_skip)
	return btn

func _on_card_chosen(index: int) -> void:
	if index < _options.size():
		GameState.add_card_to_deck(_options[index])
	_close()

func _on_skip() -> void:
	_close()

func _close() -> void:
	var t = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "modulate:a", 0.0, 0.35)
	t.tween_callback(func():
		visible = false
		modulate.a = 1.0
		reward_chosen.emit()
	)

func _animate_in() -> void:
	modulate.a = 0.0
	var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "modulate:a", 1.0, 0.4)
	for i in _card_nodes.size():
		var card = _card_nodes[i]
		var base_y = card.position.y
		card.position.y = base_y + 40
		t.parallel().tween_property(card, "position:y", base_y, 0.35).set_delay(i * 0.06)
