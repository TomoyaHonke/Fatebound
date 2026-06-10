extends Control

const MAIN_SCENE = "res://scenes/Main.tscn"

var _victory: bool = false

func show_end(is_victory: bool) -> void:
	_victory = is_victory
	SaveManager.record_run_end(is_victory)
	visible = true
	modulate.a = 0.0
	_build()
	_animate_in()

func _build() -> void:
	for c in get_children():
		c.queue_free()

	# Background
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.03, 0.10)
	add_child(bg)

	if _victory:
		_build_victory()
	else:
		_build_defeat()

	# Restart button
	var btn = _make_button("もう一度", Vector2(640, 510))
	btn.pressed.connect(_on_restart)
	add_child(btn)

func _build_victory() -> void:
	# Glow ring
	var glow = _GlowRing.new()
	glow.position = Vector2(640, 280)
	glow.color = Color(0.8, 0.7, 0.2, 0.12)
	glow.radius = 180.0
	add_child(glow)

	var title = _make_label("勝利", 76, Color(0.95, 0.88, 0.35))
	title.position = Vector2(640 - 300, 200)
	title.size = Vector2(600, 100)
	add_child(title)

	var sub = _make_label("影の王は崩れ落ちた。\n虚無に、かすかな光が戻る。", 24, Color(0.76, 0.70, 0.54))
	sub.position = Vector2(640 - 320, 320)
	sub.size = Vector2(640, 80)
	add_child(sub)

	var hp_info = _make_label("残りHP %d" % GameState.player_hp, 18, Color(0.55, 0.72, 0.58))
	hp_info.position = Vector2(640 - 200, 410)
	hp_info.size = Vector2(400, 40)
	add_child(hp_info)

func _build_defeat() -> void:
	var title = _make_label("敗北", 76, Color(0.78, 0.16, 0.16))
	title.position = Vector2(640 - 300, 200)
	title.size = Vector2(600, 100)
	add_child(title)

	var sub = _make_label("影に呑まれた。\n旅はここで終わる。", 24, Color(0.58, 0.42, 0.42))
	sub.position = Vector2(640 - 300, 320)
	sub.size = Vector2(600, 80)
	add_child(sub)

func _make_label(text: String, font_size: int, color: Color) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.72))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	return lbl

func _make_button(text: String, center: Vector2) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.size = Vector2(210, 56)
	btn.position = center - btn.size / 2.0
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color(0.9, 0.85, 1.0))

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.06, 0.32)
	style.border_color = Color(0.5, 0.2, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", style)

	var style_h = StyleBoxFlat.new()
	style_h.bg_color = Color(0.28, 0.10, 0.50)
	style_h.border_color = Color(0.7, 0.3, 1.0)
	style_h.set_border_width_all(2)
	style_h.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("hover", style_h)
	btn.add_theme_stylebox_override("pressed", style_h)
	return btn

func _on_restart() -> void:
	var t = create_tween().set_ease(Tween.EASE_IN)
	t.tween_property(self, "modulate:a", 0.0, 0.45)
	t.tween_callback(func(): get_tree().change_scene_to_file(MAIN_SCENE))

func _animate_in() -> void:
	var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "modulate:a", 1.0, 0.6)


# ── Inline glow ring Node2D for victory screen ────────────────────────────────
class _GlowRing extends Node2D:
	var color: Color = Color(0.8, 0.7, 0.2, 0.12)
	var radius: float = 180.0
	var _phase: float = 0.0

	func _process(delta: float) -> void:
		_phase += delta
		queue_redraw()

	func _draw() -> void:
		var pulse = 1.0 + sin(_phase * 0.8) * 0.06
		for i in range(6, 0, -1):
			draw_circle(Vector2.ZERO, radius * pulse + i * 12, Color(color, color.a * (0.5 + i * 0.08)))
