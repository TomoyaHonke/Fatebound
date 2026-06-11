extends Control

signal card_clicked(card_index: int)

# ── Card dimensions ───────────────────────────────────────────────────────────
const CARD_W = 130.0
const CARD_H = 190.0

# ── Layout zones ──────────────────────────────────────────────────────────────
const CARD_PAD      = 8.0
const CARD_HEADER_H = 40.0
const CARD_FOOTER_H = 24.0
const CARD_SEP1_Y   = 44.0   # header / body divider
const CARD_SEP2_Y   = 161.0  # body / footer divider

# ── Cost gem ──────────────────────────────────────────────────────────────────
const COST_POS_X     = 20.0
const COST_POS_Y     = 20.0
const COST_RADIUS    = 13.0
const COST_FONT_SIZE = 18

# ── Font sizes ────────────────────────────────────────────────────────────────
const TITLE_FONT_SIZE  = 14
const EFFECT_FONT_SIZE = 13
const TYPE_FONT_SIZE   = 11

# ── Color palette ─────────────────────────────────────────────────────────────
const COLOR_ATTACK  = Color(0.78, 0.14, 0.18)   # crimson
const COLOR_DEFENSE = Color(0.18, 0.36, 0.72)   # indigo
const COLOR_SKILL   = Color(0.16, 0.48, 0.48)   # teal
const COLOR_POWER   = Color(0.58, 0.22, 0.86)   # violet
const COLOR_STATUS  = Color(0.38, 0.38, 0.46)
const COLOR_CURSE   = Color(0.34, 0.16, 0.46)
const COLOR_BG      = Color(0.022, 0.020, 0.050)
const COLOR_BG2     = Color(0.040, 0.036, 0.076)
const COLOR_BG3     = Color(0.058, 0.052, 0.098)
const COLOR_BORDER  = Color(0.44, 0.40, 0.62)
const COLOR_HOVER   = Color(0.90, 0.80, 0.44)
const COLOR_TEXT    = Color(0.97, 0.93, 1.00)
const COLOR_BODY    = Color(0.88, 0.86, 0.96)
const COLOR_COST_BG = Color(0.042, 0.038, 0.088)
const COLOR_GOLD    = Color(0.82, 0.70, 0.40)
const COLOR_RARE    = Color(0.40, 0.62, 1.0)
const COLOR_EPIC    = Color(0.82, 0.42, 1.0)

# ── Icon opacity (tune here) ──────────────────────────────────────────────────
const ICON_ALPHA_NORMAL     = 0.30
const ICON_ALPHA_HOVER      = 0.42
const ICON_ALPHA_UNPLAYABLE = 0.14

# ── Per-card art icon (game-icons.net, CC BY 3.0 — see CREDITS.md) ────────────
const ICON_DIR  = "res://assets/cards/icons/"
const ICON_SIZE = 78.0
static var _icon_cache: Dictionary = {}

var card_data: Dictionary = {}
var card_index: int = 0
var playable: bool = true
var display_only: bool = false
var count_badge: int = 1

var _hovered: bool = false
var _base_y: float = 0.0
var _base_scale: Vector2 = Vector2.ONE
var _target_y: float = 0.0
var _hover_tween: Tween = null

func setup(data: Dictionary, index: int, can_play: bool, display_only_mode: bool = false, count: int = 1) -> void:
	card_data = data
	card_index = index
	display_only = display_only_mode
	playable = true if display_only else can_play
	count_badge = maxi(1, count)
	custom_minimum_size = Vector2(CARD_W, CARD_H)
	size = Vector2(CARD_W, CARD_H)
	pivot_offset = Vector2(CARD_W / 2.0, CARD_H)
	mouse_filter = Control.MOUSE_FILTER_IGNORE if display_only else Control.MOUSE_FILTER_STOP
	queue_redraw()

func get_card_data_safe() -> Dictionary:
	return card_data

