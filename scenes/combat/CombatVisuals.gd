extends RefCounted
## 戦闘画面の手続き描画ノード群(背景・プレイヤーシルエット・各種エフェクト)。
## CombatScene からは CombatVisuals.AmbientBG.new() のように参照する。

class AmbientBG extends Node2D:
	const DESIGN_SIZE := Vector2(1280, 720)

	var _phase: float = 0.0
	var _bg_texture: Texture2D
	var _background_key: String = "act1_battle_road"

	func _ready() -> void:
		_bg_texture = _load_background_texture()

	func set_background_key(key: String) -> void:
		_background_key = key
		_bg_texture = _load_background_texture()
		queue_redraw()

	func _load_background_texture() -> Texture2D:
		var texture = GameState.load_background_texture(GameState.get_background_path(_background_key))
		if texture == null:
			var fallback = Image.create(16, 9, false, Image.FORMAT_RGBA8)
			fallback.fill(Color(0.035, 0.032, 0.080, 1.0))
			return ImageTexture.create_from_image(fallback)
		return texture

	func _process(delta: float) -> void:
		_phase += delta
		queue_redraw()

	func _draw() -> void:
		_draw_cover_background()
		_draw_scene_grade()
		_draw_focal_lighting()
		_draw_floor_blend()
		_draw_fog_layers()
		_draw_bottom_ui_band()
		_draw_vignette()

	func _draw_cover_background() -> void:
		if not _bg_texture:
			return
		var viewport_size = DESIGN_SIZE
		var texture_size = _bg_texture.get_size()
		var scale = maxf(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y)
		var draw_size = texture_size * scale
		var pos = (viewport_size - draw_size) * 0.5
		draw_texture_rect(_bg_texture, Rect2(pos, draw_size), false)

	func _draw_scene_grade() -> void:
		draw_rect(Rect2(0, 0, 1280, 500), Color(0.018, 0.014, 0.026, 0.20), true)
		draw_rect(Rect2(0, 430, 1280, 92), Color(0.010, 0.010, 0.018, 0.16), true)

	func _draw_focal_lighting() -> void:
		draw_line(Vector2(72, 416), Vector2(400, 386), Color(0.70, 0.78, 0.94, 0.078), 15.0)
		draw_line(Vector2(118, 282), Vector2(334, 262), Color(0.60, 0.70, 0.92, 0.048), 9.0)
		draw_line(Vector2(675, 430), Vector2(1025, 408), Color(0.58, 0.56, 0.72, 0.08), 2.0)

	func _draw_floor_blend() -> void:
		draw_colored_polygon(PackedVector2Array([
			Vector2(0, 454), Vector2(1280, 436), Vector2(1280, 720), Vector2(0, 720),
		]), Color(0.004, 0.004, 0.010, 0.20))
		draw_colored_polygon(PackedVector2Array([
			Vector2(0, 474), Vector2(1280, 456), Vector2(1280, 504), Vector2(0, 522),
		]), Color(0.018, 0.016, 0.030, 0.34))
		draw_line(Vector2(0, 486), Vector2(1280, 468), Color(0.44, 0.38, 0.42, 0.14), 1.2)

	func _draw_fog_layers() -> void:
		for i in 3:
			var y = 390 + i * 42
			var drift = fmod(_phase * (10 + i * 4) + i * 170, 420.0) - 210.0
			_draw_fog_band(y, drift, 46 + i * 10, Color(0.24, 0.25, 0.33, 0.034 - i * 0.004))
		for i in 3:
			var drift = fmod(_phase * (16 + i * 4) + i * 160, 520.0) - 260.0
			_draw_fog_band(486 + i * 18, drift, 34, Color(0.15, 0.16, 0.22, 0.026))

	func _draw_bottom_ui_band() -> void:
		# Base fill layers — deep dark backdrop
		draw_rect(Rect2(0, 488, 1280, 232), Color(0.005, 0.004, 0.012, 0.97), true)
		draw_rect(Rect2(0, 502, 1280, 218), Color(0.016, 0.015, 0.036, 0.94), true)

		# Slanted transition polygon blending battlefield into UI
		draw_colored_polygon(PackedVector2Array([
			Vector2(0, 488), Vector2(1280, 470), Vector2(1280, 520), Vector2(0, 538),
		]), Color(0.034, 0.028, 0.062, 0.90))

		# Section tints (gentler)
		draw_rect(Rect2(0, 502, 188, 218), Color(0.014, 0.012, 0.028, 0.38), true)    # energy
		draw_rect(Rect2(1030, 502, 250, 218), Color(0.010, 0.008, 0.024, 0.38), true)  # end-turn

		# ── Top border — refined metallic edge ───────────────────────────────────
		draw_line(Vector2(0, 491), Vector2(1280, 473), Color(0.58, 0.46, 0.20, 0.14), 3.0)
		draw_line(Vector2(0, 488), Vector2(1280, 470), Color(0.86, 0.74, 0.42, 0.34), 1.2)
		# Inner shadow line
		draw_line(Vector2(0, 508), Vector2(1280, 490), Color(0.16, 0.14, 0.28, 0.36), 1.6)

		# ── Section dividers (subtle) ─────────────────────────────────────────────
		var ldx = 188.0  # energy | cards
		var rdx = 1030.0  # cards | end-turn
		# Left divider
		draw_line(Vector2(ldx, 505), Vector2(ldx, 716), Color(0.44, 0.34, 0.60, 0.22), 1.0)
		draw_line(Vector2(ldx + 2, 505), Vector2(ldx + 2, 716), Color(0.06, 0.04, 0.14, 0.20), 0.8)
		draw_circle(Vector2(ldx + 1, 505), 3.0, Color(0.78, 0.64, 0.30, 0.38))
		draw_circle(Vector2(ldx + 1, 610), 2.2, Color(0.66, 0.52, 0.24, 0.18))
		draw_circle(Vector2(ldx + 1, 716), 3.0, Color(0.78, 0.64, 0.30, 0.30))
		# Right divider
		draw_line(Vector2(rdx, 505), Vector2(rdx, 716), Color(0.44, 0.34, 0.60, 0.22), 1.0)
		draw_line(Vector2(rdx + 2, 505), Vector2(rdx + 2, 716), Color(0.06, 0.04, 0.14, 0.20), 0.8)
		draw_circle(Vector2(rdx + 1, 505), 3.0, Color(0.78, 0.64, 0.30, 0.38))
		draw_circle(Vector2(rdx + 1, 610), 2.2, Color(0.66, 0.52, 0.24, 0.18))
		draw_circle(Vector2(rdx + 1, 716), 3.0, Color(0.78, 0.64, 0.30, 0.30))

		# ── Corner decorations (restrained) ──────────────────────────────────────
		var gold = Color(0.80, 0.68, 0.34, 0.38)
		var gold_dim = Color(0.68, 0.56, 0.26, 0.22)
		var cs = 14.0  # corner size
		# Top-left
		draw_line(Vector2(10, 492), Vector2(10 + cs, 492), gold, 1.4)
		draw_line(Vector2(10, 492), Vector2(10, 492 + cs), gold, 1.4)
		draw_circle(Vector2(10, 492), 2.5, gold)
		# Top-right
		draw_line(Vector2(1270, 474), Vector2(1270 - cs, 474), gold, 1.4)
		draw_line(Vector2(1270, 474), Vector2(1270, 474 + cs), gold, 1.4)
		draw_circle(Vector2(1270, 474), 2.5, gold)
		# Bottom-left
		draw_line(Vector2(10, 714), Vector2(10 + cs, 714), gold_dim, 1.2)
		draw_line(Vector2(10, 714), Vector2(10, 714 - cs), gold_dim, 1.2)
		draw_circle(Vector2(10, 714), 2.0, gold_dim)
		# Bottom-right
		draw_line(Vector2(1270, 714), Vector2(1270 - cs, 714), gold_dim, 1.2)
		draw_line(Vector2(1270, 714), Vector2(1270, 714 - cs), gold_dim, 1.2)
		draw_circle(Vector2(1270, 714), 2.0, gold_dim)

		# ── Bottom edge ──────────────────────────────────────────────────────────
		draw_rect(Rect2(0, 710, 1280, 10), Color(0.002, 0.002, 0.008, 0.40), true)
		draw_line(Vector2(0, 710), Vector2(1280, 710), Color(0.38, 0.30, 0.50, 0.14), 1.0)

		# ── Subtle texture bands in card hand area ───────────────────────────────
		for i in 3:
			var y = 556 + i * 40
			draw_line(Vector2(190 + i * 28, y), Vector2(1028 - i * 28, y - 10),
				Color(0.038, 0.042, 0.078, 0.10 - i * 0.018), 8.0)

	func _draw_vignette() -> void:
		for i in 7:
			var a = 0.018 + i * 0.012
			draw_rect(Rect2(-i * 18, -i * 10, 1280 + i * 36, 42 + i * 16), Color(0, 0, 0, a), true)
			draw_rect(Rect2(-i * 18, 664 - i * 8, 1280 + i * 36, 70 + i * 22), Color(0, 0, 0, a), true)
			draw_rect(Rect2(-i * 12, 0, 62 + i * 18, 720), Color(0, 0, 0, a * 0.80), true)
			draw_rect(Rect2(1218 - i * 6, 0, 72 + i * 18, 720), Color(0, 0, 0, a * 0.80), true)

	func _draw_fog_band(y: float, drift: float, height: float, color: Color) -> void:
		var points = PackedVector2Array()
		for i in 9:
			var x = -180 + i * 205 + drift
			var wave = sin(_phase * 0.55 + i * 0.9 + y * 0.03) * 12.0
			points.append(Vector2(x, y + wave))
		for i in range(8, -1, -1):
			var x = -180 + i * 205 + drift
			var wave = cos(_phase * 0.48 + i * 0.8 + y * 0.02) * 14.0
			points.append(Vector2(x, y + height + wave))
		draw_colored_polygon(points, color)


