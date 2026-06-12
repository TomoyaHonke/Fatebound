extends Control

const COMBAT_SCENE        = "res://scenes/combat/CombatScene.tscn"
const EVENT_SCENE         = "res://scenes/ui/EventScreen.tscn"
const REST_SCENE          = "res://scenes/ui/RestScreen.tscn"
const TREASURE_SCENE      = "res://scenes/ui/TreasureScreen.tscn"
const MAIN_SCENE          = "res://scenes/Main.tscn"
const DECK_VIEWER_SCENE   = "res://scenes/ui/DeckViewer.tscn"
const RELIC_VIEWER_SCENE  = "res://scenes/ui/RelicViewer.tscn"
const RELIC_CHOICE_SCENE  = "res://scenes/ui/RelicChoiceScreen.tscn"

const CombatVisuals = preload("res://scenes/combat/CombatVisuals.gd")
const OrnateFrame   = preload("res://scenes/ui/OrnateFrame.gd")

const C_BG     = Color(0.018, 0.014, 0.026)
const C_GOLD   = Color(0.86, 0.72, 0.34)
const C_PURPLE = Color(0.55, 0.20, 0.90)
const C_TEXT   = Color(0.88, 0.82, 1.00)
const NODE_R   = 28.0
const GRAPH_VIEW_POS := Vector2(190, 58)
const GRAPH_VIEW_SIZE := Vector2(890, 654)
const GRAPH_CONTENT_SIZE := Vector2(1080, 1120)
const GRAPH_SCROLL_STEP := 54.0
const GRAPH_DRAG_THRESHOLD := 8.0
const GRAPH_NODE_CLICK_R := NODE_R + 6.0
const TOP_RIGHT_BUTTON_POS := Vector2(1054, 11)
const TOP_RIGHT_BUTTON_SIZE := Vector2(104, 34)
const TOP_RIGHT_BUTTON_GAP := 10

var _graph_viewport: Control
var _graph_content: Control
var _canvas: _MapCanvas
var _node_btns: Dictionary = {}  # node_id → _NodeButton (Control)
var _selected_id: String = ""
var _info_title: Label
var _info_desc: Label
var _enter_btn: Button
var _hp_label: Label
var _relic_strip: HBoxContainer
var _relic_strip_signature: String = ""
var _deck_viewer: Control
var _relic_viewer: Control
var _phase: float = 0.0
var _graph_pan_active: bool = false
var _graph_pan_started: bool = false
var _graph_pan_button: int = 0
var _graph_pan_start_mouse: Vector2 = Vector2.ZERO
var _graph_pan_start_pos: Vector2 = Vector2.ZERO
var _hovered_graph_node_id: String = ""
var _is_moving: bool = false


func _ready() -> void:
	_apply_screen_scale()
	_build_ui()
	_refresh()
	_center_graph_on_current()
	SaveManager.save_run()

func _apply_screen_scale() -> void:
	var scaler = get_node_or_null("/root/ScreenScale")
	if scaler and scaler.has_method("apply"):
		scaler.apply(self)


func _process(delta: float) -> void:
	_phase += delta
	if _canvas:
		_canvas.phase = _phase
		_canvas.queue_redraw()
	for node_id in _node_btns:
		var btn: _NodeButton = _node_btns[node_id]
		if btn.state in ["selectable", "current"]:
			btn.phase = _phase
			btn.queue_redraw()


# ─── UI construction ──────────────────────────────────────────────────────────

func _build_ui() -> void:
	var map_bg_key := "act%d_map" % GameState.current_act if GameState.current_act >= 1 and GameState.current_act <= 3 else "act1_map"
	_add_background(map_bg_key, Color(0, 0, 0, 0.36))
	_build_graph_viewport()

	_build_top_bar()
	_build_legend()
	_build_info_panel()
	_build_node_buttons()
	_build_top_right_buttons()
	_build_deck_viewer()
	_build_relic_viewer()


func _build_graph_viewport() -> void:
	_graph_viewport = Control.new()
	_graph_viewport.name = "GraphViewport"
	_graph_viewport.position = GRAPH_VIEW_POS
	_graph_viewport.size = GRAPH_VIEW_SIZE
	_graph_viewport.clip_contents = true
	_graph_viewport.mouse_filter = Control.MOUSE_FILTER_STOP
	_graph_viewport.gui_input.connect(_on_graph_viewport_input)
	add_child(_graph_viewport)

	_graph_content = Control.new()
	_graph_content.name = "GraphContent"
	_graph_content.position = Vector2.ZERO
	_graph_content.size = GRAPH_CONTENT_SIZE
	_graph_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_graph_viewport.add_child(_graph_content)

	_canvas = _MapCanvas.new()
	_canvas.content_size = GRAPH_CONTENT_SIZE
	_graph_content.add_child(_canvas)


