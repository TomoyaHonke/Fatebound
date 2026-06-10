extends Control

# ── Scene references ──────────────────────────────────────────────────────────
const ENEMY_SCENE  = "res://scenes/ui/EnemyNode.tscn"
const CARD_SCENE   = "res://scenes/ui/CardNode.tscn"
const REWARD_SCENE = "res://scenes/ui/RewardScreen.tscn"
const END_SCENE    = "res://scenes/ui/EndScreen.tscn"
const MAP_SCENE    = "res://scenes/MapScreen.tscn"
const DECK_VIEWER_SCENE        = "res://scenes/ui/DeckViewer.tscn"
const RELIC_VIEWER_SCENE       = "res://scenes/ui/RelicViewer.tscn"
const RELIC_REWARD_SCENE       = "res://scenes/ui/RelicRewardScreen.tscn"
const BOSS_RELIC_REWARD_SCENE  = "res://scenes/ui/BossRelicRewardScreen.tscn"

# ── Colors ────────────────────────────────────────────────────────────────────
const C_BG           = Color(0.035, 0.032, 0.080)
const C_BG_BOSS      = Color(0.065, 0.018, 0.070)
const C_PANEL        = Color(0.065, 0.055, 0.120, 0.94)
const C_TEXT         = Color(0.88, 0.82, 1.00)
const C_HP_FILL      = Color(0.55, 0.12, 0.12)
const C_BLOCK_FILL   = Color(0.22, 0.38, 0.70)
const C_ENERGY_ON    = Color(0.55, 0.15, 0.90)
const C_ENERGY_OFF   = Color(0.18, 0.14, 0.28)
const C_BTN_NORMAL   = Color(0.18, 0.06, 0.32)
const C_BTN_HOVER    = Color(0.28, 0.10, 0.50)
const C_GOLD         = Color(0.90, 0.78, 0.25)
const STATUS_TOOLTIP_ORDER = ["vulnerable", "weak", "poison", "strength"]
const STATUS_DESCRIPTIONS = {
	"vulnerable": {"name": "脆弱", "description": "受けるダメージが増加する。", "value_label": "残り"},
	"weak": {"name": "脱力", "description": "与えるダメージが低下する。", "value_label": "残り"},
	"poison": {"name": "毒", "description": "ターン終了時にHPを失う。", "value_label": "残り"},
	"strength": {"name": "筋力", "description": "攻撃カードのダメージが増加する。", "value_label": "値"}
}

# ── Layout constants ──────────────────────────────────────────────────────────
const HAND_Y     = 500.0
const CARD_W     = 130.0
const CARD_H     = 190.0
const CARD_GAP   = 18.0
const CARD_GAP_MIN = 8.0
const HAND_MAX   = 10
const DRAW_COUNT = 5
const HAND_AREA_LEFT = 190.0
const HAND_AREA_RIGHT = 1012.0
const HAND_AREA_MARGIN = 16.0
const BUTTON_AREA_W = 220.0
const BUTTON_CENTER = Vector2(1168, 598)
const BUTTON_SIZE = Vector2(196, 72)
const BOTTOM_UI_TOP_Y = 488.0
const PLAYER_STATUS_OFFSET = Vector2(12, 82)
const ENERGY_PANEL_POS = Vector2(18, 534)
const ENERGY_PANEL_SIZE = Vector2(168, 86)
const ENERGY_ORB_SIZE = Vector2(64, 64)
const ENEMY_INFO_AREA_POS = Vector2(458, 34)
const ENEMY_INFO_AREA_SIZE = Vector2(724, 70)
const ENEMY_INFO_CARD_SIZE = Vector2(260, 56)

# ── State ─────────────────────────────────────────────────────────────────────
var _enemy_data:   Dictionary = {}
var _enemy_node:   Node = null
var _enemy_hp:     int = 0
var _enemy_max_hp: int = 0
var _enemy_block:  int = 0
var _enemy_turn_idx: int = 0
var _enemy_next_action: Dictionary = {}
var _player_turn:  bool = true
var _busy:         bool = false  # while animating / enemy acting
var _battle_turn:  int = 0
var _was_elite:    bool = false

# ── UI nodes ─────────────────────────────────────────────────────────────────
var _bg:              ColorRect
var _battle_layer:    Control
var _ambient_bg:      Node2D
var _player_silhouette: Node2D
var _hand_container:  Control
var _card_nodes:      Array = []
var _end_turn_btn:    Button
var _hp_bar:          ProgressBar
var _hp_label:        Label
var _block_label:     Label
var _player_status_label: Label
var _player_hud_panel: Panel
var _energy_container: Control
var _energy_orb:       Control
var _energy_label:     Label
var _log_label:       Label
var _reward_screen:   Control
var _end_screen:      Control
var _damage_label:    Label  # floating damage number
var _deck_viewer:     Control
var _relic_viewer:    Control
var _relic_reward:    Control
var _boss_relic_reward: Control
var _status_tooltip_panel: Panel
var _status_tooltip_label: Label
var _enemy_info_area: HBoxContainer
var _enemy_info_cards: Array = []

func _ready() -> void:
	_apply_screen_scale()
	_build_ui()
	_start_battle()
	_build_deck_viewer()
	_build_relic_viewer()
	_build_relic_reward()
	_build_boss_relic_reward()

func _apply_screen_scale() -> void:
	var scaler = get_node_or_null("/root/ScreenScale")
	if scaler and scaler.has_method("apply"):
		scaler.apply(self)

# ═══════════════════════════════════════════════════════════════════════════════
#  UI Construction
# ═══════════════════════════════════════════════════════════════════════════════

func _build_ui() -> void:
	_battle_layer = Control.new()
	_battle_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_battle_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_battle_layer)

	# Background
	_bg = ColorRect.new()
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.color = C_BG
	_battle_layer.add_child(_bg)

	# Ambient background Node2D (drawn procedurally)
	_ambient_bg = _AmbientBG.new()
	_battle_layer.add_child(_ambient_bg)

	# Player silhouette (left side)
	_player_silhouette = _PlayerSilhouette.new()
	_player_silhouette.position = Vector2(320, 314)
	_player_silhouette.scale = Vector2(1.18, 1.18)
	_battle_layer.add_child(_player_silhouette)

	# Hand container
	_hand_container = Control.new()
	_hand_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hand_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_battle_layer.add_child(_hand_container)

	# HUD panel (top-left: player stats)
	_build_player_hud()

	# Enemy info cards (top-center, kept away from enemy portraits)
	_build_enemy_info_area()

	# Energy panel near the hand/action area
	_build_energy_panel()

	# Log label (bottom-left)
	_log_label = Label.new()
	_log_label.position = Vector2(28, 448)
	_log_label.size = Vector2(560, 28)
	_log_label.add_theme_font_size_override("font_size", 15)
	_log_label.add_theme_color_override("font_color", Color(0.82, 0.78, 0.92))
	_log_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_log_label.add_theme_constant_override("shadow_offset_x", 1)
	_log_label.add_theme_constant_override("shadow_offset_y", 1)
	_battle_layer.add_child(_log_label)

	# End Turn button
	_end_turn_btn = _make_button("ターン終了", BUTTON_CENTER, BUTTON_SIZE)
	_end_turn_btn.pressed.connect(_on_end_turn)
	_battle_layer.add_child(_end_turn_btn)

	# Ornate corner frame around the button
	var btn_orn = _ButtonOrnament.new()
	var btn_top_left = BUTTON_CENTER - BUTTON_SIZE / 2.0
	btn_orn.position = btn_top_left - Vector2(10, 10)
	btn_orn.btn_size = BUTTON_SIZE + Vector2(20, 20)
	btn_orn.size = btn_orn.btn_size
	_battle_layer.add_child(btn_orn)

	# Floating damage label
	_damage_label = Label.new()
	_damage_label.add_theme_font_size_override("font_size", 28)
	_damage_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.25))
	_damage_label.modulate.a = 0.0
	_damage_label.size = Vector2(120, 40)
	_battle_layer.add_child(_damage_label)

	var deck_btn = _make_button("デッキ", Vector2(1212, 34), Vector2(104, 40))
	deck_btn.add_theme_font_size_override("font_size", 16)
	deck_btn.pressed.connect(_on_deck_pressed)
	_battle_layer.add_child(deck_btn)

	var relic_btn = _make_button("レリック", Vector2(1212, 84), Vector2(104, 40))
	relic_btn.add_theme_font_size_override("font_size", 16)
	relic_btn.pressed.connect(_on_relic_pressed)
	_battle_layer.add_child(relic_btn)

	# Reward screen (hidden)
	var reward_res = load(REWARD_SCENE)
	_reward_screen = reward_res.instantiate()
	_reward_screen.visible = false
	_reward_screen.reward_chosen.connect(_on_reward_chosen)
	add_child(_reward_screen)

	# End screen (hidden)
	var end_res = load(END_SCENE)
	_end_screen = end_res.instantiate()
	_end_screen.visible = false
	add_child(_end_screen)

func _build_deck_viewer() -> void:
	var viewer_res = load(DECK_VIEWER_SCENE)
	_deck_viewer = viewer_res.instantiate()
	add_child(_deck_viewer)

func _build_relic_viewer() -> void:
	var res = load(RELIC_VIEWER_SCENE)
	_relic_viewer = res.instantiate()
	add_child(_relic_viewer)

func _build_relic_reward() -> void:
	var res = load(RELIC_REWARD_SCENE)
	_relic_reward = res.instantiate()
	_relic_reward.visible = false
	_relic_reward.reward_accepted.connect(_on_relic_reward_accepted)
	add_child(_relic_reward)

func _build_boss_relic_reward() -> void:
	var res = load(BOSS_RELIC_REWARD_SCENE)
	_boss_relic_reward = res.instantiate()
	_boss_relic_reward.visible = false
	_boss_relic_reward.reward_chosen.connect(_on_boss_relic_reward_chosen)
	add_child(_boss_relic_reward)

