## 石碑脚本（Stele.gd）
## 功能：占领石碑解锁新的 SpawnEntry
## 复用 BaseArea 的占领机制

extends "res://scripts/areas/BaseArea.gd"

## ========== 可配置变量 ==========

## 解锁的 SpawnEntry ID
@export var unlock_entry_id: String = ""
## 解锁后显示的提示文本
@export var unlock_message: String = "解锁了新的刷新条目！"

## ========== 占领完成回调 ==========

func _on_capture_completed() -> void:
	super._on_capture_completed()

	if unlock_entry_id == "":
		GameConsole.warn("Stele: unlock_entry_id 为空")
		return

	# 通过 GameManager.main_scene 获取 SpawnManager 并解锁
	var main_scene = GameManager.main_scene
	if main_scene != null and main_scene.has_method("get_spawner"):
		var spawn_mgr = main_scene.get_spawner()
		if spawn_mgr != null and spawn_mgr.has_method("unlock_entry"):
			spawn_mgr.unlock_entry(unlock_entry_id)
			GameConsole.info("[Stele] 解锁 SpawnEntry: %s" % unlock_entry_id)

	# 显示提示
	GameManager.reward_obtained.emit(unlock_message)

	# 延迟 1 秒后消失（让玩家看到金色完成效果）
	await get_tree().create_timer(1.0).timeout
	queue_free()