func _build_top_bar() -> void:
	# Decorative header strip (Node2D, draws at position 0,0)
	var strip = _TopStrip.new()
	add_child(strip)

	var title = Label.new()
	title.text = "マップ"
	title.position = Vector2(0, 10)
	title.size = Vector2(1280, 38)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", C_GOLD)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	add_child(title)

	_hp_label = Label.new()
	_hp_label.position = Vector2(16, 14)
	_hp_label.size = Vector2(130, 26)
	_hp_label.add_theme_font_size_override("font_size", 15)
	_hp_label.add_theme_color_override("font_color", Color(0.90, 0.55, 0.55))
	add_child(_hp_label)

	# 所持レリックの常時表示(HPの右)
	_relic_strip = HBoxContainer.new()
	_relic_strip.name = "RelicStrip"
	_relic_strip.position = Vector2(150, 11)
	_relic_strip.add_theme_constant_override("separation", 5)
	add_child(_relic_strip)


func _build_legend() -> void:
	var panel = _make_panel(Vector2(10, 58), Vector2(174, 298))
	add_child(panel)

	var lbl_title = Label.new()
	lbl_title.text = "凡例"
	lbl_title.position = Vector2(0, 7)
	lbl_title.size = Vector2(174, 22)
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.add_theme_font_size_override("font_size", 13)
	lbl_title.add_theme_color_override("font_color", Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.85))
	panel.add_child(lbl_title)

	var entries = [
		["normal_battle", "戦闘"],
		["elite_battle",  "強敵"],
		["rest",          "休憩"],
		["event",         "イベント"],
		["treasure",      "宝箱"],
		["boss",          "ボス"],
	]
	for i in entries.size():
		var row_icon = _NodeButton.new()
		row_icon.node_id = ""
		row_icon.node_type = entries[i][0]
		row_icon.state = "selectable"
		row_icon.interactive = false
		row_icon.position = Vector2(10, 32 + i * 40)
		row_icon.size = Vector2(28, 28)
		panel.add_child(row_icon)

		var row_lbl = Label.new()
		row_lbl.text = entries[i][1]
		row_lbl.position = Vector2(44, 36 + i * 40)
		row_lbl.size = Vector2(126, 22)
		row_lbl.add_theme_font_size_override("font_size", 13)
		row_lbl.add_theme_color_override("font_color", Color(0.74, 0.68, 0.90))
		panel.add_child(row_lbl)


func _build_info_panel() -> void:
	var panel = _make_panel(Vector2(1092, 58), Vector2(180, 390))
	add_child(panel)

	var header = Label.new()
	header.text = "次の目的地"
	header.position = Vector2(0, 8)
	header.size = Vector2(180, 20)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 11)
	header.add_theme_color_override("font_color", Color(C_PURPLE.r, C_PURPLE.g, C_PURPLE.b, 0.80))
	panel.add_child(header)

	_info_title = Label.new()
	_info_title.position = Vector2(8, 30)
	_info_title.size = Vector2(164, 32)
	_info_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_title.add_theme_font_size_override("font_size", 22)
	_info_title.add_theme_color_override("font_color", C_GOLD)
	_info_title.text = "─"
	panel.add_child(_info_title)

	_info_desc = Label.new()
	_info_desc.position = Vector2(10, 68)
	_info_desc.size = Vector2(160, 150)
	_info_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_desc.add_theme_font_size_override("font_size", 13)
	_info_desc.add_theme_color_override("font_color", Color(0.70, 0.66, 0.86))
	_info_desc.text = "ノードを\n選択してください。"
	panel.add_child(_info_desc)

	_enter_btn = _make_button("進む", Vector2(90, 238), Vector2(138, 44))
	_enter_btn.visible = false
	_enter_btn.pressed.connect(_on_enter_pressed)
	var enter_frame = CombatVisuals.FrameOverlay.new()
	enter_frame.frame_alpha = 0.55
	enter_frame.corner = 8.0
	_enter_btn.add_child(enter_frame)
	panel.add_child(_enter_btn)


