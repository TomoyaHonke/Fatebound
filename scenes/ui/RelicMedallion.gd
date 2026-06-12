extends Control
## レリックの円形メダリオン(台座+レア度リング+アイコン)。
## setup(relic_id, サイズ, ツールチップ有無) で初期化して使う共通部品。

const OrnateFrame = preload("res://scenes/ui/OrnateFrame.gd")
const ICON_DIR = "res://assets/ui/icons/relics/"

const RARITY_COLORS = {
	"common": Color(0.78, 0.66, 0.42),
	"rare":   Color(0.45, 0.65, 1.0),
	"epic":   Color(0.78, 0.45, 1.0),
	"boss":   Color(0.95, 0.35, 0.40),
}

static var _icon_cache: Dictionary = {}

var relic_id: String = ""
var _relic: Dictionary = {}
var _tooltip: Control = null
var _hovered: bool = false
var _phase: float = 0.0
var _reveal: float = -1.0  # 0〜1の間は獲得フラッシュ演出中

func setup(id: String, px: float = 32.0, tooltip_enabled: bool = true, reveal: bool = false) -> void:
	relic_id = id
	_relic = GameState.get_relic_definition(id)
	custom_minimum_size = Vector2(px, px)
	size = Vector2(px, px)
	if tooltip_enabled:
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)
	else:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	# エピック=周回光 / ボス=脈動 はアニメーションが必要
	var rarity = _relic.get("rarity", "common")
	set_process(rarity == "epic" or rarity == "boss" or reveal)
	if reveal:
		_reveal = 0.0
		pivot_offset = Vector2(px, px) * 0.5
		scale = Vector2(1.6, 1.6)
		modulate.a = 0.0
		var tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(self, "modulate:a", 1.0, 0.18)
		tw.parallel().tween_property(self, "scale", Vector2.ONE, 0.32)
	queue_redraw()

func _process(delta: float) -> void:
	_phase += delta
	if _reveal >= 0.0:
		_reveal += delta * 1.6
		if _reveal >= 1.0:
			_reveal = -1.0
			var rarity = _relic.get("rarity", "common")
			set_process(rarity == "epic" or rarity == "boss")
	queue_redraw()

func _draw() -> void:
	if _relic.is_empty():
		return
	var c = size * 0.5
	var r = size.x * 0.5 - 1.0
	var rc: Color = RARITY_COLORS.get(_relic.get("rarity", "common"), RARITY_COLORS["common"])

	# 台座
	draw_circle(c, r, Color(0.085, 0.070, 0.140, 0.97))
	draw_circle(c + Vector2(-r * 0.25, -r * 0.30), r * 0.55, Color(1, 1, 1, 0.045))
	# レア度リング+内側のブロンズ環
	draw_circle(c, r, Color(rc, 0.92), false, maxf(1.6, r * 0.09))
	draw_circle(c, r - maxf(2.5, r * 0.14), Color(OrnateFrame.BRONZE, 0.45), false, 1.0)

	var tex = _get_icon()
	if tex:
		var s = r * 1.15
		draw_texture_rect(tex, Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s)),
			false, Color(rc.lightened(0.38), 0.95))

	# ── レア度による格付け ────────────────────────────────────────────────────
	var rarity = _relic.get("rarity", "common")
	# レア以上: リングに目盛り装飾
	if rarity != "common":
		for i in 12:
			var ang = TAU * i / 12.0
			var dir = Vector2(cos(ang), sin(ang))
			draw_line(c + dir * (r - 1.0), c + dir * (r + 1.5), Color(OrnateFrame.BRONZE_BRIGHT, 0.40), 1.2)
	# エピック: 外周を光が周回する
	if rarity == "epic":
		var sweep_ang = _phase * 1.6
		draw_arc(c, r + 1.5, sweep_ang, sweep_ang + PI * 0.4, 10, Color(rc.lightened(0.40), 0.85), 1.6)
	# ボス: 脈動するリング+四方のひし形
	if rarity == "boss":
		var pulse = 0.5 + sin(_phase * 2.4) * 0.5
		draw_circle(c, r + 2.5, Color(rc, 0.20 + pulse * 0.40), false, 1.5)
		if size.x < 56.0:
			for off in [Vector2(0, -r), Vector2(r, 0), Vector2(0, r), Vector2(-r, 0)]:
				OrnateFrame.draw_gem(self, c + off, 2.6, 0.85)

	# 大きいサイズでは四方に飾り
	if size.x >= 56.0:
		for off in [Vector2(0, -r), Vector2(r, 0), Vector2(0, r), Vector2(-r, 0)]:
			OrnateFrame.draw_gem(self, c + off, 3.4, 0.85)

	# 獲得フラッシュ
	if _reveal >= 0.0 and _reveal < 1.0:
		draw_circle(c, r * (0.7 + _reveal * 1.0), Color(1.0, 0.98, 0.92, (1.0 - _reveal) * 0.65))

	if _hovered:
		draw_circle(c, r + 2.0, Color(1.0, 0.88, 0.50, 0.60), false, 1.5)

func _get_icon() -> Texture2D:
	if relic_id.is_empty():
		return null
	if _icon_cache.has(relic_id):
		return _icon_cache[relic_id]
	var path = ICON_DIR + relic_id + ".svg"
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_icon_cache[relic_id] = tex
	return tex

func _on_mouse_entered() -> void:
	_hovered = true
	_show_tooltip()
	queue_redraw()

func _on_mouse_exited() -> void:
	_hovered = false
	if _tooltip:
		_tooltip.visible = false
	queue_redraw()

func _show_tooltip() -> void:
	if _tooltip == null:
		_build_tooltip()
	if _tooltip:
		_tooltip.visible = true

func _build_tooltip() -> void:
	if _relic.is_empty():
		return
	_tooltip = PanelContainer.new()
	_tooltip.visible = false
	_tooltip.z_index = 1200
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.custom_minimum_size = Vector2(240, 0)
	_tooltip.position = Vector2(0, size.y + 6.0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.030, 0.026, 0.060, 0.95)
	style.border_color = Color(0.58, 0.42, 0.84, 0.70)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(9)
	_tooltip.add_theme_stylebox_override("panel", style)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.add_child(box)

	var rows = [
		[_relic.get("name_jp", ""), 13, Color(0.92, 0.80, 0.50)],
		[_relic.get("effect_jp", ""), 12, Color(0.88, 0.86, 0.96)],
		[_relic.get("memory_jp", ""), 10, Color(0.62, 0.58, 0.74)],
	]
	for row in rows:
		if String(row[0]).is_empty():
			continue
		var lbl = Label.new()
		lbl.text = row[0]
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.custom_minimum_size = Vector2(222, 0)
		lbl.add_theme_font_size_override("font_size", row[1])
		lbl.add_theme_color_override("font_color", row[2])
		lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
		lbl.add_theme_constant_override("shadow_offset_x", 1)
		lbl.add_theme_constant_override("shadow_offset_y", 1)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(lbl)
	add_child(_tooltip)
