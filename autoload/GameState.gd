extends Node

# ── Player state ────────────────────────────────────────────────────────────
var player_hp: int = 70
var player_max_hp: int = 70
var player_block: int = 0
var player_energy: int = 3
var player_max_energy: int = 3
var player_statuses: Dictionary = {}  # { "vulnerable": 2, "weak": 1 }

# ── Deck state ───────────────────────────────────────────────────────────────
var deck: Array = []        # permanent deck / collection
var draw_pile: Array = []   # active combat draw pile
var hand: Array = []
var discard: Array = []
var exhaust_pile: Array = []
var next_turn_draw_penalty: int = 0
var combat_log_messages: Array[String] = []
var combat_damage_events: Array[Dictionary] = []

# ── Progression ──────────────────────────────────────────────────────────────
var current_battle: int = 0  # kept for legacy compat, not used by map flow
var current_act: int = 1

# ── Relic state ───────────────────────────────────────────────────────────────
var owned_relic_ids: Array = []
var initial_relic_chosen: bool = false
var relic_choice_done: bool = false

# ── Map state ─────────────────────────────────────────────────────────────────
var map_current_node_id: String = "start"
var map_visited_nodes: Array = ["start"]
var map_available_nodes: Array = ["starter_relic"]
var map_encounter_enemy_idx: int = 0
var map_encounter_enemy_id: String = "holy_soldier"
var map_encounter_is_boss: bool = false
var last_enemy_id: String = ""
# 敵抽選の袋(幕ごとにリセット。引き切るまで同じ敵は出ない)
var enemy_bag_normal: Array = []
var enemy_bag_elite: Array = []
var first_attack_used_this_combat: bool = false

# ── Enemy debug ───────────────────────────────────────────────────────────────
# Set debug_enemy_enabled = true and debug_enemy_id to one of:
# holy_soldier, temple_archer, inquisitor, paladin_captain, young_swordsman,
# novice_cleric, bounty_hunter, chain_jailer, sun_priest, white_shield_knight,
# fallen_saint, sage_of_the_party, hunter_companion, hero, forest_hunter,
# mercenary_axeman, poison_rogue, war_mage, battle_scavenger, war_wolf,
# wyvern_dragon, stone_golem, dark_fairy, royal_guard, alley_duelist,
# royal_mage, prison_guard, hired_knight, beastman_mercenary,
# elven_city_archer, foxkin_spy, elven_court_mage, wolfkin_guard,
# palace_steward, throne_guard, king_hound, living_holy_armor, chancellor
var debug_enemy_enabled: bool = false
var debug_enemy_id: String = ""
var current_battle_background_key: String = ""
var current_battle_background_path: String = ""

const BACKGROUND_PATHS: Dictionary = {
	"title": "res://assets/backgrounds/title/title_background.png",
	"act1_map": "res://assets/backgrounds/act1/act1_map_background.png",
	"act1_battle_road": "res://assets/backgrounds/act1/act1_battle_road.png",
	"act1_battle_forest": "res://assets/backgrounds/act1/act1_battle_forest.png",
	"act1_battle_chapel_ruins": "res://assets/backgrounds/act1/act1_battle_chapel_ruins.png",
	"act1_event": "res://assets/backgrounds/act1/act1_event_background.png",
	"act1_rest": "res://assets/backgrounds/act1/act1_rest_background.png",
	"act1_treasure": "res://assets/backgrounds/act1/act1_treasure_background.png",
	"act1_reward": "res://assets/backgrounds/act1/act1_reward_background.png",
	"act1_boss": "res://assets/backgrounds/act1/act1_boss_background.png",
	"act2_map": "res://assets/backgrounds/act2/act2_map_background.png",
	"act2_battle_city_gate": "res://assets/backgrounds/act2/act2_battle_city_gate.png",
	"act2_battle_cathedral_street": "res://assets/backgrounds/act2/act2_battle_cathedral_street.png",
	"act2_battle_execution_ground": "res://assets/backgrounds/act2/act2_battle_execution_ground.png",
	"act3_map": "res://assets/backgrounds/act3/act3_map_background.png",
	"act3_battle_palace_gate": "res://assets/backgrounds/act3/act3_battle_palace_gate.png",
	"act3_battle_great_hall": "res://assets/backgrounds/act3/act3_battle_great_hall.png",
	"act3_battle_throne_room": "res://assets/backgrounds/act3/act3_battle_throne_room.png",
	"shared_event": "res://assets/backgrounds/shared/event_background.png",
	"shared_rest": "res://assets/backgrounds/shared/rest_background.png",
	"shared_treasure": "res://assets/backgrounds/shared/treasure_background.png",
}

func get_background_path(key: String) -> String:
	return BACKGROUND_PATHS.get(key, "")

func set_current_battle_background(key: String) -> void:
	current_battle_background_key = key
	current_battle_background_path = get_background_path(key)

func get_current_battle_background_path() -> String:
	if not current_battle_background_path.is_empty():
		return current_battle_background_path
	if not current_battle_background_key.is_empty():
		return get_background_path(current_battle_background_key)
	return ""

func get_battle_background_key_for_enemy(enemy_id: String) -> String:
	return get_battle_background_key_for_enemies([enemy_id])

func get_battle_background_key_for_enemies(enemy_ids: Array) -> String:
	if current_act == 3:
		for enemy_id in enemy_ids:
			if enemy_id == "hero":
				return "act3_battle_throne_room"
		for enemy_id in enemy_ids:
			if enemy_id == "paladin_captain":
				return "act3_battle_throne_room"
		for enemy_id in enemy_ids:
			if ["chancellor", "inquisitor", "living_holy_armor", "palace_steward", "sun_priest", "white_shield_knight"].has(enemy_id):
				return "act3_battle_great_hall"
		return "act3_battle_palace_gate"

	if current_act == 2:
		for enemy_id in enemy_ids:
			if enemy_id == "fallen_saint":
				return "act2_battle_cathedral_street"
		for enemy_id in enemy_ids:
			if ["royal_mage", "elven_court_mage", "novice_cleric"].has(enemy_id):
				return "act2_battle_cathedral_street"
		for enemy_id in enemy_ids:
			if ["prison_guard", "chain_jailer", "foxkin_spy", "alley_duelist"].has(enemy_id):
				return "act2_battle_execution_ground"
		return "act2_battle_city_gate"

	for enemy_id in enemy_ids:
		if enemy_id == "hunter_companion":
			return "act1_battle_forest"
	for enemy_id in enemy_ids:
		if ["stone_golem", "wyvern_dragon", "war_mage", "battle_scavenger"].has(enemy_id):
			return "act1_battle_chapel_ruins"
	for enemy_id in enemy_ids:
		if ["forest_hunter", "war_wolf", "dark_fairy"].has(enemy_id):
			return "act1_battle_forest"
	return "act1_battle_road"

func load_background_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if not ResourceLoader.exists(path) and not FileAccess.file_exists(ProjectSettings.globalize_path(path)):
		return null
	if ResourceLoader.exists(path):
		var texture = load(path)
		if texture is Texture2D:
			return texture
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image:
		return ImageTexture.create_from_image(image)
	push_warning("Failed to load background: %s" % path)
	return null

# ── 幕ごとのマップ定義 ─────────────────────────────────────────────────────────
# MAP_NODES は現在の幕のマップを指す(reset_map / start_act*_map / apply_act_map で切替)。

# 第1幕: 街道と森 — 横に広い三本道
const MAP_NODES_ACT1: Dictionary = {
	"start": {"id": "start", "layer": 0, "type": "start", "connections": ["starter_relic"], "pos": Vector2(540, 1080)},
	"starter_relic": {"id": "starter_relic", "layer": 0, "type": "starter_relic", "connections": ["f2_battle_a", "f2_battle_b"], "pos": Vector2(540, 1040)},
	"f2_battle_a": {"id": "f2_battle_a", "layer": 1, "type": "normal_battle", "connections": ["f3_battle_a", "f3_event"], "pos": Vector2(380, 960)},
	"f2_battle_b": {"id": "f2_battle_b", "layer": 1, "type": "normal_battle", "connections": ["f3_event", "f3_battle_b"], "pos": Vector2(700, 960)},
	"f3_battle_a": {"id": "f3_battle_a", "layer": 3, "type": "normal_battle", "connections": ["f4_battle_a", "f4_treasure"], "pos": Vector2(250, 850)},
	"f3_event": {"id": "f3_event", "layer": 3, "type": "event", "connections": ["f4_battle_a", "f4_battle_b"], "pos": Vector2(540, 850)},
	"f3_battle_b": {"id": "f3_battle_b", "layer": 3, "type": "normal_battle", "connections": ["f4_treasure", "f4_battle_b"], "pos": Vector2(830, 850)},
	"f4_battle_a": {"id": "f4_battle_a", "layer": 4, "type": "normal_battle", "connections": ["f5_elite", "f5_battle"], "pos": Vector2(250, 770)},
	"f4_treasure": {"id": "f4_treasure", "layer": 4, "type": "treasure", "connections": ["f5_elite", "f5_battle", "f5_event"], "pos": Vector2(540, 770)},
	"f4_battle_b": {"id": "f4_battle_b", "layer": 4, "type": "normal_battle", "connections": ["f5_battle", "f5_event"], "pos": Vector2(830, 770)},
	"f5_elite": {"id": "f5_elite", "layer": 5, "type": "elite_battle", "connections": ["f6_rest"], "pos": Vector2(260, 690)},
	"f5_battle": {"id": "f5_battle", "layer": 5, "type": "normal_battle", "connections": ["f6_rest", "f6_battle"], "pos": Vector2(540, 690)},
	"f5_event": {"id": "f5_event", "layer": 5, "type": "event", "connections": ["f6_battle"], "pos": Vector2(820, 690)},
	"f6_rest": {"id": "f6_rest", "layer": 6, "type": "rest", "connections": ["f7_battle_a", "f7_elite"], "pos": Vector2(380, 610)},
	"f6_battle": {"id": "f6_battle", "layer": 6, "type": "normal_battle", "connections": ["f7_elite", "f7_battle_b"], "pos": Vector2(700, 610)},
	"f7_battle_a": {"id": "f7_battle_a", "layer": 7, "type": "normal_battle", "connections": ["f8_event", "f8_battle"], "pos": Vector2(260, 530)},
	"f7_elite": {"id": "f7_elite", "layer": 7, "type": "elite_battle", "connections": ["f8_battle", "f8_treasure"], "pos": Vector2(540, 530)},
	"f7_battle_b": {"id": "f7_battle_b", "layer": 7, "type": "normal_battle", "connections": ["f8_battle", "f8_treasure"], "pos": Vector2(820, 530)},
	"f8_event": {"id": "f8_event", "layer": 8, "type": "event", "connections": ["f9_battle_a", "f9_elite"], "pos": Vector2(250, 450)},
	"f8_battle": {"id": "f8_battle", "layer": 8, "type": "normal_battle", "connections": ["f9_battle_a", "f9_elite", "f9_battle_b"], "pos": Vector2(540, 450)},
	"f8_treasure": {"id": "f8_treasure", "layer": 8, "type": "treasure", "connections": ["f9_elite", "f9_battle_b"], "pos": Vector2(830, 450)},
	"f9_battle_a": {"id": "f9_battle_a", "layer": 9, "type": "normal_battle", "connections": ["f10_rest", "f10_battle"], "pos": Vector2(260, 370)},
	"f9_elite": {"id": "f9_elite", "layer": 9, "type": "elite_battle", "connections": ["f10_rest", "f10_battle"], "pos": Vector2(540, 370)},
	"f9_battle_b": {"id": "f9_battle_b", "layer": 9, "type": "normal_battle", "connections": ["f10_battle"], "pos": Vector2(820, 370)},
	"f10_rest": {"id": "f10_rest", "layer": 10, "type": "rest", "connections": ["f11_battle_a", "f11_event"], "pos": Vector2(380, 290)},
	"f10_battle": {"id": "f10_battle", "layer": 10, "type": "normal_battle", "connections": ["f11_event", "f11_battle_b"], "pos": Vector2(700, 290)},
	"f11_battle_a": {"id": "f11_battle_a", "layer": 11, "type": "normal_battle", "connections": ["f12_elite", "f12_battle"], "pos": Vector2(260, 210)},
	"f11_event": {"id": "f11_event", "layer": 11, "type": "event", "connections": ["f12_battle"], "pos": Vector2(540, 210)},
	"f11_battle_b": {"id": "f11_battle_b", "layer": 11, "type": "normal_battle", "connections": ["f12_battle"], "pos": Vector2(820, 210)},
	"f12_elite": {"id": "f12_elite", "layer": 12, "type": "elite_battle", "connections": ["f13_rest"], "pos": Vector2(400, 170)},
	"f12_battle": {"id": "f12_battle", "layer": 12, "type": "normal_battle", "connections": ["f13_rest"], "pos": Vector2(680, 170)},
	"f13_rest": {"id": "f13_rest", "layer": 13, "type": "rest", "connections": ["f14_boss"], "pos": Vector2(540, 100)},
	"f14_boss": {"id": "f14_boss", "layer": 14, "type": "boss", "connections": [], "pos": Vector2(540, 34)},
}