func _build_node_buttons() -> void:
	for node_id in GameState.MAP_NODES:
		if _is_hidden_graph_node(node_id):
			continue
		var data: Dictionary = GameState.MAP_NODES[node_id]
		var pos: Vector2 = data.get("pos", Vector2.ZERO)
		var btn = _NodeButton.new()
		btn.node_id    = node_id
		btn.node_type  = data.get("type", "normal_battle")
		btn.interactive = true
		btn.position   = pos - Vector2(NODE_R, NODE_R)
		btn.size       = Vector2(NODE_R * 2.0, NODE_R * 2.0)
		btn.node_clicked.connect(_on_node_clicked)
		_graph_content.add_child(btn)
		_node_btns[node_id] = btn
		# 入場演出: マップ奥から手前へ波及するフェードイン
		btn.modulate.a = 0.0
		var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		t.tween_property(btn, "modulate:a", 1.0, 0.25).set_delay(0.05 + pos.y * 0.0005)


func _build_top_right_buttons() -> void:
	var container = HBoxContainer.new()
	container.name = "TopRightButtons"
	container.position = TOP_RIGHT_BUTTON_POS
	container.size = Vector2(
		TOP_RIGHT_BUTTON_SIZE.x * 2.0 + TOP_RIGHT_BUTTON_GAP,
		TOP_RIGHT_BUTTON_SIZE.y
	)
	container.add_theme_constant_override("separation", TOP_RIGHT_BUTTON_GAP)
	add_child(container)

	var relic_btn = _make_top_right_button("レリック", "RelicButton")
	relic_btn.pressed.connect(_on_relic_pressed)
	_decorate_menu_button(relic_btn, "res://assets/ui/icons/relic.svg")
	container.add_child(relic_btn)

	var deck_btn = _make_top_right_button("デッキ", "DeckButton")
	deck_btn.pressed.connect(_on_deck_pressed)
	_decorate_menu_button(deck_btn, "res://assets/ui/icons/deck.svg")
	container.add_child(deck_btn)

func _make_top_right_button(text: String, node_name: String) -> Button:
	var btn = _make_button(text, TOP_RIGHT_BUTTON_SIZE / 2.0, TOP_RIGHT_BUTTON_SIZE)
	btn.name = node_name
	btn.custom_minimum_size = TOP_RIGHT_BUTTON_SIZE
	btn.add_theme_font_size_override("font_size", 15)
	return btn

func _build_deck_viewer() -> void:
	var viewer_res = load(DECK_VIEWER_SCENE)
	_deck_viewer = viewer_res.instantiate()
	add_child(_deck_viewer)

func _build_relic_viewer() -> void:
	var res = load(RELIC_VIEWER_SCENE)
	_relic_viewer = res.instantiate()
	add_child(_relic_viewer)


# ─── Map logic ────────────────────────────────────────────────────────────────

func _refresh() -> void:
	var visited   = GameState.map_visited_nodes
	var available = GameState.map_available_nodes
	var current   = GameState.map_current_node_id

	for node_id in _node_btns:
		var btn: _NodeButton = _node_btns[node_id]
		if node_id == current and visited.has(node_id):
			btn.state = "current"
		elif visited.has(node_id):
			btn.state = "visited"
		elif _can_move_to_node(node_id):
			btn.state = "selectable"
		else:
			btn.state = "locked"
		btn.is_selected = (node_id == _selected_id)
		btn.queue_redraw()

	if _canvas:
		_canvas.visited_nodes   = visited
		_canvas.available_nodes = available
		_canvas.current_node    = current
		_canvas.queue_redraw()

	if _hp_label:
		_hp_label.text = "♥  %d / %d" % [GameState.player_hp, GameState.player_max_hp]

	_refresh_relic_strip()

func _refresh_relic_strip() -> void:
	if not _relic_strip:
		return
	var signature = "|".join(GameState.owned_relic_ids)
	if signature == _relic_strip_signature:
		return
	_relic_strip_signature = signature
	for child in _relic_strip.get_children():
		child.queue_free()
	for relic_id in GameState.owned_relic_ids:
		var m = preload("res://scenes/ui/RelicMedallion.gd").new()
		_relic_strip.add_child(m)
		m.setup(relic_id, 30.0, true)


func _on_node_clicked(node_id: String) -> void:
	if _is_moving:
		return
	if not _can_move_to_node(node_id):
		return
	_selected_id = node_id
	var data: Dictionary = GameState.MAP_NODES.get(node_id, {})
	var ntype: String    = data.get("type", "normal_battle")
	_info_title.text = _type_label(ntype)
	_info_desc.text  = _type_desc(ntype)
	_refresh()
	_on_enter_pressed()


