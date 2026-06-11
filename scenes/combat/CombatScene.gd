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

# ── Split-out modules ─────────────────────────────────────────────────────────
const EnemyAI       = preload("res://scenes/combat/EnemyAI.gd")
const EnemyInfoCard = preload("res://scenes/combat/EnemyInfoCard.gd")
const CombatVisuals = preload("res://scenes/combat/CombatVisuals.gd")
const StatusBadges  = preload("res://scenes/ui/StatusBadges.gd")

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
const STATUS_TOOLTIP_ORDER = ["block", "vulnerable", "weak", "poison", "strength"]
const STATUS_DESCRIPTIONS = {
	"block": {"name": "ブロック", "description": "次に受けるダメージを軽減する。", "value_label": "値"},
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
const ENERGY_PANEL_POS = Vector2(10, 514)
const ENERGY_PANEL_SIZE = Vector2(168, 180)
const ENERGY_ORB_SIZE = Vector2(76, 102)  # 上76x76がオーブ、下にピップ列
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
var _player_status_row: HBoxContainer
var _player_status_signature: String = ""
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
	_ambient_bg = CombatVisuals.AmbientBG.new()
	_battle_layer.add_child(_ambient_bg)

	# Player silhouette (left side)
	_player_silhouette = CombatVisuals.PlayerSilhouette.new()
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
	var btn_orn = CombatVisuals.ButtonOrnament.new()
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

	var deck_btn = _make_button("デッキ", Vector2(1206, 34), Vector2(116, 40))
	deck_btn.add_theme_font_size_override("font_size", 16)
	deck_btn.pressed.connect(_on_deck_pressed)
	_decorate_menu_button(deck_btn, "res://assets/ui/icons/deck.svg")
	_battle_layer.add_child(deck_btn)

	var relic_btn = _make_button("レリック", Vector2(1206, 84), Vector2(116, 40))
	relic_btn.add_theme_font_size_override("font_size", 16)
	relic_btn.pressed.connect(_on_relic_pressed)
	_decorate_menu_button(relic_btn, "res://assets/ui/icons/relic.svg")
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
	panel_style.bg_color = Color(0.030, 0.026, 0.058, 0.92)
	panel_style.set_border_width_all(0)
	panel_style.set_corner_radius_all(2)
	_player_hud_panel.add_theme_stylebox_override("panel", panel_style)
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

	# Ornate frame over the panel
	var hud_frame = CombatVisuals.FrameOverlay.new()
	hud_frame.frame_alpha = 0.78
	hud_frame.corner = 10.0
	_player_hud_panel.add_child(hud_frame)

	# Player crest (reuses the pentagram card icon, tinted violet)
	var crest = TextureRect.new()
	crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crest.stretch_mode = TextureRect.STRETCH_SCALE
	crest.texture = load("res://assets/cards/icons/abyss_contract.svg")
	crest.position = Vector2(9, 4)
	crest.size = Vector2(18, 18)
	crest.modulate = Color(0.72, 0.52, 1.0, 0.85)
	_player_hud_panel.add_child(crest)

	# Player name label
	var name_label = Label.new()
	name_label.text = "プレイヤー"
	name_label.position = Vector2(32, 4)
	name_label.size = Vector2(180, 20)
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
	bg_s.border_color = Color(0.62, 0.50, 0.28, 0.55)
	bg_s.set_border_width_all(1)
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

	# Block + status badge row (icons with per-badge tooltips)
	_player_status_row = HBoxContainer.new()
	_player_status_row.position = Vector2(10, 72)
	_player_status_row.size = Vector2(202, 24)
	_player_status_row.add_theme_constant_override("separation", 4)
	_player_hud_panel.add_child(_player_status_row)

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
		var card = EnemyInfoCard.new()
		card.custom_minimum_size = ENEMY_INFO_CARD_SIZE
		card.size = ENEMY_INFO_CARD_SIZE
		card.setup(enemy_node)
		_enemy_info_area.add_child(card)
		_enemy_info_cards.append(card)

func _build_energy_panel() -> void:
	var panel = Panel.new()
	panel.position = ENERGY_PANEL_POS
	panel.size = ENERGY_PANEL_SIZE
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	add_child(panel)
	_energy_container = panel

	_energy_orb = CombatVisuals.EnergyOrb.new()
	_energy_orb.position = Vector2((ENERGY_PANEL_SIZE.x - ENERGY_ORB_SIZE.x) / 2.0, 34.0)
	_energy_orb.size = ENERGY_ORB_SIZE
	_energy_orb.custom_minimum_size = ENERGY_ORB_SIZE
	panel.add_child(_energy_orb)

	var title_label = Label.new()
	title_label.text = "エナジー"
	title_label.position = Vector2(0, 6)
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
	_energy_label.size = Vector2(ENERGY_ORB_SIZE.x, ENERGY_ORB_SIZE.x)
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

	_update_player_status_badges()

	_rebuild_energy_dots()
	_update_card_playability()

func _update_player_status_badges() -> void:
	if not _player_status_row:
		return
	var entries: Array = []
	if GameState.player_block > 0:
		entries.append(["block", GameState.player_block])
	var statuses: Dictionary = GameState.player_statuses
	for status_id in STATUS_TOOLTIP_ORDER:
		if status_id == "block":
			continue
		var value = int(statuses.get(status_id, 0))
		if value > 0:
			entries.append([status_id, value])
	for status_id in statuses.keys():
		if STATUS_TOOLTIP_ORDER.has(status_id):
			continue
		var value = int(statuses.get(status_id, 0))
		if value > 0:
			entries.append([status_id, value])

	var signature_parts: Array[String] = []
	for entry in entries:
		signature_parts.append("%s:%d" % [entry[0], entry[1]])
	var signature = "|".join(signature_parts)
	if signature == _player_status_signature:
		return
	_player_status_signature = signature

	_hide_status_tooltip()
	for child in _player_status_row.get_children():
		child.queue_free()
	for entry in entries:
		var status_id: String = entry[0]
		var value: int = entry[1]
		var text = str(value)
		if not StatusBadges.SPECS.has(status_id):
			text = "%s %d" % [_status_name(status_id), value]
		var badge = StatusBadges.make_badge(status_id, text)
		badge.mouse_entered.connect(func(): _show_status_tooltip({status_id: value}, badge))
		badge.mouse_exited.connect(_hide_status_tooltip)
		_player_status_row.add_child(badge)

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

func _show_status_tooltip(statuses: Dictionary, anchor: Control) -> void:
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
	# global系は実ピクセル、size系はデザイン座標なのでUIスケールを掛けて揃える
	var ui_scale = anchor.get_global_transform().get_scale()
	var global_pos = anchor.global_position + Vector2(0, (anchor.size.y + 8.0) * ui_scale.y)
	var viewport_size = get_viewport_rect().size
	var real_size = panel_size * ui_scale
	global_pos.x = clampf(global_pos.x, 8.0, maxf(8.0, viewport_size.x - real_size.x - 8.0))
	global_pos.y = clampf(global_pos.y, 8.0, maxf(8.0, viewport_size.y - real_size.y - 8.0))
	_status_tooltip_panel.global_position = global_pos
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
	_enemy_next_action = EnemyAI.decide_next_action(_enemy_data, _enemy_node, _enemy_turn_idx + 1)
	if _enemy_next_action.is_empty():
		return
	_enemy_node.set_intent(_enemy_next_action)

# ═══════════════════════════════════════════════════════════════════════════════
#  Card Hand
# ═══════════════════════════════════════════════════════════════════════════════

func _refresh_hand(slide_from_current: bool = false) -> void:
	# カード使用後はその場からスライドして詰める。ターン開始時などは配り直し演出。
	var old_positions: Array = []
	if slide_from_current:
		for cn in _card_nodes:
			if is_instance_valid(cn):
				old_positions.append(cn.position)
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
		if slide_from_current and i < old_positions.size():
			# 既存カードは元の位置から滑らかにスライド
			cn.position = Vector2(old_positions[i].x, HAND_Y)
			var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			t.tween_property(cn, "position:x", target_x, 0.16)
		else:
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

	# カード飛行演出 — 着弾した瞬間に効果が発生する
	if card_node:
		await _animate_card_flight(card_node, card_data)
	await _apply_effects(card_data)
	if card_data.get("type", "") == "attack" and not GameState.first_attack_used_this_combat:
		GameState.first_attack_used_this_combat = true
	if _player_turn and _enemy_node and _enemy_node.current_hp > 0 and GameState.player_hp > 0:
		_busy = false

func _animate_card_flight(card_node: Control, card_data: Dictionary) -> void:
	card_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_node.z_index = 25
	var is_attack = card_data.get("type", "") == "attack"
	var type_color: Color = {
		"attack": Color(0.95, 0.30, 0.26),
		"defense": Color(0.38, 0.58, 0.95),
	}.get(card_data.get("type", ""), Color(0.36, 0.80, 0.78))

	# 行き先: 敵を対象とする効果(ダメージ・敵へのデバフ)を含むなら敵へ、それ以外は自分へ
	var targets_enemy = false
	for effect in card_data.get("effects", []):
		match effect.get("type", ""):
			"damage", "damage_multi", "conditional_damage", "vulnerable_bonus_damage":
				targets_enemy = true
			"apply_status":
				if effect.get("target", "enemy") == "enemy":
					targets_enemy = true
	var target_point: Vector2
	if targets_enemy and _enemy_node:
		target_point = _enemy_node.position + Vector2(0, -90)
	elif _player_silhouette:
		target_point = _player_silhouette.position + Vector2(0, -40)
	else:
		target_point = Vector2(640, 320)

	# ① 掴み — わずかに拡大して光る
	var pop = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	pop.tween_property(card_node, "scale", card_node.scale * 1.15, 0.09)
	pop.parallel().tween_property(card_node, "modulate", Color(1.30, 1.24, 1.06), 0.09)
	pop.parallel().tween_property(card_node, "position:y", card_node.position.y - 14.0, 0.09)
	await pop.finished
	if not is_instance_valid(card_node):
		return

	# ② 飛行 — 弧を描いて縮小・回転しながら飛ぶ(毎回少しランダム)
	var start_pos = card_node.position
	var end_pos = target_point - Vector2(CARD_W * 0.5, CARD_H * 0.7)
	var ctrl = (start_pos + end_pos) * 0.5 + Vector2(randf_range(-50.0, 50.0), -70.0 - randf_range(0.0, 40.0))
	var fly = create_tween()
	fly.tween_method(func(t: float):
		if is_instance_valid(card_node):
			card_node.position = start_pos.lerp(ctrl, t).lerp(ctrl.lerp(end_pos, t), t)
	, 0.0, 1.0, 0.24).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	fly.parallel().tween_property(card_node, "scale", card_node.scale * 0.40, 0.24)
	fly.parallel().tween_property(card_node, "rotation", randf_range(-0.35, 0.35), 0.24)
	for i in 3:
		fly.parallel().tween_callback(_spawn_card_ghost.bind(card_node)).set_delay(0.05 + i * 0.06)
	await fly.finished
	if not is_instance_valid(card_node):
		return

	# ③ 着弾 — バースト+(攻撃なら)画面の微シェイク、カードは消える
	var burst = CombatVisuals.ImpactBurst.new()
	burst.color = type_color
	burst.position = target_point
	_battle_layer.add_child(burst)
	if is_attack:
		_shake_battle_layer()
	var out = create_tween()
	out.tween_property(card_node, "modulate:a", 0.0, 0.07)
	out.tween_callback(card_node.queue_free)

func _spawn_card_ghost(card_node: Control) -> void:
	if not is_instance_valid(card_node):
		return
	var ghost = card_node.duplicate(DUPLICATE_SCRIPTS)
	ghost.setup(card_node.card_data, 0, true, true)
	ghost.position = card_node.position
	ghost.scale = card_node.scale
	ghost.rotation = card_node.rotation
	ghost.z_index = 18
	ghost.modulate = Color(1, 1, 1, 0.30)
	_hand_container.add_child(ghost)
	var t = create_tween()
	t.tween_property(ghost, "modulate:a", 0.0, 0.22)
	t.tween_callback(ghost.queue_free)

func _shake_battle_layer(strength: float = 4.0) -> void:
	var t = create_tween()
	for i in 3:
		t.tween_property(_battle_layer, "position",
			Vector2(randf_range(-strength, strength), randf_range(-strength * 0.5, strength * 0.5)), 0.04)
	t.tween_property(_battle_layer, "position", Vector2.ZERO, 0.05)

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
	_refresh_hand(true)
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
	# 表示はバフ/デバフ(筋力・脱力・脆弱)のみ反映する。
	# 敵ブロックの吸収は一時的な状態なのでカードの数字には含めない。
	if not _enemy_node:
		return amount
	var actual = amount
	if _enemy_node.statuses.get("vulnerable", 0) > 0:
		actual = int(actual * 1.5)
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
	var effect = CombatVisuals.BlockShieldEffect.new()
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
		action = EnemyAI.decide_next_action(_enemy_data, _enemy_node, _enemy_turn_idx + 1)
	if action.is_empty():
		_end_enemy_turn()
		return

	_enemy_turn_idx += 1

	# Tick enemy statuses
	_enemy_node.tick_statuses()

	# 行動名の宣言(頭上に短く表示)
	_show_enemy_callout(action.get("desc", ""))

	match action.get("type", ""):
		"attack":
			var raw = _enemy_node.get_attack_value(action.get("value", 5))
			_log("敵の攻撃: %dダメージ。" % raw)
			_enemy_attack_animation(raw)
		"attack_buff":
			var raw = _enemy_node.get_attack_value(action.get("value", 5))
			var buff = action.get("buff", 1)
			_enemy_node.add_strength(buff)
			_spawn_enemy_aura(Color(1.0, 0.78, 0.28))
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
			_fly_curse_mote(Vector2(610, 600))
			_log(action.get("log", "敵は攻撃し、おじゃまカードを捨て札に混ぜた。"))
			_enemy_attack_animation(raw)
			return
		"attack_status":
			var status = action.get("status", "vulnerable")
			var amount = action.get("amount", 1)
			var raw = _enemy_node.get_attack_value(action.get("value", 0))
			GameState.apply_status(status, amount)
			_spawn_enemy_aura(Color(0.70, 0.45, 1.0), true)
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
			_spawn_enemy_block_effect()
			_log("敵は防御を固めた。ブロック%d。" % amount)
			var t = create_tween()
			t.tween_interval(0.8)
			t.tween_callback(_end_enemy_turn)
		"strength":
			var buff = action.get("buff", 1)
			_enemy_node.add_strength(buff)
			_spawn_enemy_aura(Color(1.0, 0.78, 0.28))
			_log("敵の力が増した。攻撃力+%d。" % buff)
			var t = create_tween()
			t.tween_interval(0.8)
			t.tween_callback(_end_enemy_turn)
		"block_strength":
			var block_amount = action.get("value", 5)
			var buff = action.get("buff", 1)
			_enemy_node.gain_block(block_amount)
			_enemy_node.add_strength(buff)
			_spawn_enemy_block_effect()
			_spawn_enemy_aura(Color(1.0, 0.78, 0.28))
			_log(action.get("log", "敵は防御を固め、攻撃力を上げた。"))
			var t = create_tween()
			t.tween_interval(0.8)
			t.tween_callback(_end_enemy_turn)
		"heal":
			var amount = action.get("value", 1)
			_enemy_node.heal(amount)
			_spawn_enemy_aura(Color(0.42, 0.90, 0.50))
			_log("敵はHPを%d回復した。" % amount)
			var t = create_tween()
			t.tween_interval(0.8)
			t.tween_callback(_end_enemy_turn)
		"heal_strength":
			var amount = action.get("value", 1)
			var buff = action.get("buff", 1)
			_enemy_node.heal(amount)
			_enemy_node.add_strength(buff)
			_spawn_enemy_aura(Color(0.42, 0.90, 0.50))
			_spawn_enemy_aura(Color(1.0, 0.78, 0.28))
			_log(action.get("log", "敵は回復し、攻撃力を上げた。"))
			var t = create_tween()
			t.tween_interval(0.8)
			t.tween_callback(_end_enemy_turn)
		"apply_status":
			var status = action.get("status", "weak")
			var amount = action.get("amount", 1)
			GameState.apply_status(status, amount)
			_spawn_enemy_aura(Color(0.70, 0.45, 1.0), true)
			_log("敵の呪い。%sを%d受けた。" % [_status_name(status), amount])
			var t = create_tween()
			t.tween_interval(0.8)
			t.tween_callback(_end_enemy_turn)
		"add_temp_draw":
			var card_id = action.get("card_id", "")
			var amount = action.get("amount", 1)
			GameState.add_temporary_card_to_draw_pile(card_id, amount)
			_fly_curse_mote(Vector2(610, 600))
			_log(action.get("log", "敵はおじゃまカードを山札に混ぜた。"))
			var t = create_tween()
			t.tween_interval(0.8)
			t.tween_callback(_end_enemy_turn)
		"add_temp_discard":
			var card_id = action.get("card_id", "")
			var amount = action.get("amount", 1)
			GameState.add_temporary_card_to_discard_pile(card_id, amount)
			_fly_curse_mote(Vector2(610, 600))
			_log(action.get("log", "敵はおじゃまカードを捨て札に混ぜた。"))
			var t = create_tween()
			t.tween_interval(0.8)
			t.tween_callback(_end_enemy_turn)
		"add_temp_cards":
			for item in action.get("draw", []):
				GameState.add_temporary_card_to_draw_pile(item.get("id", ""), item.get("amount", 1))
			for item in action.get("discard", []):
				GameState.add_temporary_card_to_discard_pile(item.get("id", ""), item.get("amount", 1))
			_fly_curse_mote(Vector2(610, 600))
			_log(action.get("log", "敵は複数のおじゃまカードを混ぜた。"))
			var t = create_tween()
			t.tween_interval(0.8)
			t.tween_callback(_end_enemy_turn)
		_:
			_end_enemy_turn()

func _enemy_attack_animation(damage: int) -> void:
	# ①溜め(後退+沈み) → ②踏み込み → ③命中(閃光+シェイク+赤明滅) → 戻り
	var start_x = _enemy_node.position.x
	var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	t.tween_property(_enemy_node, "position:x", start_x + 26, 0.18)
	t.parallel().tween_property(_enemy_node, "modulate", Color(0.55, 0.50, 0.62), 0.18)
	t.tween_interval(0.06)
	t.tween_property(_enemy_node, "position:x", start_x - 96, 0.13) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.parallel().tween_property(_enemy_node, "modulate", Color.WHITE, 0.10)
	t.tween_callback(func():
		_play_attack_impact()
		_damage_player_with_effect(damage)
		if GameState.player_hp <= 0:
			_on_player_died()
	)
	t.tween_property(_enemy_node, "position:x", start_x, 0.24)
	t.tween_interval(0.25)
	t.tween_callback(func():
		if GameState.player_hp > 0:
			_end_enemy_turn()
	)

func _enemy_multi_attack_animation(damage: int, times: int) -> void:
	# 溜めは1回、踏み込み+命中をヒット数ぶん連発する
	var start_x = _enemy_node.position.x
	var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	t.tween_property(_enemy_node, "position:x", start_x + 26, 0.16)
	t.parallel().tween_property(_enemy_node, "modulate", Color(0.55, 0.50, 0.62), 0.16)
	t.tween_property(_enemy_node, "modulate", Color.WHITE, 0.08)
	for i in times:
		t.tween_property(_enemy_node, "position:x", start_x - 80, 0.12) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		t.tween_callback(func():
			_play_attack_impact(5.0, 0.32)
			_damage_player_with_effect(damage, Vector2(0, -154 - randf_range(0, 30)))
		)
		t.tween_property(_enemy_node, "position:x", start_x - 30, 0.14)
		t.tween_interval(0.05)
	t.tween_property(_enemy_node, "position:x", start_x, 0.20)
	t.tween_interval(0.25)
	t.tween_callback(func():
		if GameState.player_hp <= 0:
			_on_player_died()
		else:
			_end_enemy_turn()
	)

func _play_attack_impact(shake_strength: float = 7.0, vignette_strength: float = 0.45) -> void:
	if _player_silhouette:
		var slash = CombatVisuals.SlashFlash.new()
		slash.position = _player_silhouette.position + Vector2(0, -30)
		_battle_layer.add_child(slash)
	_shake_battle_layer(shake_strength)
	ScreenFx.pulse_vignette(Color(0.78, 0.07, 0.05), vignette_strength, 0.40)

func _show_enemy_callout(text: String) -> void:
	if text.is_empty() or not _enemy_node:
		return
	var lbl = Label.new()
	lbl.text = text
	lbl.size = Vector2(280, 30)
	lbl.position = _enemy_node.position + Vector2(-140, -292)
	lbl.pivot_offset = Vector2(140, 15)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 21)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.42))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.92))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	lbl.modulate.a = 0.0
	lbl.scale = Vector2(0.8, 0.8)
	_battle_layer.add_child(lbl)
	var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(lbl, "modulate:a", 1.0, 0.12)
	t.parallel().tween_property(lbl, "scale", Vector2.ONE, 0.14)
	t.tween_interval(0.55)
	t.tween_property(lbl, "modulate:a", 0.0, 0.22)
	t.parallel().tween_property(lbl, "position:y", lbl.position.y - 16.0, 0.22)
	t.tween_callback(lbl.queue_free)

