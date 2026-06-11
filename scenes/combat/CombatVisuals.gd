extends RefCounted
## 戦闘画面の手続き描画ノード群(背景・プレイヤーシルエット・各種エフェクト)。
## CombatScene からは CombatVisuals.AmbientBG.new() のように参照する。

class AmbientBG extends Node2D:
	const OrnateFrame = preload("res://scenes/ui/OrnateFrame.gd")
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
		var top = 490.0

		# Soft gradient strips easing the battlefield into the band
		draw_rect(Rect2(0, top - 26, 1280, 26), Color(0.006, 0.005, 0.014, 0.30), true)
		draw_rect(Rect2(0, top - 12, 1280, 12), Color(0.006, 0.005, 0.014, 0.55), true)

		# Base fill layers — deep dark backdrop
		draw_rect(Rect2(0, top, 1280, 720 - top), Color(0.008, 0.007, 0.018, 0.98), true)
		draw_rect(Rect2(0, top + 5, 1280, 715 - top), Color(0.022, 0.019, 0.044, 0.94), true)

		# Section tints: energy | hand | end-turn
		draw_rect(Rect2(0, top, 188, 720 - top), Color(0.030, 0.022, 0.056, 0.40), true)
		draw_rect(Rect2(1030, top, 250, 720 - top), Color(0.026, 0.018, 0.052, 0.40), true)

		# ── Top trim — antique bronze edge ────────────────────────────────────────
		draw_line(Vector2(0, top - 2), Vector2(1280, top - 2), Color(OrnateFrame.EDGE_DARK, 0.80), 2.0)
		draw_line(Vector2(0, top), Vector2(1280, top), Color(OrnateFrame.BRONZE, 0.62), 1.8)
		draw_line(Vector2(0, top + 2), Vector2(1280, top + 2), Color(OrnateFrame.BRONZE_BRIGHT, 0.20), 1.0)
		draw_line(Vector2(0, top + 9), Vector2(1280, top + 9), Color(0.10, 0.08, 0.18, 0.45), 1.4)
		# Center finial on the trim
		OrnateFrame.draw_gem(self, Vector2(640, top), 5.0, 0.80)

		# ── Inner frame line around the whole band ───────────────────────────────
		var inner = Rect2(7, top + 7, 1266, 706 - top)
		draw_rect(inner, Color(OrnateFrame.BRONZE, 0.16), false, 1.0)
		for p in [inner.position, Vector2(inner.end.x, inner.position.y), inner.end, Vector2(inner.position.x, inner.end.y)]:
			OrnateFrame.draw_corner(self, p, inner.get_center(), 12.0, 0.42)

		# ── Section dividers ──────────────────────────────────────────────────────
		OrnateFrame.draw_divider(self, Vector2(188, top + 14), Vector2(188, 706), 0.75)
		OrnateFrame.draw_divider(self, Vector2(1030, top + 14), Vector2(1030, 706), 0.75)

		# ── Bottom edge ──────────────────────────────────────────────────────────
		draw_rect(Rect2(0, 712, 1280, 8), Color(0.002, 0.002, 0.008, 0.45), true)
		draw_line(Vector2(0, 712), Vector2(1280, 712), Color(OrnateFrame.BRONZE_DARK, 0.50), 1.0)

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
	## 上部の正方形領域にオーブ、その下にエナジー残数のひし形ピップを描く。
	const OrnateFrame = preload("res://scenes/ui/OrnateFrame.gd")

	var _phase: float = 0.0

	func _process(delta: float) -> void:
		_phase += delta
		queue_redraw()

	func _draw() -> void:
		var center = Vector2(size.x / 2.0, size.x / 2.0)
		var radius = size.x * 0.40
		var pulse = 0.5 + sin(_phase * 1.7) * 0.5

		# Outer purple glow (breathing)
		for i in range(4, 0, -1):
			draw_circle(center, radius + 2.0 + i * 4.5,
				Color(0.56, 0.20, 0.95, (0.030 + 0.022 * (4 - i)) * (0.75 + pulse * 0.45)))

		# Orb body
		draw_circle(center, radius, Color(0.15, 0.080, 0.30, 0.98))
		draw_circle(center + Vector2(-radius * 0.26, -radius * 0.32), radius * 0.48, Color(0.62, 0.40, 0.95, 0.16))
		draw_circle(center + Vector2(radius * 0.18, radius * 0.30), radius * 0.55, Color(0.04, 0.02, 0.10, 0.35))

		# Bronze outer ring with tick marks
		draw_circle(center, radius + 5.0, Color(OrnateFrame.BRONZE, 0.55), false, 1.4)
		for i in 12:
			var ang = TAU * i / 12.0
			var dir = Vector2(cos(ang), sin(ang))
			draw_line(center + dir * (radius + 3.0), center + dir * (radius + 7.0),
				Color(OrnateFrame.BRONZE_BRIGHT, 0.42), 1.4)

		# Inner purple rings
		draw_circle(center, radius, Color(0.74, 0.38, 1.0, 0.88), false, 2.6)
		draw_circle(center, radius - 5.0, Color(0.88, 0.70, 1.0, 0.16 + pulse * 0.08), false, 1.2)

		_draw_energy_pips()

	func _draw_energy_pips() -> void:
		var max_e = GameState.player_max_energy
		var cur_e = GameState.player_energy
		if max_e <= 0 or max_e > 8:
			return
		var spacing = 16.0
		var y = size.x + 12.0
		var x0 = size.x / 2.0 - (max_e - 1) * spacing / 2.0
		for i in max_e:
			var pos = Vector2(x0 + i * spacing, y)
			if i < cur_e:
				draw_circle(pos, 7.0, Color(0.60, 0.26, 0.95, 0.22))
				OrnateFrame.draw_gem(self, pos, 5.0, 1.0, Color(0.78, 0.50, 1.0))
			else:
				OrnateFrame.draw_gem(self, pos, 4.4, 0.40, Color(0.30, 0.24, 0.42))