func _draw() -> void:
	if card_data.is_empty():
		return

	var type_color = _get_type_color()
	var is_hovered = _hovered and playable and not display_only
	var alpha      = 1.0 if playable else 0.52
	var font       = ThemeDB.fallback_font
	var name_str: String = card_data.get("name", "")
	var desc: String     = card_data.get("description", "")
	var type_text        = _get_type_label()
	var rarity_color     = _get_rarity_color()
	var rarity_level     = _get_rarity_level()
	var cost_pos         = Vector2(COST_POS_X, COST_POS_Y)

	# ── Rarity / hover outer glow ────────────────────────────────────────────
	if rarity_level > 0:
		var glow_alpha = 0.026 if rarity_level == 1 else 0.050
		var glow_steps = 4 if rarity_level == 1 else 7
		for i in range(glow_steps, 0, -1):
			var pad = float(i) * (2.2 if rarity_level == 1 else 3.0)
			var gr = Rect2(-pad, -pad, CARD_W + pad * 2.0, CARD_H + pad * 2.0)
			_draw_round_rect(gr, 9, Color(rarity_color, glow_alpha * i * alpha), true, 1.0)
	if is_hovered:
		for i in range(5, 0, -1):
			var gr = Rect2(-i * 2.4, -i * 2.4, CARD_W + i * 4.8, CARD_H + i * 4.8)
			_draw_round_rect(gr, 9, Color(type_color, 0.032 * i), true, 1.0)

	# ── Card body — three dark layers for depth ──────────────────────────────
	_draw_round_rect(Rect2(0, 0, CARD_W, CARD_H), 7, Color(COLOR_BG, alpha), true, 1.0)
	_draw_round_rect(Rect2(3, 3, CARD_W - 6, CARD_H - 6), 6, Color(COLOR_BG2, alpha), true, 1.0)
	_draw_round_rect(Rect2(6, 6, CARD_W - 12, CARD_H - 12), 5, Color(COLOR_BG3, alpha * 0.96), true, 1.0)

	# ── Header zone (type-colored dark) ──────────────────────────────────────
	_draw_round_rect(Rect2(6, 6, CARD_W - 12, CARD_SEP1_Y - 6), 5,
		Color(type_color.darkened(0.46), alpha * 0.96), true, 1.0)
	draw_rect(Rect2(8, 7, CARD_W - 16, 4), Color(type_color.lightened(0.35), alpha * 0.16), true)
	if rarity_level > 0:
		var title_alpha = 0.28 if rarity_level == 1 else 0.46
		draw_rect(Rect2(8, 7, CARD_W - 16, 3), Color(rarity_color.lightened(0.24), alpha * title_alpha), true)
		draw_rect(Rect2(10, CARD_SEP1_Y - 5, CARD_W - 20, 1), Color(COLOR_GOLD, alpha * (0.32 + rarity_level * 0.13)), true)

	# ── Body zone (main effect area) ──────────────────────────────────────────
	_draw_round_rect(Rect2(6, CARD_SEP1_Y + 3, CARD_W - 12, CARD_SEP2_Y - CARD_SEP1_Y - 5), 3,
		Color(0.026, 0.024, 0.056, alpha * 0.90), true, 1.0)

	# ── Footer zone (type-colored accent) ────────────────────────────────────
	_draw_round_rect(Rect2(6, CARD_SEP2_Y + 3, CARD_W - 12, CARD_H - CARD_SEP2_Y - 9), 4,
		Color(type_color.darkened(0.40), alpha * 0.48), true, 1.0)

	# ── Outer border ──────────────────────────────────────────────────────────
	var border_col = COLOR_HOVER if is_hovered else rarity_color.lerp(type_color.lightened(0.22), 0.45)
	var border_a   = (0.96 if is_hovered else (0.78 + rarity_level * 0.08)) * alpha
	_draw_round_rect(Rect2(0.5, 0.5, CARD_W - 1, CARD_H - 1), 7,
		Color(border_col, border_a), false, 1.6 + rarity_level * 0.35)
	if rarity_level >= 1:
		_draw_round_rect(Rect2(2.5, 2.5, CARD_W - 5, CARD_H - 5), 6,
			Color(COLOR_GOLD, alpha * (0.38 + rarity_level * 0.14)), false, 0.9 + rarity_level * 0.15)
	if rarity_level >= 2:
		_draw_round_rect(Rect2(-1.5, -1.5, CARD_W + 3, CARD_H + 3), 9,
			Color(COLOR_EPIC, alpha * 0.58), false, 1.1)

	# ── Inner gold hairline border ────────────────────────────────────────────
	_draw_round_rect(Rect2(5.5, 5.5, CARD_W - 11, CARD_H - 11), 5,
		Color(COLOR_GOLD.lerp(rarity_color, 0.28), alpha * (0.28 + rarity_level * 0.08)), false, 0.8)

	# ── Header / body separator with gold dots ────────────────────────────────
	draw_rect(Rect2(9, CARD_SEP1_Y, CARD_W - 18, 1),
		Color(type_color.lightened(0.34), alpha * 0.68), true)
	draw_circle(Vector2(9, CARD_SEP1_Y + 0.5), 2.0, Color(COLOR_GOLD, alpha * 0.70))
	draw_circle(Vector2(CARD_W - 9, CARD_SEP1_Y + 0.5), 2.0, Color(COLOR_GOLD, alpha * 0.70))

	# ── Body / footer separator ───────────────────────────────────────────────
	draw_rect(Rect2(11, CARD_SEP2_Y, CARD_W - 22, 1),
		Color(COLOR_GOLD, alpha * 0.36), true)
	if rarity_level >= 1:
		_draw_rarity_side_accents(rarity_level, rarity_color, alpha)

	# ── Corner accent L-shapes ────────────────────────────────────────────────
	_draw_corner_ornaments(rarity_level, rarity_color, alpha)

	# ── Inner art panel (emblem backdrop with subtle frame) ───────────────────
	var art_rect = Rect2(11, CARD_SEP1_Y + 5, CARD_W - 22, CARD_SEP2_Y - CARD_SEP1_Y - 10)
	_draw_round_rect(art_rect, 3, Color(0.013, 0.011, 0.028, alpha * 0.88), true, 1.0)
	_draw_round_rect(art_rect, 3, Color(type_color.darkened(0.18), alpha * 0.38), false, 1.0)
	# Glow behind emblem center
	var art_center = Vector2(CARD_W * 0.5, (CARD_SEP1_Y + CARD_SEP2_Y) * 0.5)
	draw_circle(art_center, 30.0, Color(type_color, alpha * 0.09))
	draw_circle(art_center, 17.0, Color(type_color, alpha * 0.12))

	# ── Card emblem (type-specific background icon) ──────────────────────────
	_draw_card_emblem(type_color, is_hovered)

	# ── Cost gem ──────────────────────────────────────────────────────────────
	var gem_glow = 0.16 + rarity_level * 0.08
	draw_circle(cost_pos, COST_RADIUS + 7 + rarity_level * 3, Color(rarity_color.lerp(type_color, 0.35), alpha * (gem_glow + rarity_level * 0.04)))
	if rarity_level >= 2:
		draw_circle(cost_pos, COST_RADIUS + 11, Color(COLOR_GOLD, alpha * 0.16))
	draw_circle(cost_pos, COST_RADIUS + 4, Color(type_color, alpha * 0.10 + rarity_level * 0.05))
	draw_circle(cost_pos + Vector2(1, 2), COST_RADIUS + 2, Color(0, 0, 0, alpha * 0.42))
	draw_circle(cost_pos, COST_RADIUS + 2, Color(type_color.lightened(0.24).lerp(rarity_color, rarity_level * 0.22), alpha * (0.65 + rarity_level * 0.10)), false, 2.0 + rarity_level * 0.25)
	draw_circle(cost_pos, COST_RADIUS, Color(COLOR_COST_BG, alpha))
	draw_circle(cost_pos, COST_RADIUS - 3, Color(type_color, alpha * 0.20), false, 0.8)
	draw_circle(cost_pos + Vector2(-3, -3), 4.0, Color(1.0, 0.98, 0.92, alpha * 0.20))
	var cost_value = card_data.get("cost", 0)
	var cost_str = "-" if cost_value < 0 else str(cost_value)
	draw_string(font, Vector2(8, 27), cost_str, HORIZONTAL_ALIGNMENT_CENTER, 24, COST_FONT_SIZE,
		Color(0.06, 0.06, 0.12, alpha * 0.60))
	draw_string(font, Vector2(7, 26), cost_str, HORIZONTAL_ALIGNMENT_CENTER, 26, COST_FONT_SIZE,
		Color(1.0, 0.95, 0.78, alpha))

	# ── Card name ─────────────────────────────────────────────────────────────
	var name_x     = COST_POS_X + COST_RADIUS + 6.0
	var name_w     = CARD_W - name_x - 8.0
	var title_size = _fit_font_size(font, name_str, name_w, TITLE_FONT_SIZE, 11)
	draw_string(font, Vector2(name_x + 1, 28), name_str,
		HORIZONTAL_ALIGNMENT_LEFT, name_w, title_size, Color(0.05, 0.04, 0.10, alpha * 0.70))
	draw_string(font, Vector2(name_x, 27), name_str,
		HORIZONTAL_ALIGNMENT_LEFT, name_w, title_size, Color(COLOR_TEXT, alpha))

	# ── Effect text (vertically centered in body zone) ────────────────────────
	var body_top  = CARD_SEP1_Y + 3.0
	var body_bot  = CARD_SEP2_Y - 2.0
	var body_h    = body_bot - body_top
	var line_size = EFFECT_FONT_SIZE
	var line_gap  = 16.0
	var segment_lines = _get_description_segment_lines()
	var lines = _wrap_description(font, desc, CARD_W - 22.0, line_size) if segment_lines.is_empty() else []
	var line_count = segment_lines.size() if not segment_lines.is_empty() else lines.size()
	if line_count > 4:
		line_size = 11
		line_gap  = 14.0
		if segment_lines.is_empty():
			lines = _wrap_description(font, desc, CARD_W - 22.0, line_size)
		line_count = segment_lines.size() if not segment_lines.is_empty() else lines.size()
	var max_lines = mini(line_count, 5)
	var block_h   = max_lines * line_gap
	var y_start   = body_top + (body_h - block_h) / 2.0 + line_size
	for i in max_lines:
		if segment_lines.is_empty():
			draw_string(font, Vector2(12, y_start + 1), lines[i],
				HORIZONTAL_ALIGNMENT_CENTER, CARD_W - 24, line_size,
				Color(0.05, 0.04, 0.10, alpha * 0.65))
			draw_string(font, Vector2(11, y_start), lines[i],
				HORIZONTAL_ALIGNMENT_CENTER, CARD_W - 22, line_size,
				Color(COLOR_BODY, alpha))
		else:
			_draw_segment_line(font, segment_lines[i], y_start, line_size, alpha)
		y_start += line_gap

	# ── Type label ────────────────────────────────────────────────────────────
	var footer_y = CARD_H - 14.0
	draw_string(font, Vector2(10, footer_y + 1), type_text,
		HORIZONTAL_ALIGNMENT_CENTER, CARD_W - 20, TYPE_FONT_SIZE,
		Color(0.05, 0.04, 0.10, alpha * 0.60))
	draw_string(font, Vector2(10, footer_y), type_text,
		HORIZONTAL_ALIGNMENT_CENTER, CARD_W - 20, TYPE_FONT_SIZE,
		Color(type_color.lightened(0.58), alpha * 0.95))

	if count_badge > 1:
		_draw_count_badge(font, alpha, rarity_color, type_color)

	# ── Unplayable overlay (dim + desaturation wash) ──────────────────────────
	if not playable:
		_draw_round_rect(Rect2(0, 0, CARD_W, CARD_H), 7, Color(0.04, 0.04, 0.12, 0.25), true, 1.0)
		draw_rect(Rect2(0, 0, CARD_W, CARD_H), Color(0.26, 0.25, 0.38, 0.10), true)