# 第2幕: 王都の市街 — 左右二本の大通りがときどき交差する
const MAP_NODES_ACT2: Dictionary = {
	"start": {"id": "start", "layer": 0, "type": "start", "connections": ["starter_relic"], "pos": Vector2(540, 1080)},
	"starter_relic": {"id": "starter_relic", "layer": 0, "type": "starter_relic", "connections": ["c2_battle_a", "c2_battle_b"], "pos": Vector2(540, 1040)},
	"c2_battle_a": {"id": "c2_battle_a", "layer": 2, "type": "normal_battle", "connections": ["c3_battle_a", "c3_event"], "pos": Vector2(330, 960)},
	"c2_battle_b": {"id": "c2_battle_b", "layer": 2, "type": "normal_battle", "connections": ["c3_event", "c3_battle_b"], "pos": Vector2(750, 960)},
	"c3_battle_a": {"id": "c3_battle_a", "layer": 3, "type": "normal_battle", "connections": ["c4_elite", "c4_treasure"], "pos": Vector2(270, 870)},
	"c3_event": {"id": "c3_event", "layer": 3, "type": "event", "connections": ["c4_treasure"], "pos": Vector2(540, 880)},
	"c3_battle_b": {"id": "c3_battle_b", "layer": 3, "type": "normal_battle", "connections": ["c4_treasure", "c4_battle"], "pos": Vector2(810, 870)},
	"c4_elite": {"id": "c4_elite", "layer": 4, "type": "elite_battle", "connections": ["c5_rest"], "pos": Vector2(270, 780)},
	"c4_treasure": {"id": "c4_treasure", "layer": 4, "type": "treasure", "connections": ["c5_rest", "c5_battle"], "pos": Vector2(540, 790)},
	"c4_battle": {"id": "c4_battle", "layer": 4, "type": "normal_battle", "connections": ["c5_battle", "c5_event"], "pos": Vector2(810, 780)},
	"c5_rest": {"id": "c5_rest", "layer": 5, "type": "rest", "connections": ["c6_battle_a"], "pos": Vector2(300, 690)},
	"c5_battle": {"id": "c5_battle", "layer": 5, "type": "normal_battle", "connections": ["c6_battle_a", "c6_battle_b"], "pos": Vector2(620, 690)},
	"c5_event": {"id": "c5_event", "layer": 5, "type": "event", "connections": ["c6_battle_b", "c6_treasure"], "pos": Vector2(850, 690)},
	"c6_battle_a": {"id": "c6_battle_a", "layer": 6, "type": "normal_battle", "connections": ["c7_event", "c7_elite"], "pos": Vector2(300, 600)},
	"c6_battle_b": {"id": "c6_battle_b", "layer": 6, "type": "normal_battle", "connections": ["c7_elite"], "pos": Vector2(640, 600)},
	"c6_treasure": {"id": "c6_treasure", "layer": 6, "type": "treasure", "connections": ["c7_elite", "c7_battle"], "pos": Vector2(860, 600)},
	"c7_event": {"id": "c7_event", "layer": 7, "type": "event", "connections": ["c8_battle_a"], "pos": Vector2(330, 510)},
	"c7_elite": {"id": "c7_elite", "layer": 7, "type": "elite_battle", "connections": ["c8_battle_a", "c8_battle_b"], "pos": Vector2(580, 510)},
	"c7_battle": {"id": "c7_battle", "layer": 7, "type": "normal_battle", "connections": ["c8_battle_b", "c8_event"], "pos": Vector2(830, 510)},
	"c8_battle_a": {"id": "c8_battle_a", "layer": 8, "type": "normal_battle", "connections": ["c9_rest", "c9_elite"], "pos": Vector2(330, 420)},
	"c8_battle_b": {"id": "c8_battle_b", "layer": 8, "type": "normal_battle", "connections": ["c9_elite"], "pos": Vector2(640, 420)},
	"c8_event": {"id": "c8_event", "layer": 8, "type": "event", "connections": ["c9_elite", "c9_battle"], "pos": Vector2(860, 420)},
	"c9_rest": {"id": "c9_rest", "layer": 9, "type": "rest", "connections": ["c10_battle_a"], "pos": Vector2(400, 330)},
	"c9_elite": {"id": "c9_elite", "layer": 9, "type": "elite_battle", "connections": ["c10_battle_a", "c10_battle_b"], "pos": Vector2(660, 330)},
	"c9_battle": {"id": "c9_battle", "layer": 9, "type": "normal_battle", "connections": ["c10_battle_b"], "pos": Vector2(880, 330)},
	"c10_battle_a": {"id": "c10_battle_a", "layer": 10, "type": "normal_battle", "connections": ["c11_rest"], "pos": Vector2(420, 240)},
	"c10_battle_b": {"id": "c10_battle_b", "layer": 10, "type": "normal_battle", "connections": ["c11_rest"], "pos": Vector2(700, 240)},
	"c11_rest": {"id": "c11_rest", "layer": 11, "type": "rest", "connections": ["c12_boss"], "pos": Vector2(540, 150)},
	"c12_boss": {"id": "c12_boss", "layer": 12, "type": "boss", "connections": [], "pos": Vector2(540, 60)},
}

# 第3幕: 王宮 — 縦に細く荘厳。中間に必ず通る白盾の騎士(中ボス)の関門がある
const MAP_NODES_ACT3: Dictionary = {
	"start": {"id": "start", "layer": 0, "type": "start", "connections": ["starter_relic"], "pos": Vector2(540, 1080)},
	"starter_relic": {"id": "starter_relic", "layer": 0, "type": "starter_relic", "connections": ["p2_battle_a", "p2_battle_b"], "pos": Vector2(540, 1040)},
	"p2_battle_a": {"id": "p2_battle_a", "layer": 2, "type": "normal_battle", "connections": ["p3_event", "p3_battle"], "pos": Vector2(420, 950)},
	"p2_battle_b": {"id": "p2_battle_b", "layer": 2, "type": "normal_battle", "connections": ["p3_battle", "p3_treasure"], "pos": Vector2(660, 950)},
	"p3_event": {"id": "p3_event", "layer": 3, "type": "event", "connections": ["p4_battle"], "pos": Vector2(380, 860)},
	"p3_battle": {"id": "p3_battle", "layer": 3, "type": "normal_battle", "connections": ["p4_battle", "p4_elite"], "pos": Vector2(540, 860)},
	"p3_treasure": {"id": "p3_treasure", "layer": 3, "type": "treasure", "connections": ["p4_elite"], "pos": Vector2(700, 860)},
	"p4_battle": {"id": "p4_battle", "layer": 4, "type": "normal_battle", "connections": ["p5_rest", "p5_battle"], "pos": Vector2(440, 770)},
	"p4_elite": {"id": "p4_elite", "layer": 4, "type": "elite_battle", "connections": ["p5_rest", "p5_battle"], "pos": Vector2(660, 770)},
	"p5_rest": {"id": "p5_rest", "layer": 5, "type": "rest", "connections": ["p6_midboss"], "pos": Vector2(440, 680)},
	"p5_battle": {"id": "p5_battle", "layer": 5, "type": "normal_battle", "connections": ["p6_midboss"], "pos": Vector2(660, 680)},
	# 大広間の関門 — 全ルートがここに収束する(白盾の騎士・中ボス)
	"p6_midboss": {"id": "p6_midboss", "layer": 6, "type": "boss", "enemy_id": "white_shield_knight", "connections": ["p7_battle", "p7_event"], "pos": Vector2(540, 580)},
	"p7_battle": {"id": "p7_battle", "layer": 7, "type": "normal_battle", "connections": ["p8_elite", "p8_treasure"], "pos": Vector2(420, 480)},
	"p7_event": {"id": "p7_event", "layer": 7, "type": "event", "connections": ["p8_elite", "p8_treasure"], "pos": Vector2(660, 480)},
	"p8_elite": {"id": "p8_elite", "layer": 8, "type": "elite_battle", "connections": ["p9_battle_a", "p9_battle_b"], "pos": Vector2(420, 390)},
	"p8_treasure": {"id": "p8_treasure", "layer": 8, "type": "treasure", "connections": ["p9_battle_b"], "pos": Vector2(660, 390)},
	"p9_battle_a": {"id": "p9_battle_a", "layer": 9, "type": "normal_battle", "connections": ["p10_rest"], "pos": Vector2(440, 290)},
	"p9_battle_b": {"id": "p9_battle_b", "layer": 9, "type": "normal_battle", "connections": ["p10_rest"], "pos": Vector2(660, 290)},
	"p10_rest": {"id": "p10_rest", "layer": 10, "type": "rest", "connections": ["p11_boss"], "pos": Vector2(540, 190)},
	"p11_boss": {"id": "p11_boss", "layer": 11, "type": "boss", "connections": [], "pos": Vector2(540, 80)},
}

# 現在の幕のマップ(既存コードはこの MAP_NODES を参照する)
var MAP_NODES: Dictionary = MAP_NODES_ACT1

func get_map_nodes_for_act(act: int) -> Dictionary:
	match act:
		2: return MAP_NODES_ACT2
		3: return MAP_NODES_ACT3
		_: return MAP_NODES_ACT1

func apply_act_map() -> void:
	MAP_NODES = get_map_nodes_for_act(current_act)

func reset_map() -> void:
	current_act = 1
	apply_act_map()
	reset_enemy_bags()
	map_current_node_id = "start"
	map_visited_nodes = ["start"]
	map_available_nodes = ["starter_relic"]
	map_encounter_enemy_idx = 0
	map_encounter_enemy_id = "holy_soldier"
	map_encounter_is_boss = false
	last_enemy_id = ""

func enter_map_node(node_id: String) -> void:
	map_current_node_id = node_id
	if not map_visited_nodes.has(node_id):
		map_visited_nodes.append(node_id)

func complete_map_node(node_id: String) -> void:
	var node = MAP_NODES.get(node_id, {})
	map_available_nodes = node.get("connections", []).duplicate()

func start_act2_map() -> void:
	current_act = 2
	apply_act_map()
	reset_enemy_bags()
	map_current_node_id = "starter_relic"
	map_visited_nodes = ["start", "starter_relic"]
	map_available_nodes = MAP_NODES.get("starter_relic", {}).get("connections", []).duplicate()
	map_encounter_enemy_idx = 0
	map_encounter_enemy_id = "holy_soldier"
	map_encounter_is_boss = false
	last_enemy_id = ""

func start_act3_map() -> void:
	current_act = 3
	apply_act_map()
	reset_enemy_bags()
	map_current_node_id = "starter_relic"
	map_visited_nodes = ["start", "starter_relic"]
	map_available_nodes = MAP_NODES.get("starter_relic", {}).get("connections", []).duplicate()
	map_encounter_enemy_idx = 0
	map_encounter_enemy_id = "royal_guard"
	map_encounter_is_boss = false
	last_enemy_id = ""

# ── Relic definitions ────────────────────────────────────────────────────────
const RELIC_RARITY_WEIGHTS_NORMAL: Dictionary = {"common": 70, "rare": 25, "epic": 5}
const RELIC_RARITY_WEIGHTS_ELITE: Dictionary  = {"common": 55, "rare": 35, "epic": 10}
const RELIC_RARITY_WEIGHTS_START: Dictionary  = {"common": 70, "rare": 25, "epic": 5}
const RELIC_RARITY_WEIGHTS_BOSS: Dictionary   = {"common": 20, "rare": 50, "epic": 30}