class PlayerGroundShadow extends Node2D:
	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(2.8, 0.45))
		draw_circle(Vector2.ZERO, 20, Color(0, 0, 0, 0.40))
		draw_circle(Vector2.ZERO, 13, Color(0.12, 0.15, 0.24, 0.16))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


class PlayerSilhouette extends Node2D:
	const PLAYER_TEXTURE_PATH = "res://assets/characters/player.png"
	const SPRITE_GROUND_LIFT = -18.0

	var _phase: float = 0.0
	var _hit_flash: float = 0.0
	var _shake: float = 0.0
	var _base_sprite_scale := Vector2(0.49, 0.49)
	var _sprite: Sprite2D
	var _rim_sprite: Sprite2D
	var _shadow: Node2D

	func _ready() -> void:
		var player_texture = _load_player_texture()

		_shadow = PlayerGroundShadow.new()
		_shadow.position = Vector2(0, 142)
		add_child(_shadow)

		_rim_sprite = Sprite2D.new()
		_rim_sprite.texture = player_texture
		_rim_sprite.centered = true
		_rim_sprite.position = Vector2(-4, SPRITE_GROUND_LIFT - 4)
		_rim_sprite.scale = _base_sprite_scale * 1.07
		_rim_sprite.modulate = Color(0.52, 0.42, 0.98, 0.22)
		add_child(_rim_sprite)

		_sprite = Sprite2D.new()
		_sprite.texture = player_texture
		_sprite.centered = true
		_sprite.scale = _base_sprite_scale
		add_child(_sprite)

	func _load_player_texture() -> Texture2D:
		var image = Image.new()
		var err = image.load(ProjectSettings.globalize_path(PLAYER_TEXTURE_PATH))
		if err != OK:
			push_error("Failed to load player texture: %s" % PLAYER_TEXTURE_PATH)
			var fallback = Image.create(8, 8, false, Image.FORMAT_RGBA8)
			fallback.fill(Color(1, 1, 1, 1))
			return ImageTexture.create_from_image(fallback)
		return ImageTexture.create_from_image(image)

	func take_hit() -> void:
		_hit_flash = 1.0
		_shake = 1.0

	func _process(delta: float) -> void:
		_phase += delta
		if _hit_flash > 0.0:
			_hit_flash = maxf(0.0, _hit_flash - delta * 4.0)
		if _shake > 0.0:
			_shake = maxf(0.0, _shake - delta * 5.5)
		_apply_sprite_motion()

	func _apply_sprite_motion() -> void:
		if not _sprite or not _rim_sprite:
			return
		var float_y = sin(_phase * 0.95) * 6.0
		var sway_x = sin(_phase * 0.72) * 2.2
		var breath_x = 1.0 + sin(_phase * 0.78) * 0.010
		var breath_y = 1.0 + sin(_phase * 0.78 + 0.6) * 0.018
		var shake_offset = Vector2.ZERO
		if _shake > 0.0:
			shake_offset = Vector2(randf_range(-5, 5), randf_range(-2, 2)) * _shake

		var grounded_offset = Vector2(0, SPRITE_GROUND_LIFT)
		_sprite.position = grounded_offset + Vector2(sway_x, float_y) + shake_offset
		_sprite.scale = Vector2(_base_sprite_scale.x * breath_x, _base_sprite_scale.y * breath_y)
		_sprite.rotation = sin(_phase * 0.58) * 0.010
		_sprite.modulate = Color(1, 1, 1, 1).lerp(Color(1.0, 0.30, 0.26, 1.0), _hit_flash * 0.55)

		_rim_sprite.position = grounded_offset + Vector2(sway_x - 5.0, float_y - 4.0) + shake_offset * 0.65
		_rim_sprite.scale = _sprite.scale * 1.07
		_rim_sprite.rotation = _sprite.rotation
		_rim_sprite.modulate = Color(0.52, 0.42, 0.98, 0.19 + sin(_phase * 1.6) * 0.03)

		if _shadow:
			_shadow.scale = Vector2(1.0 + sin(_phase * 0.95) * 0.025, 1.0)
			_shadow.modulate.a = 0.62 - sin(_phase * 0.95) * 0.06


