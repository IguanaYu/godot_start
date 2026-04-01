## 全局管理器（GameManager.gd）
## 功能：管理游戏全局状态，包括金币统计、玩家血量、生成金币雨、清除全屏敌人等
## 使用方式：在 Project Settings -> AutoLoad 中设置为单例

extends Node

## ========== 信号定义 ==========

## 金币数量变化时发出（参数：当前金币数量）
signal coins_changed(new_coins: int)
## 玩家生命值变化时发出（参数：当前生命值）
signal health_changed(new_health: int)
## 玩家死亡时发出
signal player_died()
## 获得奖励时发出（参数：奖励描述文本）
signal reward_obtained(reward_text: String)
## 音量变化时发出（参数：音量类型，音量值）
signal volume_changed(volume_type: String, value: float)
## 背包变化时发出
signal inventory_changed()

## ========== 可配置变量 ==========

## 每收集多少金币自动恢复1滴血
@export var coins_to_heal: int = 10
## 玩家最大生命值
@export var max_health: int = 3
## 金币雨持续时间（秒）
@export var coin_rain_duration: float = 20.0
## 金币雨生成间隔（秒）
@export var coin_rain_interval: float = 1.0

## ========== 音量设置 ==========

## 主音量（0.0到1.0）
@export var master_volume: float = 0.8
## 音效音量（0.0到1.0）
@export var sfx_volume: float = 0.8
## 背景音乐音量（0.0到1.0）
@export var music_volume: float = 0.8

## ========== 私有变量 ==========

## 当前收集的金币数量
var _coins: int = 0
## 当前选中的角色数据
var selected_character_data: Resource = null
## 当前玩家生命值
var _health: int = max_health
## 金币雨计时器
var _coin_rain_timer: Timer = null
## 金币雨是否激活
var _is_coin_rain_active: bool = false
## 金币雨剩余时间
var _coin_rain_time_left: float = 0.0
## 金币雨生成计时器
var _coin_rain_spawn_timer: float = 0.0
## 当前活动中的占领据点列表
var _active_capture_points: Array = []
## 当前活动中的敌人列表
var _active_enemies: Array = []

## ========== 背包系统 ==========

## 背包中的物品列表
var inventory_items: Array = []

## ========== 永久性增益存储 ==========

## 速度增加百分比（累计）
var speed_boost_percent: float = 0.0
## 金币刷新几率增加百分比
var coin_spawn_rate_bonus: float = 0.0
## 敌人刷新几率减少百分比
var enemy_spawn_rate_penalty: float = 0.0
## 钻石刷新几率增加百分比
var diamond_spawn_rate_bonus: float = 0.0
## 最大生命值加成
var max_health_bonus: int = 0

## ========== 节点引用 ==========

## 玩家引用（在游戏中动态设置）
var player: Node2D = null
## 主场景引用
var main_scene: Node2D = null

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	# 初始化计时器
	_coin_rain_timer = Timer.new()
	_coin_rain_timer.wait_time = coin_rain_duration
	_coin_rain_timer.one_shot = true
	_coin_rain_timer.timeout.connect(_on_coin_rain_finished)
	add_child(_coin_rain_timer)

## ========== _process 处理金币雨逻辑 ==========

func _process(delta: float) -> void:
	# 处理金币雨逻辑
	if _is_coin_rain_active:
		_coin_rain_time_left -= delta
		_coin_rain_spawn_timer -= delta

		# 每隔一定时间生成一个金币
		if _coin_rain_spawn_timer <= 0:
			_spawn_coin_rain_coin()
			_coin_rain_spawn_timer = coin_rain_interval

		# 金币雨时间结束
		if _coin_rain_time_left <= 0:
			_stop_coin_rain()

## ========== 公共方法：金币管理 ==========

## 增加金币数量
func add_coins(amount: int) -> void:
	_coins += amount
	coins_changed.emit(_coins)

	# 检查是否达到回血条件
	var heal_thresholds: int = _coins / coins_to_heal
	var previous_thresholds: int = (_coins - amount) / coins_to_heal

	if heal_thresholds > previous_thresholds:
		# 达到新的回血阈值，恢复生命值
		heal_player(1)

## 获取当前金币数量
func get_coins() -> int:
	return _coins

## 重置金币数量
func reset_coins() -> void:
	_coins = 0
	coins_changed.emit(0)

## ========== 公共方法：生命值管理 ==========

## 玩家受到伤害
func damage_player(amount: int) -> void:
	if _health <= 0:
		return

	_health -= amount
	health_changed.emit(_health)

	if _health <= 0:
		_health = 0
		player_died.emit()

## 恢复玩家生命值
func heal_player(amount: int) -> void:
	if _health <= 0:
		return

	_health = min(_health + amount, max_health)
	health_changed.emit(_health)
	reward_obtained.emit("恢复生命值 +%d" % amount)

## 获取当前生命值
func get_health() -> int:
	return _health

## 重置生命值
func reset_health() -> void:
	# 如果有选中的角色，使用角色的最大生命值
	if selected_character_data != null:
		_health = selected_character_data.get_initial_health()
	else:
		_health = max_health
	health_changed.emit(_health)

## 重置游戏状态
func reset_game() -> void:
	reset_coins()
	reset_health()
	_stop_coin_rain()

## ========== 公共方法：金币雨 ==========

## 启动金币雨效果
func start_coin_rain() -> void:
	if _is_coin_rain_active:
		return

	_is_coin_rain_active = true
	_coin_rain_time_left = coin_rain_duration
	_coin_rain_spawn_timer = 0.0
	reward_obtained.emit("金币雨开始！持续 %.0f 秒" % coin_rain_duration)