const RELICS: Dictionary = {
	"broken_oath_badge": {
		"id": "broken_oath_badge", "name_jp": "砕けた誓章",
		"effect_jp": "戦闘開始時、ブロックを5得る。",
		"memory_jp": "かつて勇者一行の証だったもの。今は半分に砕けている。",
		"description_jp": "戦闘開始時、ブロックを5得る。\nかつて勇者一行の証だったもの。今は半分に砕けている。",
		"rarity": "common", "icon_text": "誓"
	},
	"avenger_ring": {
		"id": "avenger_ring", "name_jp": "復讐者の指輪",
		"effect_jp": "攻撃カードのダメージが1増える。",
		"memory_jp": "失ったものを思い出すたび、刃は重くなる。",
		"description_jp": "攻撃カードのダメージが1増える。\n失ったものを思い出すたび、刃は重くなる。",
		"rarity": "common", "icon_text": "指"
	},
	"old_wound_bandage": {
		"id": "old_wound_bandage", "name_jp": "古傷の包帯",
		"effect_jp": "休憩時の回復量が8増える。",
		"memory_jp": "奈落で傷を塞いだ布。まだ血の匂いが残っている。",
		"description_jp": "休憩時の回復量が8増える。\n奈落で傷を塞いだ布。まだ血の匂いが残っている。",
		"rarity": "common", "icon_text": "帯"
	},
	"cracked_amulet": {
		"id": "cracked_amulet", "name_jp": "ひび割れた護符",
		"effect_jp": "防御カードで得るブロックが2増える。",
		"memory_jp": "仲間を守るための護符。今は自分だけを守る。",
		"description_jp": "防御カードで得るブロックが2増える。\n仲間を守るための護符。今は自分だけを守る。",
		"rarity": "common", "icon_text": "護"
	},
	"fallen_feather": {
		"id": "fallen_feather", "name_jp": "堕天使の羽片",
		"effect_jp": "戦闘開始時、カードを1枚多く引く。",
		"memory_jp": "奈落で授かった黒い羽。触れると微かに脈打つ。",
		"description_jp": "戦闘開始時、カードを1枚多く引く。\n奈落で授かった黒い羽。触れると微かに脈打つ。",
		"rarity": "rare", "icon_text": "羽"
	},
	"memory_of_betrayal": {
		"id": "memory_of_betrayal", "name_jp": "裏切りの記憶",
		"effect_jp": "各戦闘の最初のターン、エナジーを1多く得る。",
		"memory_jp": "あの瞬間の記憶だけが、足を前に進ませる。",
		"description_jp": "各戦闘の最初のターン、エナジーを1多く得る。\nあの瞬間の記憶だけが、足を前に進ませる。",
		"rarity": "rare", "icon_text": "記"
	},
	"bloodied_blade_shard": {
		"id": "bloodied_blade_shard", "name_jp": "血濡れの剣片",
		"effect_jp": "敵を倒した時、HPを5回復する。",
		"memory_jp": "かつて自分を貫いた刃の欠片。",
		"description_jp": "敵を倒した時、HPを5回復する。\nかつて自分を貫いた刃の欠片。",
		"rarity": "rare", "icon_text": "刃"
	},
	"pact_brand": {
		"id": "pact_brand", "name_jp": "契約の焼印",
		"effect_jp": "HPを失うカードを使うたび、ブロックを4得る。",
		"memory_jp": "堕天使との契約の証。痛みは守りへ変わる。",
		"description_jp": "HPを失うカードを使うたび、ブロックを4得る。\n堕天使との契約の証。痛みは守りへ変わる。",
		"rarity": "rare", "icon_text": "印"
	},
	"executioner_mask": {
		"id": "executioner_mask", "name_jp": "処刑人の仮面",
		"effect_jp": "HPが半分以下の敵に与える攻撃ダメージが3増える。",
		"memory_jp": "弱った者を見逃す慈悲は、もう残っていない。",
		"description_jp": "HPが半分以下の敵に与える攻撃ダメージが3増える。\n弱った者を見逃す慈悲は、もう残っていない。",
		"rarity": "rare", "icon_text": "仮"
	},
	"rotted_crown": {
		"id": "rotted_crown", "name_jp": "朽ちた王冠",
		"effect_jp": "カード報酬の選択肢が1枚増える。",
		"memory_jp": "誰かが夢見た王の証。今は復讐者の手にある。",
		"description_jp": "カード報酬の選択肢が1枚増える。\n誰かが夢見た王の証。今は復讐者の手にある。",
		"rarity": "epic", "icon_text": "冠"
	},
	"abyss_core": {
		"id": "abyss_core", "name_jp": "奈落の核",
		"effect_jp": "毎ターン開始時、エナジーを1得る。ただし戦闘開始時にHPを3失う。最低HPは1。",
		"memory_jp": "奈落の底で拾い上げた、脈打つ黒い結晶。",
		"description_jp": "毎ターン開始時、エナジーを1得る。ただし戦闘開始時にHPを3失う。最低HPは1。\n奈落の底で拾い上げた、脈打つ黒い結晶。",
		"rarity": "epic", "icon_text": "核"
	},
	"chain_of_judgement": {
		"id": "chain_of_judgement", "name_jp": "断罪の鎖",
		"effect_jp": "敵に脆弱を付与するたび、追加で脆弱を1付与する。",
		"memory_jp": "裁く側だった者たちを、今度はこちらが縛る。",
		"description_jp": "敵に脆弱を付与するたび、追加で脆弱を1付与する。\n裁く側だった者たちを、今度はこちらが縛る。",
		"rarity": "epic", "icon_text": "鎖"
	},
	"fate_severing_thread": {
		"id": "fate_severing_thread", "name_jp": "運命断ちの黒糸",
		"effect_jp": "カード報酬で rare / epic カードが出やすくなる。",
		"memory_jp": "決められた運命を、黒い糸が断ち切る。",
		"description_jp": "カード報酬で rare / epic カードが出やすくなる。\n決められた運命を、黒い糸が断ち切る。",
		"rarity": "epic", "icon_text": "鎖"
	},
	"former_hunter_bow": {
		"id": "former_hunter_bow", "name_jp": "狩人の遺弓",
		"effect_jp": "各戦闘の最初に使用する攻撃カードは、追加で3ダメージを与える。",
		"memory_jp": "かつて獲物を逃さなかった弓。今は、復讐者の初撃を導く。",
		"description_jp": "各戦闘の最初に使用する攻撃カードは、追加で3ダメージを与える。\nかつて獲物を逃さなかった弓。今は、復讐者の初撃を導く。",
		"rarity": "boss", "icon_text": "弓"
	},
	"hunter_tracking_eye": {
		"id": "hunter_tracking_eye", "name_jp": "獲物を追う眼",
		"effect_jp": "各戦闘開始時、敵に脆弱を2付与する。",
		"memory_jp": "足跡、息遣い、血の匂い。見失わないための眼だけが残った。",
		"description_jp": "各戦闘開始時、敵に脆弱を2付与する。\n足跡、息遣い、血の匂い。見失わないための眼だけが残った。",
		"rarity": "boss", "icon_text": "眼"
	},
	"hungry_blade": {
		"id": "hungry_blade", "name_jp": "飢えた魔剣",
		"effect_jp": "攻撃カードのダメージが3増える。戦闘終了時にHPを2失う。",
		"memory_jp": "刃が血を覚えてしまった。もう、ただの鉄には戻れない。",
		"description_jp": "攻撃カードのダメージが3増える。戦闘終了時にHPを2失う。\n刃が血を覚えてしまった。もう、ただの鉄には戻れない。",
		"rarity": "rare", "icon_text": "剣"
	},
	"leaden_heart": {
		"id": "leaden_heart", "name_jp": "鈍色の心臓",
		"effect_jp": "最大HPが15増える。ただしカード報酬の選択肢が1枚減る。",
		"memory_jp": "重い。だが、止まらない。",
		"description_jp": "最大HPが15増える。ただしカード報酬の選択肢が1枚減る。\n重い。だが、止まらない。",
		"rarity": "epic", "icon_text": "心"
	},
	"serpent_fang": {
		"id": "serpent_fang", "name_jp": "蛇の牙",
		"effect_jp": "敵に毒を付与するたび、追加で毒を1付与する。",
		"memory_jp": "乾いた牙に、まだ毒が残っている。",
		"description_jp": "敵に毒を付与するたび、追加で毒を1付与する。\n乾いた牙に、まだ毒が残っている。",
		"rarity": "rare", "icon_text": "牙"
	},
	"unyielding_white_shield": {
		"id": "unyielding_white_shield", "name_jp": "不抜の白盾",
		"effect_jp": "ターン開始時にブロックが消えず、10まで持ち越せる。",
		"memory_jp": "彼の盾が下がるのを、見た者はいない。",
		"description_jp": "ターン開始時にブロックが消えず、10まで持ち越せる。\n彼の盾が下がるのを、見た者はいない。",
		"rarity": "boss", "icon_text": "盾"
	},
	"shield_thorns": {
		"id": "shield_thorns", "name_jp": "盾の棘",
		"effect_jp": "敵の攻撃でダメージを受けたとき、敵に3ダメージを返す。",
		"memory_jp": "壁に挑んだ者は、皆その棘を知った。",
		"description_jp": "敵の攻撃でダメージを受けたとき、敵に3ダメージを返す。\n壁に挑んだ者は、皆その棘を知った。",
		"rarity": "boss", "icon_text": "棘"
	},
	"knight_oath": {
		"id": "knight_oath", "name_jp": "騎士の誓い",
		"effect_jp": "ターン終了時、残ったエナジー1につきブロックを3得る。",
		"memory_jp": "力より忍耐を。攻めるより、立ち続けることを。",
		"description_jp": "ターン終了時、残ったエナジー1につきブロックを3得る。\n力より忍耐を。攻めるより、立ち続けることを。",
		"rarity": "boss", "icon_text": "誓"
	},
	"false_holy_seal": {
		"id": "false_holy_seal", "name_jp": "偽りの聖印",
		"effect_jp": "エナジー上限が1増える。ただし休憩での回復量が半分になる。",
		"memory_jp": "聖女の祝福は本物だった。──祝福だけは。",
		"description_jp": "エナジー上限が1増える。ただし休憩での回復量が半分になる。\n聖女の祝福は本物だった。──祝福だけは。",
		"rarity": "boss", "icon_text": "聖"
	},
	"deceit_chalice": {
		"id": "deceit_chalice", "name_jp": "欺瞞の聖杯",
		"effect_jp": "戦闘開始時、敵に毒を3付与する。",
		"memory_jp": "彼女が回した杯を、疑った者はいなかった。",
		"description_jp": "戦闘開始時、敵に毒を3付与する。\n彼女が回した杯を、疑った者はいなかった。",
		"rarity": "boss", "icon_text": "杯"
	},
	"martyr_rosary": {
		"id": "martyr_rosary", "name_jp": "殉教者のロザリオ",
		"effect_jp": "防御カードを使うたび、HPを1回復する。",
		"memory_jp": "祈りの数だけ珠が減っている。誰のための祈りだったのか。",
		"description_jp": "防御カードを使うたび、HPを1回復する。\n祈りの数だけ珠が減っている。誰のための祈りだったのか。",
		"rarity": "boss", "icon_text": "珠"
	},
	"hunter_trapwire": {
		"id": "hunter_trapwire", "name_jp": "狩人の罠糸",
		"effect_jp": "各戦闘開始時、敵に脱力を1付与する。",
		"memory_jp": "獲物の逃げ道を塞いだ細い罠糸。今は、復讐者の進む道を開く。",
		"description_jp": "各戦闘開始時、敵に脱力を1付与する。\n獲物の逃げ道を塞いだ細い罠糸。今は、復讐者の進む道を開く。",
		"rarity": "boss", "icon_text": "罠"
	},
}

# ── Card definitions ─────────────────────────────────────────────────────────
const CARD_RARITY_WEIGHTS: Dictionary = {
	"common": 75,
	"rare": 22,
	"epic": 3,
}
const CARD_REWARD_POOL: Array = [
	"rusted_combo", "corroding_blade", "corrosive_mist", "end_of_pain", "parry", "brace", "mark_of_hatred", "borrowed_life",
	"revenge_blade", "condemnation", "blood_pursuit", "pain_to_power", "fallen_grace", "pact_price",
	"unforgiven", "headsman", "slow_death", "blood_price", "abyss_reversal", "oathbreaker", "fallen_wings", "life_reap",
	"endless_revenge", "abyss_contract", "poison_burst", "abyss_thirst",
]

const CARDS: Dictionary = {
	"old_slash": {
		"id": "old_slash", "name": "古びた斬撃", "cost": 1,
		"description": "敵に6ダメージ。",
		"rarity": "starter",
		"type": "attack",
		"effects": [{"type": "damage", "value": 6}]
	},
	"worn_guard": {
		"id": "worn_guard", "name": "朽ちた防御", "cost": 1,
		"description": "ブロックを5得る。",
		"rarity": "starter",
		"type": "defense",
		"effects": [{"type": "block", "value": 5}]
	},
	"betrayal_blow": {
		"id": "betrayal_blow", "name": "裏切りの一撃", "cost": 2,
		"description": "敵に8ダメージ。\n脆弱を2付与。",
		"rarity": "starter",
		"type": "attack",
		"effects": [
			{"type": "damage", "value": 8},
			{"type": "apply_status", "target": "enemy", "status": "vulnerable", "amount": 2}
		]
	},
	"rusted_combo": {
		"id": "rusted_combo", "name": "錆びた連撃", "cost": 1,
		"description": "敵に4ダメージを\n2回与える。",
		"rarity": "common",
		"type": "attack",
		"effects": [{"type": "damage_multi", "value": 4, "times": 2}]
	},
	"corroding_blade": {
		"id": "corroding_blade", "name": "蝕む刃", "cost": 1,
		"description": "敵に4ダメージ。\n毒を2付与。",
		"rarity": "common",
		"type": "attack",
		"effects": [
			{"type": "damage", "value": 4},
			{"type": "apply_status", "target": "enemy", "status": "poison", "amount": 2}
		]
	},
	"corrosive_mist": {
		"id": "corrosive_mist", "name": "腐食の霧", "cost": 1,
		"description": "敵に毒を3付与。\nカードを1枚引く。",
		"rarity": "common",
		"type": "skill",
		"effects": [
			{"type": "apply_status", "target": "enemy", "status": "poison", "amount": 3},
			{"type": "draw", "value": 1}
		]
	},
	"slow_death": {
		"id": "slow_death", "name": "緩慢な死", "cost": 1,
		"description": "敵の毒を2倍にする。",
		"rarity": "rare",
		"type": "skill",
		"effects": [{"type": "double_poison"}]
	},
	"poison_burst": {
		"id": "poison_burst", "name": "蝕み爆ぜる", "cost": 2,
		"description": "敵の毒1につき\n4ダメージを与え、\n毒をすべて消費する。",
		"rarity": "epic",
		"type": "attack",
		"effects": [{"type": "poison_burst", "value": 4}]
	},
	"end_of_pain": {
		"id": "end_of_pain", "name": "痛みの果て", "cost": 2,
		"description": "失っているHPが\n20以上なら26ダメージ。\nそうでなければ10ダメージ。",
		"rarity": "rare",
		"type": "attack",
		"effects": [{"type": "conditional_damage", "condition": "missing_hp", "threshold": 20, "value": 10, "bonus_value": 26}]
	},
	"blood_price": {
		"id": "blood_price", "name": "血の代償", "cost": 1,
		"description": "HPを3失う。\n敵に14ダメージ。\n最低HPは1。",
		"rarity": "rare",
		"type": "attack",
		"effects": [
			{"type": "lose_hp", "value": 3, "minimum_hp": 1},
			{"type": "damage", "value": 14}
		]
	},
	"abyss_thirst": {
		"id": "abyss_thirst", "name": "奈落の渇き", "cost": 0,
		"description": "エナジーを2得る。\n「罪悪感」を\n捨て札に混ぜる。",
		"rarity": "epic",
		"type": "skill",
		"effects": [
			{"type": "gain_energy", "value": 2},
			{"type": "self_temp_discard", "card_id": "guilt", "amount": 1}
		]
	},
	"parry": {
		"id": "parry", "name": "受け流し", "cost": 1,
		"description": "ブロックを7得る。",
		"rarity": "common",
		"type": "defense",
		"effects": [{"type": "block", "value": 7}]
	},
	"brace": {
		"id": "brace", "name": "身構える", "cost": 1,
		"description": "ブロックを5得る。\nカードを1枚引く。",
		"rarity": "common",
		"type": "defense",
		"effects": [
			{"type": "block", "value": 5},
			{"type": "draw", "value": 1}
		]
	},
	"mark_of_hatred": {
		"id": "mark_of_hatred", "name": "憎悪の印", "cost": 1,
		"description": "敵に脆弱を2付与。",
		"rarity": "common",
		"type": "skill",
		"effects": [{"type": "apply_status", "target": "enemy", "status": "vulnerable", "amount": 2}]
	},
	"borrowed_life": {
		"id": "borrowed_life", "name": "命の前借り", "cost": 1,
		"description": "HPを8回復。\n最大HPが3減る。",
		"rarity": "common",
		"type": "skill",
		"effects": [
			{"type": "heal", "value": 8},
			{"type": "lose_max_hp", "value": 3}
		]
	},
	"revenge_blade": {
		"id": "revenge_blade", "name": "復讐の刃", "cost": 1,
		"description": "敵に7ダメージ。\n敵が脆弱なら追加で\n5ダメージ。",
		"rarity": "rare",
		"type": "attack",
		"effects": [
			{"type": "damage", "value": 7},
			{"type": "vulnerable_bonus_damage", "value": 5}
		]
	},
	"condemnation": {
		"id": "condemnation", "name": "断罪", "cost": 2,
		"description": "敵に12ダメージ。\n脆弱を1付与。",
		"rarity": "rare",
		"type": "attack",
		"effects": [
			{"type": "damage", "value": 12},
			{"type": "apply_status", "target": "enemy", "status": "vulnerable", "amount": 1}
		]
	},
	"blood_pursuit": {
		"id": "blood_pursuit", "name": "血濡れの追撃", "cost": 1,
		"description": "敵に3ダメージを\n3回与える。",
		"rarity": "rare",
		"type": "attack",
		"effects": [{"type": "damage_multi", "value": 3, "times": 3}]
	},
	"pain_to_power": {
		"id": "pain_to_power", "name": "傷を力に", "cost": 0,
		"description": "HPを3失い、\nエナジーを1得る。\n最低HPは1。",
		"rarity": "rare",
		"type": "skill",
		"effects": [
			{"type": "lose_hp", "value": 3, "minimum_hp": 1},
			{"type": "gain_energy", "value": 1}
		]
	},
	"fallen_grace": {
		"id": "fallen_grace", "name": "堕天の加護", "cost": 1,
		"description": "ブロックを8得る。\n敵に脱力を1付与。",
		"rarity": "rare",
		"type": "defense",
		"effects": [
			{"type": "block", "value": 8},
			{"type": "apply_status", "target": "enemy", "status": "weak", "amount": 1}
		]
	},
	"pact_price": {
		"id": "pact_price", "name": "契約の代償", "cost": 1,
		"description": "カードを2枚引く。\nHPを2失う。\n最低HPは1。",
		"rarity": "rare",
		"type": "skill",
		"effects": [
			{"type": "draw", "value": 2},
			{"type": "lose_hp", "value": 2, "minimum_hp": 1}
		]
	},
	"unforgiven": {
		"id": "unforgiven", "name": "赦されぬ者", "cost": 2,
		"description": "ブロックを12得る。\nカードを1枚引く。",
		"rarity": "rare",
		"type": "defense",
		"effects": [
			{"type": "block", "value": 12},
			{"type": "draw", "value": 1}
		]
	},
	"headsman": {
		"id": "headsman", "name": "首狩り", "cost": 2,
		"description": "敵のHPが半分以下なら\n24ダメージ。そうでなければ\n12ダメージ。",
		"rarity": "rare",
		"type": "attack",
		"effects": [{"type": "conditional_damage", "condition": "enemy_half_hp", "value": 12, "bonus_value": 24}]
	},
	"abyss_reversal": {
		"id": "abyss_reversal", "name": "奈落返し", "cost": 2,
		"description": "敵に18ダメージ。\n敵が脆弱なら追加で\n8ダメージ。",
		"rarity": "epic",
		"type": "attack",
		"effects": [
			{"type": "damage", "value": 18},
			{"type": "vulnerable_bonus_damage", "value": 8}
		]
	},
	"oathbreaker": {
		"id": "oathbreaker", "name": "誓約破り", "cost": 3,
		"description": "敵に32ダメージ。",
		"rarity": "epic",
		"type": "attack",
		"effects": [{"type": "damage", "value": 32}]
	},
	"fallen_wings": {
		"id": "fallen_wings", "name": "堕天の翼", "cost": 2,
		"description": "ブロックを10得る。\nエナジーを1得る。",
		"rarity": "epic",
		"type": "defense",
		"effects": [
			{"type": "block", "value": 10},
			{"type": "gain_energy", "value": 1}
		]
	},
	"life_reap": {
		"id": "life_reap", "name": "命の収奪", "cost": 2,
		"description": "敵に12ダメージ。\nHPを5回復。",
		"rarity": "epic",
		"type": "attack",
		"effects": [
			{"type": "damage", "value": 12},
			{"type": "heal", "value": 5}
		]
	},
	"endless_revenge": {
		"id": "endless_revenge", "name": "終わらぬ復讐", "cost": 2,
		"description": "敵に6ダメージを\n3回与える。",
		"rarity": "epic",
		"type": "attack",
		"effects": [{"type": "damage_multi", "value": 6, "times": 3}]
	},
	"abyss_contract": {
		"id": "abyss_contract", "name": "奈落との契約", "cost": 0,
		"description": "HPを5失う。\nカードを3枚引く。\nエナジーを1得る。\n最低HPは1。",
		"rarity": "epic",
		"type": "skill",
		"effects": [
			{"type": "lose_hp", "value": 5, "minimum_hp": 1},
			{"type": "draw", "value": 3},
			{"type": "gain_energy", "value": 1}
		]
	},
}