func _on_enter_pressed() -> void:
	if _is_moving:
		return
	if _selected_id.is_empty():
		return
	if not _can_move_to_node(_selected_id):
		return
	_is_moving = true
	_enter_btn.visible = false
	_enter_btn.disabled = true
	var data: Dictionary = GameState.MAP_NODES.get(_selected_id, {})
	var ntype: String    = data.get("type", "normal_battle")

	var target := ""
	match ntype:
		"start":
			if GameState.initial_relic_chosen:
				_complete_start_node()
			else:
				_show_relic_choice_for_node("start")
			return
		"starter_relic", "relic", "initial_relic", "relic_reward":
			if GameState.initial_relic_chosen:
				_complete_relic_node(_selected_id)
			else:
				_show_relic_choice_for_node(_selected_id)
			return
		"normal_battle":
			GameState.enter_map_node(_selected_id)
			GameState.set_map_encounter_enemy(GameState.choose_enemy_for_map_node(ntype, _selected_id))
			GameState.map_encounter_is_boss   = false
			target = COMBAT_SCENE
		"elite_battle":
			GameState.enter_map_node(_selected_id)
			GameState.set_map_encounter_enemy(GameState.choose_enemy_for_map_node(ntype, _selected_id))
			GameState.map_encounter_is_boss   = false
			target = COMBAT_SCENE
		"boss":
			GameState.enter_map_node(_selected_id)
			GameState.set_map_encounter_enemy(GameState.choose_enemy_for_map_node(ntype, _selected_id))
			GameState.map_encounter_is_boss   = true
			target = COMBAT_SCENE
		"rest":
			GameState.enter_map_node(_selected_id)
			target = REST_SCENE
		"event":
			GameState.enter_map_node(_selected_id)
			target = EVENT_SCENE
		"treasure":
			GameState.enter_map_node(_selected_id)
			target = TREASURE_SCENE

	if target.is_empty():
		_is_moving = false
		_enter_btn.disabled = false
		return
	var t = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "modulate:a", 0.0, 0.38)
	t.tween_callback(func(): get_tree().change_scene_to_file(target))


func _on_deck_pressed() -> void:
	if _deck_viewer and _deck_viewer.has_method("show_deck"):
		_deck_viewer.show_deck(GameState.deck)

func _on_relic_pressed() -> void:
	if _relic_viewer and _relic_viewer.has_method("show_relics"):
		_relic_viewer.show_relics()

func _show_relic_choice_for_node(node_id: String) -> void:
	_enter_btn.disabled = true
	var res = load(RELIC_CHOICE_SCENE)
	var screen = res.instantiate()
	add_child(screen)
	screen.choice_made.connect(func():
		screen.queue_free()
		_complete_relic_node(node_id)
		_enter_btn.disabled = false
	)
	screen.show_choice()

func _complete_start_node() -> void:
	GameState.enter_map_node("start")
	GameState.complete_map_node("start")
	_finish_map_node_completion()

func _complete_relic_node(node_id: String) -> void:
	if node_id.is_empty():
		node_id = "starter_relic"
	GameState.enter_map_node(node_id)
	GameState.complete_map_node(node_id)
	_finish_map_node_completion()

func _finish_map_node_completion() -> void:
	SaveManager.save_run()
	_selected_id = ""
	_info_title.text = "─"
	_info_desc.text = "次の目的地を\n選択してください。"
	_enter_btn.visible = false
	_enter_btn.disabled = false
	_is_moving = false
	_refresh()
	_center_graph_on_current()


func _on_graph_viewport_input(event: InputEvent) -> void:
	if _deck_viewer and _deck_viewer.visible:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_pan_graph(Vector2(0, GRAPH_SCROLL_STEP))
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_pan_graph(Vector2(0, -GRAPH_SCROLL_STEP))
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				_graph_pan_active = true
				_graph_pan_started = false
				_graph_pan_button = event.button_index
				_graph_pan_start_mouse = event.position
				_graph_pan_start_pos = _graph_content.position
			else:
				var was_click = _graph_pan_active and not _graph_pan_started and _graph_pan_button == MOUSE_BUTTON_LEFT
				_graph_pan_active = false
				_graph_pan_started = false
				_graph_pan_button = 0
				if was_click:
					var node_id = _hit_test_graph_node(event.position)
					if not node_id.is_empty():
						_on_node_clicked(node_id)
						get_viewport().set_input_as_handled()
	if event is InputEventMouseMotion:
		_update_graph_hover(event.position)
	if event is InputEventMouseMotion and _graph_pan_active:
		var delta = event.position - _graph_pan_start_mouse
		if delta.length() >= GRAPH_DRAG_THRESHOLD:
			_graph_pan_started = true
		if _graph_pan_started:
			_set_graph_position(_graph_pan_start_pos + delta)
			_update_graph_hover(event.position)
			get_viewport().set_input_as_handled()


