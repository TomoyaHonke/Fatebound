extends RefCounted
## 「古びたブロンズ」装飾フレームの共通描画ヘルパー。
## 戦闘UI・カード・各種パネルから static 関数として呼び、見た目の言語を統一する。
## 使い方: const OrnateFrame = preload("res://scenes/ui/OrnateFrame.gd")

const BRONZE        = Color(0.62, 0.50, 0.28)
const BRONZE_BRIGHT = Color(0.88, 0.74, 0.44)
const BRONZE_DARK   = Color(0.26, 0.20, 0.11)
const EDGE_DARK     = Color(0.012, 0.010, 0.020)

## 矩形の装飾フレーム(外縁の影/ブロンズ線/内側の沈み/四隅の飾り)。
static func draw_frame(ci: CanvasItem, rect: Rect2, alpha: float = 1.0, corner: float = 10.0, gem_top: bool = false) -> void:
	ci.draw_rect(rect.grow(2.0), Color(EDGE_DARK, 0.85 * alpha), false, 2.0)
	ci.draw_rect(rect, Color(BRONZE, 0.80 * alpha), false, 1.6)
	ci.draw_rect(rect.grow(-3.0), Color(BRONZE_DARK, 0.55 * alpha), false, 1.0)
	# 上辺の内側ハイライト(金属の反射)
	ci.draw_line(rect.position + Vector2(corner, 1.5),
		Vector2(rect.end.x - corner, rect.position.y + 1.5),
		Color(BRONZE_BRIGHT, 0.26 * alpha), 1.0)
	var center = rect.get_center()
	for p in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
		draw_corner(ci, p, center, corner, alpha)
	if gem_top:
		draw_gem(ci, Vector2(center.x, rect.position.y), 5.0, alpha)

## フレーム角の飾り(内向きのL字線+ひし形)。
static func draw_corner(ci: CanvasItem, corner_pos: Vector2, toward: Vector2, size: float, alpha: float = 1.0) -> void:
	var dx = signf(toward.x - corner_pos.x)
	var dy = signf(toward.y - corner_pos.y)
	ci.draw_line(corner_pos, corner_pos + Vector2(dx * size, 0), Color(BRONZE_BRIGHT, 0.72 * alpha), 2.0)
	ci.draw_line(corner_pos, corner_pos + Vector2(0, dy * size), Color(BRONZE_BRIGHT, 0.72 * alpha), 2.0)
	draw_gem(ci, corner_pos, 3.4, alpha)

## ひし形の宝飾(明るい縁+暗い芯)。
static func draw_gem(ci: CanvasItem, pos: Vector2, r: float, alpha: float = 1.0, col: Color = BRONZE_BRIGHT) -> void:
	ci.draw_colored_polygon(PackedVector2Array([
		pos + Vector2(0, -r), pos + Vector2(r * 0.7, 0),
		pos + Vector2(0, r), pos + Vector2(-r * 0.7, 0),
	]), Color(col, 0.95 * alpha))
	var r2 = r * 0.42
	ci.draw_colored_polygon(PackedVector2Array([
		pos + Vector2(0, -r2), pos + Vector2(r2 * 0.7, 0),
		pos + Vector2(0, r2), pos + Vector2(-r2 * 0.7, 0),
	]), Color(EDGE_DARK, 0.80 * alpha))

## 縦の区切り罫(両端と中央にひし形)。
static func draw_divider(ci: CanvasItem, from: Vector2, to: Vector2, alpha: float = 1.0) -> void:
	ci.draw_line(from, to, Color(BRONZE, 0.38 * alpha), 1.2)
	ci.draw_line(from + Vector2(2, 0), to + Vector2(2, 0), Color(EDGE_DARK, 0.50 * alpha), 1.0)
	draw_gem(ci, from, 4.0, alpha * 0.92)
	draw_gem(ci, (from + to) * 0.5, 2.8, alpha * 0.50)
	draw_gem(ci, to, 4.0, alpha * 0.92)