const TEMPORARY_STATUS_CARDS: Dictionary = {
	"junk": {
		"id": "junk", "name": "ガラクタ", "cost": -1,
		"description": "使用できない。\n手札を圧迫する。",
		"rarity": "common",
		"type": "status",
		"temporary": true
	},
	"brand_of_sin": {
		"id": "brand_of_sin", "name": "罪の烙印", "cost": -1,
		"description": "手札に残ると\nHPを2失う。",
		"rarity": "common",
		"type": "curse",
		"temporary": true
	},
	"arrow_wound": {
		"id": "arrow_wound", "name": "矢傷", "cost": -1,
		"description": "引いた時、\n脆弱を1受ける。",
		"rarity": "common",
		"type": "status",
		"temporary": true
	},
	"restraint": {
		"id": "restraint", "name": "拘束", "cost": -1,
		"description": "手札に残ると\n次のドロー-1。",
		"rarity": "common",
		"type": "status",
		"temporary": true
	},
	"judgement": {
		"id": "judgement", "name": "裁き", "cost": -1,
		"description": "手札に残ると\n4ダメージ。",
		"rarity": "common",
		"type": "curse",
		"temporary": true
	},
	"pressure": {
		"id": "pressure", "name": "重圧", "cost": -1,
		"description": "引いた時、\nエナジー-1。",
		"rarity": "common",
		"type": "status",
		"temporary": true
	},
	"poison_blade": {
		"id": "poison_blade", "name": "毒刃", "cost": -1,
		"description": "引いた時、\n2ダメージと脱力。",
		"rarity": "common",
		"type": "status",
		"temporary": true
	},
	"illusion": {
		"id": "illusion", "name": "幻惑", "cost": -1,
		"description": "引いた時、\nエナジー-1。",
		"rarity": "common",
		"type": "status",
		"temporary": true
	},
	"guilt": {
		"id": "guilt", "name": "罪悪感", "cost": -1,
		"description": "手札に残ると\nHPを2失う。",
		"rarity": "common",
		"type": "curse",
		"temporary": true
	},
	"magic_disruption": {
		"id": "magic_disruption", "name": "魔力乱れ", "cost": -1,
		"description": "引いた時、\nエナジー-1。",
		"rarity": "common",
		"type": "status",
		"temporary": true
	},
	"bleeding": {
		"id": "bleeding", "name": "出血", "cost": -1,
		"description": "手札に残ると\n3ダメージ。",
		"rarity": "common",
		"type": "status",
		"temporary": true
	},
	"petrified_shard": {
		"id": "petrified_shard", "name": "石化の欠片", "cost": -1,
		"description": "引いた時、\n脱力を1受ける。",
		"rarity": "common",
		"type": "status",
		"temporary": true
	},
	"dragon_burn": {
		"id": "dragon_burn", "name": "竜の火傷", "cost": -1,
		"description": "引いた時、\n4ダメージ。",
		"rarity": "common",
		"type": "status",
		"temporary": true
	},
	"fairy_mischief": {
		"id": "fairy_mischief", "name": "妖精の悪戯", "cost": -1,
		"description": "引いた時、\n1ダメージとエナジー-1。",
		"rarity": "common",
		"type": "status",
		"temporary": true
	},
}

# ── Enemy definitions ─────────────────────────────────────────────────────────
const ENEMY_IDS: Array = [
	"holy_soldier",
	"temple_archer",
	"inquisitor",
	"paladin_captain",
	"young_swordsman",
	"novice_cleric",
	"bounty_hunter",
	"chain_jailer",
	"sun_priest",
	"white_shield_knight",
	"fallen_saint",
	"sage_of_the_party",
	"hunter_companion",
	"hero",
	"forest_hunter",
	"mercenary_axeman",
	"poison_rogue",
	"war_mage",
	"battle_scavenger",
	"war_wolf",
	"wyvern_dragon",
	"stone_golem",
	"dark_fairy",
	"royal_guard",
	"alley_duelist",
	"royal_mage",
	"prison_guard",
	"hired_knight",
	"beastman_mercenary",
	"elven_city_archer",
	"foxkin_spy",
	"elven_court_mage",
	"wolfkin_guard",
	"palace_steward",
	"throne_guard",
	"king_hound",
	"living_holy_armor",
	"chancellor",
]

const ENEMY_POOLS: Dictionary = {
	"act1_normal": ["young_swordsman", "forest_hunter", "mercenary_axeman", "poison_rogue", "battle_scavenger", "war_wolf", "dark_fairy", "bounty_hunter"],
	"act1_elite": ["stone_golem", "war_mage", "wyvern_dragon"],
	"act1_boss": ["hunter_companion"],
	"act2_normal": ["royal_guard", "alley_duelist", "prison_guard", "beastman_mercenary", "elven_city_archer", "foxkin_spy", "chain_jailer", "novice_cleric", "elven_court_mage"],
	"act2_elite": ["royal_mage", "hired_knight", "wolfkin_guard"],
	"act2_boss": ["fallen_saint"],
	"act3_normal": ["holy_soldier", "temple_archer", "sun_priest", "palace_steward", "throne_guard", "king_hound", "living_holy_armor"],
	"act3_elite": ["inquisitor", "paladin_captain", "chancellor"],
	"act3_boss": ["hero"],
}