class ImpactBurst extends Node2D:
	## カード着弾時の小さな光の破裂(リング+火花)。再生後に自動で消える。
	const DURATION := 0.30

	var color: Color = Color(1.0, 0.42, 0.30)
	var _t: float = 0.0
	var _spark_angles: Array = []

	func _ready() -> void:
		z_index = 30
		for i in 9:
			_spark_angles.append(randf() * TAU)

	func _process(delta: float) -> void:
		_t += delta / DURATION
		if _t >= 1.0:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var expand = 1.0 - pow(1.0 - _t, 2.0)
		var fade = 1.0 - _t
		# 中心の閃光
		draw_circle(Vector2.ZERO, 4.0 + 14.0 * (1.0 - expand), Color(1.0, 0.96, 0.88, fade * 0.75))
		# 広がるリング
		draw_arc(Vector2.ZERO, 10.0 + 38.0 * expand, 0.0, TAU, 28,
			Color(color, fade * 0.85), 1.5 + 3.5 * fade)
		draw_arc(Vector2.ZERO, 6.0 + 26.0 * expand, 0.0, TAU, 24,
			Color(color.lightened(0.35), fade * 0.45), 1.2)
		# 火花
		for a in _spark_angles:
			var dir = Vector2(cos(a), sin(a))
			var inner = dir * (10.0 + 34.0 * expand)
			var outer = dir * (16.0 + 44.0 * expand)
			draw_line(inner, outer, Color(color.lightened(0.25), fade * 0.80), 1.6)


class AuraEffect extends Node2D:
	## バフ・回復などで足元から立ち上る光の粒。色を設定して使う。再生後自動で消える。
	const DURATION := 0.85

	var color: Color = Color(1.0, 0.78, 0.28)
	var _t: float = 0.0
	var _motes: Array = []

	func _ready() -> void:
		z_index = 28
		for i in 12:
			_motes.append({
				"x": randf_range(-46.0, 46.0),
				"delay": randf_range(0.0, 0.35),
				"speed": randf_range(0.8, 1.3),
				"r": randf_range(2.0, 4.5),
			})

	func _process(delta: float) -> void:
		_t += delta / DURATION
		if _t >= 1.0:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var fade = 1.0 - _t
		# 足元の光だまり
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.35))
		draw_circle(Vector2.ZERO, 52.0, Color(color, 0.14 * fade))
		draw_circle(Vector2.ZERO, 30.0, Color(color, 0.18 * fade))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# 立ち上る粒
		for m in _motes:
			var lt = clampf((_t - m["delay"]) / (1.0 - m["delay"]), 0.0, 1.0)
			if lt <= 0.0:
				continue
			var pos = Vector2(m["x"] + sin(lt * 6.0 + m["x"]) * 6.0, -lt * 150.0 * m["speed"])
			draw_circle(pos, m["r"] * (1.0 - lt * 0.5), Color(color.lightened(0.30), (1.0 - lt) * 0.85))


