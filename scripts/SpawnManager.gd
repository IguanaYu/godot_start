## 刷新管理器脚本（SpawnManager.gd）
## 功能：数据驱动的刷新管理器，从 SpawnEntry Resource 读取配置驱动刷新
## 节点结构：Node2D (根节点)
##   └── 可选 SpawnZone 子节点

extends Node2D

class_name SpawnManager

## ========== 信号定义 ==========

## 金币雨开始
signal coin_rain_started(duration: float)
## 金币雨结束
signal coin_rain_ended()

## ========== 预加载场景 ==========

## 预加载敌人场景
var enemy_scene: PackedScene = preload("res://scenes/Enemy.tscn")
## 预加载基础收集品场景
var base_collectible_scene: PackedScene = preload("res://scenes/collectibles/BaseCollectible.tscn")
## 预加载宝箱场景
var chest_scene: PackedScene = preload("res://scenes/Chest.tscn")

## ========== 收集品数据 ==========

var coin_data: CollectibleData = preload("res://resources/collectibles/coin.tres")
var giant_coin_data: CollectibleData = preload("res://resources/collectibles/giant_coin.tres")
var red_key_data: CollectibleData = preload("res://resources/collectibles/red_key.tres")
var capture_area_data: CollectibleData = preload("res://resources/collectibles/capture_area.tres")

## ========== 私有变量 ==========

## 当前活跃的 SpawnPhase
var _current_phase: SpawnPhase = null
## 默认 SpawnZone（用于无 zone_id 的条目）
var _default_zone: SpawnZone = null
## 各条目的计时器状态 { entry_id: { "timer": float, "spawned": bool } }
var _entry_timers: Dictionary = {}
## 难度倍率（只影响敌人）
var _difficulty_multiplier: float = 1.0
## 基础敌人刷新间隔缓存（用于 increase_difficulty）
var _base_enemy_intervals: Dictionary = {}
## 已解锁的条目 ID 集合
var _unlocked_entries: Dictionary = {}

## 金币雨相关
var _is_coin_rain_active: bool = false
var _coin_rain_time_left: float = 0.0
var _coin_rain_spawn_timer: float = 0.0
var _coin_rain_duration: float = 20.0
var _coin_rain_interval: float = 1.0

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	# 创建默认 SpawnZone（PLAYER_RELATIVE 模式）
	_default_zone = SpawnZone.new()
	_default_zone.zone_mode = SpawnZone.ZoneType.PLAYER_RELATIVE
	add_child(_default_zone)

func _process(delta: float) -> void:
	if _current_phase == null:
		return

	# 处理每个活跃条目的计时器
	var enabled_entries = _current_phase.get_enabled_entries()
	for entry in enabled_entries:
		_process_entry(entry, delta)

	# 处理金币雨
	if _is_coin_rain_active:
		_process_coin_rain(delta)

## ========== 配置方法 ==========

## 配置刷新管理器
func configure(phase: SpawnPhase, zone: SpawnZone = null) -> void:
	_current_phase = phase
	_entry_timers.clear()
	_base_enemy_intervals.clear()

	if zone != null:
		_default_zone = zone

	# 初始化各条目的计时器
	for entry in phase.get_enabled_entries():
		_init_entry_timer(entry)

	print("[SpawnManager] 已配置阶段: %s, 活跃条目: %d" % [phase.phase_id, phase.get_enabled_entries().size()])

## 切换活跃阶段
func set_active_phase(phase: SpawnPhase) -> void:
	configure(phase)

## 设置活跃时段（按 DAY/NIGHT 过滤阶段中的条目）
func set_active_period(period: SpawnPhase.Period) -> void:
	if _current_phase == null:
		return
	_current_phase.period = period
	# 重新初始化计时器
	_entry_timers.clear()
	_base_enemy_intervals.clear()
	for entry in _current_phase.get_enabled_entries():
		_init_entry_timer(entry)
	print("[SpawnManager] 切换到%s阶段, 活跃条目: %d" % ["白天" if period == SpawnPhase.Period.DAY else "黑夜", _current_phase.get_enabled_entries().size()])

## ========== 计时器初始化 ==========

## 初始化条目的计时器
func _init_entry_timer(entry: SpawnEntry) -> void:
	var timer_data = {
		"timer": 0.0,
		"delay_remaining": entry.start_delay,
		"first_spawn": true,
	}
	_entry_timers[entry.entry_id] = timer_data

	# 非正计时器：随机化初始计时器（复刻 Spawner._ready 的行为）
	if not entry.is_cumulative_timer:
		timer_data["timer"] = randf() * entry.spawn_interval

	# 缓存敌人条目的基础间隔
	if entry.entity_type == "enemy":
		_base_enemy_intervals[entry.entry_id] = entry.spawn_interval

