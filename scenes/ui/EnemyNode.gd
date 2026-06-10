extends Node2D

# Draws authored silhouette-style character art entirely in code.

var enemy_data: Dictionary = {}
var current_hp: int = 0
var max_hp: int = 1
var block: int = 0
var statuses: Dictionary = {}  # { "vulnerable": n, "weak": n }
var next_action: Dictionary = {}

var _phase: float = 0.0
var _shake_offset: Vector2 = Vector2.ZERO
var _flash_intensity: float = 0.0
var _is_dead: bool = false
var _strength_bonus: int = 0
var _sprite: Sprite2D
var _rim_sprite: Sprite2D
var _sprite_shadow: Node2D
var _sprite_base_scale := Vector2.ONE

# UI child refs
var _name_label: Label
var _hp_bar: ProgressBar
var _hp_label: Label
var _intent_panel: Panel
var _intent_header: Label
var _intent_label: Label
var _block_label: Label
var _status_label: Label
var _status_tooltip_panel: Panel
var _status_tooltip_label: Label

const SILHOUETTE_COLOR = Color(0.050, 0.046, 0.095)
const UI_BG            = Color(0.08, 0.06, 0.16, 0.85)
const ENEMY_1_SPRITE_PATH = "res://assets/enemies/holy_soldier.png"
# Enemy 1 visual tuning. The sprite is anchored by bottom-center feet.
const ENEMY_1_SPRITE_SCALE = 0.68
const ENEMY_1_SPRITE_OFFSET = Vector2(0, 142)
const ENEMY_1_HP_BAR_WIDTH = 166.0
const ENEMY_STATUS_BADGE_W = 96.0
const ENEMY_STATUS_BADGE_H = 20.0
const DEFAULT_SPRITE_ENEMY_SCALE = 0.68
const DEFAULT_SPRITE_ENEMY_OFFSET = Vector2(0, 130)
const DEFAULT_SPRITE_HP_BAR_WIDTH = 180.0
const DEFAULT_SPRITE_AURA_COLOR = Color(1.0, 0.86, 0.42)
const DEFAULT_SPRITE_AURA_STRENGTH = 0.12
const DEFAULT_ENEMY_NAME_OFFSET = Vector2(0, -240)
const DEFAULT_ENEMY_HP_OFFSET = Vector2(0, -214)
const DEFAULT_ENEMY_STATUS_OFFSET = Vector2(0, -190)
const INTENT_PANEL_SIZE = Vector2(260, 72)
const STATUS_TOOLTIP_ORDER = ["vulnerable", "weak", "poison", "strength"]
const STATUS_DESCRIPTIONS = {
	"vulnerable": {"name": "脆弱", "description": "受けるダメージが増加する。", "value_label": "残り"},
	"weak": {"name": "脱力", "description": "与えるダメージが低下する。", "value_label": "残り"},
	"poison": {"name": "毒", "description": "ターン終了時にHPを失う。", "value_label": "残り"},
	"strength": {"name": "筋力", "description": "攻撃力が増加する。", "value_label": "値"}
}
# Enemy intent text position relative to the enemy sprite.
# Increase x to move it right. Decrease x to move it left.
# Increase y to move it downward. Decrease y to move it upward.
# Keep this away from HP/status/block UI.
const ENEMY_INTENT_TEXT_OFFSET := Vector2(225, -78)

signal died

func setup(data: Dictionary) -> void:
	enemy_data = data
	max_hp = data.get("max_hp", 50)
	current_hp = max_hp
	block = 0
	statuses = {}
	_strength_bonus = 0
	_is_dead = false
	_clear_sprite_enemy()
	if _uses_sprite_enemy(data):
		_build_sprite_enemy(data)
	queue_redraw()

func _clear_sprite_enemy() -> void:
	if _sprite:
		_sprite.queue_free()
	if _rim_sprite:
		_rim_sprite.queue_free()
	if _sprite_shadow:
		_sprite_shadow.queue_free()
	_sprite = null
	_rim_sprite = null
	_sprite_shadow = null

func _build_sprite_enemy(data: Dictionary) -> void:
	var texture = _load_sprite_texture(data.get("sprite_path", data.get("image_path", ENEMY_1_SPRITE_PATH)))
	var visual_scale = _get_sprite_scale(data)
	var offset = _get_sprite_offset(data)
	_sprite_base_scale = Vector2(visual_scale, visual_scale)
	var texture_size = texture.get_size()
	var foot_anchor = Vector2(0, -texture_size.y * visual_scale * 0.5)

	_sprite_shadow = _EnemySpriteShadow.new()
	_sprite_shadow.position = offset
	add_child(_sprite_shadow)

	_rim_sprite = Sprite2D.new()
	_rim_sprite.texture = texture
	_rim_sprite.centered = true
	_rim_sprite.position = offset + foot_anchor + Vector2(-3, -3)
	_rim_sprite.scale = _sprite_base_scale * 1.04
	_rim_sprite.modulate = Color(1.0, 0.88, 0.36, 0.18)
	add_child(_rim_sprite)

	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.centered = true
	_sprite.position = offset + foot_anchor
	_sprite.scale = _sprite_base_scale
	add_child(_sprite)