const ENEMIES: Dictionary = {
	"holy_soldier": {
		"id": "holy_soldier", "enemy_id": "holy_soldier", "name": "聖都兵", "name_jp": "聖都兵", "enemy_name": "聖都兵", "display_name": "聖都兵",
		"image_path": "res://assets/enemies/holy_soldier.png", "sprite_path": "res://assets/enemies/holy_soldier.png",
		"max_hp": 36, "hp": 36, "attack": 7, "block": 6, "enemy_type": "holy_soldier", "turn_count": 0, "next_action": {}, "is_boss": false,
		"shape": "sprite_enemy", "sprite_scale": 0.63, "sprite_offset": Vector2(0, 157), "enemy_name_offset": Vector2(0, -240), "enemy_hp_offset": Vector2(0, -214), "enemy_status_offset": Vector2(0, -190), "hp_bar_width": 166.0, "intent_offset": Vector2(225, -78), "glow_color": Color(0.95, 0.82, 0.38), "aura_color": Color(0.95, 0.82, 0.38), "aura_strength": 0.12, "shadow_scale": Vector2(1.20, 1.0)
	},
	"temple_archer": {
		"id": "temple_archer", "enemy_id": "temple_archer", "name": "神殿弓兵", "name_jp": "神殿弓兵", "enemy_name": "神殿弓兵", "display_name": "神殿弓兵",
		"image_path": "res://assets/enemies/temple_archer.png", "sprite_path": "res://assets/enemies/temple_archer.png",
		"max_hp": 32, "hp": 32, "attack": 6, "block": 5, "enemy_type": "temple_archer", "turn_count": 0, "next_action": {}, "is_boss": false,
		"shape": "sprite_enemy", "sprite_scale": 0.54, "sprite_offset": Vector2(0, 150), "enemy_name_offset": Vector2(0, -250), "enemy_hp_offset": Vector2(0, -224), "enemy_status_offset": Vector2(0, -200), "hp_bar_width": 176.0, "intent_offset": Vector2(225, -78), "glow_color": Color(0.88, 0.68, 0.34), "aura_color": Color(0.88, 0.68, 0.34), "aura_strength": 0.09, "shadow_scale": Vector2(1.05, 0.90)
	},
	"inquisitor": {
		"id": "inquisitor", "enemy_id": "inquisitor", "name": "異端審問官", "name_jp": "異端審問官", "enemy_name": "異端審問官", "display_name": "異端審問官",
		"image_path": "res://assets/enemies/inquisitor.png", "sprite_path": "res://assets/enemies/inquisitor.png",
		"max_hp": 54, "hp": 54, "attack": 8, "block": 8, "enemy_type": "inquisitor", "turn_count": 0, "next_action": {}, "is_boss": false,
		"shape": "sprite_enemy", "sprite_scale": 0.54, "sprite_offset": Vector2(0, 150), "enemy_name_offset": Vector2(0, -250), "enemy_hp_offset": Vector2(0, -224), "enemy_status_offset": Vector2(0, -200), "hp_bar_width": 188.0, "intent_offset": Vector2(225, -78), "glow_color": Color(0.84, 0.62, 0.30), "aura_color": Color(0.84, 0.62, 0.30), "aura_strength": 0.10, "shadow_scale": Vector2(1.10, 0.92)
	},
	"paladin_captain": {
		"id": "paladin_captain", "enemy_id": "paladin_captain", "name": "聖騎士隊長", "name_jp": "聖騎士隊長", "enemy_name": "聖騎士隊長", "display_name": "聖騎士隊長",
		"image_path": "res://assets/enemies/paladin_captain.png", "sprite_path": "res://assets/enemies/paladin_captain.png",
		"max_hp": 84, "hp": 84, "attack": 10, "block": 11, "enemy_type": "paladin_captain", "turn_count": 0, "next_action": {}, "is_boss": false,
		"shape": "sprite_enemy", "sprite_scale": 0.58, "sprite_offset": Vector2(0, 150), "enemy_name_offset": Vector2(0, -254), "enemy_hp_offset": Vector2(0, -228), "enemy_status_offset": Vector2(0, -204), "hp_bar_width": 196.0, "intent_offset": Vector2(225, -82), "glow_color": Color(1.0, 0.78, 0.34), "aura_color": Color(1.0, 0.78, 0.34), "aura_strength": 0.13, "shadow_scale": Vector2(1.14, 0.94)
	},
	"young_swordsman": {
		"id": "young_swordsman", "enemy_id": "young_swordsman", "name": "若き剣士", "name_jp": "若き剣士", "enemy_name": "若き剣士", "display_name": "若き剣士",
		"image_path": "res://assets/enemies/young_swordsman.png", "sprite_path": "res://assets/enemies/young_swordsman.png",
		"max_hp": 34, "hp": 34, "attack": 7, "block": 5, "enemy_type": "young_swordsman", "turn_count": 0, "next_action": {}, "is_boss": false,
		"shape": "sprite_enemy", "sprite_scale": 0.56, "sprite_offset": Vector2(0, 150), "enemy_name_offset": Vector2(0, -248), "enemy_hp_offset": Vector2(0, -222), "enemy_status_offset": Vector2(0, -198), "hp_bar_width": 176.0, "intent_offset": Vector2(225, -78), "glow_color": Color(0.72, 0.64, 0.48), "aura_color": Color(0.72, 0.64, 0.48), "aura_strength": 0.08, "shadow_scale": Vector2(1.08, 0.90)
	},
	"novice_cleric": {
		"id": "novice_cleric", "enemy_id": "novice_cleric", "name": "僧侶見習い", "name_jp": "僧侶見習い", "enemy_name": "僧侶見習い", "display_name": "僧侶見習い",
		"image_path": "res://assets/enemies/novice_cleric.png", "sprite_path": "res://assets/enemies/novice_cleric.png",
		"max_hp": 30, "hp": 30, "attack": 5, "block": 7, "enemy_type": "novice_cleric", "turn_count": 0, "next_action": {}, "is_boss": false,
		"shape": "sprite_enemy", "sprite_scale": 0.54, "sprite_offset": Vector2(0, 150), "enemy_name_offset": Vector2(0, -248), "enemy_hp_offset": Vector2(0, -222), "enemy_status_offset": Vector2(0, -198), "hp_bar_width": 176.0, "intent_offset": Vector2(225, -78), "glow_color": Color(0.86, 0.82, 0.55), "aura_color": Color(0.86, 0.82, 0.55), "aura_strength": 0.10, "shadow_scale": Vector2(1.04, 0.88)
	},
	"bounty_hunter": {
		"id": "bounty_hunter", "enemy_id": "bounty_hunter", "name": "賞金稼ぎ", "name_jp": "賞金稼ぎ", "enemy_name": "賞金稼ぎ", "display_name": "賞金稼ぎ",
		"image_path": "res://assets/enemies/bounty_hunter.png", "sprite_path": "res://assets/enemies/bounty_hunter.png",
		"max_hp": 46, "hp": 46, "attack": 11, "block": 7, "enemy_type": "bounty_hunter", "turn_count": 0, "next_action": {}, "is_boss": false,
		"shape": "sprite_enemy", "sprite_scale": 0.56, "sprite_offset": Vector2(0, 150), "enemy_name_offset": Vector2(0, -248), "enemy_hp_offset": Vector2(0, -222), "enemy_status_offset": Vector2(0, -198), "hp_bar_width": 182.0, "intent_offset": Vector2(225, -78), "glow_color": Color(0.80, 0.50, 0.32), "aura_color": Color(0.80, 0.50, 0.32), "aura_strength": 0.08, "shadow_scale": Vector2(1.10, 0.90)
	},
	"chain_jailer": {
		"id": "chain_jailer", "enemy_id": "chain_jailer", "name": "鎖の看守", "name_jp": "鎖の看守", "enemy_name": "鎖の看守", "display_name": "鎖の看守",
		"image_path": "res://assets/enemies/chain_jailer.png", "sprite_path": "res://assets/enemies/chain_jailer.png",
		"max_hp": 52, "hp": 52, "attack": 8, "block": 10, "enemy_type": "chain_jailer", "turn_count": 0, "next_action": {}, "is_boss": false,
		"shape": "sprite_enemy", "sprite_scale": 0.58, "sprite_offset": Vector2(0, 150), "enemy_name_offset": Vector2(0, -250), "enemy_hp_offset": Vector2(0, -224), "enemy_status_offset": Vector2(0, -200), "hp_bar_width": 184.0, "intent_offset": Vector2(225, -78), "glow_color": Color(0.58, 0.58, 0.66), "aura_color": Color(0.58, 0.58, 0.66), "aura_strength": 0.08, "shadow_scale": Vector2(1.12, 0.92)
	},
	"sun_priest": {
		"id": "sun_priest", "enemy_id": "sun_priest", "name": "太陽司祭", "name_jp": "太陽司祭", "enemy_name": "太陽司祭", "display_name": "太陽司祭",
		"image_path": "res://assets/enemies/sun_priest.png", "sprite_path": "res://assets/enemies/sun_priest.png",
		"max_hp": 48, "hp": 48, "attack": 7, "block": 8, "enemy_type": "sun_priest", "turn_count": 0, "next_action": {}, "is_boss": false,
		"shape": "sprite_enemy", "sprite_scale": 0.56, "sprite_offset": Vector2(0, 150), "enemy_name_offset": Vector2(0, -250), "enemy_hp_offset": Vector2(0, -224), "enemy_status_offset": Vector2(0, -200), "hp_bar_width": 184.0, "intent_offset": Vector2(225, -78), "glow_color": Color(1.0, 0.86, 0.36), "aura_color": Color(1.0, 0.86, 0.36), "aura_strength": 0.12, "shadow_scale": Vector2(1.06, 0.90)
	},
	"white_shield_knight": {
		"id": "white_shield_knight", "enemy_id": "white_shield_knight", "name": "白盾の騎士", "name_jp": "白盾の騎士", "enemy_name": "白盾の騎士", "display_name": "白盾の騎士",
		"image_path": "res://assets/enemies/white_shield_knight.png", "sprite_path": "res://assets/enemies/white_shield_knight.png",
		"max_hp": 120, "hp": 120, "attack": 12, "block": 16, "enemy_type": "white_shield_knight", "turn_count": 0, "next_action": {}, "is_boss": false,
		"shape": "sprite_enemy", "sprite_scale": 0.59, "sprite_offset": Vector2(0, 154), "enemy_name_offset": Vector2(0, -254), "enemy_hp_offset": Vector2(0, -228), "enemy_status_offset": Vector2(0, -204), "hp_bar_width": 196.0, "intent_offset": Vector2(225, -82), "glow_color": Color(0.88, 0.92, 1.0), "aura_color": Color(0.88, 0.92, 1.0), "aura_strength": 0.12, "shadow_scale": Vector2(1.18, 0.94)
	},
	"fallen_saint": {
		"id": "fallen_saint", "enemy_id": "fallen_saint", "name": "偽りの聖女", "name_jp": "偽りの聖女", "enemy_name": "偽りの聖女", "display_name": "偽りの聖女",
		"image_path": "res://assets/enemies/fallen_saint.png", "sprite_path": "res://assets/enemies/fallen_saint.png",
		"max_hp": 76, "hp": 76, "attack": 9, "block": 10, "enemy_type": "fallen_saint", "turn_count": 0, "next_action": {}, "is_boss": false,
		"shape": "sprite_enemy", "sprite_scale": 0.58, "sprite_offset": Vector2(0, 153), "enemy_name_offset": Vector2(0, -254), "enemy_hp_offset": Vector2(0, -228), "enemy_status_offset": Vector2(0, -204), "hp_bar_width": 190.0, "intent_offset": Vector2(225, -82), "glow_color": Color(0.96, 0.70, 0.96), "aura_color": Color(0.96, 0.70, 0.96), "aura_strength": 0.11, "shadow_scale": Vector2(1.12, 0.92)
	},
	"sage_of_the_party": {
		"id": "sage_of_the_party", "enemy_id": "sage_of_the_party", "name": "叡智の賢者", "name_jp": "叡智の賢者", "enemy_name": "叡智の賢者", "display_name": "叡智の賢者",
		"image_path": "res://assets/enemies/sage_of_the_party.png", "sprite_path": "res://assets/enemies/sage_of_the_party.png",
		"max_hp": 72, "hp": 72, "attack": 12, "block": 8, "enemy_type": "sage_of_the_party", "turn_count": 0, "next_action": {}, "is_boss": false,
		"shape": "sprite_enemy", "sprite_scale": 0.56, "sprite_offset": Vector2(0, 150), "enemy_name_offset": Vector2(0, -254), "enemy_hp_offset": Vector2(0, -228), "enemy_status_offset": Vector2(0, -204), "hp_bar_width": 190.0, "intent_offset": Vector2(225, -82), "glow_color": Color(0.54, 0.72, 1.0), "aura_color": Color(0.54, 0.72, 1.0), "aura_strength": 0.12, "shadow_scale": Vector2(1.10, 0.92)
	},
	"hunter_companion": {
		"id": "hunter_companion", "enemy_id": "hunter_companion", "name": "かつての狩人", "name_jp": "かつての狩人", "enemy_name": "かつての狩人", "display_name": "かつての狩人",
		"image_path": "res://assets/enemies/hunter_companion.png", "sprite_path": "res://assets/enemies/hunter_companion.png",
		"max_hp": 70, "hp": 70, "attack": 6, "block": 9, "enemy_type": "hunter_companion", "turn_count": 0, "next_action": {}, "is_boss": false,
		"shape": "sprite_enemy", "sprite_scale": 0.58, "sprite_offset": Vector2(0, 161), "enemy_name_offset": Vector2(0, -254), "enemy_hp_offset": Vector2(0, -228), "enemy_status_offset": Vector2(0, -204), "hp_bar_width": 190.0, "intent_offset": Vector2(225, -82), "glow_color": Color(0.70, 0.82, 0.52), "aura_color": Color(0.70, 0.82, 0.52), "aura_strength": 0.10, "shadow_scale": Vector2(1.12, 0.90)
	},
	"hero": {
		"id": "hero", "enemy_id": "hero", "name": "勇者", "name_jp": "勇者", "enemy_name": "勇者", "display_name": "勇者",
		"image_path": "res://assets/enemies/hero.png", "sprite_path": "res://assets/enemies/hero.png",
		"max_hp": 140, "hp": 140, "attack": 13, "block": 14, "enemy_type": "hero", "turn_count": 0, "next_action": {}, "phase": 1, "enraged": false, "is_boss": true,
		"shape": "sprite_enemy", "sprite_scale": 0.58, "sprite_offset": Vector2(0, 152), "enemy_name_offset": Vector2(0, -240), "enemy_hp_offset": Vector2(0, -214), "enemy_status_offset": Vector2(0, -190), "hp_bar_width": 200.0, "intent_offset": Vector2(235, -88), "glow_color": Color(1.0, 0.82, 0.34), "aura_color": Color(1.0, 0.84, 0.40), "aura_strength": 0.15, "shadow_scale": Vector2(1.18, 1.0)
	},
	"forest_hunter": {
		"id": "forest_hunter", "enemy_id": "forest_hunter", "name": "森の追跡者", "name_jp": "森の追跡者", "enemy_name": "森の追跡者", "display_name": "森の追跡者",
		"image_path": "res://assets/enemies/forest_hunter.png", "sprite_path": "res://assets/enemies/forest_hunter.png",
		"max_hp": 40, "hp": 40, "attack": 5, "block": 7, "enemy_type": "forest_hunter", "turn_count": 0, "next_action": {}, "is_boss": false,
		"shape": "sprite_enemy", "sprite_scale": 0.56, "sprite_offset": Vector2(0, 150), "enemy_name_offset": Vector2(0, -248), "enemy_hp_offset": Vector2(0, -222), "enemy_status_offset": Vector2(0, -198), "hp_bar_width": 176.0, "intent_offset": Vector2(225, -78), "glow_color": Color(0.46, 0.76, 0.44), "aura_color": Color(0.46, 0.76, 0.44), "aura_strength": 0.09, "shadow_scale": Vector2(1.06, 0.88)
	},
	"mercenary_axeman": {
		"id": "mercenary_axeman", "enemy_id": "mercenary_axeman", "name": "傭兵斧使い", "name_jp": "傭兵斧使い", "enemy_name": "傭兵斧使い", "display_name": "傭兵斧使い",
		"image_path": "res://assets/enemies/mercenary_axeman.png", "sprite_path": "res://assets/enemies/mercenary_axeman.png",
		"max_hp": 56, "hp": 56, "attack": 12, "block": 6, "enemy_type": "mercenary_axeman", "turn_count": 0, "next_action": {}, "charged_attack": false, "is_boss": false,
		"shape": "sprite_enemy", "sprite_scale": 0.57, "sprite_offset": Vector2(0, 151), "enemy_name_offset": Vector2(0, -250), "enemy_hp_offset": Vector2(0, -224), "enemy_status_offset": Vector2(0, -200), "hp_bar_width": 184.0, "intent_offset": Vector2(225, -78), "glow_color": Color(0.86, 0.48, 0.30), "aura_color": Color(0.86, 0.48, 0.30), "aura_strength": 0.09, "shadow_scale": Vector2(1.18, 0.92)
	},
	"poison_rogue": {
		"id": "poison_rogue", "enemy_id": "poison_rogue", "name": "毒刃の盗賊", "name_jp": "毒刃の盗賊", "enemy_name": "毒刃の盗賊", "display_name": "毒刃の盗賊",
		"image_path": "res://assets/enemies/poison_rogue.png", "sprite_path": "res://assets/enemies/poison_rogue.png",
		"max_hp": 42, "hp": 42, "attack": 4, "block": 7, "enemy_type": "poison_rogue", "turn_count": 0, "next_action": {}, "is_boss": false,
		"shape": "sprite_enemy", "sprite_scale": 0.56, "sprite_offset": Vector2(0, 150), "enemy_name_offset": Vector2(0, -248), "enemy_hp_offset": Vector2(0, -222), "enemy_status_offset": Vector2(0, -198), "hp_bar_width": 176.0, "intent_offset": Vector2(225, -78), "glow_color": Color(0.46, 0.82, 0.40), "aura_color": Color(0.46, 0.82, 0.40), "aura_strength": 0.10, "shadow_scale": Vector2(1.06, 0.88)
	},
	"war_mage": {
		"id": "war_mage", "enemy_id": "war_mage", "name": "戦場魔術師", "name_jp": "戦場魔術師", "enemy_name": "戦場魔術師", "display_name": "戦場魔術師",
		"image_path": "res://assets/enemies/war_mage.png", "sprite_path": "res://assets/enemies/war_mage.png",
		"max_hp": 50, "hp": 50, "attack": 10, "block": 7, "enemy_type": "war_mage", "turn_count": 0, "next_action": {}, "is_boss": false,
		"shape": "sprite_enemy", "sprite_scale": 0.56, "sprite_offset": Vector2(0, 150), "enemy_name_offset": Vector2(0, -250), "enemy_hp_offset": Vector2(0, -224), "enemy_status_offset": Vector2(0, -200), "hp_bar_width": 184.0, "intent_offset": Vector2(225, -78), "glow_color": Color(0.62, 0.46, 1.0), "aura_color": Color(0.62, 0.46, 1.0), "aura_strength": 0.11, "shadow_scale": Vector2(1.08, 0.90)
	},
	"battle_scavenger": {
		"id": "battle_scavenger", "enemy_id": "battle_scavenger", "name": "戦場漁り", "name_jp": "戦場漁り", "enemy_name": "戦場漁り", "display_name": "戦場漁り",
		"image_path": "res://assets/enemies/battle_scavenger.png", "sprite_path": "res://assets/enemies/battle_scavenger.png",
		"max_hp": 38, "hp": 38, "attack": 7, "block": 6, "enemy_type": "battle_scavenger", "turn_count": 0, "next_action": {}, "is_boss": false,
		"shape": "sprite_enemy", "sprite_scale": 0.54, "sprite_offset": Vector2(0, 150), "enemy_name_offset": Vector2(0, -248), "enemy_hp_offset": Vector2(0, -222), "enemy_status_offset": Vector2(0, -198), "hp_bar_width": 176.0, "intent_offset": Vector2(225, -78), "glow_color": Color(0.62, 0.52, 0.38), "aura_color": Color(0.62, 0.52, 0.38), "aura_strength": 0.08, "shadow_scale": Vector2(1.04, 0.88)
	},
	"war_wolf": {
		"id": "war_wolf", "enemy_id": "war_wolf", "name": "戦狼", "name_jp": "戦狼", "enemy_name": "戦狼", "display_name": "戦狼",
		"image_path": "res://assets/enemies/war_wolf.png", "sprite_path": "res://assets/enemies/war_wolf.png",
		"max_hp": 44, "hp": 44, "attack": 5, "block": 5, "enemy_type": "war_wolf", "turn_count": 0, "next_action": {}, "is_boss": false,
		"shape": "sprite_enemy", "sprite_scale": 0.58, "sprite_offset": Vector2(0, 186), "enemy_name_offset": Vector2(0, -248), "enemy_hp_offset": Vector2(0, -222), "enemy_status_offset": Vector2(0, -198), "hp_bar_width": 176.0, "intent_offset": Vector2(225, -78), "glow_color": Color(0.76, 0.62, 0.52), "aura_color": Color(0.76, 0.62, 0.52), "aura_strength": 0.10, "shadow_scale": Vector2(1.12, 0.86)
	},
	"wyvern_dragon": {
		"id": "wyvern_dragon", "enemy_id": "wyvern_dragon", "name": "飛竜", "name_jp": "飛竜", "enemy_name": "飛竜", "display_name": "飛竜",
		"image_path": "res://assets/enemies/wyvern_dragon.png", "sprite_path": "res://assets/enemies/wyvern_dragon.png",
		"max_hp": 90, "hp": 90, "attack": 13, "block": 10, "enemy_type": "wyvern_dragon", "turn_count": 0, "next_action": {}, "charged_attack": false, "is_boss": false,
		"shape": "sprite_enemy", "sprite_scale": 0.6, "sprite_offset": Vector2(8, 163), "enemy_name_offset": Vector2(0, -254), "enemy_hp_offset": Vector2(0, -228), "enemy_status_offset": Vector2(0, -204), "hp_bar_width": 196.0, "intent_offset": Vector2(235, -88), "glow_color": Color(1.0, 0.42, 0.24), "aura_color": Color(1.0, 0.42, 0.24), "aura_strength": 0.13, "shadow_scale": Vector2(1.35, 0.96)
	},
	"stone_golem": {
		"id": "stone_golem", "enemy_id": "stone_golem", "name": "石像ゴーレム", "name_jp": "石像ゴーレム", "enemy_name": "石像ゴーレム", "display_name": "石像ゴーレム",
		"image_path": "res://assets/enemies/stone_golem.png", "sprite_path": "res://assets/enemies/stone_golem.png",
		"max_hp": 92, "hp": 92, "attack": 12, "block": 18, "enemy_type": "stone_golem", "turn_count": 0, "next_action": {}, "is_boss": false,
		"shape": "sprite_enemy", "sprite_scale": 0.635, "sprite_offset": Vector2(0, 172), "enemy_name_offset": Vector2(0, -254), "enemy_hp_offset": Vector2(0, -228), "enemy_status_offset": Vector2(0, -204), "hp_bar_width": 196.0, "intent_offset": Vector2(225, -82), "glow_color": Color(0.58, 0.62, 0.64), "aura_color": Color(0.58, 0.62, 0.64), "aura_strength": 0.08, "shadow_scale": Vector2(1.30, 0.96)
	},
	"dark_fairy": {
		"id": "dark_fairy", "enemy_id": "dark_fairy", "name": "闇妖精", "name_jp": "闇妖精", "enemy_name": "闇妖精", "display_name": "闇妖精",
		"image_path": "res://assets/enemies/dark_fairy.png", "sprite_path": "res://assets/enemies/dark_fairy.png",
		"max_hp": 60, "hp": 60, "attack": 8, "block": 9, "enemy_type": "dark_fairy", "turn_count": 0, "next_action": {}, "is_boss": false,
		"shape": "sprite_enemy", "sprite_scale": 0.52, "sprite_offset": Vector2(0, 150), "enemy_name_offset": Vector2(0, -250), "enemy_hp_offset": Vector2(0, -224), "enemy_status_offset": Vector2(0, -200), "hp_bar_width": 184.0, "intent_offset": Vector2(225, -78), "glow_color": Color(0.84, 0.36, 1.0), "aura_color": Color(0.84, 0.36, 1.0), "aura_strength": 0.13, "shadow_scale": Vector2(0.92, 0.82)
	},
	"royal_guard": {
		"id": "royal_guard", "enemy_id": "royal_guard", "name": "王都衛兵", "name_jp": "王都衛兵", "enemy_name": "王都衛兵", "display_name": "王都衛兵",
		"image_path": "res://assets/enemies/act2/royal_guard.png", "sprite_path": "res://assets/enemies/act2/royal_guard.png",
		"max_hp": 48, "hp": 48, "attack": 7, "block": 8, "enemy_type": "royal_guard", "turn_count": 0, "next_action": {}, "is_boss": false, "content_act": 2, "future_enemy": true,
		"shape": "sprite_enemy", "sprite_scale": 0.56, "sprite_offset": Vector2(0, 150), "enemy_name_offset": Vector2(0, -248), "enemy_hp_offset": Vector2(0, -222), "enemy_status_offset": Vector2(0, -198), "hp_bar_width": 176.0, "intent_offset": Vector2(225, -78), "glow_color": Color(0.62, 0.66, 0.78), "aura_color": Color(0.62, 0.66, 0.78), "aura_strength": 0.08, "shadow_scale": Vector2(1.08, 0.90)
	},
	"alley_duelist": {
		"id": "alley_duelist", "enemy_id": "alley_duelist", "name": "路地裏の決闘者", "name_jp": "路地裏の決闘者", "enemy_name": "路地裏の決闘者", "display_name": "路地裏の決闘者",
		"image_path": "res://assets/enemies/act2/alley_duelist.png", "sprite_path": "res://assets/enemies/act2/alley_duelist.png",
		"max_hp": 40, "hp": 40, "attack": 10, "block": 0, "enemy_type": "alley_duelist", "turn_count": 0, "next_action": {}, "is_boss": false, "content_act": 2, "future_enemy": true,
		"shape": "sprite_enemy", "sprite_scale": 0.56, "sprite_offset": Vector2(0, 150), "enemy_name_offset": Vector2(0, -248), "enemy_hp_offset": Vector2(0, -222), "enemy_status_offset": Vector2(0, -198), "hp_bar_width": 176.0, "intent_offset": Vector2(225, -78), "glow_color": Color(0.70, 0.52, 0.42), "aura_color": Color(0.70, 0.52, 0.42), "aura_strength": 0.08, "shadow_scale": Vector2(1.08, 0.90)
	},
	"royal_mage": {
		"id": "royal_mage", "enemy_id": "royal_mage", "name": "王宮魔術師", "name_jp": "王宮魔術師", "enemy_name": "王宮魔術師", "display_name": "王宮魔術師",
		"image_path": "res://assets/enemies/act2/royal_mage.png", "sprite_path": "res://assets/enemies/act2/royal_mage.png",
		"max_hp": 64, "hp": 64, "attack": 8, "block": 14, "enemy_type": "royal_mage", "turn_count": 0, "next_action": {}, "is_boss": false, "content_act": 2, "future_enemy": true,
		"shape": "sprite_enemy", "sprite_scale": 0.56, "sprite_offset": Vector2(0, 150), "enemy_name_offset": Vector2(0, -250), "enemy_hp_offset": Vector2(0, -224), "enemy_status_offset": Vector2(0, -200), "hp_bar_width": 184.0, "intent_offset": Vector2(225, -78), "glow_color": Color(0.58, 0.48, 0.92), "aura_color": Color(0.58, 0.48, 0.92), "aura_strength": 0.10, "shadow_scale": Vector2(1.08, 0.90)
	},
	"prison_guard": {
		"id": "prison_guard", "enemy_id": "prison_guard", "name": "牢獄番", "name_jp": "牢獄番", "enemy_name": "牢獄番", "display_name": "牢獄番",
		"image_path": "res://assets/enemies/act2/prison_guard.png", "sprite_path": "res://assets/enemies/act2/prison_guard.png",
		"max_hp": 54, "hp": 54, "attack": 11, "block": 0, "enemy_type": "prison_guard", "turn_count": 0, "next_action": {}, "is_boss": false, "content_act": 2, "future_enemy": true,
		"shape": "sprite_enemy", "sprite_scale": 0.56, "sprite_offset": Vector2(0, 150), "enemy_name_offset": Vector2(0, -248), "enemy_hp_offset": Vector2(0, -222), "enemy_status_offset": Vector2(0, -198), "hp_bar_width": 176.0, "intent_offset": Vector2(225, -78), "glow_color": Color(0.54, 0.54, 0.60), "aura_color": Color(0.54, 0.54, 0.60), "aura_strength": 0.08, "shadow_scale": Vector2(1.08, 0.90)
	},
	"hired_knight": {
		"id": "hired_knight", "enemy_id": "hired_knight", "name": "雇われ騎士", "name_jp": "雇われ騎士", "enemy_name": "雇われ騎士", "display_name": "雇われ騎士",
		"image_path": "res://assets/enemies/act2/hired_knight.png", "sprite_path": "res://assets/enemies/act2/hired_knight.png",
		"max_hp": 78, "hp": 78, "attack": 12, "block": 16, "enemy_type": "hired_knight", "turn_count": 0, "next_action": {}, "is_boss": false, "content_act": 2, "future_enemy": true,
		"shape": "sprite_enemy", "sprite_scale": 0.58, "sprite_offset": Vector2(0, 150), "enemy_name_offset": Vector2(0, -250), "enemy_hp_offset": Vector2(0, -224), "enemy_status_offset": Vector2(0, -200), "hp_bar_width": 184.0, "intent_offset": Vector2(225, -78), "glow_color": Color(0.72, 0.60, 0.46), "aura_color": Color(0.72, 0.60, 0.46), "aura_strength": 0.08, "shadow_scale": Vector2(1.12, 0.92)
	},
	"beastman_mercenary": {
		"id": "beastman_mercenary", "enemy_id": "beastman_mercenary", "name": "獣人傭兵", "name_jp": "獣人傭兵", "enemy_name": "獣人傭兵", "display_name": "獣人傭兵",
		"image_path": "res://assets/enemies/act2/beastman_mercenary.png", "sprite_path": "res://assets/enemies/act2/beastman_mercenary.png",
		"max_hp": 52, "hp": 52, "attack": 9, "block": 0, "enemy_type": "beastman_mercenary", "turn_count": 0, "next_action": {}, "is_boss": false, "content_act": 2, "future_enemy": true,
		"shape": "sprite_enemy", "sprite_scale": 0.58, "sprite_offset": Vector2(0, 150), "enemy_name_offset": Vector2(0, -250), "enemy_hp_offset": Vector2(0, -224), "enemy_status_offset": Vector2(0, -200), "hp_bar_width": 184.0, "intent_offset": Vector2(225, -78), "glow_color": Color(0.58, 0.48, 0.36), "aura_color": Color(0.58, 0.48, 0.36), "aura_strength": 0.08, "shadow_scale": Vector2(1.12, 0.92)
	},
	"elven_city_archer": {
		"id": "elven_city_archer", "enemy_id": "elven_city_archer", "name": "エルフの王都射手", "name_jp": "エルフの王都射手", "enemy_name": "エルフの王都射手", "display_name": "エルフの王都射手",
		"image_path": "res://assets/enemies/act2/elven_city_archer.png", "sprite_path": "res://assets/enemies/act2/elven_city_archer.png",
		"max_hp": 38, "hp": 38, "attack": 7, "block": 0, "enemy_type": "elven_city_archer", "turn_count": 0, "next_action": {}, "is_boss": false, "content_act": 2, "future_enemy": true,
		"shape": "sprite_enemy", "sprite_scale": 0.54, "sprite_offset": Vector2(0, 150), "enemy_name_offset": Vector2(0, -250), "enemy_hp_offset": Vector2(0, -224), "enemy_status_offset": Vector2(0, -200), "hp_bar_width": 184.0, "intent_offset": Vector2(225, -78), "glow_color": Color(0.50, 0.72, 0.48), "aura_color": Color(0.50, 0.72, 0.48), "aura_strength": 0.09, "shadow_scale": Vector2(1.04, 0.88)
	},
	"foxkin_spy": {
		"id": "foxkin_spy", "enemy_id": "foxkin_spy", "name": "狐獣人の密偵", "name_jp": "狐獣人の密偵", "enemy_name": "狐獣人の密偵", "display_name": "狐獣人の密偵",
		"image_path": "res://assets/enemies/act2/foxkin_spy.png", "sprite_path": "res://assets/enemies/act2/foxkin_spy.png",
		"max_hp": 38, "hp": 38, "attack": 6, "block": 8, "enemy_type": "foxkin_spy", "turn_count": 0, "next_action": {}, "is_boss": false, "content_act": 2, "future_enemy": true,
		"shape": "sprite_enemy", "sprite_scale": 0.54, "sprite_offset": Vector2(0, 150), "enemy_name_offset": Vector2(0, -248), "enemy_hp_offset": Vector2(0, -222), "enemy_status_offset": Vector2(0, -198), "hp_bar_width": 176.0, "intent_offset": Vector2(225, -78), "glow_color": Color(0.76, 0.50, 0.38), "aura_color": Color(0.76, 0.50, 0.38), "aura_strength": 0.08, "shadow_scale": Vector2(1.04, 0.88)
	},
	"elven_court_mage": {
		"id": "elven_court_mage", "enemy_id": "elven_court_mage", "name": "エルフの宮廷術師", "name_jp": "エルフの宮廷術師", "enemy_name": "エルフの宮廷術師", "display_name": "エルフの宮廷術師",
		"image_path": "res://assets/enemies/act2/elven_court_mage.png", "sprite_path": "res://assets/enemies/act2/elven_court_mage.png",
		"max_hp": 62, "hp": 62, "attack": 9, "block": 6, "enemy_type": "elven_court_mage", "turn_count": 0, "next_action": {}, "is_boss": false, "content_act": 2, "future_enemy": true,
		"shape": "sprite_enemy", "sprite_scale": 0.56, "sprite_offset": Vector2(0, 150), "enemy_name_offset": Vector2(0, -250), "enemy_hp_offset": Vector2(0, -224), "enemy_status_offset": Vector2(0, -200), "hp_bar_width": 184.0, "intent_offset": Vector2(225, -78), "glow_color": Color(0.54, 0.76, 0.68), "aura_color": Color(0.54, 0.76, 0.68), "aura_strength": 0.10, "shadow_scale": Vector2(1.08, 0.90)
	},
	"wolfkin_guard": {
		"id": "wolfkin_guard", "enemy_id": "wolfkin_guard", "name": "狼獣人の近衛", "name_jp": "狼獣人の近衛", "enemy_name": "狼獣人の近衛", "display_name": "狼獣人の近衛",
		"image_path": "res://assets/enemies/act2/wolfkin_guard.png", "sprite_path": "res://assets/enemies/act2/wolfkin_guard.png",
		"max_hp": 84, "hp": 84, "attack": 10, "block": 14, "enemy_type": "wolfkin_guard", "turn_count": 0, "next_action": {}, "is_boss": false, "content_act": 2, "future_enemy": true,
		"shape": "sprite_enemy", "sprite_scale": 0.58, "sprite_offset": Vector2(0, 150), "enemy_name_offset": Vector2(0, -250), "enemy_hp_offset": Vector2(0, -224), "enemy_status_offset": Vector2(0, -200), "hp_bar_width": 184.0, "intent_offset": Vector2(225, -78), "glow_color": Color(0.50, 0.56, 0.62), "aura_color": Color(0.50, 0.56, 0.62), "aura_strength": 0.09, "shadow_scale": Vector2(1.12, 0.90)
	},
	"palace_steward": {
		"id": "palace_steward", "enemy_id": "palace_steward", "name": "王宮侍従長", "name_jp": "王宮侍従長", "enemy_name": "王宮侍従長", "display_name": "王宮侍従長",
		"image_path": "res://assets/enemies/act3/palace_steward.png", "sprite_path": "res://assets/enemies/act3/palace_steward.png",
		"max_hp": 46, "hp": 46, "attack": 5, "block": 0, "enemy_type": "palace_steward", "turn_count": 0, "next_action": {}, "is_boss": false, "content_act": 3, "future_enemy": true,
		"shape": "sprite_enemy", "sprite_scale": 0.56, "sprite_offset": Vector2(0, 150), "enemy_name_offset": Vector2(0, -250), "enemy_hp_offset": Vector2(0, -224), "enemy_status_offset": Vector2(0, -200), "hp_bar_width": 184.0, "intent_offset": Vector2(225, -78), "glow_color": Color(0.80, 0.68, 0.48), "aura_color": Color(0.80, 0.68, 0.48), "aura_strength": 0.08, "shadow_scale": Vector2(1.06, 0.88)
	},
	"throne_guard": {
		"id": "throne_guard", "enemy_id": "throne_guard", "name": "玉座の間の衛兵", "name_jp": "玉座の間の衛兵", "enemy_name": "玉座の間の衛兵", "display_name": "玉座の間の衛兵",
		"image_path": "res://assets/enemies/act3/throne_guard.png", "sprite_path": "res://assets/enemies/act3/throne_guard.png",
		"max_hp": 64, "hp": 64, "attack": 10, "block": 14, "enemy_type": "throne_guard", "turn_count": 0, "next_action": {}, "is_boss": false, "content_act": 3, "future_enemy": true,
		"shape": "sprite_enemy", "sprite_scale": 0.58, "sprite_offset": Vector2(0, 150), "enemy_name_offset": Vector2(0, -250), "enemy_hp_offset": Vector2(0, -224), "enemy_status_offset": Vector2(0, -200), "hp_bar_width": 188.0, "intent_offset": Vector2(225, -78), "glow_color": Color(0.76, 0.72, 0.62), "aura_color": Color(0.76, 0.72, 0.62), "aura_strength": 0.09, "shadow_scale": Vector2(1.14, 0.92)
	},
	"king_hound": {
		"id": "king_hound", "enemy_id": "king_hound", "name": "王の猟犬", "name_jp": "王の猟犬", "enemy_name": "王の猟犬", "display_name": "王の猟犬",
		"image_path": "res://assets/enemies/act3/king_hound.png", "sprite_path": "res://assets/enemies/act3/king_hound.png",
		"max_hp": 48, "hp": 48, "attack": 5, "block": 0, "enemy_type": "king_hound", "turn_count": 0, "next_action": {}, "is_boss": false, "content_act": 3, "future_enemy": true,
		"shape": "sprite_enemy", "sprite_scale": 0.58, "sprite_offset": Vector2(0, 184), "enemy_name_offset": Vector2(0, -248), "enemy_hp_offset": Vector2(0, -222), "enemy_status_offset": Vector2(0, -198), "hp_bar_width": 176.0, "intent_offset": Vector2(225, -78), "glow_color": Color(0.78, 0.56, 0.42), "aura_color": Color(0.78, 0.56, 0.42), "aura_strength": 0.10, "shadow_scale": Vector2(1.12, 0.86)
	},
	"living_holy_armor": {
		"id": "living_holy_armor", "enemy_id": "living_holy_armor", "name": "生ける聖鎧", "name_jp": "生ける聖鎧", "enemy_name": "生ける聖鎧", "display_name": "生ける聖鎧",
		"image_path": "res://assets/enemies/act3/living_holy_armor.png", "sprite_path": "res://assets/enemies/act3/living_holy_armor.png",
		"max_hp": 86, "hp": 86, "attack": 16, "block": 18, "enemy_type": "living_holy_armor", "turn_count": 0, "next_action": {}, "is_boss": false, "content_act": 3, "future_enemy": true,
		"shape": "sprite_enemy", "sprite_scale": 0.62, "sprite_offset": Vector2(0, 160), "enemy_name_offset": Vector2(0, -254), "enemy_hp_offset": Vector2(0, -228), "enemy_status_offset": Vector2(0, -204), "hp_bar_width": 196.0, "intent_offset": Vector2(225, -82), "glow_color": Color(0.86, 0.84, 0.72), "aura_color": Color(0.86, 0.84, 0.72), "aura_strength": 0.10, "shadow_scale": Vector2(1.24, 0.94)
	},
	"chancellor": {
		"id": "chancellor", "enemy_id": "chancellor", "name": "宰相", "name_jp": "宰相", "enemy_name": "宰相", "display_name": "宰相",
		"image_path": "res://assets/enemies/act3/chancellor.png", "sprite_path": "res://assets/enemies/act3/chancellor.png",
		"max_hp": 58, "hp": 58, "attack": 6, "block": 12, "enemy_type": "chancellor", "turn_count": 0, "next_action": {}, "is_boss": false, "content_act": 3, "future_enemy": true,
		# TODO: 宰相撃破時に物語断片を落とす場合は、この敵IDを報酬分岐で参照する。
		"shape": "sprite_enemy", "sprite_scale": 0.56, "sprite_offset": Vector2(0, 150), "enemy_name_offset": Vector2(0, -250), "enemy_hp_offset": Vector2(0, -224), "enemy_status_offset": Vector2(0, -200), "hp_bar_width": 184.0, "intent_offset": Vector2(225, -78), "glow_color": Color(0.60, 0.46, 0.82), "aura_color": Color(0.60, 0.46, 0.82), "aura_strength": 0.11, "shadow_scale": Vector2(1.06, 0.88)
	},
}

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_init_deck()