## ========== 条目处理 ==========

## 处理单个条目的计时逻辑
func _process_entry(entry: SpawnEntry, delta: float) -> void:
	var entry_id = entry.entry_id
	if not _entry_timers.has(entry_id):
		return

	var timer_data = _entry_timers[entry_id]

	# 处理首次生成延迟
	if timer_data["delay_remaining"] > 0.0:
		timer_data["delay_remaining"] -= delta
		return

	if entry.is_cumulative_timer:
		# 正计时器：累计时间达到间隔后触发
		timer_data["timer"] += delta
		if timer_data["timer"] >= entry.spawn_interval:
			_spawn_from_entry(entry)
			timer_data["timer"] = 0.0
	else:
		# 倒计时器：时间归零后触发
		timer_data["timer"] -= delta
		if timer_data["timer"] <= 0.0:
			_spawn_from_entry(entry)
			# 重置计时器（考虑难度倍率）
			var interval = _get_effective_interval(entry)
			timer_data["timer"] = interval

## 获取考虑难度倍率后的有效间隔
func _get_effective_interval(entry: SpawnEntry) -> float:
	if entry.entity_type == "enemy" and _difficulty_multiplier > 1.0:
		var base_interval = _base_enemy_intervals.get(entry.entry_id, entry.spawn_interval)
		return base_interval / _difficulty_multiplier
	return entry.spawn_interval

## ========== 生成逻辑 ==========

## 从 SpawnEntry 生成实体
func _spawn_from_entry(entry: SpawnEntry) -> void:
	match entry.entity_type:
		"enemy":
			_spawn_enemies(entry)
		"coin":
			_spawn_coins(entry)
		"capture_point":
			_spawn_capture_point(entry)
		"chest":
			_spawn_chest(entry)
		"giant_coin":
			_spawn_giant_coin(entry)
		"red_key":
			_spawn_red_keys(entry)

## 获取生成位置
func _get_spawn_position(entry: SpawnEntry) -> Vector2:
	var zone = _default_zone
	# TODO: 支持通过 zone_id 查找特定 SpawnZone
	return zone.get_spawn_position(entry.min_offset, entry.max_offset)

## 生成敌人
func _spawn_enemies(entry: SpawnEntry) -> void:
	var current_count = GameManager.get_active_enemy_count()
	if current_count >= entry.max_in_scene:
		return

	var spawn_count = randi_range(entry.spawn_count_min, entry.spawn_count_max)
	for i in spawn_count:
		if current_count + i >= entry.max_in_scene:
			break
		var pos = _get_spawn_position(entry)
		var enemy = enemy_scene.instantiate()
		enemy.global_position = pos
		get_parent().add_child(enemy)

## 生成金币
func _spawn_coins(entry: SpawnEntry) -> void:
	var current_count = get_tree().get_nodes_in_group("coins").size()
	if current_count >= entry.max_in_scene:
		return

	var spawn_count = randi_range(entry.spawn_count_min, entry.spawn_count_max)
	for i in spawn_count:
		if current_count + i >= entry.max_in_scene:
			break
		_spawn_single_coin(entry)

## 生成单个金币
func _spawn_single_coin(entry: SpawnEntry) -> void:
	var pos = _get_spawn_position(entry)
	var collectible = base_collectible_scene.instantiate()
	collectible.collectible_data = coin_data
	collectible.global_position = pos
	collectible.add_to_group("coins")
	get_parent().add_child(collectible)

## 生成占领点
func _spawn_capture_point(entry: SpawnEntry) -> void:
	var current_count = GameManager.get_active_capture_point_count()
	if current_count >= entry.max_in_scene:
		return

	var pos = _get_spawn_position(entry)
	var collectible = base_collectible_scene.instantiate()
	collectible.collectible_data = capture_area_data
	collectible.global_position = pos
	get_parent().add_child(collectible)

## 生成宝箱
func _spawn_chest(entry: SpawnEntry) -> void:
	var current_count = get_tree().get_nodes_in_group("chests").size()
	if current_count >= entry.max_in_scene:
		return

	var pos = _get_spawn_position(entry)
	var chest = chest_scene.instantiate()
	chest.global_position = pos
	chest.add_to_group("chests")
	get_parent().add_child(chest)

## 生成巨型金币
func _spawn_giant_coin(entry: SpawnEntry) -> void:
	var pos = _get_spawn_position(entry)
	var collectible = base_collectible_scene.instantiate()
	collectible.collectible_data = giant_coin_data
	collectible.global_position = pos
	get_parent().add_child(collectible)

