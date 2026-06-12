extends Node
## ラン途中のオートセーブと通算統計の永続化。
## 保存形式は var_to_str / str_to_var(Godot標準のVariantテキスト表現。型がそのまま保たれる)。
## セーブはマップ画面に戻るたびに行い、ラン終了(勝利・敗北)で削除する。

const RUN_SAVE_PATH = "user://run_save.txt"
const STATS_PATH = "user://stats.txt"
const SAVE_VERSION = 1

# ── ランのセーブ/ロード ──────────────────────────────────────────────────────

func save_run() -> void:
	var data := {
		"version": SAVE_VERSION,
		"player_hp": GameState.player_hp,
		"player_max_hp": GameState.player_max_hp,
		"deck": GameState.deck.duplicate(true),
		"current_act": GameState.current_act,
		"owned_relic_ids": GameState.owned_relic_ids.duplicate(),
		"initial_relic_chosen": GameState.initial_relic_chosen,
		"relic_choice_done": GameState.relic_choice_done,
		"map_current_node_id": GameState.map_current_node_id,
		"map_visited_nodes": GameState.map_visited_nodes.duplicate(),
		"map_available_nodes": GameState.map_available_nodes.duplicate(),
		"map_encounter_enemy_idx": GameState.map_encounter_enemy_idx,
		"map_encounter_enemy_id": GameState.map_encounter_enemy_id,
		"map_encounter_is_boss": GameState.map_encounter_is_boss,
		"last_enemy_id": GameState.last_enemy_id,
		# 任意キー(旧セーブには無くても良い)
		"enemy_bag_normal": GameState.enemy_bag_normal.duplicate(),
		"enemy_bag_elite": GameState.enemy_bag_elite.duplicate(),
		"event_bag": GameState.event_bag.duplicate(),
	}
	_write_variant(RUN_SAVE_PATH, data)

func has_run_save() -> bool:
	return FileAccess.file_exists(RUN_SAVE_PATH)

## セーブを読み込んで GameState に反映する。壊れている場合は削除して false。
func load_run() -> bool:
	var data = _read_variant(RUN_SAVE_PATH)
	if not _is_valid_run_data(data):
		delete_run_save()
		return false
	GameState.player_max_hp = int(data["player_max_hp"])
	GameState.player_hp = clampi(int(data["player_hp"]), 1, GameState.player_max_hp)
	GameState.deck = (data["deck"] as Array).duplicate(true)
	GameState.current_act = int(data["current_act"])
	GameState.apply_act_map()
	GameState.owned_relic_ids = (data["owned_relic_ids"] as Array).duplicate()
	GameState.player_max_energy = 3 + (1 if GameState.has_relic("false_holy_seal") else 0)
	GameState.initial_relic_chosen = bool(data["initial_relic_chosen"])
	GameState.relic_choice_done = bool(data["relic_choice_done"])
	GameState.map_current_node_id = String(data["map_current_node_id"])
	GameState.map_visited_nodes = (data["map_visited_nodes"] as Array).duplicate()
	GameState.map_available_nodes = (data["map_available_nodes"] as Array).duplicate()
	GameState.map_encounter_enemy_idx = int(data["map_encounter_enemy_idx"])
	GameState.map_encounter_enemy_id = String(data["map_encounter_enemy_id"])
	GameState.map_encounter_is_boss = bool(data["map_encounter_is_boss"])
	GameState.last_enemy_id = String(data["last_enemy_id"])
	GameState.enemy_bag_normal = (data.get("enemy_bag_normal", []) as Array).duplicate()
	GameState.enemy_bag_elite = (data.get("enemy_bag_elite", []) as Array).duplicate()
	GameState.event_bag = (data.get("event_bag", []) as Array).duplicate()
	# 戦闘スコープの状態はクリーンに戻す
	GameState.player_block = 0
	GameState.player_energy = GameState.player_max_energy
	GameState.player_statuses = {}
	GameState.clear_combat_piles()
	return true

func delete_run_save() -> void:
	if FileAccess.file_exists(RUN_SAVE_PATH):
		DirAccess.remove_absolute(RUN_SAVE_PATH)

func _is_valid_run_data(data) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if int(data.get("version", 0)) != SAVE_VERSION:
		return false
	var required := {
		"player_hp": TYPE_INT,
		"player_max_hp": TYPE_INT,
		"deck": TYPE_ARRAY,
		"current_act": TYPE_INT,
		"owned_relic_ids": TYPE_ARRAY,
		"initial_relic_chosen": TYPE_BOOL,
		"relic_choice_done": TYPE_BOOL,
		"map_current_node_id": TYPE_STRING,
		"map_visited_nodes": TYPE_ARRAY,
		"map_available_nodes": TYPE_ARRAY,
		"map_encounter_enemy_idx": TYPE_INT,
		"map_encounter_enemy_id": TYPE_STRING,
		"map_encounter_is_boss": TYPE_BOOL,
		"last_enemy_id": TYPE_STRING,
	}
	for key in required:
		if not data.has(key) or typeof(data[key]) != required[key]:
			return false
	if (data["deck"] as Array).is_empty():
		return false
	if int(data["player_hp"]) <= 0:
		return false
	# 保存された幕のマップに対してノードIDを検証する
	var act_map: Dictionary = GameState.get_map_nodes_for_act(int(data["current_act"]))
	if not act_map.has(String(data["map_current_node_id"])):
		return false
	return true

# ── 通算統計 ──────────────────────────────────────────────────────────────────

func get_stats() -> Dictionary:
	var data = _read_variant(STATS_PATH)
	if typeof(data) != TYPE_DICTIONARY:
		return {"runs": 0, "wins": 0, "losses": 0}
	return {
		"runs": int(data.get("runs", 0)),
		"wins": int(data.get("wins", 0)),
		"losses": int(data.get("losses", 0)),
	}

func record_run_start() -> void:
	var stats := get_stats()
	stats["runs"] += 1
	_write_variant(STATS_PATH, stats)

func record_run_end(victory: bool) -> void:
	var stats := get_stats()
	if victory:
		stats["wins"] += 1
	else:
		stats["losses"] += 1
	_write_variant(STATS_PATH, stats)
	delete_run_save()

# ── ファイルIO ────────────────────────────────────────────────────────────────

func _write_variant(path: String, value) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: failed to open %s for writing (%s)" % [path, FileAccess.get_open_error()])
		return
	f.store_string(var_to_str(value))
	f.close()

func _read_variant(path: String):
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var text := f.get_as_text()
	f.close()
	return str_to_var(text)