func _pan_graph(delta: Vector2) -> void:
	if not _graph_content:
		return
	_set_graph_position(_graph_content.position + delta)


func _set_graph_position(pos: Vector2) -> void:
	if not _graph_content:
		return
	_graph_content.position = Vector2(
		_clamp_graph_axis(pos.x, GRAPH_VIEW_SIZE.x, GRAPH_CONTENT_SIZE.x),
		_clamp_graph_axis(pos.y, GRAPH_VIEW_SIZE.y, GRAPH_CONTENT_SIZE.y)
	)
	if _canvas:
		_canvas.queue_redraw()


func _clamp_graph_axis(value: float, viewport_size: float, content_size: float) -> float:
	if content_size <= viewport_size:
		return (viewport_size - content_size) * 0.5
	return clampf(value, viewport_size - content_size, 0.0)


func _center_graph_on_current() -> void:
	if not _graph_content:
		return
	var points: Array = []
	var current_data: Dictionary = GameState.MAP_NODES.get(GameState.map_current_node_id, {})
	if not current_data.is_empty():
		points.append(current_data.get("pos", GRAPH_CONTENT_SIZE * 0.5))
	for node_id in GameState.map_available_nodes:
		var data: Dictionary = GameState.MAP_NODES.get(node_id, {})
		if not data.is_empty():
			points.append(data.get("pos", GRAPH_CONTENT_SIZE * 0.5))
	if points.is_empty():
		points.append(Vector2(GRAPH_CONTENT_SIZE.x * 0.5, GRAPH_CONTENT_SIZE.y - 80.0))

	var center = Vector2.ZERO
	for point in points:
		center += point
	center /= float(points.size())
	_set_graph_position(GRAPH_VIEW_SIZE * 0.5 - center)


func _viewport_to_graph_pos(viewport_pos: Vector2) -> Vector2:
	if not _graph_content:
		return viewport_pos
	return viewport_pos - _graph_content.position


func _hit_test_graph_node(viewport_pos: Vector2) -> String:
	var graph_pos = _viewport_to_graph_pos(viewport_pos)
	var best_id := ""
	var best_dist := INF
	for node_id in GameState.MAP_NODES:
		if _is_hidden_graph_node(node_id):
			continue
		var data: Dictionary = GameState.MAP_NODES[node_id]
		var pos: Vector2 = data.get("pos", Vector2.ZERO)
		var dist = graph_pos.distance_to(pos)
		if dist <= GRAPH_NODE_CLICK_R and dist < best_dist:
			best_id = node_id
			best_dist = dist
	return best_id

func _is_hidden_graph_node(node_id: String) -> bool:
	return node_id == "start"


func _can_move_to_node(node_id: String) -> bool:
	if not GameState.map_available_nodes.has(node_id):
		return false
	if node_id == "start":
		return true
	var current_data: Dictionary = GameState.MAP_NODES.get(GameState.map_current_node_id, {})
	return current_data.get("connections", []).has(node_id)


func _update_graph_hover(viewport_pos: Vector2) -> void:
	var node_id = _hit_test_graph_node(viewport_pos)
	if node_id == _hovered_graph_node_id:
		return
	if _node_btns.has(_hovered_graph_node_id):
		_node_btns[_hovered_graph_node_id].set_hovered(false)
	_hovered_graph_node_id = node_id
	if _node_btns.has(_hovered_graph_node_id):
		_node_btns[_hovered_graph_node_id].set_hovered(true)


# ─── Helpers ─────────────────────────────────────────────────────────────────

func _type_label(t: String) -> String:
	match t:
		"normal_battle": return "戦闘"
		"elite_battle":  return "強敵"
		"rest":          return "休憩"
		"event":         return "イベント"
		"treasure":      return "宝箱"
		"boss":          return "ボス"
		"start":         return "開始"
		"starter_relic", "relic", "initial_relic", "relic_reward": return "レリック"
		_: return "？"