## 生成红钥匙
func _spawn_red_keys(entry: SpawnEntry) -> void:
	var count = randi_range(entry.spawn_count_min, entry.spawn_count_max)
	for i in count:
		var pos = _get_spawn_position(entry)
		var collectible = base_collectible_scene.instantiate()
		collectible.collectible_data = red_key_data
		collectible.global_position = pos
		get_parent().add_child(collectible)

## ========== 公共 API（兼容 Spawner） ==========

## 暂停所有生成
func pause_spawning() -> void:
	set_process(false)

## 恢复所有生成
func resume_spawning() -> void:
	set_process(true)

## 立即生成指定数量的敌人
func spawn_enemy_immediate(count: int = 1) -> void:
	var entry = _find_entry_by_type("enemy")
	if entry == null:
		# fallback：使用默认参数直接生成
		for i in count:
			var pos = _default_zone.get_spawn_position(100.0, 500.0)
			var enemy = enemy_scene.instantiate()
			enemy.global_position = pos
			get_parent().add_child(enemy)
		return

	for i in count:
		if GameManager.get_active_enemy_count() < entry.max_in_scene:
			var pos = _get_spawn_position(entry)
			var enemy = enemy_scene.instantiate()
			enemy.global_position = pos
			get_parent().add_child(enemy)

## 立即生成指定数量的金币
func spawn_coin_immediate(count: int = 1) -> void:
	for i in count:
		var pos = _default_zone.get_spawn_position(50.0, 300.0)
		var collectible = base_collectible_scene.instantiate()
		collectible.collectible_data = coin_data
		collectible.global_position = pos
		collectible.add_to_group("coins")
		get_parent().add_child(collectible)

## 立即生成一个占领据点
func spawn_capture_point_immediate() -> void:
	var pos = _default_zone.get_spawn_position(100.0, 400.0)
	var collectible = base_collectible_scene.instantiate()
	collectible.collectible_data = capture_area_data
	collectible.global_position = pos
	get_parent().add_child(collectible)

## 立即生成一个宝箱
func spawn_chest_immediate() -> void:
	var pos = _default_zone.get_spawn_position(80.0, 350.0)
	var chest = chest_scene.instantiate()
	chest.global_position = pos
	chest.add_to_group("chests")
	get_parent().add_child(chest)

## 增加难度（敌人刷新频率翻倍）
func increase_difficulty(multiplier: float = 2.0) -> void:
	_difficulty_multiplier = multiplier
	print("[SpawnManager] 难度提升, 倍率: %.1f" % multiplier)

## 解锁条目
func unlock_entry(entry_id: String) -> void:
	_unlocked_entries[entry_id] = true
	# 如果当前阶段中有该条目但被禁用，启用它
	if _current_phase != null:
		var entry = _current_phase.get_entry_by_id(entry_id)
		if entry != null:
			entry.enabled = true
			if not _entry_timers.has(entry_id):
				_init_entry_timer(entry)
			print("[SpawnManager] 解锁条目: %s" % entry_id)

## ========== 金币雨系统 ==========

## 启动金币雨
func start_coin_rain(duration: float = 20.0, interval: float = 1.0) -> void:
	if _is_coin_rain_active:
		return
	_is_coin_rain_active = true
	_coin_rain_duration = duration
	_coin_rain_time_left = duration
	_coin_rain_spawn_timer = 0.0
	_coin_rain_interval = interval
	coin_rain_started.emit(duration)
	print("[SpawnManager] 金币雨开始！持续 %.0f 秒" % duration)

## 停止金币雨
func stop_coin_rain() -> void:
	_is_coin_rain_active = false
	_coin_rain_time_left = 0.0
	coin_rain_ended.emit()

## 处理金币雨逻辑
func _process_coin_rain(delta: float) -> void:
	_coin_rain_time_left -= delta
	_coin_rain_spawn_timer -= delta

	if _coin_rain_spawn_timer <= 0:
		_spawn_coin_rain_coin()
		_coin_rain_spawn_timer = _coin_rain_interval

	if _coin_rain_time_left <= 0:
		stop_coin_rain()
		print("[SpawnManager] 金币雨结束")

## 生成金币雨中的单个金币
func _spawn_coin_rain_coin() -> void:
	var pos = _default_zone.get_spawn_position(50.0, 300.0)
	var collectible = base_collectible_scene.instantiate()
	collectible.collectible_data = coin_data
	collectible.global_position = pos
	collectible.add_to_group("coins")
	get_parent().add_child(collectible)

## ========== 辅助方法 ==========

## 根据 entity_type 查找当前阶段的条目
func _find_entry_by_type(entity_type: String) -> SpawnEntry:
	if _current_phase == null:
		return null
	for entry in _current_phase.get_enabled_entries():
		if entry.entity_type == entity_type:
			return entry
	return null

## 获取当前阶段
func get_current_phase() -> SpawnPhase:
	return _current_phase