func _load_sprite_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path) and not FileAccess.file_exists(ProjectSettings.globalize_path(path)):
		var missing = Image.create(8, 8, false, Image.FORMAT_RGBA8)
		missing.fill(Color(1.0, 0.9, 0.45, 1.0))
		return ImageTexture.create_from_image(missing)
	if ResourceLoader.exists(path):
		var texture = load(path)
		if texture is Texture2D:
			return texture
	var image = Image.new()
	var err = image.load(ProjectSettings.globalize_path(path))
	if err != OK:
		push_warning("Failed to load enemy sprite: %s" % path)
		var fallback = Image.create(8, 8, false, Image.FORMAT_RGBA8)
		fallback.fill(Color(1.0, 0.9, 0.45, 1.0))
		return ImageTexture.create_from_image(fallback)
	return ImageTexture.create_from_image(image)

func _uses_sprite_enemy(data: Dictionary = enemy_data) -> bool:
	var shape = data.get("shape", "")
	return shape == "holy_soldier" or shape == "sprite_enemy"

func _get_sprite_scale(data: Dictionary = enemy_data) -> float:
	var fallback = ENEMY_1_SPRITE_SCALE if data.get("shape", "") == "holy_soldier" else DEFAULT_SPRITE_ENEMY_SCALE
	return float(data.get("enemy_1_sprite_scale", data.get("sprite_scale", fallback))) * float(data.get("size_mult", 1.0))

func _get_sprite_offset(data: Dictionary = enemy_data) -> Vector2:
	var fallback = ENEMY_1_SPRITE_OFFSET if data.get("shape", "") == "holy_soldier" else DEFAULT_SPRITE_ENEMY_OFFSET
	return data.get("enemy_1_sprite_offset", data.get("sprite_offset", fallback))

func _get_enemy_name_offset(data: Dictionary = enemy_data) -> Vector2:
	return data.get("enemy_name_offset", DEFAULT_ENEMY_NAME_OFFSET)

func _get_enemy_hp_offset(data: Dictionary = enemy_data) -> Vector2:
	return data.get("enemy_hp_offset", DEFAULT_ENEMY_HP_OFFSET)

func _get_enemy_status_offset(data: Dictionary = enemy_data) -> Vector2:
	return data.get("enemy_status_offset", DEFAULT_ENEMY_STATUS_OFFSET)

func _get_sprite_hp_width(data: Dictionary = enemy_data) -> float:
	var fallback = ENEMY_1_HP_BAR_WIDTH if data.get("shape", "") == "holy_soldier" else DEFAULT_SPRITE_HP_BAR_WIDTH
	return float(data.get("enemy_1_hp_bar_width", data.get("hp_bar_width", fallback)))

func _get_enemy_intent_offset(data: Dictionary = enemy_data) -> Vector2:
	return data.get("intent_offset", ENEMY_INTENT_TEXT_OFFSET)

func _get_sprite_aura_color(data: Dictionary = enemy_data) -> Color:
	return data.get("aura_color", data.get("glow_color", DEFAULT_SPRITE_AURA_COLOR))

func _get_sprite_aura_strength(data: Dictionary = enemy_data) -> float:
	return float(data.get("aura_strength", DEFAULT_SPRITE_AURA_STRENGTH))