func _build_player_hud() -> void:
	_player_hud_panel = Panel.new()
	_player_hud_panel.position = Vector2(14, 14)
	_player_hud_panel.size = Vector2(222, 108)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.038, 0.034, 0.070, 0.90)
	panel_style.border_color = Color(0.34, 0.26, 0.50, 0.48)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8)
	_player_hud_panel.add_theme_stylebox_override("panel", panel_style)
	_player_hud_panel.clip_contents = true
	add_child(_player_hud_panel)

	# Header strip behind player name
	var header_strip = Panel.new()
	header_strip.position = Vector2(0, 0)
	header_strip.size = Vector2(222, 26)
	var hs = StyleBoxFlat.new()
	hs.bg_color = Color(0.050, 0.042, 0.082, 0.80)
	hs.set_border_width_all(0)
	hs.set_corner_radius_all(0)
	header_strip.add_theme_stylebox_override("panel", hs)
	_player_hud_panel.add_child(header_strip)

	# Player name label
	var name_label = Label.new()
	name_label.text = "プレイヤー"
	name_label.position = Vector2(10, 4)
	name_label.size = Vector2(202, 20)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color(0.64, 0.58, 0.76))
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.70))
	name_label.add_theme_constant_override("shadow_offset_x", 1)
	name_label.add_theme_constant_override("shadow_offset_y", 1)
	_player_hud_panel.add_child(name_label)

	# HP bar
	_hp_bar = ProgressBar.new()
	_hp_bar.min_value = 0
	_hp_bar.max_value = GameState.player_max_hp
	_hp_bar.value = GameState.player_hp
	_hp_bar.show_percentage = false
	_hp_bar.position = Vector2(10, 30)
	_hp_bar.size = Vector2(202, 16)
	var fill_s = StyleBoxFlat.new()
	fill_s.bg_color = C_HP_FILL
	fill_s.set_corner_radius_all(4)
	_hp_bar.add_theme_stylebox_override("fill", fill_s)
	var bg_s = StyleBoxFlat.new()
	bg_s.bg_color = Color(0.07, 0.05, 0.12)
	bg_s.set_corner_radius_all(4)
	_hp_bar.add_theme_stylebox_override("background", bg_s)
	_player_hud_panel.add_child(_hp_bar)

	# HP label
	_hp_label = Label.new()
	_hp_label.position = Vector2(10, 50)
	_hp_label.size = Vector2(202, 18)
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.add_theme_font_size_override("font_size", 14)
	_hp_label.add_theme_color_override("font_color", Color(0.90, 0.68, 0.68))
	_player_hud_panel.add_child(_hp_label)

	# Block label
	_block_label = Label.new()
	_block_label.position = Vector2(10, 70)
	_block_label.size = Vector2(96, 18)
	_block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_block_label.add_theme_font_size_override("font_size", 13)
	_block_label.add_theme_color_override("font_color", Color(0.45, 0.65, 1.0))
	_player_hud_panel.add_child(_block_label)

	# Player status badges
	_player_status_label = Label.new()
	_player_status_label.position = PLAYER_STATUS_OFFSET
	_player_status_label.size = Vector2(202, 18)
	_player_status_label.add_theme_font_size_override("font_size", 12)
	_player_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_player_status_label.visible = false
	_player_status_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_player_status_label.mouse_entered.connect(_on_player_status_mouse_entered)
	_player_status_label.mouse_exited.connect(_on_player_status_mouse_exited)
	_style_badge(_player_status_label, Color(0.9, 0.45, 0.25))
	_player_hud_panel.add_child(_player_status_label)

func _build_enemy_info_area() -> void:
	_enemy_info_area = HBoxContainer.new()
	_enemy_info_area.name = "EnemyInfoCards"
	_enemy_info_area.position = ENEMY_INFO_AREA_POS
	_enemy_info_area.size = ENEMY_INFO_AREA_SIZE
	_enemy_info_area.alignment = BoxContainer.ALIGNMENT_CENTER
	_enemy_info_area.add_theme_constant_override("separation", 12)
	_enemy_info_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_enemy_info_area.z_index = 80
	_battle_layer.add_child(_enemy_info_area)

func _set_enemy_info_nodes(enemy_nodes: Array) -> void:
	if not _enemy_info_area:
		return
	for card in _enemy_info_cards:
		if is_instance_valid(card):
			card.queue_free()
	_enemy_info_cards = []
	for enemy_node in enemy_nodes:
		if not is_instance_valid(enemy_node):
			continue
		var card = _EnemyInfoCard.new()
		card.custom_minimum_size = ENEMY_INFO_CARD_SIZE
		card.size = ENEMY_INFO_CARD_SIZE
		card.setup(enemy_node)
		_enemy_info_area.add_child(card)
		_enemy_info_cards.append(card)

func _build_energy_panel() -> void:
	var panel = Panel.new()
	panel.position = ENERGY_PANEL_POS
	panel.size = ENERGY_PANEL_SIZE
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.026, 0.020, 0.056, 0.92)
	panel_style.border_color = Color(0.38, 0.26, 0.58, 0.50)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(9)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)
	_energy_container = panel

	_energy_orb = _EnergyOrb.new()
	_energy_orb.position = Vector2((ENERGY_PANEL_SIZE.x - ENERGY_ORB_SIZE.x) / 2.0, 28.0)
	_energy_orb.size = ENERGY_ORB_SIZE
	_energy_orb.custom_minimum_size = ENERGY_ORB_SIZE
	panel.add_child(_energy_orb)

	var title_label = Label.new()
	title_label.text = "エナジー"
	title_label.position = Vector2(0, 3)
	title_label.size = Vector2(ENERGY_PANEL_SIZE.x, 22)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", Color(0.82, 0.76, 0.96))
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.82))
	title_label.add_theme_constant_override("shadow_offset_x", 1)
	title_label.add_theme_constant_override("shadow_offset_y", 1)
	panel.add_child(title_label)

	_energy_label = Label.new()
	_energy_label.position = _energy_orb.position
	_energy_label.size = ENERGY_ORB_SIZE
	_energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_energy_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_energy_label.add_theme_font_size_override("font_size", 21)
	_energy_label.add_theme_color_override("font_color", Color(1.0, 0.96, 1.0))
	_energy_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.82))
	_energy_label.add_theme_constant_override("shadow_offset_x", 2)
	_energy_label.add_theme_constant_override("shadow_offset_y", 2)
	panel.add_child(_energy_label)

	_rebuild_energy_dots()

func _rebuild_energy_dots() -> void:
	if not _energy_container:
		return
	var max_e = GameState.player_max_energy
	var cur_e  = GameState.player_energy
	if _energy_label:
		_energy_label.text = "%d/%d" % [cur_e, max_e]
		_energy_label.add_theme_font_size_override("font_size", 18 if _energy_label.text.length() >= 5 else 21)

func _update_hud() -> void:
	_hp_bar.value = GameState.player_hp
	_hp_label.text = "%d / %d HP" % [GameState.player_hp, GameState.player_max_hp]

	if GameState.player_block > 0:
		_block_label.text = "盾 %d" % GameState.player_block
	else:
		_block_label.text = ""

	_update_player_status_badges()

	_rebuild_energy_dots()
	_update_card_playability()

func _update_player_status_badges() -> void:
	if not _player_status_label:
		return
	var parts = _status_badge_parts(GameState.player_statuses)
	_player_status_label.text = "  ".join(parts)
	_player_status_label.visible = not parts.is_empty()
	if parts.is_empty():
		_hide_status_tooltip()

func _status_badge_parts(statuses: Dictionary) -> Array:
	var parts: Array = []
	for status_id in STATUS_TOOLTIP_ORDER:
		var value = int(statuses.get(status_id, 0))
		if value > 0:
			var meta = STATUS_DESCRIPTIONS.get(status_id, {})
			parts.append("%s %d" % [meta.get("name", _status_name(status_id)), value])
	for status_id in statuses.keys():
		if STATUS_TOOLTIP_ORDER.has(status_id):
			continue
		var value = int(statuses.get(status_id, 0))
		if value > 0:
			parts.append("%s %d" % [_status_name(status_id), value])
	return parts

func _on_player_status_mouse_entered() -> void:
	if not _player_status_label or not _player_status_label.visible:
		return
	_player_status_label.modulate = Color(1.16, 1.16, 1.16, 1.0)
	_show_status_tooltip(GameState.player_statuses, _player_status_label.global_position + Vector2(0, _player_status_label.size.y + 8))

func _on_player_status_mouse_exited() -> void:
	if _player_status_label:
		_player_status_label.modulate = Color.WHITE
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

func _show_status_tooltip(statuses: Dictionary, anchor_pos: Vector2) -> void:
	var text = _status_tooltip_text(statuses)
	if text.is_empty():
		_hide_status_tooltip()
		return
	_ensure_status_tooltip()
	var active_count = max(1, _active_status_count(statuses))
	var panel_size = Vector2(260, 24 + active_count * 64)
	_status_tooltip_panel.size = panel_size
	_status_tooltip_label.text = text
	_status_tooltip_label.size = panel_size - Vector2(20, 16)
	_status_tooltip_panel.global_position = _clamped_tooltip_position(anchor_pos, panel_size)
	_status_tooltip_panel.visible = true

func _hide_status_tooltip() -> void:
	if _status_tooltip_panel:
		_status_tooltip_panel.visible = false

func _status_tooltip_text(statuses: Dictionary) -> String:
	var chunks: Array = []
	for status_id in STATUS_TOOLTIP_ORDER:
		var value = int(statuses.get(status_id, 0))
		if value <= 0:
			continue
		var meta = STATUS_DESCRIPTIONS.get(status_id, {})
		chunks.append("%s\n%s\n%s %d" % [
			meta.get("name", _status_name(status_id)),
			meta.get("description", "状態異常。"),
			meta.get("value_label", "残り"),
			value
		])
	for status_id in statuses.keys():
		if STATUS_TOOLTIP_ORDER.has(status_id):
			continue
		var value = int(statuses.get(status_id, 0))
		if value > 0:
			chunks.append("%s\n%s\n値 %d" % [_status_name(status_id), "状態異常。", value])
	return "\n\n".join(chunks)

func _active_status_count(statuses: Dictionary) -> int:
	var count = 0
	for status_id in statuses.keys():
		if int(statuses.get(status_id, 0)) > 0:
			count += 1
	return count

func _clamped_tooltip_position(anchor_pos: Vector2, panel_size: Vector2) -> Vector2:
	var viewport_size = get_viewport_rect().size
	var pos = anchor_pos
	pos.x = clampf(pos.x, 8.0, maxf(8.0, viewport_size.x - panel_size.x - 8.0))
	pos.y = clampf(pos.y, 8.0, maxf(8.0, viewport_size.y - panel_size.y - 8.0))
	return pos

func _update_card_playability() -> void:
	_prune_card_nodes()
	for card_node in _card_nodes:
		if not is_instance_valid(card_node):
			continue
		if not card_node.has_method("get_card_data_safe"):
			continue
		var card_data = card_node.get_card_data_safe()
		if card_data.is_empty():
			continue
		var cost = card_data.get("cost", 0)
		var can = cost >= 0 and GameState.player_energy >= cost
		card_node.playable = can
		card_node.queue_redraw()

func _prune_card_nodes() -> void:
	var valid_nodes: Array = []
	for card_node in _card_nodes:
		if is_instance_valid(card_node):
			valid_nodes.append(card_node)
	_card_nodes = valid_nodes