func _spawn_enemy_aura(color: Color, target_player: bool = false) -> void:
	var aura = CombatVisuals.AuraEffect.new()
	aura.color = color
	if target_player and _player_silhouette:
		aura.position = _player_silhouette.position + Vector2(0, 120)
	elif _enemy_node:
		aura.position = _enemy_node.position + Vector2(0, 110)
	else:
		return
	_battle_layer.add_child(aura)

func _spawn_enemy_block_effect() -> void:
	if not _enemy_node:
		return
	var effect = CombatVisuals.BlockShieldEffect.new()
	effect.position = _enemy_node.position + Vector2(0, -40)
	effect.scale = Vector2(0.78, 0.78)
	effect.modulate.a = 0.0
	_battle_layer.add_child(effect)
	var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(effect, "modulate:a", 0.58, 0.08)
	t.parallel().tween_property(effect, "scale", Vector2(1.02, 1.02), 0.18)
	t.tween_property(effect, "modulate:a", 0.0, 0.28)
	t.tween_callback(effect.queue_free)

func _fly_curse_mote(target_point: Vector2) -> void:
	# 紫の光弾が敵からプレイヤーの手札方向へ飛ぶ(お邪魔カード混入の可視化)
	if not _enemy_node:
		return
	var mote = CombatVisuals.GlowMote.new()
	var start = _enemy_node.position + Vector2(0, -60)
	mote.position = start
	_battle_layer.add_child(mote)
	var ctrl = (start + target_point) * 0.5 + Vector2(randf_range(-60.0, 60.0), -90.0)
	var t = create_tween()
	t.tween_method(func(s: float):
		if is_instance_valid(mote):
			mote.position = start.lerp(ctrl, s).lerp(ctrl.lerp(target_point, s), s)
	, 0.0, 1.0, 0.34).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	t.tween_callback(func():
		var burst = CombatVisuals.ImpactBurst.new()
		burst.color = Color(0.70, 0.45, 1.0)
		burst.position = target_point
		_battle_layer.add_child(burst)
		mote.queue_free()
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
		var number_pos = (_player_silhouette.position if _player_silhouette else Vector2(290, 334)) + number_offset
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

func _decorate_menu_button(btn: Button, icon_path: String) -> void:
	if ResourceLoader.exists(icon_path):
		btn.icon = load(icon_path)
		btn.expand_icon = true
		btn.add_theme_color_override("icon_normal_color", Color(0.78, 0.66, 0.42, 0.85))
		btn.add_theme_color_override("icon_hover_color", Color(0.95, 0.84, 0.58, 1.0))
		btn.add_theme_color_override("icon_pressed_color", Color(0.95, 0.84, 0.58, 1.0))
		btn.add_theme_constant_override("icon_max_width", 20)
		btn.add_theme_constant_override("h_separation", 7)
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	var frame = CombatVisuals.FrameOverlay.new()
	frame.frame_alpha = 0.50
	frame.corner = 7.0
	btn.add_child(frame)

func _make_button(text: String, position: Vector2, size: Vector2) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.position = position - size / 2.0
	btn.size = size
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color(0.94, 0.88, 1.0))

	var style_n = StyleBoxFlat.new()
	style_n.bg_color = Color(0.085, 0.040, 0.175, 0.97)
	style_n.border_color = Color(0.46, 0.26, 0.70, 0.62)
	style_n.set_border_width_all(1)
	style_n.set_corner_radius_all(5)
	style_n.shadow_color = Color(0.40, 0.14, 0.72, 0.22)
	style_n.shadow_size = 5
	btn.add_theme_stylebox_override("normal", style_n)

	var style_h = StyleBoxFlat.new()
	style_h.bg_color = Color(0.155, 0.070, 0.32, 0.98)
	style_h.border_color = Color(0.74, 0.46, 0.98, 0.85)
	style_h.set_border_width_all(1)
	style_h.set_corner_radius_all(5)
	style_h.shadow_color = Color(0.56, 0.24, 0.92, 0.40)
	style_h.shadow_size = 9
	btn.add_theme_stylebox_override("hover", style_h)
	btn.add_theme_stylebox_override("pressed", style_h)

	var style_d = StyleBoxFlat.new()
	style_d.bg_color = Color(0.055, 0.045, 0.115, 0.92)
	style_d.border_color = Color(0.22, 0.16, 0.34, 0.50)
	style_d.set_border_width_all(1)
	style_d.set_corner_radius_all(5)
	btn.add_theme_stylebox_override("disabled", style_d)
	return btn