class BlockShieldEffect extends Node2D:
	func _draw() -> void:
		var glow = Color(0.55, 0.82, 1.0, 0.20)
		var edge = Color(0.78, 0.92, 1.0, 0.62)
		var violet = Color(0.66, 0.56, 1.0, 0.24)
		draw_circle(Vector2.ZERO, 84.0, glow)
		draw_circle(Vector2.ZERO, 66.0, violet)
		draw_arc(Vector2.ZERO, 74.0, -2.35, -0.78, 24, edge, 3.0)
		draw_arc(Vector2.ZERO, 74.0, 0.78, 2.35, 24, edge, 3.0)
		draw_arc(Vector2.ZERO, 54.0, -2.1, 2.1, 34, Color(0.90, 0.98, 1.0, 0.36), 1.4)
		draw_line(Vector2(-48, -18), Vector2(-26, -44), Color(0.90, 0.98, 1.0, 0.34), 1.5)
		draw_line(Vector2(48, -18), Vector2(26, -44), Color(0.90, 0.98, 1.0, 0.34), 1.5)


class EnergyOrb extends Control:
	func _draw() -> void:
		var center = size / 2.0
		var radius = minf(size.x, size.y) * 0.42
		draw_circle(center, radius + 9.0, Color(0.58, 0.18, 0.96, 0.18))
		draw_circle(center, radius + 4.0, Color(0.50, 0.12, 0.84, 0.34))
		draw_circle(center, radius, Color(0.19, 0.10, 0.36, 0.98))
		draw_circle(center + Vector2(-7, -8), radius * 0.42, Color(0.78, 0.54, 1.0, 0.20))
		draw_circle(center, radius, Color(0.72, 0.34, 1.0, 0.86), false, 2.4)
		draw_circle(center, radius - 6.0, Color(0.86, 0.68, 1.0, 0.22), false, 1.2)