# ═══════════════════════════════════════════════════════════════════════════════
#  Battle Setup
# ═══════════════════════════════════════════════════════════════════════════════

func _start_battle() -> void:
	_battle_layer.visible = true
	_battle_turn = 0
	_enemy_turn_idx = 0
	var enemy_id = GameState.get_active_enemy_id_for_combat()
	_enemy_data = GameState.get_enemy_data(enemy_id)
	var background_key = GameState.get_battle_background_key_for_enemy(enemy_id)
	GameState.set_current_battle_background(background_key)
	if _ambient_bg and _ambient_bg.has_method("set_background_key"):
		_ambient_bg.set_background_key(background_key)
	_enemy_hp = _enemy_data.get("max_hp", 50)
	_enemy_max_hp = _enemy_hp
	_enemy_block = 0

	var is_boss = _enemy_data.get("is_boss", false) or GameState.map_encounter_is_boss
	var node_type = GameState.MAP_NODES.get(GameState.map_current_node_id, {}).get("type", "normal_battle")
	_was_elite = (node_type == "elite_battle")

	# Boss background tint
	if is_boss:
		_bg.color = C_BG_BOSS

	# Spawn enemy
	if _enemy_node:
		_enemy_node.queue_free()
	var enemy_res = load(ENEMY_SCENE)
	_enemy_node = enemy_res.instantiate()
	add_child(_enemy_node)
	_enemy_node.position = Vector2(820, 310)
	_enemy_node.setup(_enemy_data)
	_enemy_node.died.connect(_on_enemy_died)
	_set_enemy_info_nodes([_enemy_node])

	# Reset turn state
	GameState.reset_combat_state()

	# Battle-start relic effects
	var start_block = GameState.get_battle_start_block()
	if start_block > 0:
		GameState.apply_block(start_block)
	if GameState.has_relic("abyss_core"):
		GameState.player_hp = maxi(1, GameState.player_hp - 3)
	if GameState.has_relic("hunter_tracking_eye") and _enemy_node:
		var vuln_amount = 2 + GameState.get_vulnerable_status_bonus()
		_enemy_node.apply_status("vulnerable", vuln_amount)
	if GameState.has_relic("hunter_trapwire") and _enemy_node:
		_enemy_node.apply_status("weak", 1)

	_update_hud()
	_start_player_turn()

	# Entrance animation
	_enemy_node.modulate.a = 0.0
	var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(_enemy_node, "modulate:a", 1.0, 0.7)

func _start_player_turn() -> void:
	_battle_turn += 1
	_player_turn = true
	_busy = false
	_end_turn_btn.disabled = false
	GameState.player_energy = GameState.player_max_energy

	# ターン1以外はブロックをリセット（ターン1は戦闘開始時レリック効果を保持）
	if _battle_turn > 1:
		GameState.player_block = 0

	# Turn-start relic energy bonus
	var energy_bonus = GameState.get_turn_energy_bonus(_battle_turn)
	if energy_bonus > 0:
		GameState.player_energy += energy_bonus

	var draw_count = DRAW_COUNT
	if _battle_turn == 1:
		draw_count += GameState.get_initial_draw_bonus()
	else:
		draw_count = maxi(1, draw_count - GameState.consume_draw_penalty())
	GameState.draw_cards(draw_count)
	_set_next_enemy_intent()
	_refresh_hand()
	_update_hud()
	_log("あなたのターン。カードを%d枚引いた。" % draw_count)
	_flush_combat_damage_events()
	_flush_combat_log_messages()
	if GameState.player_hp <= 0:
		_on_player_died()

func _set_next_enemy_intent() -> void:
	_enemy_next_action = _decide_enemy_next_action()
	if _enemy_next_action.is_empty():
		return
	_enemy_node.set_intent(_enemy_next_action)

# ═══════════════════════════════════════════════════════════════════════════════
#  Card Hand
# ═══════════════════════════════════════════════════════════════════════════════

func _refresh_hand() -> void:
	# Clear old card nodes
	for cn in _card_nodes:
		if is_instance_valid(cn):
			cn.queue_free()
	_card_nodes = []

	var hand = GameState.hand
	var count = hand.size()
	if count == 0:
		return

	var hand_left = HAND_AREA_LEFT + HAND_AREA_MARGIN
	var hand_right = HAND_AREA_RIGHT - HAND_AREA_MARGIN
	var hand_w = hand_right - hand_left
	var card_scale = 1.0
	var gap = CARD_GAP
	var total_w = count * CARD_W + (count - 1) * gap
	if total_w > hand_w and count > 1:
		gap = maxf(CARD_GAP_MIN, (hand_w - count * CARD_W) / float(count - 1))
		total_w = count * CARD_W + (count - 1) * gap
	if total_w > hand_w:
		card_scale = clampf(hand_w / total_w, 0.82, 1.0)
		total_w *= card_scale
		gap *= card_scale
	var scaled_card_w = CARD_W * card_scale
	var start_x = hand_left + (hand_w - total_w) / 2.0
	var card_res = load(CARD_SCENE)

	for i in count:
		var card_data = GameState.get_card(hand[i])
		if card_data.is_empty():
			continue
		card_data = _with_combat_damage_preview(card_data)
		var cn = card_res.instantiate()
		_hand_container.add_child(cn)
		var target_x = start_x + i * (scaled_card_w + gap)
		cn.position = Vector2(target_x, HAND_Y)
		var cost = card_data.get("cost", 0)
		cn.setup(card_data, i, cost >= 0 and GameState.player_energy >= cost)
		cn.set_base_y(HAND_Y)
		cn.set_base_scale(Vector2(card_scale, card_scale))
		cn.card_clicked.connect(_on_card_played)
		_card_nodes.append(cn)
		# Animate in
		cn.modulate.a = 0.0
		cn.position.y = HAND_Y + 30
		var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		t.tween_property(cn, "modulate:a", 1.0, 0.2).set_delay(i * 0.04)
		t.parallel().tween_property(cn, "position:y", HAND_Y, 0.2).set_delay(i * 0.04)

# ═══════════════════════════════════════════════════════════════════════════════
#  Card Play
# ═══════════════════════════════════════════════════════════════════════════════

func _on_card_played(card_index: int) -> void:
	if _busy or not _player_turn:
		return
	if card_index >= GameState.hand.size():
		return

	var card_ref = GameState.hand[card_index]
	var card_data = GameState.get_card(card_ref).duplicate(true)
	if card_data.is_empty():
		return

	var card_node = _get_card_node_at(card_index)
	var cost = card_data.get("cost", 0)
	if cost < 0:
		if card_node:
			card_node.flash_unplayable()
		_log("このカードは使用できない。")
		return
	if GameState.player_energy < cost:
		if card_node:
			card_node.flash_unplayable()
		_log("エナジーが足りない。")
		return

	# Remove the used CardNode from hand tracking before any awaited attack effects.
	_busy = true
	if card_node:
		_card_nodes.erase(card_node)
	GameState.player_energy -= cost
	GameState.hand.remove_at(card_index)
	GameState.discard.append(card_ref)

	# Animate the played card flying toward enemy
	if card_node:
		var t = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		t.tween_property(card_node, "position", Vector2(700, 250), 0.18)
		t.parallel().tween_property(card_node, "modulate:a", 0.0, 0.18)
		t.tween_callback(card_node.queue_free)

	await _apply_effects(card_data)
	if card_data.get("type", "") == "attack" and not GameState.first_attack_used_this_combat:
		GameState.first_attack_used_this_combat = true
	if _player_turn and _enemy_node and _enemy_node.current_hp > 0 and GameState.player_hp > 0:
		_busy = false

func _get_card_node_at(card_index: int):
	if card_index < 0 or card_index >= _card_nodes.size():
		return null
	var card_node = _card_nodes[card_index]
	if not is_instance_valid(card_node):
		return null
	return card_node

func _apply_effects(card_data: Dictionary) -> void:
	var effects = card_data.get("effects", [])
	var card_name = card_data.get("name", "カード")
	_log("使用: " + card_name)

	for effect in effects:
		match effect.get("type", ""):
			"damage":
				var dmg = _calc_player_damage(effect.get("value", 0) + _get_attack_relic_damage_bonus(card_data))
				await _deal_damage_to_enemy_with_effect(dmg)
			"damage_multi":
				var times = effect.get("times", 1)
				for _i in times:
					if not _enemy_node or _enemy_node.current_hp <= 0:
						break
					var dmg = _calc_player_damage(effect.get("value", 0) + _get_attack_relic_damage_bonus(card_data))
					await _deal_damage_to_enemy_with_effect(dmg)
					await get_tree().create_timer(0.12).timeout
			"block":
				var block_bonus = GameState.get_block_bonus()
				var before_block = GameState.player_block
				GameState.apply_block(effect.get("value", 0) + block_bonus)
				if GameState.player_block > before_block:
					_play_player_block_effect()
				if block_bonus > 0:
					_log("レリック効果でブロック+%d。" % block_bonus)
			"heal":
				GameState.heal(effect.get("value", 0))
			"draw":
				GameState.draw_cards(effect.get("value", 1))
				_flush_combat_damage_events()
				_flush_combat_log_messages()
			"gain_energy":
				GameState.player_energy += effect.get("value", 1)
			"lose_hp":
				var amount = effect.get("value", 0)
				var min_hp = effect.get("minimum_hp", 1)
				if amount > 0:
					var actual = mini(amount, maxi(0, GameState.player_hp - min_hp))
					GameState.player_hp = maxi(min_hp, GameState.player_hp - amount)
					_play_player_damage_feedback(actual)
					var block_bonus = GameState.get_hp_loss_block_bonus()
					if actual > 0 and block_bonus > 0:
						GameState.apply_block(block_bonus)
						_log("契約の焼印でブロック+%d。" % block_bonus)
			"conditional_damage":
				var dmg = effect.get("value", 0)
				if effect.get("condition", "") == "enemy_half_hp" and _enemy_node and _enemy_node.current_hp <= int(_enemy_node.max_hp / 2):
					dmg = effect.get("bonus_value", dmg)
				await _deal_damage_to_enemy_with_effect(_calc_player_damage(dmg + _get_attack_relic_damage_bonus(card_data)))
			"vulnerable_bonus_damage":
				if _enemy_node and _enemy_node.statuses.get("vulnerable", 0) > 0:
					await _deal_damage_to_enemy_with_effect(_calc_player_damage(effect.get("value", 0) + _get_attack_relic_damage_bonus(card_data)))
			"apply_status":
				var target = effect.get("target", "enemy")
				var status = effect.get("status", "")
				var amount = effect.get("amount", 1)
				if target == "enemy":
					if status == "vulnerable":
						amount += GameState.get_vulnerable_status_bonus()
					_enemy_node.apply_status(status, amount)
					_log("敵に%sを%d付与。" % [_status_name(status), amount])
				else:
					GameState.apply_status(status, amount)

	_update_hud()
	_refresh_hand()
	if GameState.player_hp <= 0:
		_on_player_died()