func reset_run() -> void:
	player_hp = player_max_hp
	player_block = 0
	player_max_energy = 3
	player_energy = player_max_energy
	player_statuses = {}
	current_battle = 0
	owned_relic_ids = []
	initial_relic_chosen = false
	relic_choice_done = false
	reset_map()
	_init_deck()

func _init_deck() -> void:
	deck = []
	for _i in 5:
		deck.append("old_slash")
	for _i in 4:
		deck.append("worn_guard")
	deck.append("betrayal_blow")
	draw_pile = deck.duplicate()
	hand = []
	discard = []
	exhaust_pile = []
	next_turn_draw_penalty = 0
	combat_log_messages = []
	combat_damage_events = []

func reset_combat_state() -> void:
	hand = []
	discard = []
	exhaust_pile = []
	next_turn_draw_penalty = 0
	combat_log_messages = []
	combat_damage_events = []
	player_block = 0
	player_energy = player_max_energy
	player_statuses = {}
	draw_pile = deck.duplicate()
	draw_pile.shuffle()
	first_attack_used_this_combat = false

# ── Deck management ───────────────────────────────────────────────────────────
func draw_cards(count: int) -> void:
	for _i in count:
		if draw_pile.is_empty():
			if discard.is_empty():
				return
			draw_pile = discard.duplicate()
			discard = []
			draw_pile.shuffle()
		if not draw_pile.is_empty():
			var card_ref = draw_pile.pop_back()
			hand.append(card_ref)
			_trigger_temporary_card_on_draw(card_ref)

