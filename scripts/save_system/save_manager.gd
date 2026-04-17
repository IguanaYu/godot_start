extends Node
## 存档管理器。收集各系统数据并序列化为 JSON 存档。

signal save_completed(slot: int)
signal load_completed(slot: int)
signal save_failed(slot: int, error: String)

const SAVE_VERSION := 1
const MAX_SLOTS := 3


func save_game(slot: int = 0) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		push_warning("SaveManager: 无效的存档位 %d" % slot)
		return false

	var data := _collect_save_data()
	var json_str := JSON.stringify(data, "\t")

	var path := "user://save_slot_%d.sav" % slot
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		save_failed.emit(slot, "无法打开存档文件")
		return false

	file.store_string(json_str)
	file.close()
	save_completed.emit(slot)
	return true


func load_game(slot: int = 0) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		push_warning("SaveManager: 无效的存档位 %d" % slot)
		return false

	var path := "user://save_slot_%d.sav" % slot
	if not FileAccess.file_exists(path):
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false

	var json_str := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(json_str)
	if err != OK:
		push_warning("SaveManager: 存档解析失败: %s" % json.get_error_message())
		return false

	var data: Dictionary = json.data
	_restore_save_data(data)
	load_completed.emit(slot)
	return true


func has_save(slot: int = 0) -> bool:
	return FileAccess.file_exists("user://save_slot_%d.sav" % slot)


func delete_save(slot: int = 0) -> void:
	var path := "user://save_slot_%d.sav" % slot
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func get_save_info(slot: int) -> Dictionary:
	var path := "user://save_slot_%d.sav" % slot
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json_str := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_str) != OK:
		return {}

	var data: Dictionary = json.data
	var meta: Dictionary = data.get("meta", {})
	var game_state: Dictionary = data.get("game_state", {})
	return {
		"timestamp": meta.get("timestamp", ""),
		"day": game_state.get("current_day_number", 1),
		"coins": game_state.get("coins", 0),
	}


func _collect_save_data() -> Dictionary:
	return {
		"meta": {
			"save_version": SAVE_VERSION,
			"timestamp": Time.get_datetime_string_from_system(),
		},
		"game_state": _collect_game_state(),
		"quest_states": QuestManager.get_save_data(),
		"dialogue": DialogueManager.get_save_data(),
		"exploration": ExplorationProgress.get_save_data(),
		"iguana": Iguana.get_save_data(),
	}


func _collect_game_state() -> Dictionary:
	return {
		"coins": GameManager._coins,
		"health": GameManager.get_health(),
		"max_health": GameManager.max_health,
		"current_day_number": GameManager.current_day_number,
		"speed_boost_percent": GameManager.speed_boost_percent,
		"coin_spawn_rate_bonus": GameManager.coin_spawn_rate_bonus,
		"enemy_spawn_rate_penalty": GameManager.enemy_spawn_rate_penalty,
		"diamond_spawn_rate_bonus": GameManager.diamond_spawn_rate_bonus,
		"max_health_bonus": GameManager.max_health_bonus,
		"red_keys_collected": GameManager.red_keys_collected,
	}


func _restore_save_data(data: Dictionary) -> void:
	# 恢复游戏状态
	var gs: Dictionary = data.get("game_state", {})
	GameManager._coins = gs.get("coins", 0)
	GameManager.current_day_number = gs.get("current_day_number", 1)
	GameManager.speed_boost_percent = gs.get("speed_boost_percent", 0.0)
	GameManager.coin_spawn_rate_bonus = gs.get("coin_spawn_rate_bonus", 0.0)
	GameManager.enemy_spawn_rate_penalty = gs.get("enemy_spawn_rate_penalty", 0.0)
	GameManager.diamond_spawn_rate_bonus = gs.get("diamond_spawn_rate_bonus", 0.0)
	GameManager.max_health_bonus = gs.get("max_health_bonus", 0)
	GameManager.red_keys_collected = gs.get("red_keys_collected", 0)
	# 触发信号刷新 UI
	GameManager.coins_changed.emit(GameManager._coins)
	GameManager.health_changed.emit(gs.get("health", 3))

	# 恢复各子系统
	QuestManager.restore_save_data(data.get("quest_states", {}))
	DialogueManager.restore_save_data(data.get("dialogue", {}))
	ExplorationProgress.restore_save_data(data.get("exploration", {}))
	Iguana.restore_save_data(data.get("iguana", {}))