func _get_attack_relic_damage_bonus(card_data: Dictionary) -> int:
	if not _enemy_node:
		return 0
	var card_type = card_data.get("type", "")
	var bonus = GameState.get_attack_damage_bonus(card_type) + GameState.get_enemy_half_hp_attack_damage_bonus(card_type, _enemy_node.current_hp, _enemy_node.max_hp)
	if card_type == "attack" and GameState.has_relic("former_hunter_bow") and not GameState.first_attack_used_this_combat:
		bonus += 3
	return bonus

func _with_combat_damage_preview(card_data: Dictionary) -> Dictionary:
	var preview = card_data.duplicate(true)
	var lines = _build_combat_description_segments(card_data)
	if not lines.is_empty():
		preview["combat_description_segments"] = lines
	return preview

func _build_combat_description_segments(card_data: Dictionary) -> Array:
	var lines: Array = []
	for effect in card_data.get("effects", []):
		match effect.get("type", ""):
			"damage":
				lines.append(_damage_line(["敵に", "ダメージ"], effect.get("value", 0), _preview_damage(card_data, effect.get("value", 0))))
			"damage_multi":
				var times = effect.get("times", 1)
				lines.append(_damage_line(["敵に", "ダメージx%d" % times], effect.get("value", 0), _preview_damage(card_data, effect.get("value", 0))))
			"conditional_damage":
				var base = effect.get("value", 0)
				var bonus = effect.get("bonus_value", base)
				lines.append(_damage_line(["半分以下:", "ダメージ"], bonus, _preview_damage(card_data, bonus)))
				lines.append(_damage_line(["通常:", "ダメージ"], base, _preview_damage(card_data, base)))
			"vulnerable_bonus_damage":
				var current = effect.get("value", 0)
				if _enemy_node and _enemy_node.statuses.get("vulnerable", 0) > 0:
					current = _preview_damage(card_data, effect.get("value", 0))
				lines.append(_damage_line(["脆弱追加:", "ダメージ"], effect.get("value", 0), current))
			"block":
				lines.append(_value_line(["ブロックを", "得る。"], effect.get("value", 0), _preview_block(effect.get("value", 0))))
			"heal":
				lines.append([_plain_segment("HPを%d回復。" % effect.get("value", 0))])
			"draw":
				lines.append([_plain_segment("カードを%d枚引く。" % effect.get("value", 1))])
			"gain_energy":
				lines.append([_plain_segment("エナジーを%d得る。" % effect.get("value", 1))])
			"lose_hp":
				lines.append([_plain_segment("HPを%d失う。" % effect.get("value", 0))])
				if effect.get("minimum_hp", 0) > 0:
					lines.append([_plain_segment("最低HPは%d。" % effect.get("minimum_hp", 1))])
			"apply_status":
				var target = "敵に" if effect.get("target", "enemy") == "enemy" else "自分に"
				lines.append([_plain_segment("%s%sを%d付与。" % [target, _status_name(effect.get("status", "")), effect.get("amount", 1)])])
	return lines

func _preview_damage(card_data: Dictionary, base: int) -> int:
	var player_damage = _calc_player_damage(base + _get_attack_relic_damage_bonus(card_data))
	return _preview_damage_to_enemy(player_damage)

func _preview_damage_to_enemy(amount: int) -> int:
	if not _enemy_node:
		return amount
	var actual = amount
	if _enemy_node.statuses.get("vulnerable", 0) > 0:
		actual = int(actual * 1.5)
	var absorbed = mini(_enemy_node.block, actual)
	actual -= absorbed
	return maxi(0, actual)

func _preview_block(base: int) -> int:
	return base + GameState.get_block_bonus()

func _damage_line(parts: Array, base: int, current: int) -> Array:
	return _value_line(parts, base, current)

func _value_line(parts: Array, base: int, current: int) -> Array:
	return [
		_plain_segment(parts[0]),
		{"text": str(current), "color": _damage_preview_color(base, current)},
		_plain_segment(parts[1]),
	]

func _plain_segment(text: String) -> Dictionary:
	return {"text": text, "color": Color(0.88, 0.86, 0.96)}

func _damage_preview_color(base: int, current: int) -> Color:
	if current > base:
		return Color(0.58, 0.96, 0.62)
	if current < base:
		return Color(1.0, 0.42, 0.38)
	return Color(0.88, 0.86, 0.96)

func _calc_player_damage(base: int) -> int:
	var dmg = base
	if GameState.player_statuses.get("weak", 0) > 0:
		dmg = int(dmg * 0.75)
	return dmg

func _deal_damage_to_enemy(amount: int) -> void:
	if not _enemy_node:
		return
	var actual = _enemy_node.take_damage(amount)
	_show_damage_number(actual, _enemy_node.position + Vector2(-30, -160), Color(1.0, 0.4, 0.2))

func _deal_damage_to_enemy_with_effect(amount: int) -> void:
	if amount <= 0 or not _enemy_node or _enemy_node.current_hp <= 0:
		return
	await _play_player_attack_effect()
	_deal_damage_to_enemy(amount)

func _play_player_attack_effect() -> void:
	if not _player_silhouette:
		return
	var start_pos = _player_silhouette.position
	var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(_player_silhouette, "position:x", start_pos.x + 28.0, 0.08)
	t.tween_property(_player_silhouette, "position:x", start_pos.x, 0.12)
	await t.finished

func _play_player_block_effect() -> void:
	if not _battle_layer:
		return
	var effect = _BlockShieldEffect.new()
	effect.position = (_player_silhouette.position if _player_silhouette else Vector2(320, 314)) + Vector2(0, -18)
	effect.scale = Vector2(0.78, 0.78)
	effect.modulate.a = 0.0
	_battle_layer.add_child(effect)

	var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(effect, "modulate:a", 0.58, 0.08)
	t.parallel().tween_property(effect, "scale", Vector2(1.02, 1.02), 0.18)
	t.tween_property(effect, "modulate:a", 0.0, 0.28)
	t.parallel().tween_property(effect, "scale", Vector2(1.18, 1.18), 0.28)
	t.tween_callback(effect.queue_free)

# ═══════════════════════════════════════════════════════════════════════════════
#  End Turn / Enemy Turn
# ═══════════════════════════════════════════════════════════════════════════════

func _on_end_turn() -> void:
	if _busy or not _player_turn:
		return
	_player_turn = false
	_busy = true
	_end_turn_btn.disabled = true

	GameState.trigger_temporary_cards_on_turn_end()
	_flush_combat_damage_events()
	_flush_combat_log_messages()
	if GameState.player_hp <= 0:
		_refresh_hand()
		_update_hud()
		_on_player_died()
		return

	GameState.discard_hand()
	_refresh_hand()
	_log("敵のターン。")

	# Short delay then enemy acts
	var t = create_tween()
	t.tween_interval(0.5)
	t.tween_callback(_do_enemy_turn)

func _do_enemy_turn() -> void:
	var action = _enemy_next_action
	if action.is_empty():
		action = _decide_enemy_next_action()
	if action.is_empty():
		_end_enemy_turn()
		return

	_enemy_turn_idx += 1

	# Tick enemy statuses
	_enemy_node.tick_statuses()

	match action.get("type", ""):
		"attack":
			var raw = _enemy_node.get_attack_value(action.get("value", 5))
			_log("敵の攻撃: %dダメージ。" % raw)
			_enemy_attack_animation(raw)
		"attack_buff":
			var raw = _enemy_node.get_attack_value(action.get("value", 5))
			var buff = action.get("buff", 1)
			_enemy_node.add_strength(buff)
			_log("敵の強撃: %dダメージ。攻撃力上昇。" % raw)
			_enemy_attack_animation(raw)
		"attack_multi":
			var times = action.get("times", 2)
			var raw   = _enemy_node.get_attack_value(action.get("value", 5))
			_log("敵の連撃: %dダメージを%d回。" % [raw, times])
			_enemy_multi_attack_animation(raw, times)
			return  # multi handles its own chain
		"attack_add_temp_discard":
			var card_id = action.get("card_id", "")
			var amount = action.get("amount", 1)
			var raw = _enemy_node.get_attack_value(action.get("value", 0))
			GameState.add_temporary_card_to_discard_pile(card_id, amount)
			_log(action.get("log", "敵は攻撃し、おじゃまカードを捨て札に混ぜた。"))
			_enemy_attack_animation(raw)
			return
		"attack_status":
			var status = action.get("status", "vulnerable")
			var amount = action.get("amount", 1)
			var raw = _enemy_node.get_attack_value(action.get("value", 0))
			GameState.apply_status(status, amount)
			_log("敵の呪い。%sを%d受けた。" % [_status_name(status), amount])
			if raw > 0:
				_enemy_attack_animation(raw)
			else:
				var t = create_tween()
				t.tween_interval(0.8)
				t.tween_callback(_end_enemy_turn)
			return
		"block":
			var amount = action.get("value", 5)
			_enemy_node.gain_block(amount)
			_log("敵は防御を固めた。ブロック%d。" % amount)
			var t = create_tween()
			t.tween_interval(0.8)
			t.tween_callback(_end_enemy_turn)
		"strength":
			var buff = action.get("buff", 1)
			_enemy_node.add_strength(buff)
			_log("敵の力が増した。攻撃力+%d。" % buff)
			var t = create_tween()
			t.tween_interval(0.8)
			t.tween_callback(_end_enemy_turn)
		"block_strength":
			var block_amount = action.get("value", 5)
			var buff = action.get("buff", 1)
			_enemy_node.gain_block(block_amount)
			_enemy_node.add_strength(buff)
			_log(action.get("log", "敵は防御を固め、攻撃力を上げた。"))
			var t = create_tween()
			t.tween_interval(0.8)
			t.tween_callback(_end_enemy_turn)
		"heal":
			var amount = action.get("value", 1)
			_enemy_node.heal(amount)
			_log("敵はHPを%d回復した。" % amount)
			var t = create_tween()
			t.tween_interval(0.8)
			t.tween_callback(_end_enemy_turn)
		"heal_strength":
			var amount = action.get("value", 1)
			var buff = action.get("buff", 1)
			_enemy_node.heal(amount)
			_enemy_node.add_strength(buff)
			_log(action.get("log", "敵は回復し、攻撃力を上げた。"))
			var t = create_tween()
			t.tween_interval(0.8)
			t.tween_callback(_end_enemy_turn)
		"apply_status":
			var status = action.get("status", "weak")
			var amount = action.get("amount", 1)
			GameState.apply_status(status, amount)
			_log("敵の呪い。%sを%d受けた。" % [_status_name(status), amount])
			var t = create_tween()
			t.tween_interval(0.8)
			t.tween_callback(_end_enemy_turn)
		"add_temp_draw":
			var card_id = action.get("card_id", "")
			var amount = action.get("amount", 1)
			GameState.add_temporary_card_to_draw_pile(card_id, amount)
			_log(action.get("log", "敵はおじゃまカードを山札に混ぜた。"))
			var t = create_tween()
			t.tween_interval(0.8)
			t.tween_callback(_end_enemy_turn)
		"add_temp_discard":
			var card_id = action.get("card_id", "")
			var amount = action.get("amount", 1)
			GameState.add_temporary_card_to_discard_pile(card_id, amount)
			_log(action.get("log", "敵はおじゃまカードを捨て札に混ぜた。"))
			var t = create_tween()
			t.tween_interval(0.8)
			t.tween_callback(_end_enemy_turn)
		"add_temp_cards":
			for item in action.get("draw", []):
				GameState.add_temporary_card_to_draw_pile(item.get("id", ""), item.get("amount", 1))
			for item in action.get("discard", []):
				GameState.add_temporary_card_to_discard_pile(item.get("id", ""), item.get("amount", 1))
			_log(action.get("log", "敵は複数のおじゃまカードを混ぜた。"))
			var t = create_tween()
			t.tween_interval(0.8)
			t.tween_callback(_end_enemy_turn)
		_:
			_end_enemy_turn()