func _build_ui() -> void:
	# Enemy name
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.position = Vector2(-95, 0)
	_name_label.size = Vector2(190, 22)
	_name_label.text = enemy_data.get("display_name", enemy_data.get("name_jp", enemy_data.get("name", "敵")))
	_name_label.add_theme_font_size_override("font_size", 15)
	_name_label.add_theme_color_override("font_color", Color(0.95, 0.86, 0.58))
	_name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.88))
	_name_label.add_theme_constant_override("shadow_offset_x", 1)
	_name_label.add_theme_constant_override("shadow_offset_y", 1)
	var name_style = StyleBoxFlat.new()
	name_style.bg_color = Color(0.035, 0.028, 0.070, 0.82)
	name_style.border_color = Color(0.78, 0.62, 0.30, 0.46)
	name_style.set_border_width_all(1)
	name_style.set_corner_radius_all(5)
	name_style.set_content_margin_all(4)
	_name_label.add_theme_stylebox_override("normal", name_style)
	add_child(_name_label)

	# HP bar
	_hp_bar = ProgressBar.new()
	_hp_bar.min_value = 0
	_hp_bar.max_value = max_hp
	_hp_bar.value = max_hp
	_hp_bar.show_percentage = false
	_hp_bar.position = Vector2(-95, 26)
	_hp_bar.size = Vector2(190, 18)

	var bar_style = StyleBoxFlat.new()
	bar_style.bg_color = Color(0.6, 0.08, 0.08)
	bar_style.set_corner_radius_all(3)
	_hp_bar.add_theme_stylebox_override("fill", bar_style)

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.070, 0.045, 0.100, 0.92)
	bg_style.border_color = Color(0.58, 0.44, 0.22, 0.52)
	bg_style.set_border_width_all(1)
	bg_style.set_corner_radius_all(3)
	_hp_bar.add_theme_stylebox_override("background", bg_style)
	add_child(_hp_bar)

	# HP label
	_hp_label = Label.new()
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.position = Vector2(-95, 47)
	_hp_label.size = Vector2(190, 24)
	_hp_label.add_theme_font_size_override("font_size", 13)
	_hp_label.add_theme_color_override("font_color", Color(0.98, 0.88, 0.82))
	_hp_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.90))
	_hp_label.add_theme_constant_override("shadow_offset_x", 1)
	_hp_label.add_theme_constant_override("shadow_offset_y", 1)
	_update_hp_label()
	add_child(_hp_label)

	# Intent panel background (added first so labels draw on top)
	_intent_panel = Panel.new()
	var ip_style = StyleBoxFlat.new()
	ip_style.bg_color = Color(0, 0, 0, 0)
	ip_style.border_color = Color(0, 0, 0, 0)
	ip_style.set_border_width_all(0)
	ip_style.set_corner_radius_all(0)
	_intent_panel.add_theme_stylebox_override("panel", ip_style)
	_intent_panel.position = Vector2(-140, -248)
	_intent_panel.size = Vector2(280, 80)
	add_child(_intent_panel)

	# Intent header label
	_intent_header = Label.new()
	_intent_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intent_header.position = Vector2(-130, -244)
	_intent_header.size = Vector2(260, 20)
	_intent_header.text = "敵の行動"
	_intent_header.add_theme_font_size_override("font_size", 13)
	_intent_header.add_theme_color_override("font_color", Color(0.76, 0.64, 0.92))
	_intent_header.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	_intent_header.add_theme_constant_override("shadow_offset_x", 1)
	_intent_header.add_theme_constant_override("shadow_offset_y", 2)
	add_child(_intent_header)

	# Intent label (enemy next action)
	_intent_label = Label.new()
	_intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intent_label.position = Vector2(-130, -220)
	_intent_label.size = Vector2(260, 34)
	_intent_label.add_theme_font_size_override("font_size", 18)
	_intent_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	_intent_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	_intent_label.add_theme_constant_override("shadow_offset_x", 2)
	_intent_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(_intent_label)

	# Block label
	_block_label = Label.new()
	_block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_block_label.position = Vector2(-95, 72)
	_block_label.size = Vector2(190, 22)
	_block_label.add_theme_font_size_override("font_size", 14)
	_block_label.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
	_style_badge(_block_label, Color(0.45, 0.65, 1.0))
	_block_label.visible = false
	add_child(_block_label)

	# Status label
	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.position = Vector2(-95, 96)
	_status_label.size = Vector2(190, 22)
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.2))
	_style_badge(_status_label, Color(1.0, 0.55, 0.2))
	_status_label.visible = false
	_status_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_status_label.mouse_entered.connect(_on_status_mouse_entered)
	_status_label.mouse_exited.connect(_on_status_mouse_exited)
	add_child(_status_label)

	if _uses_sprite_enemy():
		var name_offset = _get_enemy_name_offset()
		var hp_offset = _get_enemy_hp_offset()
		var status_offset = _get_enemy_status_offset()
		var hp_w = _get_sprite_hp_width()
		_name_label.position = name_offset + Vector2(-hp_w * 0.5, 0)
		_name_label.size = Vector2(hp_w, 22)
		_hp_bar.position = hp_offset + Vector2(-hp_w * 0.5, 0)
		_hp_bar.size = Vector2(hp_w, 18)
		_hp_label.position = hp_offset + Vector2(-hp_w * 0.5, -1)
		_hp_label.size = Vector2(hp_w, 20)
		_block_label.position = status_offset + Vector2(-ENEMY_STATUS_BADGE_W - 4.0, 0)
		_block_label.size = Vector2(ENEMY_STATUS_BADGE_W, ENEMY_STATUS_BADGE_H)
		_status_label.position = status_offset + Vector2(4.0, 0)
		_status_label.size = Vector2(ENEMY_STATUS_BADGE_W, ENEMY_STATUS_BADGE_H)
		_layout_status_badges()
		var intent_offset = _get_enemy_intent_offset()
		_intent_panel.position = intent_offset - INTENT_PANEL_SIZE * 0.5
		_intent_panel.size = INTENT_PANEL_SIZE
		_intent_header.position = _intent_panel.position + Vector2(10, 6)
		_intent_header.size = Vector2(INTENT_PANEL_SIZE.x - 20, 18)
		_intent_label.position = _intent_panel.position + Vector2(10, 28)
		_intent_label.size = Vector2(INTENT_PANEL_SIZE.x - 20, 30)

func _style_badge(label: Label, accent: Color) -> void:
	label.add_theme_color_override("font_color", Color(0.96, 0.90, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	var badge = StyleBoxFlat.new()
	badge.bg_color = Color(0.035, 0.030, 0.065, 0.88)
	badge.border_color = Color(accent, 0.72)
	badge.set_border_width_all(1)
	badge.set_corner_radius_all(5)
	badge.set_content_margin_all(4)
	label.add_theme_stylebox_override("normal", badge)

func _update_hp_label() -> void:
	if _hp_label:
		_hp_label.text = "%d / %d" % [current_hp, max_hp]

func set_intent(action: Dictionary) -> void:
	next_action = action
	if not _intent_label:
		return
	_intent_label.text = "次: " + action.get("desc", "???")
	match action.get("type", ""):
		"attack", "attack_buff", "attack_multi":
			_intent_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35))
		"block":
			_intent_label.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
		"apply_status", "attack_status":
			_intent_label.add_theme_color_override("font_color", Color(0.9, 0.55, 1.0))
		"heal":
			_intent_label.add_theme_color_override("font_color", Color(0.55, 0.95, 0.62))
		"strength":
			_intent_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.32))
		_:
			_intent_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))

