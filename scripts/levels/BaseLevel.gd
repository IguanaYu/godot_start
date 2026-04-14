## 关卡基类（BaseLevel.gd）
## 功能：定义所有关卡场景的标准接口
## 所有关卡场景都应该继承此类并实现标准接口

extends Node2D

## ========== 玩家引用 ==========

## 玩家引用（由 GameRoot 设置）
var player: Player = null

## ========== 必须实现的标准接口 ==========

## 获取玩家出生点
## 返回玩家出生点的 Marker2D 节点
func get_player_spawn_point() -> Marker2D:
	var spawn_point = get_node_or_null("PlayerSpawn")
	if spawn_point == null:
		push_warning("关卡 %s 没有 PlayerSpawn 节点，使用默认位置 (0, 0)" % name)
		# 创建一个临时的出生点
		spawn_point = Marker2D.new()
		spawn_point.position = Vector2.ZERO
		add_child(spawn_point)
	return spawn_point

## 初始化关卡（由 GameRoot 调用）
## 参数：
##   game_root: GameRoot 实例引用
func initialize_level(game_root: Node2D) -> void:
	# 子类应该重写此方法以实现特定的初始化逻辑
	pass

## 获取生成器（如果有）
## 返回关卡中的 SpawnManager 节点，如果没有则返回 null
func get_spawner():
	return get_node_or_null("SpawnManager")

## 获取敌人列表（用于 GameManager.clear_all_enemies）
## 返回关卡中的所有敌人节点数组
func get_enemies() -> Array:
	var enemies = []
	# 遍历所有子节点查找敌人
	for child in get_children():
		if child is Enemy:
			enemies.append(child)
	return enemies

## ========== 可选的虚函数 ==========

## 关卡暂停时调用
func on_level_paused() -> void:
	pass

## 关卡恢复时调用
func on_level_resumed() -> void:
	pass

## 关卡即将卸载时调用
func on_level_unloading() -> void:
	pass

## ========== 辅助方法 ==========

## 获取关卡名称
func get_level_name() -> String:
	return name

## 是否是当前活动的关卡
func is_active_level() -> bool:
	return is_inside_tree() and get_tree().current_scene.get_current_level() == self