## 停止金币雨效果
func _stop_coin_rain() -> void:
	_is_coin_rain_active = false
	_coin_rain_time_left = 0.0

func _on_coin_rain_finished() -> void:
	_stop_coin_rain()
	reward_obtained.emit("金币雨结束")

## 生成金币雨中的单个金币
func _spawn_coin_rain_coin() -> void:
	if main_scene == null:
		return

	# 获取视口大小
	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	var screen_size: Vector2 = viewport_rect.size

	# 在玩家周围或屏幕随机位置生成金币
	var spawn_position: Vector2
	if player != null and is_instance_valid(player):
		# 50% 概率在玩家周围生成
		if randf() < 0.5:
			var random_offset: Vector2 = Vector2(randf_range(-200, 200), randf_range(-200, 200))
			spawn_position = player.global_position + random_offset
		else:
			# 在屏幕范围内随机生成
			spawn_position = Vector2(randf_range(0, screen_size.x), randf_range(0, screen_size.y))
	else:
		spawn_position = Vector2(randf_range(0, screen_size.x), randf_range(0, screen_size.y))

	# 加载并实例化金币场景
	var coin_scene: PackedScene = load("res://scenes/Coin.tscn")
	if coin_scene != null:
		var coin = coin_scene.instantiate()
		coin.global_position = spawn_position
		coin.is_from_coin_rain = true  # 标记为金币雨生成的金币
		main_scene.add_child(coin)

## ========== 公共方法：清除敌人 ==========

## 清除当前场景中的所有敌人（圣光涌动效果）
func clear_all_enemies() -> void:
	var cleared_count: int = 0

	for enemy in _active_enemies:
		if is_instance_valid(enemy):
			enemy.destroy()
			cleared_count += 1

	_active_enemies.clear()
	reward_obtained.emit("圣光涌动！消除了 %d 个敌人" % cleared_count)

## 注册敌人到管理器
func register_enemy(enemy: Node2D) -> void:
	_active_enemies.append(enemy)

## 从管理器中移除敌人
func unregister_enemy(enemy: Node2D) -> void:
	var index: int = _active_enemies.find(enemy)
	if index >= 0:
		_active_enemies.remove_at(index)

## ========== 公共方法：占领据点管理 ==========

## 注册占领据点
func register_capture_point(capture_point: Node2D) -> void:
	_active_capture_points.append(capture_point)

## 从管理器中移除占领据点
func unregister_capture_point(capture_point: Node2D) -> void:
	var index: int = _active_capture_points.find(capture_point)
	if index >= 0:
		_active_capture_points.remove_at(index)

## 获取当前活动的占领据点数量
func get_active_capture_point_count() -> int:
	return _active_capture_points.size()

## 获取当前活动的敌人数量
func get_active_enemy_count() -> int:
	return _active_enemies.size()

## ========== 公共方法：BUFF 管理 ==========

## 应用玩家BUFF效果
func apply_buff(buff_type: String) -> void:
	if player != null and is_instance_valid(player):
		player.apply_buff(buff_type)

## ========== 公共方法：音量管理 ==========

## 设置主音量
func set_master_volume(value: float) -> void:
	master_volume = clamp(value, 0.0, 1.0)
	volume_changed.emit("master", master_volume)

## 获取主音量
func get_master_volume() -> float:
	return master_volume

## 设置音效音量
func set_sfx_volume(value: float) -> void:
	sfx_volume = clamp(value, 0.0, 1.0)
	volume_changed.emit("sfx", sfx_volume)

## 获取音效音量
func get_sfx_volume() -> float:
	return sfx_volume

## 设置背景音乐音量
func set_music_volume(value: float) -> void:
	music_volume = clamp(value, 0.0, 1.0)
	volume_changed.emit("music", music_volume)

## 获取背景音乐音量
func get_music_volume() -> float:
	return music_volume

## ========== 公共方法：背包管理 ==========

## 添加物品到背包
func add_item_to_inventory(item: Resource) -> void:
	inventory_items.append(item)
	inventory_changed.emit()

## 从背包移除物品
func remove_item_from_inventory(index: int) -> void:
	if index >= 0 and index < inventory_items.size():
		inventory_items.remove_at(index)
		inventory_changed.emit()

## 使用背包中的物品
func use_item_from_inventory(index: int) -> void:
	if index >= 0 and index < inventory_items.size():
		var item: Resource = inventory_items[index]
		item.apply_to_player()

		# 如果不是永久物品，使用后移除
		if not item.is_permanent():
			inventory_items.remove_at(index)

		inventory_changed.emit()

## 获取背包中的所有物品
func get_inventory_items() -> Array:
	return inventory_items

## 清空背包
func clear_inventory() -> void:
	inventory_items.clear()
	inventory_changed.emit()

## ========== 公共方法：永久性增益管理 ==========

## 应用永久性增益到玩家
func apply_permanent_bonuses() -> void:
	# 应用最大生命值加成
	if max_health_bonus > 0:
		max_health += max_health_bonus

	# 应用速度加成
	if player != null and is_instance_valid(player) and speed_boost_percent > 0:
		player.base_speed *= (1.0 + speed_boost_percent / 100.0)

	# 恢复生命值到上限
	heal_player(max_health - get_health())

## 获取游戏总统计信息（用于调试）
func get_stats_summary() -> String:
	return "金币: %d | 生命: %d/%d | 背包: %d件 | 速度+%.1f%%" % [
		get_coins(), get_health(), max_health,
		inventory_items.size(), speed_boost_percent
	]