func take_damage(amount: int) -> int:
	var actual = amount
	if statuses.get("vulnerable", 0) > 0:
		actual = int(actual * 1.5)
	var absorbed = mini(block, actual)
	block -= absorbed
	actual -= absorbed
	current_hp = maxi(0, current_hp - actual)
	if _hp_bar:
		_hp_bar.value = current_hp
	_update_hp_label()
	_update_block_label()
	if actual > 0:
		_shake()
		_flash()
	if current_hp <= 0 and not _is_dead:
		_is_dead = true
		_play_death()
	return actual

func gain_block(amount: int) -> void:
	block += amount
	_update_block_label()

func heal(amount: int) -> void:
	if amount <= 0 or _is_dead:
		return
	current_hp = mini(max_hp, current_hp + amount)
	if _hp_bar:
		_hp_bar.value = current_hp
	_update_hp_label()

func apply_status(status: String, amount: int) -> void:
	statuses[status] = statuses.get(status, 0) + amount
	_update_status_label()

func tick_statuses() -> void:
	var to_remove: Array = []
	for key in statuses:
		statuses[key] -= 1
		if statuses[key] <= 0:
			to_remove.append(key)
	for key in to_remove:
		statuses.erase(key)
	block = 0
	_update_block_label()
	_update_status_label()

func get_attack_value(base: int) -> int:
	var dmg = base + _strength_bonus
	if statuses.get("weak", 0) > 0:
		dmg = int(dmg * 0.75)
	return dmg

func add_strength(amount: int) -> void:
	_strength_bonus += amount

func get_strength_bonus() -> int:
	return _strength_bonus

func _update_block_label() -> void:
	if not _block_label:
		return
	if block > 0:
		_block_label.text = "盾 %d" % block
		_block_label.visible = true
	else:
		_block_label.visible = false
	_layout_status_badges()

func _update_status_label() -> void:
	if not _status_label:
		return
	var parts = _status_badge_parts()
	_status_label.text = "  ".join(parts)
	_status_label.visible = not parts.is_empty()
	if parts.is_empty():
		_hide_status_tooltip()
	_layout_status_badges()

func _status_badge_parts() -> Array:
	var parts: Array = []
	for status_id in STATUS_TOOLTIP_ORDER:
		var value = int(statuses.get(status_id, 0))
		if value > 0:
			parts.append("%s %d" % [_status_display_name(status_id), value])
	for status_id in statuses.keys():
		if STATUS_TOOLTIP_ORDER.has(status_id):
			continue
		var value = int(statuses.get(status_id, 0))
		if value > 0:
			parts.append("%s %d" % [_status_display_name(status_id), value])
	return parts

func _on_status_mouse_entered() -> void:
	if not _status_label or not _status_label.visible:
		return
	_status_label.modulate = Color(1.16, 1.16, 1.16, 1.0)
	_show_status_tooltip()

func _on_status_mouse_exited() -> void:
	if _status_label:
		_status_label.modulate = Color.WHITE
	_hide_status_tooltip()

func _ensure_status_tooltip() -> void:
	if _status_tooltip_panel:
		return
	_status_tooltip_panel = Panel.new()
	_status_tooltip_panel.visible = false
	_status_tooltip_panel.z_index = 1000
	_status_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.030, 0.070, 0.88)
	panel_style.border_color = Color(0.58, 0.42, 0.84, 0.70)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(7)
	panel_style.set_content_margin_all(8)
	_status_tooltip_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_status_tooltip_panel)

	_status_tooltip_label = Label.new()
	_status_tooltip_label.position = Vector2(10, 8)
	_status_tooltip_label.add_theme_font_size_override("font_size", 13)
	_status_tooltip_label.add_theme_color_override("font_color", Color(0.92, 0.88, 1.0))
	_status_tooltip_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.86))
	_status_tooltip_label.add_theme_constant_override("shadow_offset_x", 1)
	_status_tooltip_label.add_theme_constant_override("shadow_offset_y", 1)
	_status_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_tooltip_panel.add_child(_status_tooltip_label)

func _show_status_tooltip() -> void:
	var text = _status_tooltip_text()
	if text.is_empty():
		_hide_status_tooltip()
		return
	_ensure_status_tooltip()
	var active_count = max(1, _active_status_count())
	var panel_size = Vector2(260, 24 + active_count * 64)
	_status_tooltip_panel.size = panel_size
	_status_tooltip_label.text = text
	_status_tooltip_label.size = panel_size - Vector2(20, 16)
	_status_tooltip_panel.position = _clamped_local_tooltip_position(_status_label.position + Vector2(0, _status_label.size.y + 8), panel_size)
	_status_tooltip_panel.visible = true

func _hide_status_tooltip() -> void:
	if _status_tooltip_panel:
		_status_tooltip_panel.visible = false

