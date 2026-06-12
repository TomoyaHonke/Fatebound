extends RefCounted
## ボタン・パネルの共通スタイル(戦闘画面と同じ落ち着いた紫+ブロンズ装飾)。
## 使い方: const UIStyle = preload("res://scenes/ui/UIStyle.gd")

const CombatVisuals = preload("res://scenes/combat/CombatVisuals.gd")

## 標準ボタンスタイルを適用する。with_frame でブロンズ装飾フレームを重ねる。
static func style_button(btn: Button, corner: float = 5.0, with_frame: bool = false) -> void:
	btn.add_theme_color_override("font_color", Color(0.94, 0.88, 1.0))

	var sn = StyleBoxFlat.new()
	sn.bg_color = Color(0.085, 0.040, 0.175, 0.97)
	sn.border_color = Color(0.46, 0.26, 0.70, 0.62)
	sn.set_border_width_all(1)
	sn.set_corner_radius_all(int(corner))
	sn.shadow_color = Color(0.40, 0.14, 0.72, 0.22)
	sn.shadow_size = 5
	btn.add_theme_stylebox_override("normal", sn)

	var sh = StyleBoxFlat.new()
	sh.bg_color = Color(0.155, 0.070, 0.32, 0.98)
	sh.border_color = Color(0.74, 0.46, 0.98, 0.85)
	sh.set_border_width_all(1)
	sh.set_corner_radius_all(int(corner))
	sh.shadow_color = Color(0.56, 0.24, 0.92, 0.40)
	sh.shadow_size = 9
	btn.add_theme_stylebox_override("hover", sh)
	btn.add_theme_stylebox_override("pressed", sh)

	var sd = StyleBoxFlat.new()
	sd.bg_color = Color(0.055, 0.045, 0.115, 0.92)
	sd.border_color = Color(0.22, 0.16, 0.34, 0.50)
	sd.set_border_width_all(1)
	sd.set_corner_radius_all(int(corner))
	btn.add_theme_stylebox_override("disabled", sd)

	if with_frame:
		var frame = CombatVisuals.FrameOverlay.new()
		frame.frame_alpha = 0.50
		frame.corner = 8.0
		btn.add_child(frame)

## 暗い台座+ブロンズ装飾フレームのパネルスタイルを適用する。
## bg_alpha を下げると背景アートを透かせられる。
static func style_panel(panel: Panel, frame_alpha: float = 0.70, bg_alpha: float = 0.90) -> void:
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.030, 0.026, 0.058, bg_alpha)
	ps.set_border_width_all(0)
	ps.set_corner_radius_all(2)
	panel.add_theme_stylebox_override("panel", ps)
	var frame = CombatVisuals.FrameOverlay.new()
	frame.frame_alpha = frame_alpha
	frame.corner = 10.0
	panel.add_child(frame)