func _decide_enemy_next_action() -> Dictionary:
	var enemy_type = String(_enemy_data.get("enemy_id", _enemy_data.get("enemy_type", _enemy_data.get("id", ""))))
	var turn = _enemy_turn_idx + 1
	match enemy_type:
		"holy_soldier":
			return _holy_soldier_action(turn)
		"temple_archer":
			return _temple_archer_action(turn)
		"inquisitor":
			return _inquisitor_action(turn)
		"paladin_captain":
			return _paladin_captain_action(turn)
		"young_swordsman":
			return _young_swordsman_action(turn)
		"novice_cleric":
			return _novice_cleric_action(turn)
		"bounty_hunter":
			return _bounty_hunter_action(turn)
		"chain_jailer":
			return _chain_jailer_action(turn)
		"sun_priest":
			return _sun_priest_action(turn)
		"white_shield_knight":
			return _white_shield_knight_action(turn)
		"fallen_saint":
			return _fallen_saint_action(turn)
		"sage_of_the_party":
			return _sage_of_the_party_action(turn)
		"hunter_companion":
			return _hunter_companion_action(turn)
		"hero":
			return _hero_action(turn)
		"forest_hunter":
			return _forest_hunter_action(turn)
		"mercenary_axeman":
			return _mercenary_axeman_action(turn)
		"poison_rogue":
			return _poison_rogue_action(turn)
		"war_mage":
			return _war_mage_action(turn)
		"battle_scavenger":
			return _battle_scavenger_action(turn)
		"war_wolf":
			return _war_wolf_action(turn)
		"wyvern_dragon":
			return _wyvern_dragon_action(turn)
		"stone_golem":
			return _stone_golem_action(turn)
		"dark_fairy":
			return _dark_fairy_action(turn)
		"royal_guard":
			return _royal_guard_action(turn)
		"alley_duelist":
			return _alley_duelist_action(turn)
		"royal_mage":
			return _royal_mage_action(turn)
		"prison_guard":
			return _prison_guard_action(turn)
		"hired_knight":
			return _hired_knight_action(turn)
		"beastman_mercenary":
			return _beastman_mercenary_action(turn)
		"elven_city_archer":
			return _elven_city_archer_action(turn)
		"foxkin_spy":
			return _foxkin_spy_action(turn)
		"elven_court_mage":
			return _elven_court_mage_action(turn)
		"wolfkin_guard":
			return _wolfkin_guard_action(turn)
		_:
			return _default_enemy_action(turn)

func _pattern_next_action() -> Dictionary:
	var pattern = _enemy_data.get("pattern", [])
	if pattern.is_empty():
		return {}
	return pattern[_enemy_turn_idx % pattern.size()]

func _attack_action(value: int, desc: String = "") -> Dictionary:
	return {"type": "attack", "value": value, "desc": desc if not desc.is_empty() else "攻撃 %d" % value}

func _holy_soldier_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(7)
		2: return {"type": "block", "value": 6, "desc": "防御 6"}
		_: return {"type": "strength", "buff": 2, "desc": "号令", "log": "聖都兵は号令で攻撃力を上げた。"}

func _temple_archer_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return {"type": "attack", "value": 6, "desc": "射撃 6"}
		2: return {"type": "block", "value": 5, "desc": "防御 5"}
		_: return {"type": "add_temp_draw", "card_id": "arrow_wound", "amount": 1, "desc": "矢傷", "log": "神殿弓兵は矢傷を山札に混ぜた。"}

func _inquisitor_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(8)
		2: return {"type": "block", "value": 8, "desc": "防御 8"}
		_:
			var card_id = "brand_of_sin" if turn % 2 == 0 else "restraint"
			var desc = "罪の烙印" if card_id == "brand_of_sin" else "拘束"
			return {"type": "add_temp_draw", "card_id": card_id, "amount": 1, "desc": desc, "log": "異端審問官は%sを山札に混ぜた。" % desc}

func _paladin_captain_action(turn: int) -> Dictionary:
	var half_hp = _enemy_node and _enemy_node.current_hp <= int(_enemy_node.max_hp * 0.5)
	if half_hp and turn % 3 == 0:
		return {"type": "block_strength", "value": 12, "buff": 2, "desc": "聖騎士の意地", "log": "聖騎士隊長は守りを固め、攻撃力を上げた。"}
	match turn % 3:
		1: return _attack_action(10)
		2: return {"type": "block", "value": 11, "desc": "防御 11"}
		_: return {"type": "add_temp_draw", "card_id": "judgement", "amount": 1, "desc": "裁き", "log": "聖騎士隊長は裁きを山札に混ぜた。"}

func _young_swordsman_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(7)
		2: return {"type": "block", "value": 5, "desc": "防御 5"}
		_: return {"type": "strength", "buff": 2, "desc": "気合い", "log": "若き剣士は気合いを入れた。"}

func _novice_cleric_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(5)
		2: return {"type": "block", "value": 7, "desc": "防御 7"}
		_: return {"type": "heal", "value": 8, "desc": "回復 8"}

func _bounty_hunter_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(11)
		2: return {"type": "block", "value": 7, "desc": "防御 7"}
		_: return {"type": "strength", "buff": 3, "desc": "狙いを定める", "log": "賞金稼ぎは狙いを定めた。"}

func _chain_jailer_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(8)
		2: return {"type": "block", "value": 10, "desc": "防御 10"}
		_: return {"type": "add_temp_discard", "card_id": "restraint", "amount": 1, "desc": "拘束", "log": "鎖の看守は拘束を捨て札に混ぜた。"}

func _sun_priest_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(7)
		2: return {"type": "block", "value": 8, "desc": "防御 8"}
		_: return {"type": "heal_strength", "value": 7, "buff": 1, "desc": "祝福", "log": "太陽司祭は祝福で回復し、攻撃力を上げた。"}

func _white_shield_knight_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(11)
		2: return {"type": "block", "value": 15, "desc": "防御 15"}
		_: return {"type": "block_strength", "value": 12, "buff": 2, "desc": "反撃態勢", "log": "白盾の騎士は反撃態勢を取った。"}

func _fallen_saint_action(turn: int) -> Dictionary:
	match turn % 4:
		1: return _attack_action(9)
		2: return {"type": "block", "value": 10, "desc": "防御 10"}
		3: return {"type": "heal", "value": 10, "desc": "回復 10"}
		_: return {"type": "add_temp_draw", "card_id": "guilt", "amount": 1, "desc": "罪悪感", "log": "偽りの聖女は罪悪感を山札に混ぜた。"}

func _sage_of_the_party_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(12, "魔弾 12")
		2: return {"type": "block", "value": 8, "desc": "防御 8"}
		_: return {"type": "add_temp_draw", "card_id": "magic_disruption", "amount": 1, "desc": "魔力乱れ", "log": "叡智の賢者は魔力乱れを山札に混ぜた。"}

func _hunter_companion_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return {"type": "attack_multi", "value": 6, "times": 2, "desc": "連射 6x2"}
		2: return {"type": "block", "value": 9, "desc": "防御 9"}
		_: return {"type": "add_temp_draw", "card_id": "arrow_wound", "amount": 2, "desc": "矢傷 2", "log": "かつての狩人は矢傷を2枚山札に混ぜた。"}

func _hero_action(turn: int) -> Dictionary:
	var second_phase = _enemy_node and _enemy_node.current_hp <= int(_enemy_node.max_hp * 0.5)
	if second_phase:
		match turn % 4:
			1: return _attack_action(18, "勇者の強撃 18")
			2: return {"type": "block_strength", "value": 16, "buff": 2, "desc": "第二形態", "log": "勇者は光を解き放ち第二形態の力を高めた。"}
			3: return {"type": "add_temp_draw", "card_id": "judgement", "amount": 2, "desc": "断罪 2", "log": "勇者は断罪を2枚山札に混ぜた。"}
			_: return {"type": "attack_multi", "value": 8, "times": 3, "desc": "光刃 8x3"}
	match turn % 4:
		1: return _attack_action(13)
		2: return {"type": "block", "value": 14, "desc": "防御 14"}
		3: return {"type": "strength", "buff": 3, "desc": "号令", "log": "勇者は号令で攻撃力を上げた。"}
		_: return {"type": "add_temp_draw", "card_id": "judgement", "amount": 1, "desc": "断罪", "log": "勇者は断罪を山札に混ぜた。"}

func _forest_hunter_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return {"type": "attack_multi", "value": 5, "times": 2, "desc": "連射 5x2"}
		2: return {"type": "block", "value": 7, "desc": "防御 7"}
		_: return {"type": "add_temp_draw", "card_id": "arrow_wound", "amount": 1, "desc": "矢傷", "log": "森の追跡者は矢傷を山札に混ぜた。"}

func _mercenary_axeman_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(12, "斧撃 12")
		2: return {"type": "block", "value": 6, "desc": "防御 6"}
		_: return {"type": "strength", "buff": 4, "desc": "力を溜める", "log": "傭兵斧使いは力を溜めた。"}