func _status_tooltip_text() -> String:
	var chunks: Array = []
	for status_id in STATUS_TOOLTIP_ORDER:
		var value = int(statuses.get(status_id, 0))
		if value <= 0:
			continue
		var meta = STATUS_DESCRIPTIONS.get(status_id, {})
		chunks.append("%s\n%s\n%s %d" % [
			meta.get("name", _status_display_name(status_id)),
			meta.get("description", "状態異常。"),
			meta.get("value_label", "残り"),
			value
		])
	for status_id in statuses.keys():
		if STATUS_TOOLTIP_ORDER.has(status_id):
			continue
		var value = int(statuses.get(status_id, 0))
		if value > 0:
			chunks.append("%s\n%s\n値 %d" % [_status_display_name(status_id), "状態異常。", value])
	return "\n\n".join(chunks)

func _active_status_count() -> int:
	var count = 0
	for status_id in statuses.keys():
		if int(statuses.get(status_id, 0)) > 0:
			count += 1
	return count

func _status_display_name(status_id: String) -> String:
	return STATUS_DESCRIPTIONS.get(status_id, {}).get("name", status_id)

func _clamped_local_tooltip_position(anchor_pos: Vector2, panel_size: Vector2) -> Vector2:
	var viewport_size = get_viewport_rect().size
	var global_pos = to_global(anchor_pos)
	global_pos.x = clampf(global_pos.x, 8.0, maxf(8.0, viewport_size.x - panel_size.x - 8.0))
	global_pos.y = clampf(global_pos.y, 8.0, maxf(8.0, viewport_size.y - panel_size.y - 8.0))
	return to_local(global_pos)

func _layout_status_badges() -> void:
	if not _block_label or not _status_label or not _uses_sprite_enemy():
		return
	var status_offset = _get_enemy_status_offset()
	var both_visible = _block_label.visible and _status_label.visible
	if both_visible:
		_block_label.position = status_offset + Vector2(-ENEMY_STATUS_BADGE_W - 4.0, 0)
		_status_label.position = status_offset + Vector2(4.0, 0)
	elif _block_label.visible:
		_block_label.position = status_offset + Vector2(-ENEMY_STATUS_BADGE_W * 0.5, 0)
	elif _status_label.visible:
		_status_label.position = status_offset + Vector2(-ENEMY_STATUS_BADGE_W * 0.5, 0)

func _shake() -> void:
	var t = create_tween()
	for _i in 5:
		t.tween_property(self, "position:x", position.x + randf_range(-6, 6), 0.05)
	t.tween_property(self, "position:x", position.x, 0.05)

func _flash() -> void:
	_flash_intensity = 1.0
	var t = create_tween()
	t.tween_property(self, "_flash_intensity", 0.0, 0.3)
	t.tween_callback(queue_redraw)

func _play_death() -> void:
	var t = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "modulate:a", 0.0, 0.6)
	t.tween_callback(func(): died.emit())

func _process(delta: float) -> void:
	if _is_dead:
		return
	_phase += delta
	_apply_sprite_motion()
	queue_redraw()

func _apply_sprite_motion() -> void:
	if not _sprite:
		return
	if not _uses_sprite_enemy():
		return
	var offset = _get_sprite_offset()
	var texture_size = _sprite.texture.get_size()
	var foot_anchor = Vector2(0, -texture_size.y * _sprite_base_scale.y * 0.5)
	var float_y = sin(_phase * 1.05) * 4.0
	var breath = 1.0 + sin(_phase * 0.80) * 0.012
	var sway = sin(_phase * 0.62) * 0.010
	var flash = _flash_intensity
	_sprite.position = offset + foot_anchor + Vector2(sin(_phase * 0.70) * 1.6, float_y)
	_sprite.scale = _sprite_base_scale * breath
	_sprite.rotation = sway
	_sprite.modulate = Color(1, 1, 1, 1).lerp(Color(1.0, 0.35, 0.24, 1.0), flash * 0.55)
	if _rim_sprite:
		_rim_sprite.position = offset + foot_anchor + Vector2(-4 + sin(_phase * 0.70) * 1.3, float_y - 3)
		_rim_sprite.scale = _sprite.scale * 1.04
		_rim_sprite.rotation = sway
		var aura_col = _get_sprite_aura_color()
		var aura_strength = _get_sprite_aura_strength()
		_rim_sprite.modulate = Color(aura_col.r, aura_col.g, aura_col.b, aura_strength + sin(_phase * 1.4) * 0.025)
	if _sprite_shadow:
		_sprite_shadow.position = offset
		var shadow_scale: Vector2 = enemy_data.get("shadow_scale", Vector2(1.18, 1.0))
		_sprite_shadow.scale = Vector2(shadow_scale.x + sin(_phase * 1.05) * 0.030, shadow_scale.y)
		_sprite_shadow.modulate.a = 0.62 - sin(_phase * 1.05) * 0.05

func _draw() -> void:
	if enemy_data.is_empty() or _is_dead:
		return

	var glow_col: Color  = enemy_data.get("glow_color", Color(0.5, 0.1, 0.8))
	var eye_col: Color   = enemy_data.get("eye_color", Color(0.9, 0.1, 0.1))
	var size_mult: float = enemy_data.get("size_mult", 1.0)
	var shape: String    = enemy_data.get("shape", "wisp")
	var is_boss: bool    = enemy_data.get("is_boss", false)

	var float_y = sin(_phase * 1.4) * 5.0 * size_mult
	var breath  = 1.0 + sin(_phase * 0.9) * 0.015

	# Flash overlay color
	var flash_col = glow_col.lerp(Color(1, 0.3, 0.3), _flash_intensity)

	_draw_silhouette(shape, size_mult, float_y, breath, flash_col, glow_col, eye_col, is_boss)