func _get_type_color() -> Color:
	match card_data.get("type", "skill"):
		"attack":
			return COLOR_ATTACK
		"defense":
			return COLOR_DEFENSE
		"power":
			return COLOR_POWER
		"status":
			return COLOR_STATUS
		"curse":
			return COLOR_CURSE
		_:
			return COLOR_SKILL

func _get_description_segment_lines() -> Array:
	return card_data.get("combat_description_segments", [])

func _draw_segment_line(font: Font, segments: Array, y: float, font_size: int, alpha: float) -> void:
	var total_w := 0.0
	for segment in segments:
		total_w += font.get_string_size(String(segment.get("text", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var x = (CARD_W - total_w) * 0.5
	for segment in segments:
		var text = String(segment.get("text", ""))
		var color: Color = segment.get("color", COLOR_BODY)
		var text_w = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_string(font, Vector2(x + 1, y + 1), text,
			HORIZONTAL_ALIGNMENT_LEFT, text_w + 1, font_size,
			Color(0.05, 0.04, 0.10, alpha * 0.65))
		draw_string(font, Vector2(x, y), text,
			HORIZONTAL_ALIGNMENT_LEFT, text_w + 1, font_size,
			Color(color.r, color.g, color.b, alpha))
		x += text_w

func _get_type_label() -> String:
	match card_data.get("type", "skill"):
		"attack":
			return "攻撃"
		"defense":
			return "防御"
		"skill":
			return "スキル"
		"power":
			return "特殊"
		"status":
			return "状態"
		"curse":
			return "呪い"
		_:
			return "その他"

func _get_rarity_color() -> Color:
	match card_data.get("rarity", "common"):
		"rare":
			return COLOR_RARE
		"epic":
			return COLOR_EPIC
		_:
			return COLOR_GOLD

func _get_rarity_level() -> int:
	match card_data.get("rarity", "common"):
		"rare":
			return 1
		"epic":
			return 2
		_:
			return 0

func _draw_corner_ornaments(rarity_level: int, rarity_color: Color, alpha: float) -> void:
	var base = COLOR_GOLD.lerp(rarity_color, 0.34)
	var line_alpha = alpha * (0.54 + rarity_level * 0.12)
	var lw = 1.0 + rarity_level * 0.35
	var corner = 10.0
	var short = 20.0 + rarity_level * 5.0
	var col = Color(base, line_alpha)

	draw_line(Vector2(CARD_W - short, corner), Vector2(CARD_W - corner, corner), col, lw)
	draw_line(Vector2(CARD_W - corner, corner), Vector2(CARD_W - corner, short), col, lw)
	draw_line(Vector2(corner, CARD_H - corner), Vector2(corner + short - 10.0, CARD_H - corner), col, lw)
	draw_line(Vector2(corner, CARD_H - short), Vector2(corner, CARD_H - corner), col, lw)
	draw_line(Vector2(CARD_W - short, CARD_H - corner), Vector2(CARD_W - corner, CARD_H - corner), col, lw)
	draw_line(Vector2(CARD_W - corner, CARD_H - short), Vector2(CARD_W - corner, CARD_H - corner), col, lw)

	if rarity_level >= 1:
		draw_circle(Vector2(CARD_W - corner, corner), 2.0 + rarity_level * 0.5, Color(rarity_color, alpha * 0.58))
		draw_circle(Vector2(corner, CARD_H - corner), 1.6 + rarity_level * 0.5, Color(rarity_color, alpha * 0.46))
		draw_circle(Vector2(CARD_W - corner, CARD_H - corner), 1.6 + rarity_level * 0.5, Color(rarity_color, alpha * 0.46))
		draw_line(Vector2(13, 13), Vector2(23, 13), Color(COLOR_GOLD, alpha * 0.46), 1.0)
		draw_line(Vector2(13, 13), Vector2(13, 23), Color(COLOR_GOLD, alpha * 0.46), 1.0)
	if rarity_level >= 2:
		var rune_col = Color(rarity_color.lightened(0.20), alpha * 0.48)
		draw_line(Vector2(CARD_W - 32, 19), Vector2(CARD_W - 20, 19), rune_col, 1.0)
		draw_line(Vector2(CARD_W - 26, 13), Vector2(CARD_W - 26, 25), rune_col, 1.0)
		draw_circle(Vector2(CARD_W - 26, 19), 5.5, rune_col, false, 1.0)
		draw_circle(Vector2(CARD_W * 0.5, CARD_SEP1_Y + 0.5), 3.0, Color(COLOR_GOLD, alpha * 0.70))
		var bottom_col = Color(COLOR_GOLD.lerp(rarity_color, 0.45), alpha * 0.48)
		draw_circle(Vector2(CARD_W * 0.5, CARD_H - 18), 8.0, bottom_col, false, 1.0)
		draw_line(Vector2(CARD_W * 0.5 - 10, CARD_H - 18), Vector2(CARD_W * 0.5 + 10, CARD_H - 18), bottom_col, 1.0)
		draw_line(Vector2(CARD_W * 0.5, CARD_H - 28), Vector2(CARD_W * 0.5, CARD_H - 8), bottom_col, 1.0)

func _draw_rarity_side_accents(rarity_level: int, rarity_color: Color, alpha: float) -> void:
	var gold = Color(COLOR_GOLD, alpha * (0.34 + rarity_level * 0.10))
	var accent = Color(rarity_color, alpha * (0.28 + rarity_level * 0.10))
	draw_line(Vector2(8, 52), Vector2(8, 76), gold, 1.0)
	draw_line(Vector2(CARD_W - 8, 52), Vector2(CARD_W - 8, 76), gold, 1.0)
	draw_line(Vector2(8, 126), Vector2(8, 152), gold, 1.0)
	draw_line(Vector2(CARD_W - 8, 126), Vector2(CARD_W - 8, 152), gold, 1.0)
	if rarity_level >= 2:
		draw_circle(Vector2(8, 88), 2.0, accent)
		draw_circle(Vector2(CARD_W - 8, 88), 2.0, accent)
		draw_circle(Vector2(8, 116), 2.0, accent)
		draw_circle(Vector2(CARD_W - 8, 116), 2.0, accent)
		draw_line(Vector2(13, 100), Vector2(22, 100), accent, 1.0)
		draw_line(Vector2(CARD_W - 22, 100), Vector2(CARD_W - 13, 100), accent, 1.0)

func _draw_count_badge(font: Font, alpha: float, rarity_color: Color, type_color: Color) -> void:
	var text = "×%d" % count_badge
	var badge_w = clampf(font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 13).x + 14.0, 34.0, 48.0)
	var rect = Rect2(CARD_W - badge_w - 8.0, CARD_H - 34.0, badge_w, 24.0)
	var frame_col = COLOR_GOLD.lerp(rarity_color, 0.38)
	_draw_round_rect(rect.grow(2.0), 11, Color(0, 0, 0, alpha * 0.42), true, 1.0)
	_draw_round_rect(rect, 10, Color(0.028, 0.023, 0.055, alpha * 0.96), true, 1.0)
	_draw_round_rect(rect, 10, Color(frame_col.lerp(type_color, 0.18), alpha * 0.84), false, 1.0)
	draw_string(font, rect.position + Vector2(1, 16), text,
		HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 13,
		Color(0.02, 0.018, 0.04, alpha * 0.82))
	draw_string(font, rect.position + Vector2(0, 15), text,
		HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 13,
		Color(1.0, 0.92, 0.72, alpha))

func _draw_card_emblem(type_color: Color, is_hovered: bool) -> void:
	var ea: float
	if not playable:
		ea = ICON_ALPHA_UNPLAYABLE
	elif is_hovered:
		ea = ICON_ALPHA_HOVER
	else:
		ea = ICON_ALPHA_NORMAL
	var ic = Vector2(CARD_W * 0.5, (CARD_SEP1_Y + CARD_SEP2_Y) * 0.5)
	var icon_tex = _get_card_icon()
	if icon_tex:
		var lt = type_color.lightened(0.30)
		var rect = Rect2(ic - Vector2(ICON_SIZE, ICON_SIZE) * 0.5, Vector2(ICON_SIZE, ICON_SIZE))
		draw_texture_rect(icon_tex, rect, false, Color(lt.r, lt.g, lt.b, ea))
		return
	match card_data.get("type", "skill"):
		"attack": _draw_emblem_sword(ic, type_color, ea)
		"defense": _draw_emblem_shield(ic, type_color, ea)
		"power":  _draw_emblem_rune(ic, type_color, ea)
		"status": _draw_emblem_rune(ic, type_color, ea)
		"curse":  _draw_emblem_rune(ic, type_color, ea)
		_:        _draw_emblem_rune(ic, type_color, ea)

func _get_card_icon() -> Texture2D:
	var id: String = card_data.get("id", "")
	if id.is_empty():
		return null
	if _icon_cache.has(id):
		return _icon_cache[id]
	var path = ICON_DIR + id + ".svg"
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_icon_cache[id] = tex
	return tex

func _draw_emblem_sword(c: Vector2, tc: Color, ea: float) -> void:
	var lt      = tc.lightened(0.20)
	var outline = Color(lt.r, lt.g, lt.b, ea)
	var detail  = Color(tc.r, tc.g, tc.b, ea * 0.80)
	# Blade — angled slash pointing upper-right
	var tip  = c + Vector2(19, -30)
	var heel = c + Vector2(-14, 19)
	draw_line(tip, heel, outline, 3.2)
	# Crossguard — perpendicular to blade
	var gc = c + Vector2(2, -5)
	draw_line(gc + Vector2(-12, -8), gc + Vector2(12, 8), outline, 2.4)
	# Handle
	var handle_end = heel - (tip - heel).normalized() * 15.0
	draw_line(heel, handle_end, detail, 2.4)
	# Pommel
	draw_circle(handle_end, 4.5, detail)

func _draw_emblem_shield(c: Vector2, tc: Color, ea: float) -> void:
	var lt      = tc.lightened(0.20)
	var outline = Color(lt.r, lt.g, lt.b, ea)
	var fill    = Color(lt.r, lt.g, lt.b, ea * 0.32)
	var detail  = Color(tc.r, tc.g, tc.b, ea * 0.65)
	# Shield pentagon (classic heraldic shape)
	var tl  = c + Vector2(-24, -23)
	var tr  = c + Vector2( 24, -23)
	var br  = c + Vector2( 24,   5)
	var bl  = c + Vector2(-24,   5)
	var bot = c + Vector2(  0,  28)
	draw_colored_polygon(PackedVector2Array([tl, tr, br, bot, bl]), fill)
	draw_line(tl, tr, outline, 1.8)
	draw_line(tl, bl, outline, 1.8)
	draw_line(tr, br, outline, 1.8)
	draw_line(bl, bot, outline, 1.8)
	draw_line(br, bot, outline, 1.8)
	# Heraldic cross dividers
	draw_line(c + Vector2(0, -23), c + Vector2(0, 5), detail, 1.1)
	draw_line(c + Vector2(-24, -8), c + Vector2(24, -8), detail, 1.1)

func _draw_emblem_rune(c: Vector2, tc: Color, ea: float) -> void:
	var lt      = tc.lightened(0.20)
	var outline = Color(lt.r, lt.g, lt.b, ea)
	var detail  = Color(tc.r, tc.g, tc.b, ea * 0.70)
	# Outer ring
	draw_circle(c, 26.0, outline, false, 1.8)
	# Inner ring
	draw_circle(c, 14.0, Color(outline.r, outline.g, outline.b, outline.a * 0.70), false, 1.2)
	# 4 cardinal spokes
	for i in 4:
		var angle    = i * (PI * 0.5)
		var inner_pt = c + Vector2(cos(angle), sin(angle)) * 14.0
		var outer_pt = c + Vector2(cos(angle), sin(angle)) * 26.0
		draw_line(inner_pt, outer_pt, detail, 1.4)
	# 4 diagonal accent dots
	for i in 4:
		var angle = i * (PI * 0.5) + PI * 0.25
		draw_circle(c + Vector2(cos(angle), sin(angle)) * 20.0, 2.2, detail)
	# Center dot
	draw_circle(c, 4.5, outline)

func _draw_round_rect(rect: Rect2, radius: int, color: Color, filled: bool, width: float) -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = color if filled else Color(0, 0, 0, 0)
	sb.border_color = color
	sb.set_corner_radius_all(radius)
	if not filled:
		sb.set_border_width_all(int(ceil(width)))
	draw_style_box(sb, rect)

func _fit_font_size(font: Font, text: String, max_width: float, start_size: int, min_size: int) -> int:
	var size = start_size
	while size > min_size and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > max_width:
		size -= 1
	return size

func _wrap_description(font: Font, text: String, max_width: float, font_size: int) -> Array:
	var lines: Array = []
	for raw_line in text.split("\n"):
		var line = String(raw_line)
		if font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= max_width:
			lines.append(line)
			continue
		var current = ""
		for i in line.length():
			var ch = line.substr(i, 1)
			var test = current + ch
			if current != "" and font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > max_width:
				lines.append(current)
				current = ch
			else:
				current = test
		if current != "":
			lines.append(current)
	return lines

func _gui_input(event: InputEvent) -> void:
	if display_only or not playable:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		card_clicked.emit(card_index)

func _on_mouse_entered() -> void:
	if display_only or not playable:
		return
	_hovered = true
	_animate_hover(true)
	queue_redraw()

func _on_mouse_exited() -> void:
	_hovered = false
	_animate_hover(false)
	queue_redraw()

func _animate_hover(is_hovering: bool) -> void:
	if _hover_tween:
		_hover_tween.kill()
	_hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	var target_scale = _base_scale * (1.08 if is_hovering else 1.0)
	var target_offset = -30.0 * _base_scale.y if is_hovering else 0.0
	_hover_tween.tween_property(self, "scale", target_scale, 0.15)
	_hover_tween.parallel().tween_property(self, "position:y", _base_y + target_offset, 0.15)

func set_base_y(y: float) -> void:
	_base_y = y

func set_base_scale(value: Vector2) -> void:
	_base_scale = value
	scale = value

func flash_unplayable() -> void:
	var t = create_tween()
	t.tween_property(self, "modulate", Color(1, 0.3, 0.3), 0.08)
	t.tween_property(self, "modulate", Color(1, 1, 1), 0.12)

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