func _poison_rogue_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return {"type": "attack_multi", "value": 4, "times": 2, "desc": "毒刃連撃 4x2"}
		2: return {"type": "block", "value": 7, "desc": "防御 7"}
		_: return {"type": "add_temp_draw", "card_id": "poison_blade", "amount": 1, "desc": "毒刃", "log": "毒刃の盗賊は毒刃を山札に混ぜた。"}

func _war_mage_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(10, "魔撃 10")
		2: return {"type": "block", "value": 7, "desc": "防御 7"}
		_: return {"type": "add_temp_draw", "card_id": "magic_disruption", "amount": 1, "desc": "魔力乱れ", "log": "戦場魔術師は魔力乱れを山札に混ぜた。"}

func _battle_scavenger_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(7)
		2: return {"type": "block", "value": 6, "desc": "防御 6"}
		_: return {"type": "add_temp_discard", "card_id": "junk", "amount": 2, "desc": "ガラクタ 2", "log": "戦場漁りはガラクタを2枚捨て札に混ぜた。"}

func _war_wolf_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return {"type": "attack_multi", "value": 5, "times": 2, "desc": "連撃 5x2"}
		2: return {"type": "block", "value": 5, "desc": "防御 5"}
		_: return {"type": "add_temp_discard", "card_id": "bleeding", "amount": 1, "desc": "出血", "log": "戦狼は出血を捨て札に混ぜた。"}

func _wyvern_dragon_action(turn: int) -> Dictionary:
	match turn % 4:
		1: return _attack_action(13, "爪撃 13")
		2: return {"type": "block", "value": 10, "desc": "防御 10"}
		3: return {"type": "add_temp_draw", "card_id": "dragon_burn", "amount": 1, "desc": "竜の火傷", "log": "飛竜は竜の火傷を山札に混ぜた。"}
		_: return _attack_action(20, "急降下 20")

func _stone_golem_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(12, "岩拳 12")
		2: return {"type": "block", "value": 18, "desc": "防御 18"}
		_: return {"type": "add_temp_draw", "card_id": "petrified_shard", "amount": 1, "desc": "石化の欠片", "log": "石像ゴーレムは石化の欠片を山札に混ぜた。"}

func _dark_fairy_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(8, "闇弾 8")
		2: return {"type": "block", "value": 9, "desc": "防御 9"}
		_: return {"type": "add_temp_draw", "card_id": "fairy_mischief", "amount": 1, "desc": "妖精の悪戯", "log": "闇妖精は妖精の悪戯を山札に混ぜた。"}

func _royal_guard_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(7, "槍突き 7")
		2: return {"type": "block", "value": 8, "desc": "盾を構える"}
		_: return {"type": "attack_status", "value": 5, "status": "weak", "amount": 1, "desc": "制圧命令", "log": "王都衛兵は制圧命令を下した。"}

func _alley_duelist_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return {"type": "attack_multi", "value": 4, "times": 2, "desc": "素早い刺突 4x2"}
		2: return {"type": "strength", "buff": 1, "desc": "間合いを測る", "log": "路地裏の決闘者は間合いを測った。"}
		_: return _attack_action(10, "決闘の一閃 10")

func _royal_mage_action(turn: int) -> Dictionary:
	match turn % 4:
		1: return _attack_action(8, "魔弾 8")
		2: return {"type": "add_temp_discard", "card_id": "pressure", "amount": 1, "desc": "思考干渉", "log": "王宮魔術師は重圧を捨て札に混ぜた。"}
		3: return {"type": "block", "value": 14, "desc": "王宮結界"}
		_: return {"type": "add_temp_discard", "card_id": "pressure", "amount": 1, "desc": "魔力封じ", "log": "王宮魔術師は魔力封じで重圧を捨て札に混ぜた。"}

func _prison_guard_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(7, "鎖打ち 7")
		2: return {"type": "add_temp_discard", "card_id": "restraint", "amount": 1, "desc": "拘束具", "log": "牢獄番は拘束を捨て札に混ぜた。"}
		_: return _attack_action(11, "鉄棍殴打 11")

func _hired_knight_action(turn: int) -> Dictionary:
	match turn % 4:
		1: return _attack_action(12, "大剣斬り 12")
		2: return {"type": "block", "value": 16, "desc": "鎧を固める"}
		3: return {"type": "block_strength", "value": 8, "buff": 1, "desc": "傭兵の構え", "log": "雇われ騎士は構えを取り、攻撃力を上げた。"}
		_: return {"type": "attack_multi", "value": 7, "times": 2, "desc": "踏み込み斬り 7x2"}

func _beastman_mercenary_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(9, "斧撃 9")
		2: return {"type": "strength", "buff": 1, "desc": "咆哮", "log": "獣人傭兵は咆哮で攻撃力を上げた。"}
		_: return {"type": "attack_multi", "value": 5, "times": 2, "desc": "獣の連撃 5x2"}

func _elven_city_archer_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(7, "精密射撃 7")
		2: return {"type": "strength", "buff": 1, "desc": "狙い澄ます", "log": "エルフの王都射手は狙いを澄ませた。"}
		_: return {"type": "attack_add_temp_discard", "value": 5, "card_id": "arrow_wound", "amount": 1, "desc": "裂傷の矢", "log": "エルフの王都射手は裂傷の矢を放ち、矢傷を捨て札に混ぜた。"}

func _foxkin_spy_action(turn: int) -> Dictionary:
	match turn % 4:
		1: return _attack_action(6, "袖刃 6")
		2: return {"type": "attack_status", "value": 4, "status": "weak", "amount": 1, "desc": "毒針", "log": "狐獣人の密偵は毒針を放った。"}
		3: return {"type": "block", "value": 8, "desc": "身を翻す"}
		_: return {"type": "add_temp_discard", "card_id": "pressure", "amount": 1, "desc": "攪乱", "log": "狐獣人の密偵は重圧を捨て札に混ぜた。"}

func _elven_court_mage_action(turn: int) -> Dictionary:
	match turn % 4:
		1: return _attack_action(9, "宮廷魔弾 9")
		2: return {"type": "block", "value": 6, "desc": "結界術"}
		3: return {"type": "add_temp_discard", "card_id": "pressure", "amount": 1, "desc": "記憶の撹乱", "log": "エルフの宮廷術師は重圧を捨て札に混ぜた。"}
		_: return {"type": "add_temp_discard", "card_id": "pressure", "amount": 1, "desc": "魔力封じ", "log": "エルフの宮廷術師は魔力封じで重圧を捨て札に混ぜた。"}

func _wolfkin_guard_action(turn: int) -> Dictionary:
	match turn % 4:
		1: return _attack_action(10, "近衛剣 10")
		2: return {"type": "block", "value": 14, "desc": "守護本能"}
		3: return {"type": "strength", "buff": 2, "desc": "低い唸り", "log": "狼獣人の近衛は低く唸り、攻撃力を上げた。"}
		_: return {"type": "attack_multi", "value": 5, "times": 2, "desc": "双爪追撃 5x2"}

func _default_enemy_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(7)
		2: return {"type": "block", "value": 6, "desc": "防御 6"}
		_: return {"type": "add_temp_draw", "card_id": "junk", "amount": 1, "desc": "ガラクタ", "log": "敵はガラクタを山札に混ぜた。"}

func _enemy_attack_animation(damage: int) -> void:
	# Enemy lunges left then returns
	var start_x = _enemy_node.position.x
	var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(_enemy_node, "position:x", start_x - 100, 0.18)
	t.tween_callback(func():
		_damage_player_with_effect(damage)
		if GameState.player_hp <= 0:
			_on_player_died()
			return
	)
	t.tween_property(_enemy_node, "position:x", start_x, 0.25)
	t.tween_interval(0.3)
	t.tween_callback(_end_enemy_turn)

func _enemy_multi_attack_animation(damage: int, times: int) -> void:
	var start_x = _enemy_node.position.x
	var t = create_tween().set_ease(Tween.EASE_OUT)
	for i in times:
		t.tween_property(_enemy_node, "position:x", start_x - 80, 0.14)
		t.tween_callback(func():
			_damage_player_with_effect(damage, Vector2(0, -154 - randf_range(0, 30)))
		)
		t.tween_property(_enemy_node, "position:x", start_x, 0.16)
		t.tween_interval(0.1)
	t.tween_interval(0.3)
	t.tween_callback(func():
		if GameState.player_hp <= 0:
			_on_player_died()
		else:
			_end_enemy_turn()
	)

func _end_enemy_turn() -> void:
	_start_player_turn()

# ═══════════════════════════════════════════════════════════════════════════════
#  Win / Lose
# ═══════════════════════════════════════════════════════════════════════════════

func _on_enemy_died() -> void:
	_busy = true
	_end_turn_btn.disabled = true
	_log("勝利。")

	var t = create_tween()
	t.tween_interval(0.9)
	t.tween_callback(_after_enemy_died)

func _after_enemy_died() -> void:
	# 血濡れの剣片: 敵撃破時HP回復
	if GameState.has_relic("bloodied_blade_shard"):
		GameState.heal(5)
	GameState.complete_map_node(GameState.map_current_node_id)
	var is_boss = _enemy_data.get("is_boss", false) or GameState.map_encounter_is_boss
	GameState.clear_combat_piles()
	if is_boss:
		_battle_layer.visible = false
		if GameState.current_act == 1:
			_show_boss_relic_reward()
		else:
			_end_screen.show_end(true)
	else:
		_battle_layer.visible = false
		var options = GameState.get_reward_options()
		_reward_screen.show_reward(options)

func _on_reward_chosen() -> void:
	if _was_elite:
		_show_relic_reward()
	else:
		_go_to_map()

func _show_relic_reward() -> void:
	var relic_id = GameState.roll_relic_reward("elite")
	if relic_id.is_empty():
		_go_to_map()
		return
	_relic_reward.show_reward(relic_id)

func _on_relic_reward_accepted() -> void:
	_go_to_map()

func _show_boss_relic_reward() -> void:
	if not _boss_relic_reward:
		_advance_to_act2_after_boss_relic()
		return
	_boss_relic_reward.show_reward()

func _on_boss_relic_reward_chosen(_relic_id: String) -> void:
	_advance_to_act2_after_boss_relic()

func _advance_to_act2_after_boss_relic() -> void:
	var heal_amount = int(ceil(float(GameState.player_max_hp) * 0.5))
	GameState.heal(heal_amount)
	GameState.start_act2_map()
	_go_to_map()

func _go_to_map() -> void:
	var t = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "modulate:a", 0.0, 0.4)
	t.tween_callback(func(): get_tree().change_scene_to_file(MAP_SCENE))

func _on_deck_pressed() -> void:
	if _deck_viewer and _deck_viewer.has_method("show_deck"):
		_deck_viewer.show_deck(GameState.get_combat_deck_view_cards())