func discard_hand() -> void:
	discard.append_array(hand)
	hand = []

func add_card_to_deck(card_id: String) -> void:
	deck.append(card_id)

func create_status_card(card_id: String) -> Dictionary:
	var base = TEMPORARY_STATUS_CARDS.get(card_id, {})
	if base.is_empty():
		base = {
			"id": "unknown_status",
			"name": "不明な状態異常",
			"type": "status",
			"cost": -1,
			"temporary": true,
			"description": "使用できない。"
		}
	var card = base.duplicate(true)
	card["temporary"] = true
	return card

func add_temporary_card_to_draw_pile(card_id: String, amount: int = 1) -> void:
	for _i in maxi(amount, 0):
		draw_pile.append(create_status_card(card_id))
	draw_pile.shuffle()

func add_temporary_card_to_discard_pile(card_id: String, amount: int = 1) -> void:
	for _i in maxi(amount, 0):
		discard.append(create_status_card(card_id))

func trigger_temporary_cards_on_turn_end() -> void:
	for card_ref in hand:
		_trigger_temporary_card_on_turn_end(card_ref)

func consume_draw_penalty() -> int:
	var penalty = next_turn_draw_penalty
	next_turn_draw_penalty = 0
	return penalty

func clear_combat_piles() -> void:
	hand.clear()
	draw_pile.clear()
	discard.clear()
	exhaust_pile.clear()
	next_turn_draw_penalty = 0
	combat_log_messages.clear()
	combat_damage_events.clear()

func get_combat_deck_view_cards() -> Array:
	var cards: Array = []
	_append_deck_view_zone(cards, draw_pile, "山札")
	_append_deck_view_zone(cards, discard, "捨て札")
	_append_deck_view_zone(cards, hand, "手札")
	_append_deck_view_zone(cards, exhaust_pile, "廃棄")
	return cards

func _append_deck_view_zone(result: Array, pile: Array, zone: String) -> void:
	for card_ref in pile:
		result.append({"card_ref": card_ref, "zone": zone})

func can_upgrade_card(card_ref) -> bool:
	var card = get_card(card_ref)
	if card.is_empty():
		return false
	if card.get("temporary", false):
		return false
	if card.get("type", "") == "status" or card.get("type", "") == "curse":
		return false
	if card.get("upgraded", false):
		return false
	return _card_has_upgrade_target(card)

func upgrade_card(card_ref) -> Dictionary:
	var upgraded_card = get_card(card_ref)
	if upgraded_card.is_empty() or upgraded_card.get("upgraded", false):
		return upgraded_card

	upgraded_card["upgraded"] = true
	if not String(upgraded_card.get("name", "")).ends_with("+"):
		upgraded_card["name"] = String(upgraded_card.get("name", "")) + "+"

	var upgraded_effect := false
	var effects: Array = upgraded_card.get("effects", [])
	for effect in effects:
		match effect.get("type", ""):
			"damage", "damage_multi", "vulnerable_bonus_damage":
				effect["value"] = effect.get("value", 0) + 2
				upgraded_effect = true
			"conditional_damage":
				effect["value"] = effect.get("value", 0) + 2
				effect["bonus_value"] = effect.get("bonus_value", effect.get("value", 0)) + 2
				upgraded_effect = true
			"block":
				effect["value"] = effect.get("value", 0) + 2
				upgraded_effect = true
			"draw":
				effect["value"] = effect.get("value", 1) + 1
				upgraded_effect = true
			"heal":
				effect["value"] = effect.get("value", 0) + 2
				upgraded_effect = true
			"apply_status":
				if ["vulnerable", "weak", "poison"].has(effect.get("status", "")):
					effect["amount"] = effect.get("amount", 1) + 1
					upgraded_effect = true
			"poison_burst":
				effect["value"] = effect.get("value", 4) + 1
				upgraded_effect = true
	if not upgraded_effect and upgraded_card.get("cost", 0) > 0:
		upgraded_card["cost"] = upgraded_card.get("cost", 0) - 1
	upgraded_card["effects"] = effects
	upgraded_card["description"] = _make_upgraded_description(upgraded_card)
	return upgraded_card

func upgrade_deck_card(index: int) -> bool:
	if index < 0 or index >= deck.size():
		return false
	if not can_upgrade_card(deck[index]):
		return false
	deck[index] = upgrade_card(deck[index])
	return true

func can_remove_card(card_ref) -> bool:
	var card = get_card(card_ref)
	if card.is_empty():
		return false
	if card.get("temporary", false):
		return false
	if card.get("type", "") == "status" or card.get("type", "") == "curse":
		return false
	return true

func remove_deck_card(index: int) -> bool:
	if deck.size() <= 1:
		return false
	if index < 0 or index >= deck.size():
		return false
	if not can_remove_card(deck[index]):
		return false
	deck.remove_at(index)
	return true

func get_upgradeable_deck_indices() -> Array[int]:
	var result: Array[int] = []
	for i in deck.size():
		if can_upgrade_card(deck[i]):
			result.append(i)
	return result

func get_removable_deck_indices() -> Array[int]:
	var result: Array[int] = []
	if deck.size() <= 1:
		return result
	for i in deck.size():
		if can_remove_card(deck[i]):
			result.append(i)
	return result

func _card_has_upgrade_target(card: Dictionary) -> bool:
	for effect in card.get("effects", []):
		match effect.get("type", ""):
			"damage", "damage_multi", "conditional_damage", "vulnerable_bonus_damage", "block", "draw", "heal", "poison_burst":
				return true
			"apply_status":
				if ["vulnerable", "weak", "poison"].has(effect.get("status", "")):
					return true
	return card.get("cost", 0) > 0

func _make_upgraded_description(card: Dictionary) -> String:
	var parts: Array[String] = []
	var minimum_hp_text := ""
	for effect in card.get("effects", []):
		match effect.get("type", ""):
			"damage":
				parts.append("敵に%dダメージ。" % effect.get("value", 0))
			"damage_multi":
				parts.append("敵に%dダメージを\n%d回与える。" % [effect.get("value", 0), effect.get("times", 1)])
			"vulnerable_bonus_damage":
				parts.append("敵が脆弱なら追加で\n%dダメージ。" % effect.get("value", 0))
			"conditional_damage":
				if effect.get("condition", "") == "missing_hp":
					parts.append("失っているHPが\n%d以上なら%dダメージ。\nそうでなければ%dダメージ。" % [effect.get("threshold", 20), effect.get("bonus_value", effect.get("value", 0)), effect.get("value", 0)])
				else:
					parts.append("敵のHPが半分以下なら\n%dダメージ。そうでなければ\n%dダメージ。" % [effect.get("bonus_value", effect.get("value", 0)), effect.get("value", 0)])
			"block":
				parts.append("ブロックを%d得る。" % effect.get("value", 0))
			"heal":
				parts.append("HPを%d回復。" % effect.get("value", 0))
			"draw":
				parts.append("カードを%d枚引く。" % effect.get("value", 1))
			"gain_energy":
				parts.append("エナジーを%d得る。" % effect.get("value", 1))
			"lose_hp":
				parts.append("HPを%d失う。" % effect.get("value", 0))
				if effect.get("minimum_hp", 0) > 0:
					minimum_hp_text = "最低HPは%d。" % effect.get("minimum_hp", 1)
			"apply_status":
				var target = "敵に" if effect.get("target", "enemy") == "enemy" else "自分に"
				parts.append("%s%sを%d付与。" % [target, _status_description_name(effect.get("status", "")), effect.get("amount", 1)])
			"double_poison":
				parts.append("敵の毒を2倍にする。")
			"poison_burst":
				parts.append("敵の毒1につき\n%dダメージを与え、\n毒をすべて消費する。" % effect.get("value", 4))
			"lose_max_hp":
				parts.append("最大HPが%d減る。" % effect.get("value", 0))
			"self_temp_discard":
				parts.append("「%s」を\n捨て札に混ぜる。" % TEMPORARY_STATUS_CARDS.get(effect.get("card_id", ""), {}).get("name", "お邪魔"))
	if not minimum_hp_text.is_empty():
		parts.append(minimum_hp_text)
	if parts.is_empty():
		return String(card.get("description", ""))
	return "\n".join(parts)

func _status_description_name(status: String) -> String:
	match status:
		"vulnerable":
			return "脆弱"
		"weak":
			return "脱力"
		"poison":
			return "毒"
		_:
			return status

# ── Card helpers ──────────────────────────────────────────────────────────────
func get_card(card_ref) -> Dictionary:
	if card_ref is Dictionary:
		return card_ref.duplicate(true)
	var id := String(card_ref)
	var base = CARDS.get(id, {})
	if base.is_empty():
		return {}
	return base.duplicate(true)

func is_temporary_card(card_ref) -> bool:
	return card_ref is Dictionary and card_ref.get("temporary", false)

func consume_combat_log_messages() -> Array[String]:
	var messages := combat_log_messages.duplicate()
	combat_log_messages.clear()
	return messages

func consume_combat_damage_events() -> Array[Dictionary]:
	var events := combat_damage_events.duplicate(true)
	combat_damage_events.clear()
	return events

func _queue_combat_log(message: String) -> void:
	if not message.is_empty():
		combat_log_messages.append(message)

func _queue_player_damage_event(amount: int, source: String = "") -> void:
	if amount < 0:
		return
	combat_damage_events.append({"target": "player", "amount": amount, "source": source})

