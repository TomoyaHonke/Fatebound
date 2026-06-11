extends RefCounted
## バフ/デバフ・敵の行動予告で使うアイコンバッジの共通部品。
## ID(attack/block/strength/vulnerable/weak/poison/heal/cards)から
## アイコン+数値のバッジControlを生成する。ツールチップは呼び出し側で接続する。

const ICON_DIR = "res://assets/ui/icons/"

const SPECS = {
	"attack":     {"icon": "attack",     "color": Color(1.0, 0.36, 0.30)},
	"block":      {"icon": "shield",     "color": Color(0.45, 0.70, 1.0)},
	"strength":   {"icon": "strength",   "color": Color(1.0, 0.78, 0.28)},
	"vulnerable": {"icon": "vulnerable", "color": Color(1.0, 0.58, 0.26)},
	"weak":       {"icon": "weak",       "color": Color(0.74, 0.50, 1.0)},
	"poison":     {"icon": "poison",     "color": Color(0.40, 0.88, 0.46)},
	"heal":       {"icon": "heal",       "color": Color(0.48, 0.92, 0.58)},
	"cards":      {"icon": "cards",      "color": Color(0.62, 0.50, 0.90)},
}

static var _tex_cache: Dictionary = {}

static func get_color(id: String) -> Color:
	return SPECS.get(id, {}).get("color", Color(0.82, 0.82, 0.88))

static func make_badge(id: String, value_text: String) -> Control:
	var accent = get_color(id)
	var badge = PanelContainer.new()
	badge.mouse_filter = Control.MOUSE_FILTER_STOP
	var style = StyleBoxFlat.new()
	style.bg_color = Color(accent.r, accent.g, accent.b, 0.18)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 4.0
	style.content_margin_right = 4.0
	style.content_margin_top = 2.0
	style.content_margin_bottom = 2.0
	badge.add_theme_stylebox_override("panel", style)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(row)

	var tex = _get_texture(SPECS.get(id, {}).get("icon", ""))
	if tex:
		var icon_rect = TextureRect.new()
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = Vector2(14, 14)
		icon_rect.texture = tex
		icon_rect.modulate = Color(accent.lightened(0.38), 0.95)
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon_rect)

	if value_text != "":
		var label = Label.new()
		label.text = value_text
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(0.98, 0.96, 1.0))
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.86))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(label)

	return badge

static func _get_texture(icon_name: String) -> Texture2D:
	if icon_name.is_empty():
		return null
	if _tex_cache.has(icon_name):
		return _tex_cache[icon_name]
	var path = ICON_DIR + icon_name + ".svg"
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_tex_cache[icon_name] = tex
	return tex