func _type_desc(t: String) -> String:
	match t:
		"start":         return "運命に導かれた最初の遺物を選びます。"
		"starter_relic", "relic", "initial_relic", "relic_reward": return "運命に導かれた最初の遺物を選びます。"
		"normal_battle": return "通常の敵と戦う。勝利すると報酬カードを選べる。"
		"elite_battle":  return "強力な精鋭との戦い。危険だが旅を有利にする。"
		"rest":          return "安全な場所で休む。\nHPを30%回復できる。"
		"event":         return "謎めいた遭遇が待ち受ける。運命を試せ。"
		"treasure":      return "宝が眠っている。\n道中の助けになるだろう。"
		"boss":          return "最終決戦。光の英雄を倒し、影の旅を終わらせよ。"
		_: return ""

func _make_panel(pos: Vector2, sz: Vector2) -> Panel:
	var panel = Panel.new()
	panel.position = pos
	panel.size = sz
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.030, 0.026, 0.058, 0.92)
	style.set_border_width_all(0)
	style.set_corner_radius_all(2)
	panel.add_theme_stylebox_override("panel", style)
	var frame = CombatVisuals.FrameOverlay.new()
	frame.frame_alpha = 0.70
	frame.corner = 10.0
	panel.add_child(frame)
	return panel

func _make_button(text: String, center: Vector2, sz: Vector2) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.position = center - sz / 2.0
	btn.size = sz
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color(0.94, 0.88, 1.0))
	var sn = StyleBoxFlat.new()
	sn.bg_color = Color(0.085, 0.040, 0.175, 0.97)
	sn.border_color = Color(0.46, 0.26, 0.70, 0.62)
	sn.set_border_width_all(1)
	sn.set_corner_radius_all(5)
	sn.shadow_color = Color(0.40, 0.14, 0.72, 0.22)
	sn.shadow_size = 5
	btn.add_theme_stylebox_override("normal", sn)
	var sh = StyleBoxFlat.new()
	sh.bg_color = Color(0.155, 0.070, 0.32, 0.98)
	sh.border_color = Color(0.74, 0.46, 0.98, 0.85)
	sh.set_border_width_all(1)
	sh.set_corner_radius_all(5)
	sh.shadow_color = Color(0.56, 0.24, 0.92, 0.40)
	sh.shadow_size = 9
	btn.add_theme_stylebox_override("hover", sh)
	btn.add_theme_stylebox_override("pressed", sh)
	return btn

func _decorate_menu_button(btn: Button, icon_path: String) -> void:
	if ResourceLoader.exists(icon_path):
		btn.icon = load(icon_path)
		btn.expand_icon = true
		btn.add_theme_color_override("icon_normal_color", Color(0.78, 0.66, 0.42, 0.85))
		btn.add_theme_color_override("icon_hover_color", Color(0.95, 0.84, 0.58, 1.0))
		btn.add_theme_color_override("icon_pressed_color", Color(0.95, 0.84, 0.58, 1.0))
		btn.add_theme_constant_override("icon_max_width", 18)
		btn.add_theme_constant_override("h_separation", 6)
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	var frame = CombatVisuals.FrameOverlay.new()
	frame.frame_alpha = 0.50
	frame.corner = 7.0
	btn.add_child(frame)

func _add_background(background_key: String, overlay_color: Color) -> void:
	var bg = TextureRect.new()
	bg.name = "MapBackground"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.texture = GameState.load_background_texture(GameState.get_background_path(background_key))
	if bg.texture == null:
		bg.modulate = C_BG
	add_child(bg)

	var overlay = ColorRect.new()
	overlay.name = "MapBackgroundOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = overlay_color
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

# ═══════════════════════════════════════════════════════════════════════════════
#  Inner node classes
# ═══════════════════════════════════════════════════════════════════════════════

class _TopStrip extends Node2D:
	const OrnateFrame = preload("res://scenes/ui/OrnateFrame.gd")

	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1280, 52), Color(0.025, 0.020, 0.048, 0.95), true)
		# 下端のブロンズ二重縁+中央の飾り
		draw_line(Vector2(0, 54), Vector2(1280, 54), Color(OrnateFrame.EDGE_DARK, 0.80), 2.0)
		draw_line(Vector2(0, 52), Vector2(1280, 52), Color(OrnateFrame.BRONZE, 0.62), 1.8)
		draw_line(Vector2(0, 50), Vector2(1280, 50), Color(OrnateFrame.BRONZE_BRIGHT, 0.18), 1.0)
		OrnateFrame.draw_gem(self, Vector2(640, 52), 5.0, 0.80)
		# 左右コーナー飾り
		OrnateFrame.draw_corner(self, Vector2(10, 10), Vector2(640, 26), 14.0, 0.62)
		OrnateFrame.draw_corner(self, Vector2(1270, 10), Vector2(640, 26), 14.0, 0.62)


