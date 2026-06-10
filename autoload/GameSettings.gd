extends Node
## 音量・画面設定の保持と適用。user://settings.txt に永続化する。
## オーディオバス(BGM/SFX)はここで作成する。後日のサウンド実装はこのバスに出力する。

const SETTINGS_PATH = "user://settings.txt"
const BUS_MASTER = "Master"
const BUS_BGM = "BGM"
const BUS_SFX = "SFX"

var master_volume: float = 0.8
var bgm_volume: float = 0.8
var sfx_volume: float = 0.8
var fullscreen: bool = false

func _ready() -> void:
	_ensure_buses()
	_load()
	apply_all()

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_volumes()
	_save()

func set_bgm_volume(value: float) -> void:
	bgm_volume = clampf(value, 0.0, 1.0)
	_apply_volumes()
	_save()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_volumes()
	_save()

func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	_apply_fullscreen()
	_save()

func apply_all() -> void:
	_apply_volumes()
	_apply_fullscreen()

# ── 内部処理 ──────────────────────────────────────────────────────────────────

func _ensure_buses() -> void:
	for bus_name in [BUS_BGM, BUS_SFX]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx := AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, BUS_MASTER)

func _apply_volumes() -> void:
	_set_bus_linear(BUS_MASTER, master_volume)
	_set_bus_linear(BUS_BGM, bgm_volume)
	_set_bus_linear(BUS_SFX, sfx_volume)

func _set_bus_linear(bus_name: String, value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(value, 0.0001)))
	AudioServer.set_bus_mute(idx, value <= 0.0)

func _apply_fullscreen() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var current := DisplayServer.window_get_mode()
	if fullscreen and current != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif not fullscreen and current == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _save() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f == null:
		push_error("GameSettings: failed to write %s" % SETTINGS_PATH)
		return
	f.store_string(var_to_str({
		"master_volume": master_volume,
		"bgm_volume": bgm_volume,
		"sfx_volume": sfx_volume,
		"fullscreen": fullscreen,
	}))
	f.close()

func _load() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if f == null:
		return
	var data = str_to_var(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return
	master_volume = clampf(float(data.get("master_volume", master_volume)), 0.0, 1.0)
	bgm_volume = clampf(float(data.get("bgm_volume", bgm_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(data.get("sfx_volume", sfx_volume)), 0.0, 1.0)
	fullscreen = bool(data.get("fullscreen", fullscreen))