class ButtonOrnament extends Control:
	var btn_size: Vector2 = Vector2.ZERO

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if btn_size == Vector2.ZERO:
			return
		var w = btn_size.x
		var h = btn_size.y
		var gold = Color(0.86, 0.72, 0.34)
		var glow_col = Color(0.60, 0.26, 0.94)
		var cs = 18.0

		# Outer purple glow rings
		for i in range(4, 0, -1):
			var pad = float(i) * 2.2
			var sb = StyleBoxFlat.new()
			sb.bg_color = Color(0, 0, 0, 0)
			sb.border_color = Color(glow_col.r, glow_col.g, glow_col.b, 0.06 * float(i))
			sb.set_border_width_all(1)
			sb.set_corner_radius_all(12 + i * 2)
			draw_style_box(sb, Rect2(-pad, -pad, w + pad * 2.0, h + pad * 2.0))

		# Gold corner L-shapes
		var lw = 2.2
		# Top-left
		draw_line(Vector2(0, 0), Vector2(cs, 0), Color(gold, 0.88), lw)
		draw_line(Vector2(0, 0), Vector2(0, cs), Color(gold, 0.88), lw)
		draw_circle(Vector2(0, 0), 3.5, Color(gold, 0.86))
		# Top-right
		draw_line(Vector2(w, 0), Vector2(w - cs, 0), Color(gold, 0.88), lw)
		draw_line(Vector2(w, 0), Vector2(w, cs), Color(gold, 0.88), lw)
		draw_circle(Vector2(w, 0), 3.5, Color(gold, 0.86))
		# Bottom-left
		draw_line(Vector2(0, h), Vector2(cs, h), Color(gold, 0.76), lw)
		draw_line(Vector2(0, h), Vector2(0, h - cs), Color(gold, 0.76), lw)
		draw_circle(Vector2(0, h), 3.5, Color(gold, 0.74))
		# Bottom-right
		draw_line(Vector2(w, h), Vector2(w - cs, h), Color(gold, 0.76), lw)
		draw_line(Vector2(w, h), Vector2(w, h - cs), Color(gold, 0.76), lw)
		draw_circle(Vector2(w, h), 3.5, Color(gold, 0.74))
		# Mid-edge accent dots
		draw_circle(Vector2(w * 0.5, 0), 2.5, Color(gold, 0.38))
		draw_circle(Vector2(w * 0.5, h), 2.5, Color(gold, 0.32))
