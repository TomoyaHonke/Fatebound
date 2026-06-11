extends Control
## 初回プレイ時のガイド。ハイライト枠+説明パネルを順に表示する。
## steps に {"rect": Rect2, "text": String, "panel_pos": Vector2} を設定して add_child する。

signal finished

const OrnateFrame = preload("res://scenes/ui/OrnateFrame.gd")

var steps: Array = []
var _index: int = 0
var _panel: PanelContainer
var _text_label: Label
var _next_btn: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 200
	_build_panel()
	_show_step()

func _build_panel() -> void:
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(340, 0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.030, 0.066, 0.97)
	style.border_color = Color(0.86, 0.72, 0.42, 0.85)
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.set_content_margin_all(14)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_panel.add_child(box)

	_text_label = Label.new()
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.custom_minimum_size = Vector2(312, 0)
	_text_label.add_theme_font_size_override("font_size", 15)
	_text_label.add_theme_color_override("font_color", Color(0.92, 0.90, 0.98))
	_text_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_text_label.add_theme_constant_override("shadow_offset_x", 1)
	_text_label.add_theme_constant_override("shadow_offset_y", 1)
	box.add_child(_text_label)

	_next_btn = Button.new()
	_next_btn.text = "次へ"
	_next_btn.custom_minimum_size = Vector2(0, 36)
	_next_btn.add_theme_font_size_override("font_size", 15)
	var bn = StyleBoxFlat.new()
	bn.bg_color = Color(0.085, 0.040, 0.175, 0.97)
	bn.border_color = Color(0.46, 0.26, 0.70, 0.62)
	bn.set_border_width_all(1)
	bn.set_corner_radius_all(5)
	_next_btn.add_theme_stylebox_override("normal", bn)
	var bh = StyleBoxFlat.new()
	bh.bg_color = Color(0.155, 0.070, 0.32, 0.98)
	bh.border_color = Color(0.74, 0.46, 0.98, 0.85)
	bh.set_border_width_all(1)
	bh.set_corner_radius_all(5)
	_next_btn.add_theme_stylebox_override("hover", bh)
	_next_btn.add_theme_stylebox_override("pressed", bh)
	_next_btn.pressed.connect(_on_next)
	box.add_child(_next_btn)

func _show_step() -> void:
	if _index >= steps.size():
		finished.emit()
		queue_free()
		return
	var step: Dictionary = steps[_index]
	_text_label.text = step.get("text", "")
	_panel.position = step.get("panel_pos", Vector2(470, 300))
	_next_btn.text = "閉じる" if _index == steps.size() - 1 else "次へ(%d/%d)" % [_index + 1, steps.size()]
	queue_redraw()

func _on_next() -> void:
	_index += 1
	_show_step()

func _draw() -> void:
	if _index >= steps.size():
		return
	var hl: Rect2 = steps[_index].get("rect", Rect2())
	var dim = Color(0, 0, 0, 0.52)
	# ハイライト領域以外を暗くする(上下左右の4枚)
	draw_rect(Rect2(0, 0, size.x, hl.position.y), dim, true)
	draw_rect(Rect2(0, hl.end.y, size.x, size.y - hl.end.y), dim, true)
	draw_rect(Rect2(0, hl.position.y, hl.position.x, hl.size.y), dim, true)
	draw_rect(Rect2(hl.end.x, hl.position.y, size.x - hl.end.x, hl.size.y), dim, true)
	# 金の枠で強調
	draw_rect(hl.grow(3.0), Color(OrnateFrame.BRONZE_BRIGHT, 0.90), false, 2.0)
	for p in [hl.grow(3.0).position, Vector2(hl.grow(3.0).end.x, hl.grow(3.0).position.y), hl.grow(3.0).end, Vector2(hl.grow(3.0).position.x, hl.grow(3.0).end.y)]:
		OrnateFrame.draw_gem(self, p, 3.6, 0.95)