func _on_relic_pressed() -> void:
	if _relic_viewer and _relic_viewer.has_method("show_relics"):
		_relic_viewer.show_relics()

func _on_player_died() -> void:
	_busy = true
	_end_turn_btn.disabled = true
	_log("影に呑まれた。")
	GameState.clear_combat_piles()
	_battle_layer.visible = false
	var t = create_tween()
	t.tween_interval(1.0)
	t.tween_callback(func(): _end_screen.show_end(false))

# ═══════════════════════════════════════════════════════════════════════════════
#  Helpers
# ═══════════════════════════════════════════════════════════════════════════════

func _log(text: String) -> void:
	_log_label.text = text
	_log_label.modulate.a = 1.0
	var t = create_tween()
	t.tween_interval(2.5)
	t.tween_property(_log_label, "modulate:a", 0.3, 0.8)

func _damage_player_with_effect(raw_damage: int, number_offset: Vector2 = Vector2(0, -154)) -> int:
	var actual = GameState.take_damage(raw_damage)
	_play_player_damage_feedback(actual, number_offset)
	return actual

func _play_player_damage_feedback(actual_damage: int, number_offset: Vector2 = Vector2(0, -154)) -> void:
	if _player_silhouette:
		_player_silhouette.take_hit()
	if actual_damage >= 0:
		var number_pos = (_player_silhouette.global_position if _player_silhouette else Vector2(290, 334)) + number_offset
		_show_damage_number(actual_damage, number_pos, Color(1.0, 0.25, 0.25))
	_update_hud()

func _flush_combat_damage_events() -> void:
	for event in GameState.consume_combat_damage_events():
		if event.get("target", "") == "player":
			_play_player_damage_feedback(event.get("amount", 0), Vector2(0, -154 - randf_range(0, 24)))

func _flush_combat_log_messages() -> void:
	for message in GameState.consume_combat_log_messages():
		_log(message)

func _show_damage_number(amount: int, world_pos: Vector2, color: Color) -> void:
	var lbl = Label.new()
	lbl.text = str(amount)
	lbl.position = world_pos
	lbl.size = Vector2(96, 46)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 38)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	add_child(lbl)
	var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	lbl.scale = Vector2(0.7, 0.7)
	t.tween_property(lbl, "scale", Vector2(1.18, 1.18), 0.12)
	t.tween_property(lbl, "position:y", world_pos.y - 64, 0.58)
	t.parallel().tween_property(lbl, "modulate:a", 0.0, 0.58)
	t.tween_callback(lbl.queue_free)

func _status_name(status: String) -> String:
	match status:
		"weak":
			return "脱力"
		"vulnerable":
			return "脆弱"
		_:
			return status

func _make_button(text: String, position: Vector2, size: Vector2) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.position = position - size / 2.0
	btn.size = size
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color(0.94, 0.88, 1.0))

	var style_n = StyleBoxFlat.new()
	style_n.bg_color = Color(0.12, 0.04, 0.26)
	style_n.border_color = Color(0.55, 0.26, 0.86)
	style_n.set_border_width_all(2)
	style_n.set_corner_radius_all(10)
	style_n.shadow_color = Color(0.45, 0.15, 0.78, 0.32)
	style_n.shadow_size = 6
	btn.add_theme_stylebox_override("normal", style_n)

	var style_h = StyleBoxFlat.new()
	style_h.bg_color = Color(0.22, 0.08, 0.48)
	style_h.border_color = Color(0.78, 0.44, 1.0)
	style_h.set_border_width_all(3)
	style_h.set_corner_radius_all(10)
	style_h.shadow_color = Color(0.60, 0.28, 0.95, 0.50)
	style_h.shadow_size = 10
	btn.add_theme_stylebox_override("hover", style_h)
	btn.add_theme_stylebox_override("pressed", style_h)

	var style_d = StyleBoxFlat.new()
	style_d.bg_color = Color(0.08, 0.06, 0.16)
	style_d.border_color = Color(0.22, 0.16, 0.34)
	style_d.set_border_width_all(1)
	style_d.set_corner_radius_all(10)
	btn.add_theme_stylebox_override("disabled", style_d)
	return btn