class GlowMote extends Node2D:
	## 飛んでいく光弾(呪い・お邪魔カード混入など)。位置は呼び出し側のTweenで動かす。
	var color: Color = Color(0.70, 0.45, 1.0)

	func _ready() -> void:
		z_index = 28

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		draw_circle(Vector2.ZERO, 14.0, Color(color, 0.18))
		draw_circle(Vector2.ZERO, 8.0, Color(color, 0.40))
		draw_circle(Vector2.ZERO, 4.0, Color(color.lightened(0.45), 0.95))


class SlashFlash extends Node2D:
	## 被弾時の白い斬撃閃光。再生後自動で消える。
	const DURATION := 0.18

	var _t: float = 0.0
	var _angle: float = 0.0

	func _ready() -> void:
		z_index = 32
		_angle = randf_range(-0.55, 0.20)

	func _process(delta: float) -> void:
		_t += delta / DURATION
		if _t >= 1.0:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var fade = 1.0 - _t
		var grow = 0.55 + _t * 0.85
		var dir = Vector2(cos(_angle), sin(_angle))
		draw_line(-dir * 92.0 * grow, dir * 92.0 * grow,
			Color(1.0, 0.97, 0.92, 0.85 * fade), 1.0 + 5.0 * fade)
		draw_line(-dir * 70.0 * grow, dir * 70.0 * grow,
			Color(1.0, 0.58, 0.46, 0.50 * fade), 2.0)
		draw_circle(Vector2.ZERO, 26.0 * fade, Color(1.0, 0.92, 0.86, 0.20 * fade))


class FrameOverlay extends Control:
	## 任意のControlの子に置くと、その矩形に装飾フレームを重ね描きする。
	const OrnateFrame = preload("res://scenes/ui/OrnateFrame.gd")

	var frame_alpha: float = 1.0
	var corner: float = 10.0
	var gem_top: bool = false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		resized.connect(queue_redraw)

	func _draw() -> void:
		OrnateFrame.draw_frame(self, Rect2(Vector2.ZERO, size), frame_alpha, corner, gem_top)


class ButtonOrnament extends Control:
	const OrnateFrame = preload("res://scenes/ui/OrnateFrame.gd")

	var btn_size: Vector2 = Vector2.ZERO

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if btn_size == Vector2.ZERO:
			return
		var w = btn_size.x
		var glow_col = Color(0.60, 0.26, 0.94)

		# Outer purple glow rings
		for i in range(4, 0, -1):
			var pad = float(i) * 2.2
			var sb = StyleBoxFlat.new()
			sb.bg_color = Color(0, 0, 0, 0)
			sb.border_color = Color(glow_col.r, glow_col.g, glow_col.b, 0.05 * float(i))
			sb.set_border_width_all(1)
			sb.set_corner_radius_all(8 + i * 2)
			draw_style_box(sb, Rect2(-pad, -pad, w + pad * 2.0, btn_size.y + pad * 2.0))

		# Antique bronze frame
		OrnateFrame.draw_frame(self, Rect2(Vector2.ZERO, btn_size), 1.0, 14.0)

		# Top crest — center gem flanked by short curved horns
		var crest = Vector2(w * 0.5, 0)
		draw_arc(crest + Vector2(-16, 0), 9.0, PI, PI * 1.55, 12, Color(OrnateFrame.BRONZE_BRIGHT, 0.66), 1.6)
		draw_arc(crest + Vector2(16, 0), 9.0, PI * 1.45, TAU, 12, Color(OrnateFrame.BRONZE_BRIGHT, 0.66), 1.6)
		draw_circle(crest + Vector2(0, -3), 7.5, Color(0.05, 0.03, 0.10, 0.85))
		OrnateFrame.draw_gem(self, crest + Vector2(0, -3), 6.0, 1.0)
		# Bottom small gem
		OrnateFrame.draw_gem(self, Vector2(w * 0.5, btn_size.y), 4.0, 0.70)