class _MapCanvas extends Node2D:
	var visited_nodes:   Array = []
	var available_nodes: Array = []
	var current_node:    String = ""
	var phase: float = 0.0
	var content_size: Vector2 = Vector2.ZERO

	func _draw() -> void:
		_draw_connections()

	func _draw_atmosphere() -> void:
		for i in 4:
			var y = 200.0 + i * 120.0
			var drift = fmod(phase * (8.0 + i * 3.0) + i * 140.0, 900.0) - 450.0
			var pts = PackedVector2Array()
			for j in 7:
				pts.append(Vector2(200.0 + j * 130.0 + drift, y + sin(phase * 0.4 + j * 0.8 + i) * 14.0))
			for j in range(6, -1, -1):
				pts.append(Vector2(200.0 + j * 130.0 + drift, y + 36.0 + cos(phase * 0.35 + j * 0.7 + i) * 16.0))
			if pts.size() >= 3:
				draw_colored_polygon(pts, Color(0.14, 0.12, 0.22, 0.022))

	func _draw_connections() -> void:
		for node_id in GameState.MAP_NODES:
			if node_id == "start":
				continue
			var from_data: Dictionary = GameState.MAP_NODES[node_id]
			var from_pos: Vector2 = from_data.get("pos", Vector2.ZERO)
			for to_id in from_data.get("connections", []):
				if to_id == "start":
					continue
				var to_data: Dictionary = GameState.MAP_NODES.get(to_id, {})
				var to_pos: Vector2 = to_data.get("pos", Vector2.ZERO)

				var visited_from = visited_nodes.has(node_id)
				var visited_to   = visited_nodes.has(to_id)
				var avail_to     = available_nodes.has(to_id)

				if visited_from and visited_to:
					# 通った道: 落ち着いた金の実線
					draw_line(from_pos, to_pos, Color(0.05, 0.04, 0.09, 0.55), 5.0)
					draw_line(from_pos, to_pos, Color(0.84, 0.68, 0.32, 0.62), 2.2)
				elif visited_from and avail_to:
					# 行ける道: 明るい金の点線(流れるアニメ)
					draw_line(from_pos, to_pos, Color(0.90, 0.72, 0.28, 0.14), 7.0)
					_draw_dashed(from_pos, to_pos, Color(1.0, 0.84, 0.40, 0.92), 2.6)
				else:
					draw_line(from_pos, to_pos, Color(0.16, 0.12, 0.24, 0.32), 2.6)
					draw_line(from_pos, to_pos, Color(0.40, 0.32, 0.54, 0.26), 1.2)

	func _draw_dashed(from_pos: Vector2, to_pos: Vector2, color: Color, width: float) -> void:
		const DASH := 7.0
		const GAP := 6.0
		var dir = to_pos - from_pos
		var length = dir.length()
		if length < 1.0:
			return
		dir = dir / length
		var step = DASH + GAP
		var offset = fmod(phase * 18.0, step)
		var d = -offset
		while d < length:
			var a = clampf(d, 0.0, length)
			var b = clampf(d + DASH, 0.0, length)
			if b > a:
				draw_line(from_pos + dir * a, from_pos + dir * b, color, width)
			d += step