func _draw_silhouette(shape: String, sm: float, fy: float, br: float,
		flash_col: Color, glow_col: Color, eye_col: Color, is_boss: bool) -> void:

	var glow_alpha_base = 0.115 if is_boss else 0.085

	match shape:
		"holy_soldier", "sprite_enemy":
			_draw_sprite_enemy_aura(sm, fy, br, glow_col, glow_alpha_base)
		"wisp":
			_draw_wisp(sm, fy, br, flash_col, glow_col, eye_col, glow_alpha_base)
		"knight":
			_draw_knight(sm, fy, br, flash_col, glow_col, eye_col, glow_alpha_base)
		"monarch":
			_draw_monarch(sm, fy, br, flash_col, glow_col, eye_col, glow_alpha_base)
		_:
			_draw_wisp(sm, fy, br, flash_col, glow_col, eye_col, glow_alpha_base)

func _draw_sprite_enemy_aura(sm: float, fy: float, br: float, glow_col: Color, ga: float) -> void:
	var offset = _get_sprite_offset()
	var visual_scale = _get_sprite_scale()
	var aura_col = _get_sprite_aura_color()
	var aura_strength = _get_sprite_aura_strength()
	var texture_h = 458.0
	if _sprite and _sprite.texture:
		texture_h = _sprite.texture.get_size().y
	var center = offset + Vector2(0, -texture_h * visual_scale * 0.48 + fy)
	var floor_y = offset.y
	draw_line(center + Vector2(-54 * sm, -66 * sm), center + Vector2(-46 * sm, 78 * sm), Color(aura_col, aura_strength * 1.20), 2.1 * sm)
	draw_line(center + Vector2(50 * sm, -64 * sm), center + Vector2(43 * sm, 74 * sm), Color(0.84, 0.92, 1.0, aura_strength * 0.85), 1.7 * sm)
	draw_line(Vector2(-74 * sm, floor_y + 4 * sm), Vector2(74 * sm, floor_y - 2 * sm), Color(aura_col, aura_strength * 0.72), 9.0 * sm)
	for i in 7:
		var seed = float(i)
		var sparkle_x = sin(_phase * 0.65 + seed * 1.7) * 54.0 * sm
		var sparkle_y = -118.0 * sm + fmod(seed * 31.0 + _phase * (7.0 + seed), 150.0) * sm
		var sparkle_alpha = 0.05 + 0.035 * sin(_phase * 1.8 + seed)
		var p = offset + Vector2(sparkle_x, sparkle_y)
		draw_line(p + Vector2(-2 * sm, 0), p + Vector2(2 * sm, 0), Color(aura_col, sparkle_alpha), 1.0 * sm)
		draw_line(p + Vector2(0, -2 * sm), p + Vector2(0, 2 * sm), Color(1.0, 0.98, 0.82, sparkle_alpha * 0.8), 1.0 * sm)

func _draw_wisp(sm: float, fy: float, br: float,
		flash_col: Color, glow_col: Color, eye_col: Color, ga: float) -> void:
	var center = Vector2(0, fy)
	var body = SILHOUETTE_COLOR.lerp(flash_col, _flash_intensity * 0.45)
	var unrest = sin(_phase * 3.1) * 4.0 * sm
	var sway = sin(_phase * 1.7) * 6.0 * sm
	var flicker = 0.78 + sin(_phase * 7.0) * 0.14 + sin(_phase * 11.0) * 0.08

	for i in 3:
		var y = (-18 + i * 28) * sm
		draw_line(center + Vector2(-58 * sm + sway * 0.35, y), center + Vector2(58 * sm + sway * 0.15, y + 10 * sm), Color(glow_col, 0.035), 8.0 * sm)

	# Main smoky mantle, intentionally asymmetrical and ragged.
	var mantle = PackedVector2Array([
		Vector2(-12, -90), Vector2(-34, -78), Vector2(-50, -52), Vector2(-60, -22),
		Vector2(-45, 0), Vector2(-60, 24), Vector2(-37, 30), Vector2(-50, 58),
		Vector2(-21, 47), Vector2(-19, 86), Vector2(0, 55), Vector2(16, 91),
		Vector2(22, 49), Vector2(47, 68), Vector2(36, 32), Vector2(62, 18),
		Vector2(42, -7), Vector2(49, -42), Vector2(30, -68), Vector2(11, -88),
	])
	var mantle_xform = PackedVector2Array()
	for p in mantle:
		var wave = sin(_phase * 2.4 + p.y * 0.045) * 3.5
		mantle_xform.append(center + Vector2((p.x + wave) * sm * br, p.y * sm))
	draw_colored_polygon(mantle_xform, Color(body, 0.96))
	draw_line(center + Vector2(-43 * sm + sway * 0.15, -62 * sm), center + Vector2(-32 * sm, 54 * sm), Color(0.48, 0.56, 0.76, 0.13), 1.8 * sm)
	draw_line(center + Vector2(40 * sm + sway * 0.10, -56 * sm), center + Vector2(28 * sm, 48 * sm), Color(0.48, 0.56, 0.76, 0.10), 1.5 * sm)

	# Layered translucent smoke cuts give it a ghost-like sprite silhouette.
	var left_stream = PackedVector2Array([
		Vector2(-34, -26), Vector2(-76, 0), Vector2(-68, 28), Vector2(-88, 62),
		Vector2(-48, 43), Vector2(-37, 18),
	])
	var right_stream = PackedVector2Array([
		Vector2(28, -17), Vector2(80, -4), Vector2(66, 25), Vector2(92, 45),
		Vector2(51, 48), Vector2(38, 19),
	])
	_draw_art_poly(left_stream, center + Vector2(unrest * 0.3, 0), sm, Color(body, 0.48))
	_draw_art_poly(right_stream, center + Vector2(-unrest * 0.2, 0), sm, Color(body, 0.44))
	for i in 4:
		var x = (-42 + i * 28) * sm + sin(_phase * 2.0 + i) * 5.0 * sm
		var top = center + Vector2(x, (22 + i * 6) * sm)
		var bottom = center + Vector2(x + (-1 if i % 2 == 0 else 1) * 16 * sm, (88 + i * 7) * sm)
		draw_line(top, bottom, Color(body, 0.30), 5.0 * sm)

	_draw_eye_slit(center + Vector2(-16 * sm, -32 * sm), 10 * sm * flicker, 4 * sm, eye_col)
	_draw_eye_slit(center + Vector2(16 * sm, -32 * sm), 10 * sm * flicker, 4 * sm, eye_col)