func _style_badge(label: Label, accent: Color) -> void:
	label.add_theme_color_override("font_color", Color(0.94, 0.88, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	var badge = StyleBoxFlat.new()
	badge.bg_color = Color(0.035, 0.030, 0.065, 0.88)
	badge.border_color = Color(accent, 0.70)
	badge.set_border_width_all(1)
	badge.set_corner_radius_all(5)
	badge.set_content_margin_all(4)
	label.add_theme_stylebox_override("normal", badge)


# ═══════════════════════════════════════════════════════════════════════════════
#  Inline Node classes
# ═══════════════════════════════════════════════════════════════════════════════

class _EnemyInfoCard extends Panel:
	const STATUS_ORDER := ["vulnerable", "weak", "poison"]
	const STATUS_ICONS := {
		"vulnerable": {"symbol": "◇", "color": Color(1.0, 0.56, 0.24)},
		"weak": {"symbol": "↓", "color": Color(0.72, 0.46, 1.0)},
		"poison": {"symbol": "●", "color": Color(0.36, 0.86, 0.42)},
		"strength": {"symbol": "↑", "color": Color(1.0, 0.78, 0.25)},
		"block": {"symbol": "■", "color": Color(0.42, 0.68, 1.0)}
	}
	const TEMP_CARD_COLOR := Color(0.58, 0.46, 0.86)
	const TEMP_CARD_NAMES := {
		"restraint": "拘束",
		"arrow_wound": "矢傷",
		"pressure": "重圧",
		"junk": "ガラクタ",
		"brand_of_sin": "罪の烙印",
		"judgement": "裁き",
		"guilt": "罪悪感",
		"poison_blade": "毒刃",
		"magic_disruption": "魔力乱れ",
		"petrified_shard": "石化の欠片",
		"dragon_burn": "竜の火傷",
		"fairy_mischief": "妖精の悪戯",
		"bleeding": "出血"
	}
	const ACTION_COLORS := {
		"attack": Color(1.0, 0.34, 0.28),
		"block": Color(0.42, 0.68, 1.0),
		"strength": Color(1.0, 0.78, 0.25),
		"status": Color(0.72, 0.46, 1.0),
		"heal": Color(0.36, 0.86, 0.42),
		"temp": Color(0.58, 0.46, 0.86)
	}

	var _enemy_node: Node
	var _name_label: Label
	var _hp_bar_bg: ColorRect
	var _hp_bar_fill: ColorRect
	var _hp_label: Label
	var _status_icons: HBoxContainer
	var _intent_prefix_label: Label
	var _intent_icons: HBoxContainer
	var _tooltip_panel: Panel
	var _tooltip_label: Label
	var _status_icon_signature := ""
	var _intent_icon_signature := ""

	func setup(enemy_node: Node) -> void:
		_enemy_node = enemy_node
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_build_ui()
		_update_from_enemy()

	func _build_ui() -> void:
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.030, 0.026, 0.060, 0.54)
		panel_style.border_color = Color(0.62, 0.50, 0.28, 0.22)
		panel_style.set_border_width_all(1)
		panel_style.set_corner_radius_all(4)
		panel_style.set_content_margin_all(3)
		add_theme_stylebox_override("panel", panel_style)

		_name_label = Label.new()
		_name_label.position = Vector2(9, 4)
		_name_label.size = Vector2(154, 18)
		_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_name_label.clip_text = true
		_name_label.add_theme_font_size_override("font_size", 13)
		_name_label.add_theme_color_override("font_color", Color(0.94, 0.82, 0.54))
		_name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.82))
		_name_label.add_theme_constant_override("shadow_offset_x", 1)
		_name_label.add_theme_constant_override("shadow_offset_y", 1)
		add_child(_name_label)

		_hp_bar_bg = ColorRect.new()
		_hp_bar_bg.position = Vector2(9, 26)
		_hp_bar_bg.size = Vector2(242, 4)
		_hp_bar_bg.color = Color(0.08, 0.045, 0.075, 0.58)
		add_child(_hp_bar_bg)

		_hp_bar_fill = ColorRect.new()
		_hp_bar_fill.position = _hp_bar_bg.position
		_hp_bar_fill.size = _hp_bar_bg.size
		_hp_bar_fill.color = Color(0.58, 0.10, 0.10, 0.78)
		add_child(_hp_bar_fill)

		_hp_label = Label.new()
		_hp_label.position = Vector2(166, 4)
		_hp_label.size = Vector2(85, 18)
		_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_hp_label.clip_text = true
		_hp_label.add_theme_font_size_override("font_size", 13)
		_hp_label.add_theme_color_override("font_color", Color(0.94, 0.78, 0.74))
		add_child(_hp_label)

		_status_icons = HBoxContainer.new()
		_status_icons.position = Vector2(9, 34)
		_status_icons.size = Vector2(108, 21)
		_status_icons.add_theme_constant_override("separation", 2)
		_status_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_status_icons)

		_intent_prefix_label = Label.new()
		_intent_prefix_label.text = "次"
		_intent_prefix_label.position = Vector2(196, 36)
		_intent_prefix_label.size = Vector2(18, 16)
		_intent_prefix_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_intent_prefix_label.add_theme_font_size_override("font_size", 14)
		_intent_prefix_label.add_theme_color_override("font_color", Color(0.78, 0.74, 0.88))
		_intent_prefix_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.82))
		_intent_prefix_label.add_theme_constant_override("shadow_offset_x", 1)
		_intent_prefix_label.add_theme_constant_override("shadow_offset_y", 1)
		add_child(_intent_prefix_label)

		_intent_icons = HBoxContainer.new()
		_intent_icons.position = Vector2(141, 34)
		_intent_icons.size = Vector2(110, 21)
		_intent_icons.alignment = BoxContainer.ALIGNMENT_END
		_intent_icons.add_theme_constant_override("separation", 2)
		_intent_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_intent_icons)

		_ensure_tooltip()

	func _process(_delta: float) -> void:
		_update_from_enemy()

	func _update_from_enemy() -> void:
		if not is_instance_valid(_enemy_node):
			visible = false
			return
		var data: Dictionary = _enemy_node.enemy_data
		var current_hp := int(_enemy_node.current_hp)
		var max_hp := maxi(1, int(_enemy_node.max_hp))
		visible = true
		_name_label.text = data.get("display_name", data.get("name_jp", data.get("name", "敵")))
		var hp_ratio := clampf(float(current_hp) / float(max_hp), 0.0, 1.0)
		_hp_bar_fill.size = Vector2(_hp_bar_bg.size.x * hp_ratio, _hp_bar_bg.size.y)
		_hp_label.text = "%d/%d" % [current_hp, max_hp]
		_status_icon_signature = _set_icon_row(_status_icons, _status_icon_specs(), _status_icon_signature)
		if current_hp <= 0:
			modulate = Color(0.72, 0.72, 0.72, 0.72)
			_intent_icon_signature = _set_icon_row(_intent_icons, [{"text": "撃", "color": Color(0.70, 0.70, 0.76), "tooltip": "撃破"}], _intent_icon_signature)
		else:
			modulate = Color.WHITE
			_intent_icon_signature = _set_icon_row(_intent_icons, _action_icon_specs(_enemy_node.next_action), _intent_icon_signature)

	func _status_icon_specs() -> Array:
		var specs: Array = []
		if int(_enemy_node.block) > 0:
			specs.append(_icon_spec("block", int(_enemy_node.block)))
		var statuses: Dictionary = _enemy_node.statuses
		for status_id in STATUS_ORDER:
			var value := int(statuses.get(status_id, 0))
			if value > 0:
				specs.append(_icon_spec(status_id, value))
		for status_id in statuses.keys():
			if STATUS_ORDER.has(status_id):
				continue
			var value := int(statuses.get(status_id, 0))
			if value > 0:
				specs.append(_icon_spec(status_id, value))
		if _enemy_node.has_method("get_strength_bonus"):
			var strength := int(_enemy_node.get_strength_bonus())
			if strength > 0:
				specs.append(_icon_spec("strength", strength))
		return specs

	func _action_icon_specs(action: Dictionary) -> Array:
		if action.is_empty():
			return []
		var specs: Array = []
		match action.get("type", ""):
			"attack":
				var value = action.get("value", 0)
				specs.append(_action_spec("▲", value, ACTION_COLORS["attack"], "攻撃：%sダメージ" % str(value)))
			"attack_buff":
				var value = action.get("value", 0)
				var buff = action.get("buff", 1)
				specs.append(_action_spec("▲", value, ACTION_COLORS["attack"], "攻撃：%sダメージ" % str(value)))
				specs.append(_action_spec("↑", buff, ACTION_COLORS["strength"], "強化：筋力%sを得る" % str(buff)))
			"attack_multi":
				var value = action.get("value", 0)
				var times = action.get("times", 2)
				specs.append(_action_spec("▲", "%sx%s" % [value, times], ACTION_COLORS["attack"], "連続攻撃：%sダメージを%s回" % [str(value), str(times)]))
			"attack_add_temp_discard":
				var value = action.get("value", 0)
				specs.append(_action_spec("▲", value, ACTION_COLORS["attack"], "攻撃：%sダメージ" % str(value)))
				specs.append(_temp_card_spec(action.get("card_id", ""), action.get("amount", 1)))
			"attack_status":
				var value = action.get("value", 0)
				specs.append(_action_spec("▲", value, ACTION_COLORS["attack"], "攻撃：%sダメージ" % str(value)))
				specs.append(_icon_spec(action.get("status", "weak"), action.get("amount", 1)))
			"block":
				var value = action.get("value", 0)
				specs.append(_action_spec("■", value, ACTION_COLORS["block"], "防御：ブロック%sを得る" % str(value)))
			"strength":
				var buff = action.get("buff", 1)
				specs.append(_action_spec("↑", buff, ACTION_COLORS["strength"], "強化：筋力%sを得る" % str(buff)))
			"block_strength":
				var value = action.get("value", 0)
				var buff = action.get("buff", 1)
				specs.append(_action_spec("■", value, ACTION_COLORS["block"], "防御：ブロック%sを得る" % str(value)))
				specs.append(_action_spec("↑", buff, ACTION_COLORS["strength"], "強化：筋力%sを得る" % str(buff)))
			"heal", "heal_strength":
				var value = action.get("value", 0)
				specs.append(_action_spec("＋", value, ACTION_COLORS["heal"], "回復：HPを%s回復" % str(value)))
				if action.get("type", "") == "heal_strength":
					var buff = action.get("buff", 1)
					specs.append(_action_spec("↑", buff, ACTION_COLORS["strength"], "強化：筋力%sを得る" % str(buff)))
			"apply_status":
				specs.append(_icon_spec(action.get("status", "weak"), action.get("amount", 1)))
			"add_temp_draw", "add_temp_discard":
				specs.append(_temp_card_spec(action.get("card_id", ""), action.get("amount", 1)))
			"add_temp_cards":
				for item in action.get("draw", []):
					specs.append(_temp_card_spec(item.get("id", ""), item.get("amount", 1)))
				for item in action.get("discard", []):
					specs.append(_temp_card_spec(item.get("id", ""), item.get("amount", 1)))
		return specs

	func _icon_spec(id: String, value) -> Dictionary:
		var meta: Dictionary = STATUS_ICONS.get(id, {"symbol": "?", "color": Color(0.82, 0.82, 0.88)})
		var tooltip := ""
		match id:
			"block":
				tooltip = "防御：ブロック%s" % str(value)
			"strength":
				tooltip = "強化：筋力%s" % str(value)
			"weak":
				tooltip = "弱体：攻撃ダメージが下がる"
			"vulnerable":
				tooltip = "脆弱：受けるダメージが増える"
			"poison":
				tooltip = "毒：ターンごとにダメージを受ける"
			_:
				tooltip = "%s：%s" % [id, str(value)]
		return _action_spec(meta.get("symbol", "?"), value, meta.get("color", Color.WHITE), tooltip)

	func _temp_card_spec(card_id: String, value) -> Dictionary:
		var card_name: String = TEMP_CARD_NAMES.get(card_id, "お邪魔")
		var amount := int(value)
		var tooltip := "%sカードを%d枚追加" % [card_name, amount]
		return {"text": "札%d" % amount, "color": TEMP_CARD_COLOR, "tooltip": tooltip}

	func _action_spec(symbol: String, value, color: Color, tooltip: String = "") -> Dictionary:
		return {"text": "%s%s" % [symbol, str(value)], "color": color, "tooltip": tooltip}

	func _set_icon_row(row: HBoxContainer, specs: Array, previous_signature: String) -> String:
		var signature := _icon_signature(specs)
		if signature == previous_signature:
			return previous_signature
		_hide_icon_tooltip()
		for child in row.get_children():
			child.queue_free()
		for spec in specs:
			row.add_child(_make_icon_label(spec))
		return signature

	func _icon_signature(specs: Array) -> String:
		var parts: Array[String] = []
		for spec in specs:
			parts.append("%s:%s" % [spec.get("text", ""), spec.get("tooltip", "")])
		return "|".join(parts)

	func _make_icon_label(spec: Dictionary) -> Label:
		var accent: Color = spec.get("color", Color.WHITE)
		var label = Label.new()
		label.text = spec.get("text", "")
		label.custom_minimum_size = Vector2(34, 20)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color(0.98, 0.96, 1.0))
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.86))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(accent.r, accent.g, accent.b, 0.24)
		style.border_color = Color(accent.r, accent.g, accent.b, 0.50)
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		style.set_content_margin_all(2)
		label.add_theme_stylebox_override("normal", style)
		var tooltip_text: String = spec.get("tooltip", "")
		label.mouse_entered.connect(func(): _show_icon_tooltip(label, tooltip_text))
		label.mouse_exited.connect(_hide_icon_tooltip)
		return label

	func _ensure_tooltip() -> void:
		if _tooltip_panel:
			return
		_tooltip_panel = Panel.new()
		_tooltip_panel.visible = false
		_tooltip_panel.z_index = 1000
		_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.024, 0.020, 0.050, 0.90)
		style.border_color = Color(0.58, 0.48, 0.72, 0.55)
		style.set_border_width_all(1)
		style.set_corner_radius_all(5)
		style.set_content_margin_all(6)
		_tooltip_panel.add_theme_stylebox_override("panel", style)
		add_child(_tooltip_panel)

		_tooltip_label = Label.new()
		_tooltip_label.position = Vector2(8, 5)
		_tooltip_label.add_theme_font_size_override("font_size", 12)
		_tooltip_label.add_theme_color_override("font_color", Color(0.94, 0.91, 1.0))
		_tooltip_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.86))
		_tooltip_label.add_theme_constant_override("shadow_offset_x", 1)
		_tooltip_label.add_theme_constant_override("shadow_offset_y", 1)
		_tooltip_panel.add_child(_tooltip_label)

	func _show_icon_tooltip(source: Control, text: String) -> void:
		if text.is_empty():
			return
		_ensure_tooltip()
		_tooltip_label.text = text
		var panel_w = clampf(float(text.length()) * 12.0 + 18.0, 110.0, 250.0)
		_tooltip_panel.size = Vector2(panel_w, 28)
		_tooltip_label.size = _tooltip_panel.size - Vector2(16, 8)
		var global_pos = source.global_position + Vector2(0, source.size.y + 5)
		var viewport_size = get_viewport_rect().size
		global_pos.x = clampf(global_pos.x, 8.0, maxf(8.0, viewport_size.x - _tooltip_panel.size.x - 8.0))
		global_pos.y = clampf(global_pos.y, 8.0, maxf(8.0, viewport_size.y - _tooltip_panel.size.y - 8.0))
		_tooltip_panel.position = global_pos - global_position
		_tooltip_panel.visible = true

	func _hide_icon_tooltip() -> void:
		if _tooltip_panel:
			_tooltip_panel.visible = false

class _AmbientBG extends Node2D:
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


class _PlayerSilhouette extends Node2D:
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

		_shadow = _PlayerGroundShadow.new()
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


class _BlockShieldEffect extends Node2D:
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


class _PlayerGroundShadow extends Node2D:
	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(2.8, 0.45))
		draw_circle(Vector2.ZERO, 20, Color(0, 0, 0, 0.40))
		draw_circle(Vector2.ZERO, 13, Color(0.12, 0.15, 0.24, 0.16))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


class _EnergyOrb extends Control:
	func _draw() -> void:
		var center = size / 2.0
		var radius = minf(size.x, size.y) * 0.42
		draw_circle(center, radius + 9.0, Color(0.58, 0.18, 0.96, 0.18))
		draw_circle(center, radius + 4.0, Color(0.50, 0.12, 0.84, 0.34))
		draw_circle(center, radius, Color(0.19, 0.10, 0.36, 0.98))
		draw_circle(center + Vector2(-7, -8), radius * 0.42, Color(0.78, 0.54, 1.0, 0.20))
		draw_circle(center, radius, Color(0.72, 0.34, 1.0, 0.86), false, 2.4)
		draw_circle(center, radius - 6.0, Color(0.86, 0.68, 1.0, 0.22), false, 1.2)


class _ButtonOrnament extends Control:
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