# _NodeButton is a Control so mouse_entered/exited and _gui_input work correctly.
class _NodeButton extends Control:
	signal node_clicked(node_id: String)

	const OrnateFrame = preload("res://scenes/ui/OrnateFrame.gd")

	# ノード種別 → アイコンと色
	const TYPE_META = {
		"normal_battle": {"icon": "attack",        "color": Color(0.86, 0.36, 0.32)},
		"elite_battle":  {"icon": "node_elite",    "color": Color(0.95, 0.55, 0.25)},
		"rest":          {"icon": "node_rest",     "color": Color(0.45, 0.85, 0.55)},
		"event":         {"icon": "node_event",    "color": Color(0.70, 0.50, 0.95)},
		"treasure":      {"icon": "node_treasure", "color": Color(0.92, 0.78, 0.38)},
		"boss":          {"icon": "node_boss",     "color": Color(0.95, 0.30, 0.40)},
		"start":         {"icon": "relic",         "color": Color(0.55, 0.75, 0.95)},
		"starter_relic": {"icon": "relic",         "color": Color(0.55, 0.75, 0.95)},
		"relic":         {"icon": "relic",         "color": Color(0.55, 0.75, 0.95)},
		"initial_relic": {"icon": "relic",         "color": Color(0.55, 0.75, 0.95)},
		"relic_reward":  {"icon": "relic",         "color": Color(0.55, 0.75, 0.95)},
	}

	static var _icon_cache: Dictionary = {}

	var node_id:     String = ""
	var node_type:   String = "normal_battle"
	var state:       String = "locked"
	var is_selected: bool   = false
	var interactive: bool   = true
	var phase:       float  = 0.0

	var _hovered: bool = false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_hovered(value: bool) -> void:
		if _hovered == value:
			return
		_hovered = value
		queue_redraw()

	func _has_point(pt: Vector2) -> bool:
		if not interactive:
			return false
		var r = size.x * 0.5
		return pt.distance_to(size * 0.5) <= r

	func _type_color() -> Color:
		return TYPE_META.get(node_type, {}).get("color", Color(0.70, 0.66, 0.86))

	func _draw() -> void:
		var c   = size * 0.5
		var r   = size.x * 0.5
		var pulse = 0.5 + sin(phase * 2.2) * 0.5  # 0..1
		var tc  = _type_color()
		if _hovered and state == "selectable":
			r *= 1.10

		match state:
			"current":
				for i in range(5, 0, -1):
					draw_circle(c, r + i * 3.5, Color(0.50, 0.15, 0.88, (0.04 + pulse * 0.02) * i))
				draw_circle(c, r, Color(0.20, 0.09, 0.38))
				draw_circle(c, r + 3.0, Color(OrnateFrame.BRONZE_BRIGHT, 0.85), false, 1.4)
				draw_circle(c, r, Color(0.78, 0.46, 1.0, 0.95), false, 2.6)
			"selectable":
				# 常時ゆっくり脈打つタイプ色のグロー(hover/選択でさらに強く)
				var glow_boost = 1.6 if (is_selected or _hovered) else 1.0
				for i in range(4, 0, -1):
					draw_circle(c, r + i * 3.0, Color(tc, (0.030 + pulse * 0.030) * i * glow_boost))
				draw_circle(c, r, Color(0.10, 0.08, 0.18, 0.96))
				draw_circle(c, r, Color(tc.darkened(0.25), 0.50))
				var ring = Color(1.0, 0.88, 0.46) if (is_selected or _hovered) else tc.lerp(Color(OrnateFrame.BRONZE_BRIGHT), 0.35)
				draw_circle(c, r, Color(ring, 0.95), false, 2.4)
				draw_circle(c, r - 3.5, Color(tc.lightened(0.25), 0.30), false, 1.0)
			"visited":
				draw_circle(c, r, Color(0.09, 0.075, 0.15))
				draw_circle(c, r, Color(0.40, 0.34, 0.56, 0.50), false, 1.6)
			"locked":
				draw_circle(c, r, Color(0.055, 0.048, 0.095))
				draw_circle(c, r, Color(0.20, 0.16, 0.28, 0.35), false, 1.4)

		_draw_icon(c, r)

		# 選択中マーカー: 4方位のひし形
		if is_selected and state == "selectable":
			for offset in [Vector2(0, -r - 7), Vector2(r + 7, 0), Vector2(0, r + 7), Vector2(-r - 7, 0)]:
				OrnateFrame.draw_gem(self, c + offset, 4.0, 0.95)

	func _draw_icon(c: Vector2, r: float) -> void:
		var tc = _type_color()
		var col: Color
		match state:
			"current":    col = Color(0.96, 0.86, 1.00, 0.95)
			"selectable": col = Color(tc.lightened(0.42), 0.95)
			"visited":    col = Color(0.42, 0.37, 0.56, 0.60)
			_:            col = Color(0.27, 0.23, 0.37, 0.50)

		var tex = _get_icon_texture()
		if tex:
			var icon_size = r * 1.16
			draw_texture_rect(tex, Rect2(c - Vector2(icon_size, icon_size) * 0.5, Vector2(icon_size, icon_size)), false, col)

	func _get_icon_texture() -> Texture2D:
		var icon_name: String = TYPE_META.get(node_type, {}).get("icon", "")
		if icon_name.is_empty():
			return null
		if _icon_cache.has(icon_name):
			return _icon_cache[icon_name]
		var path = "res://assets/ui/icons/%s.svg" % icon_name
		var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
		_icon_cache[icon_name] = tex
		return tex