func _trigger_temporary_card_on_draw(card_ref) -> void:
	if not is_temporary_card(card_ref):
		return
	match card_ref.get("id", ""):
		"arrow_wound":
			apply_status("vulnerable", 1)
			_queue_combat_log("矢傷が開いた。脆弱を1受けた。")
		"pressure", "illusion", "magic_disruption":
			player_energy = maxi(0, player_energy - 1)
			_queue_combat_log("%sでエナジーを1失った。" % card_ref.get("name", "状態異常"))
		"poison_blade":
			var actual = take_damage(2)
			_queue_player_damage_event(actual, "poison_blade")
			apply_status("weak", 1)
			_queue_combat_log("毒刃を引いた。2ダメージと脱力。")
		"petrified_shard":
			apply_status("weak", 1)
			_queue_combat_log("石化の欠片で脱力を1受けた。")
		"dragon_burn":
			var actual = take_damage(4)
			_queue_player_damage_event(actual, "dragon_burn")
			_queue_combat_log("竜の火傷が燃えた。4ダメージ。")
		"fairy_mischief":
			var actual = take_damage(1)
			_queue_player_damage_event(actual, "fairy_mischief")
			player_energy = maxi(0, player_energy - 1)
			_queue_combat_log("妖精の悪戯で1ダメージとエナジー-1。")

func _trigger_temporary_card_on_turn_end(card_ref) -> void:
	if not is_temporary_card(card_ref):
		return
	match card_ref.get("id", ""):
		"brand_of_sin":
			var actual = mini(2, player_hp)
			player_hp = maxi(0, player_hp - 2)
			_queue_player_damage_event(actual, "brand_of_sin")
			_queue_combat_log("罪の烙印が疼いた。HPを2失った。")
		"guilt":
			var actual = mini(2, player_hp)
			player_hp = maxi(0, player_hp - 2)
			_queue_player_damage_event(actual, "guilt")
			_queue_combat_log("罪悪感に苛まれた。HPを2失った。")
		"judgement":
			var actual = take_damage(4)
			_queue_player_damage_event(actual, "judgement")
			_queue_combat_log("裁きが下った。4ダメージ。")
		"bleeding":
			var actual = take_damage(3)
			_queue_player_damage_event(actual, "bleeding")
			_queue_combat_log("出血が広がった。3ダメージ。")
		"restraint":
			next_turn_draw_penalty += 1
			_queue_combat_log("拘束で次のドローが1枚減る。")

func get_card_rarity_label(rarity: String) -> String:
	match rarity:
		"rare":
			return "レア"
		"epic":
			return "エピック"
		_:
			return "コモン"

func set_map_encounter_enemy(enemy_id: String) -> void:
	if ENEMIES.has(enemy_id):
		map_encounter_enemy_id = enemy_id
		map_encounter_enemy_idx = ENEMY_IDS.find(enemy_id)
		last_enemy_id = enemy_id
	else:
		push_warning("Unknown enemy id: %s" % enemy_id)
		map_encounter_enemy_id = "holy_soldier"
		map_encounter_enemy_idx = 0
		last_enemy_id = map_encounter_enemy_id

func set_debug_enemy(enemy_id: String) -> void:
	debug_enemy_enabled = true
	debug_enemy_id = enemy_id

func clear_debug_enemy() -> void:
	debug_enemy_enabled = false
	debug_enemy_id = ""

func is_valid_enemy_id(enemy_id: String) -> bool:
	return ENEMIES.has(enemy_id)

func get_active_enemy_id_for_combat() -> String:
	if debug_enemy_enabled:
		if is_valid_enemy_id(debug_enemy_id):
			print("DEBUG ENEMY: %s" % debug_enemy_id)
			return debug_enemy_id
		push_warning("Invalid debug_enemy_id: %s. Falling back to map encounter enemy." % debug_enemy_id)
	return map_encounter_enemy_id

func choose_enemy_for_map_node(node_type: String, node_id: String = "") -> String:
	if debug_enemy_enabled and is_valid_enemy_id(debug_enemy_id):
		return debug_enemy_id

	# ノードに敵が固定指定されていればそれを使う(中ボス関門など)
	var fixed_enemy := String(MAP_NODES.get(node_id, {}).get("enemy_id", ""))
	if not fixed_enemy.is_empty() and is_valid_enemy_id(fixed_enemy):
		return fixed_enemy

	var act_prefix := "act%d" % current_act if current_act >= 1 and current_act <= 3 else "act1"
	var pool_key := "%s_normal" % act_prefix
	match node_type:
		"normal_battle":
			pool_key = "%s_normal" % act_prefix
		"elite_battle":
			pool_key = "%s_elite" % act_prefix
		"boss":
			pool_key = "%s_boss" % act_prefix
		_:
			pool_key = "%s_normal" % act_prefix

	# 通常/強敵は袋方式: プール全種を引き切るまで同じ敵は出ない
	if node_type == "normal_battle" or node_type == "elite_battle":
		var picked := _draw_from_enemy_bag(pool_key)
		if not picked.is_empty():
			return picked

	var pool: Array = ENEMY_POOLS.get(pool_key, ENEMY_POOLS["act1_normal"])
	if pool.is_empty():
		return "royal_guard" if current_act >= 2 else "young_swordsman"
	var candidates := pool.duplicate()
	if candidates.size() > 1 and not last_enemy_id.is_empty():
		candidates.erase(last_enemy_id)
	var seed_text := node_id if not node_id.is_empty() else node_type
	var idx = abs(hash("%s:%s" % [seed_text, last_enemy_id])) % candidates.size()
	return candidates[idx]

func _draw_from_enemy_bag(pool_key: String) -> String:
	var pool: Array = ENEMY_POOLS.get(pool_key, [])
	if pool.is_empty():
		return ""
	var bag: Array = enemy_bag_normal if pool_key.ends_with("_normal") else enemy_bag_elite
	if bag.is_empty():
		var refill: Array = pool.duplicate()
		refill.shuffle()
		# 引き直し直後に直前の敵が連続しないようにする
		if refill.size() > 1 and refill.back() == last_enemy_id:
			refill.pop_back()
			refill.insert(0, last_enemy_id)
		bag.assign(refill)
	return bag.pop_back()

func reset_enemy_bags() -> void:
	enemy_bag_normal.clear()
	enemy_bag_elite.clear()

func get_map_node_floor(node_id: String) -> int:
	var node: Dictionary = MAP_NODES.get(node_id, {})
	return int(node.get("layer", 1))

func get_enemy_data(enemy_ref = null) -> Dictionary:
	var enemy_id := ""
	if enemy_ref is String:
		enemy_id = enemy_ref
	elif enemy_ref is int:
		var idx: int = enemy_ref
		if idx >= 0 and idx < ENEMY_IDS.size():
			enemy_id = ENEMY_IDS[idx]
	else:
		enemy_id = map_encounter_enemy_id

	if enemy_id.is_empty() or not ENEMIES.has(enemy_id):
		push_warning("Enemy data not found: %s" % str(enemy_ref))
		enemy_id = "holy_soldier"
	var data = ENEMIES[enemy_id].duplicate(true)
	data["enemy_type"] = data.get("enemy_type", data.get("id", enemy_id))
	return data

func get_reward_options() -> Array:
	var result: Array = []
	var epic_count := 0
	var available := _get_valid_reward_pool()
	if available.is_empty():
		return result

	var choice_count = 3 + get_card_reward_choice_bonus()
	var weights = modify_card_reward_weights(CARD_RARITY_WEIGHTS)

	while result.size() < mini(choice_count, available.size()):
		var rarity = _choose_card_rarity(weights)
		if rarity == "epic" and epic_count >= 1:
			rarity = "rare"
		var card_id = _choose_reward_card_from_rarity(rarity, result)
		if card_id.is_empty():
			card_id = _choose_reward_card_from_rarity("common", result)
		if card_id.is_empty():
			card_id = _choose_any_reward_card(result)
		if card_id.is_empty():
			break
		result.append(card_id)
		if CARDS[card_id].get("rarity", "common") == "epic":
			epic_count += 1
	return result

func _get_valid_reward_pool() -> Array:
	var result: Array = []
	for card_id in CARD_REWARD_POOL:
		if CARDS.has(card_id):
			result.append(card_id)
	return result

func _choose_card_rarity(weights: Dictionary) -> String:
	var total := 0
	for rarity in weights:
		total += int(weights[rarity])
	if total <= 0:
		return "common"
	var roll = randi_range(1, total)
	var acc := 0
	for rarity in weights:
		acc += int(weights[rarity])
		if roll <= acc:
			return String(rarity)
	return "common"

func _choose_reward_card_from_rarity(rarity: String, excluded: Array) -> String:
	var pool: Array = []
	for card_id in CARD_REWARD_POOL:
		if excluded.has(card_id) or not CARDS.has(card_id):
			continue
		if CARDS[card_id].get("rarity", "common") == rarity:
			pool.append(card_id)
	if pool.is_empty():
		return ""
	return pool.pick_random()

func _choose_any_reward_card(excluded: Array) -> String:
	var pool: Array = []
	for card_id in CARD_REWARD_POOL:
		if not excluded.has(card_id) and CARDS.has(card_id):
			pool.append(card_id)
	if pool.is_empty():
		return ""
	return pool.pick_random()

# ── Battle helpers ────────────────────────────────────────────────────────────
func reset_turn_state() -> void:
	player_block = 0
	player_energy = player_max_energy
	_tick_statuses()

func _tick_statuses() -> void:
	var to_remove: Array = []
	for key in player_statuses:
		player_statuses[key] -= 1
		if player_statuses[key] <= 0:
			to_remove.append(key)
	for key in to_remove:
		player_statuses.erase(key)

func apply_block(amount: int) -> void:
	player_block += amount

func take_damage(raw: int) -> int:
	var dmg = raw
	if player_statuses.get("vulnerable", 0) > 0:
		dmg = int(dmg * 1.5)
	var absorbed = mini(player_block, dmg)
	player_block -= absorbed
	dmg -= absorbed
	player_hp = maxi(0, player_hp - dmg)
	return dmg

func heal(amount: int) -> void:
	player_hp = mini(player_max_hp, player_hp + amount)

func apply_status(status: String, amount: int) -> void:
	player_statuses[status] = player_statuses.get(status, 0) + amount

# ── Relic helpers ─────────────────────────────────────────────────────────────
func has_relic(id: String) -> bool:
	return owned_relic_ids.has(id)

func add_relic(id: String) -> void:
	if RELICS.has(id) and not owned_relic_ids.has(id):
		owned_relic_ids.append(id)
		if id == "false_holy_seal":
			player_max_energy += 1
			player_energy = player_max_energy
		elif id == "leaden_heart":
			player_max_hp += 15
			player_hp += 15

## 休憩での回復量(偽りの聖印で半減)
func get_rest_heal_amount() -> int:
	var amount = int(player_max_hp * 0.30) + get_rest_heal_bonus()
	if has_relic("false_holy_seal"):
		amount = int(amount / 2.0)
	return amount

func get_owned_relics() -> Array:
	var result: Array = []
	for id in owned_relic_ids:
		if RELICS.has(id):
			result.append(RELICS[id].duplicate())
	return result

func get_relic_definition(id: String) -> Dictionary:
	return RELICS.get(id, {}).duplicate()

func roll_relic_reward(context: String = "normal") -> String:
	var weights: Dictionary
	if context == "elite":
		weights = RELIC_RARITY_WEIGHTS_ELITE
	elif context == "boss_relic":
		weights = RELIC_RARITY_WEIGHTS_BOSS
	elif context == "start":
		weights = RELIC_RARITY_WEIGHTS_START
	else:
		weights = RELIC_RARITY_WEIGHTS_NORMAL

	var available: Array = []
	for id in RELICS:
		if not owned_relic_ids.has(id) and RELICS[id].get("rarity", "common") != "boss":
			available.append(id)
	if available.is_empty():
		return ""

	var rarity = _choose_card_rarity(weights)
	var pool: Array = []
	for id in available:
		if RELICS[id].get("rarity", "common") == rarity:
			pool.append(id)
	if pool.is_empty():
		pool = available
	return pool.pick_random()

func roll_relic_choices(count: int, context: String = "start") -> Array:
	var weights: Dictionary
	if context == "start":
		weights = RELIC_RARITY_WEIGHTS_START
	elif context == "boss_relic":
		weights = RELIC_RARITY_WEIGHTS_BOSS
	elif context == "elite":
		weights = RELIC_RARITY_WEIGHTS_ELITE
	else:
		weights = RELIC_RARITY_WEIGHTS_NORMAL
	var available: Array = []
	for id in RELICS:
		if not owned_relic_ids.has(id) and RELICS[id].get("rarity", "common") != "boss":
			available.append(id)

	var result: Array = []
	while result.size() < mini(count, available.size()):
		var rarity = _choose_card_rarity(weights)
		var pool: Array = []
		for id in available:
			if not result.has(id) and RELICS[id].get("rarity", "common") == rarity:
				pool.append(id)
		if pool.is_empty():
			for id in available:
				if not result.has(id):
					pool.append(id)
		if pool.is_empty():
			break
		result.append(pool.pick_random())
	return result

func get_attack_damage_bonus(card_type: String = "attack") -> int:
	if card_type != "attack":
		return 0
	var bonus := 0
	if has_relic("avenger_ring"):
		bonus += 1
	if has_relic("hungry_blade"):
		bonus += 3
	return bonus

func get_enemy_half_hp_attack_damage_bonus(card_type: String, enemy_current_hp: int, enemy_max_hp: int) -> int:
	if card_type != "attack" or not has_relic("executioner_mask"):
		return 0
	return 3 if enemy_current_hp <= int(enemy_max_hp / 2) else 0

func get_block_bonus() -> int:
	var bonus := 0
	if has_relic("cracked_amulet"):
		bonus += 2
	return bonus

func get_battle_start_block() -> int:
	return 5 if has_relic("broken_oath_badge") else 0

func get_initial_draw_bonus() -> int:
	return 1 if has_relic("fallen_feather") else 0

func get_turn_energy_bonus(turn_number: int) -> int:
	var bonus := 0
	if has_relic("abyss_core"):
		bonus += 1
	if has_relic("memory_of_betrayal") and turn_number == 1:
		bonus += 1
	return bonus

func get_card_reward_choice_bonus() -> int:
	var bonus := 0
	if has_relic("rotted_crown"):
		bonus += 1
	if has_relic("leaden_heart"):
		bonus -= 1
	return bonus

func modify_card_reward_weights(weights: Dictionary) -> Dictionary:
	var result = weights.duplicate()
	if has_relic("fate_severing_thread"):
		result["rare"] = result.get("rare", 22) + 8
		result["epic"] = result.get("epic", 3) + 5
		result["common"] = maxi(1, result.get("common", 75) - 13)
	return result

func get_rest_heal_bonus() -> int:
	return 8 if has_relic("old_wound_bandage") else 0

func get_hp_loss_block_bonus() -> int:
	return 4 if has_relic("pact_brand") else 0

func get_vulnerable_status_bonus() -> int:
	return 1 if has_relic("chain_of_judgement") else 0

func get_poison_status_bonus() -> int:
	return 1 if has_relic("serpent_fang") else 0