func _draw_knight(sm: float, fy: float, br: float,
		flash_col: Color, glow_col: Color, eye_col: Color, ga: float) -> void:
	var center = Vector2(0, fy)
	var body = SILHOUETTE_COLOR.lerp(flash_col, _flash_intensity * 0.45)
	var idle_sway = sin(_phase * 1.15) * 2.0 * sm
	var flicker = 0.85 + sin(_phase * 5.2) * 0.10

	draw_line(center + Vector2(-52 * sm + idle_sway, -78 * sm), center + Vector2(-46 * sm, 68 * sm), Color(0.48, 0.56, 0.78, 0.15), 2.0 * sm)
	draw_line(center + Vector2(55 * sm + idle_sway, -76 * sm), center + Vector2(62 * sm, 72 * sm), Color(0.48, 0.56, 0.78, 0.18), 2.0 * sm)

	# Heavy angular armor silhouette.
	_draw_art_poly([
		Vector2(-18, -92), Vector2(18, -92), Vector2(30, -72), Vector2(24, -47),
		Vector2(38, -18), Vector2(25, 62), Vector2(8, 78), Vector2(0, 38),
		Vector2(-9, 80), Vector2(-29, 63), Vector2(-38, -18), Vector2(-24, -48),
		Vector2(-30, -72),
	], center + Vector2(idle_sway, 0), sm, body)
	_draw_art_poly([
		Vector2(-21, -98), Vector2(0, -119), Vector2(22, -98), Vector2(18, -78),
		Vector2(7, -68), Vector2(0, -83), Vector2(-8, -68), Vector2(-18, -78),
	], center + Vector2(idle_sway * 0.7, 2 * sm * (br - 1.0)), sm, body)
	_draw_art_poly([
		Vector2(-28, -72), Vector2(-76, -57), Vector2(-96, -36), Vector2(-57, -26),
		Vector2(-30, -38),
	], center + Vector2(idle_sway * 0.4, 0), sm, body)
	_draw_art_poly([
		Vector2(28, -72), Vector2(82, -61), Vector2(103, -38), Vector2(58, -23),
		Vector2(30, -38),
	], center + Vector2(idle_sway * 0.4, 0), sm, body)
	_draw_art_poly([
		Vector2(53, -19), Vector2(78, 9), Vector2(91, 67), Vector2(72, 73),
		Vector2(55, 21),
	], center, sm, Color(body, 0.88))
	_draw_art_poly([
		Vector2(-44, -22), Vector2(-58, 23), Vector2(-51, 71), Vector2(-70, 70),
		Vector2(-82, 22), Vector2(-67, -20),
	], center, sm, Color(body, 0.80))
	draw_line(center + Vector2(48 * sm, -13 * sm), center + Vector2(104 * sm, 74 * sm), Color(body, 0.82), 7.5 * sm)
	draw_line(center + Vector2(106 * sm, 70 * sm), center + Vector2(126 * sm, 100 * sm), Color(body, 0.55), 3.0 * sm)
	draw_line(center + Vector2(-24 * sm, -42 * sm), center + Vector2(26 * sm, -42 * sm), Color(glow_col, 0.20), 2.0 * sm)
	draw_line(center + Vector2(-16 * sm, -16 * sm), center + Vector2(18 * sm, -16 * sm), Color(glow_col, 0.16), 1.6 * sm)
	draw_line(center + Vector2(-30 * sm, 62 * sm), center + Vector2(28 * sm, 60 * sm), Color(0.62, 0.60, 0.45, 0.10), 1.4 * sm)

	_draw_eye_slit(center + Vector2((-8 + idle_sway * 0.25) * sm, -89 * sm), 8 * sm * flicker, 3 * sm, eye_col)
	_draw_eye_slit(center + Vector2((8 + idle_sway * 0.25) * sm, -89 * sm), 8 * sm * flicker, 3 * sm, eye_col)

func _draw_monarch(sm: float, fy: float, br: float,
		flash_col: Color, glow_col: Color, eye_col: Color, ga: float) -> void:
	var center = Vector2(0, fy)
	var body = SILHOUETTE_COLOR.lerp(flash_col, _flash_intensity * 0.45)
	var h = 150.0 * sm
	var aura_shift = sin(_phase * 0.8) * 5.0 * sm
	var heavy = sin(_phase * 0.55) * 2.4 * sm
	var flicker = 0.88 + sin(_phase * 4.0) * 0.08

	# Slow monarch pressure without a circular backdrop.
	for i in 6:
		var angle = _phase * 0.35 + i * TAU / 5.0
		var p1 = center + Vector2(cos(angle) * 64 * sm, -26 * sm + sin(angle) * 40 * sm)
		var p2 = center + Vector2(cos(angle + 0.55) * 92 * sm, -30 * sm + sin(angle + 0.55) * 56 * sm)
		draw_line(p1, p2, Color(glow_col, 0.055), 3.0 * sm)
	draw_line(center + Vector2(-122 * sm, 86 * sm + heavy), center + Vector2(122 * sm, 70 * sm - heavy), Color(glow_col, 0.07), 8.0 * sm)

	# Tall monarch robe with torn cape wings.
	_draw_art_poly([
		Vector2(-18, -122), Vector2(0, -143), Vector2(18, -122), Vector2(31, -84),
		Vector2(48, -42), Vector2(37, 76), Vector2(18, 118), Vector2(5, 70),
		Vector2(0, 126), Vector2(-8, 72), Vector2(-23, 119), Vector2(-40, 76),
		Vector2(-48, -42), Vector2(-31, -84),
	], center + Vector2(0, heavy), sm, body)
	_draw_art_poly([
		Vector2(-37, -54), Vector2(-92, -24), Vector2(-132, 32), Vector2(-96, 27),
		Vector2(-128, 92), Vector2(-61, 70), Vector2(-34, 15),
	], center + Vector2(-aura_shift, heavy * 0.5), sm, Color(body, 0.82))
	_draw_art_poly([
		Vector2(37, -54), Vector2(96, -20), Vector2(137, 31), Vector2(96, 28),
		Vector2(126, 92), Vector2(59, 70), Vector2(34, 15),
	], center + Vector2(aura_shift, heavy * 0.5), sm, Color(body, 0.82))
	_draw_art_poly([
		Vector2(-25, -127), Vector2(-49, -151), Vector2(-43, -111), Vector2(-70, -122),
		Vector2(-38, -91), Vector2(0, -80), Vector2(38, -91), Vector2(70, -122),
		Vector2(43, -111), Vector2(49, -151), Vector2(25, -127), Vector2(0, -173),
	], center + Vector2(0, heavy + 2 * sm * (br - 1.0)), sm, body)
	draw_line(center + Vector2(-44 * sm, -36 * sm), center + Vector2(-82 * sm, 86 * sm), Color(body, 0.70), 8.0 * sm)
	draw_line(center + Vector2(44 * sm, -36 * sm), center + Vector2(82 * sm, 86 * sm), Color(body, 0.70), 8.0 * sm)
	draw_line(center + Vector2(-20 * sm, -38 * sm), center + Vector2(0, 98 * sm), Color(glow_col, 0.18), 2.4 * sm)
	draw_line(center + Vector2(20 * sm, -38 * sm), center + Vector2(0, 98 * sm), Color(glow_col, 0.18), 2.4 * sm)
	draw_line(center + Vector2(-56 * sm, -90 * sm + heavy), center + Vector2(-72 * sm, 78 * sm + heavy), Color(0.58, 0.62, 0.82, 0.13), 2.2 * sm)
	draw_line(center + Vector2(58 * sm, -88 * sm + heavy), center + Vector2(74 * sm, 74 * sm + heavy), Color(0.58, 0.62, 0.82, 0.15), 2.2 * sm)

	_draw_eye_slit(center + Vector2(-10 * sm, (-119 * sm) + heavy), 10 * sm * flicker, 4 * sm, eye_col)
	_draw_eye_slit(center + Vector2(10 * sm, (-119 * sm) + heavy), 10 * sm * flicker, 4 * sm, eye_col)

func _draw_art_poly(points, offset: Vector2, scale: float, color: Color) -> void:
	var poly = PackedVector2Array()
	for p in points:
		poly.append(offset + Vector2(p.x * scale, p.y * scale))
	draw_colored_polygon(poly, color)

func _draw_eye_slit(pos: Vector2, w: float, h: float, color: Color) -> void:
	var slit = PackedVector2Array([
		pos + Vector2(-w, -h * 0.25),
		pos + Vector2(-w * 0.25, -h),
		pos + Vector2(w, -h * 0.15),
		pos + Vector2(w * 0.25, h),
	])
	draw_colored_polygon(slit, color)
	draw_circle(pos, w * 0.85, Color(color, 0.18))


class _EnemySpriteShadow extends Node2D:
	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(2.4, 0.38))
		draw_circle(Vector2.ZERO, 24, Color(0, 0, 0, 0.34))
		draw_circle(Vector2.ZERO, 15, Color(0.22, 0.18, 0.08, 0.12))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
