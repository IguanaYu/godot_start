## 主关卡脚本（MainLevel.gd）
## 功能：管理主关卡的初始化和游戏流程
## 节点结构：Node2D (根节点)
##   ├── PlayerSpawn (玩家出生点)
##   ├── SpawnManager (数据驱动刷新管理器)
##   ├── DayNightCycleManager (昼夜循环)
##   ├── LevelUI (关卡特定UI)
##   └── Background (背景)

extends "res://scripts/levels/BaseLevel.gd"

## ========== 可配置变量 ==========

## 撤离点生成时间（秒）
@export var evacuation_time: float = 20.0
## 初始占领点生成时间（秒）
@export var initial_capture_points_time: float = 5.0
## 初始占领点生成数量
@export var initial_capture_points_count: int = 3
## 难度翻倍倍数
@export var difficulty_multiplier: float = 2.0

## ========== 私有变量 ==========

## 游戏计时器
var _game_timer: float = 0.0
## 撤离点是否已生成
var _evacuation_spawned: bool = false
## 初始占领点是否已生成
var _initial_capture_points_spawned: bool = false

## ========== 节点引用 ==========

## 刷新管理器节点引用
@onready var spawn_manager: SpawnManager = $SpawnManager
## 昼夜循环管理器
@onready var day_night_cycle_manager: DayNightCycleManager = $DayNightCycleManager
## 背景节点引用
@onready var background: ColorRect = $Background
## 倒计时标签引用
@onready var countdown_label: Label = $LevelUI/CountdownLabel
## 奖励提示标签引用
@onready var reward_popup: Label = $LevelUI/RewardPopup

## ========== 标准接口实现 ==========

## 获取玩家出生点
func get_player_spawn_point() -> Marker2D:
	return $PlayerSpawn

## 初始化关卡（由 GameRoot 调用）
func initialize_level(game_root: Node2D) -> void:
	# 设置玩家引用
	player = game_root.player

	# 设置 GameManager 的主场景引用
	GameManager.main_scene = self

	# 设置背景颜色
	if background != null:
		background.color = Color(0.1, 0.1, 0.15, 1.0)

	# 连接 GameManager 信号
	if not GameManager.player_died.is_connected(_on_player_died):
		GameManager.player_died.connect(_on_player_died)
	if not GameManager.reward_obtained.is_connected(_on_reward_obtained):
		GameManager.reward_obtained.connect(_on_reward_obtained)

	# 初始化 SpawnManager（加载默认白天阶段配置）
	_init_spawn_manager()

	# 初始化昼夜循环
	_init_day_night_cycle()

	# 重置游戏计时器
	_game_timer = 0.0
	_evacuation_spawned = false
	_initial_capture_points_spawned = false

	# 隐藏倒计时（开始时）
	if countdown_label != null:
		countdown_label.visible = true

	print("MainLevel: 关卡初始化完成")

## 获取刷新管理器（兼容接口）
func get_spawner() -> SpawnManager:
	return spawn_manager

## ========== 初始化方法 ==========

## 初始化 SpawnManager
func _init_spawn_manager() -> void:
	if spawn_manager == null:
		push_error("MainLevel: SpawnManager 节点未找到！")
		return

	# 加载默认白天阶段配置
	var default_phase: SpawnPhase = load("res://resources/spawn/phases/default_day_phase.tres")
	if default_phase == null:
		push_error("MainLevel: 无法加载默认白天阶段配置")
		return

	# 配置 SpawnManager
	spawn_manager.configure(default_phase)
	spawn_manager.resume_spawning()

	print("MainLevel: SpawnManager 已配置")

## 初始化昼夜循环
func _init_day_night_cycle() -> void:
	if day_night_cycle_manager == null:
		return

	# 加载默认昼夜挡位
	var default_tier: DayNightTier = load("res://resources/spawn/tiers/default_tier.tres")
	if default_tier == null:
		push_warning("MainLevel: 无法加载默认昼夜挡位")
		return

	# 设置背景节点
	day_night_cycle_manager.set_background(background)

	# 启动昼夜循环
	day_night_cycle_manager.start_cycle(default_tier)

	# 监听昼夜切换信号（步骤6：影响刷新）
	if not day_night_cycle_manager.period_changed.is_connected(_on_period_changed):
		day_night_cycle_manager.period_changed.connect(_on_period_changed)

	print("MainLevel: 昼夜循环已启动")

## ========== 信号回调 ==========

## 昼夜时段切换（步骤6）
func _on_period_changed(period: SpawnPhase.Period) -> void:
	if spawn_manager == null:
		return

	# 根据时段加载对应阶段配置
	var phase_path := "res://resources/spawn/phases/default_day_phase.tres" if period == SpawnPhase.Period.DAY else "res://resources/spawn/phases/default_night_phase.tres"
	var phase: SpawnPhase = load(phase_path)
	if phase != null:
		spawn_manager.set_active_phase(phase)

## 玩家死亡
func _on_player_died() -> void:
	print("MainLevel: 玩家死亡")
	# 暂停刷新管理器
	if spawn_manager != null:
		spawn_manager.pause_spawning()

	# 重新开始当前关卡（通过 GameRoot）
	var game_root = get_tree().current_scene
	if game_root and game_root.has_method("restart_current_level"):
		await get_tree().create_timer(2.0).timeout
		game_root.restart_current_level()

## 获得奖励
func _on_reward_obtained(reward_text: String) -> void:
	# 在 UI 上显示奖励提示
	_show_reward_popup(reward_text)

## ========== UI 显示 ==========

## 显示奖励提示
func _show_reward_popup(reward_text: String) -> void:
	if reward_popup != null:
		reward_popup.text = reward_text
		reward_popup.visible = true

		# 2秒后隐藏
		await get_tree().create_timer(2.0).timeout
		reward_popup.visible = false

## ========== 处理逻辑 ==========

func _process(delta: float) -> void:
	_game_timer += delta

	# 处理初始占领点生成（5秒时）
	if not _initial_capture_points_spawned:
		if _game_timer >= initial_capture_points_time:
			_spawn_initial_capture_points()
			_initial_capture_points_spawned = true

	# 处理撤离点生成计时器
	if not _evacuation_spawned:
		# 更新倒计时显示
		_update_countdown()

		if _game_timer >= evacuation_time:
			_spawn_evacuation_point()
			_increase_difficulty()
			_evacuation_spawned = true

			# 隐藏倒计时
			if countdown_label != null:
				countdown_label.visible = false

## ========== 撤离点系统 ==========

## 生成撤离点
func _spawn_evacuation_point() -> void:
	var evacuation_scene = load("res://scenes/areas/EvacuationArea.tscn")
	if evacuation_scene == null:
		push_error("MainLevel: 无法加载 EvacuationArea.tscn")
		return

	var evacuation_point = evacuation_scene.instantiate()

	# 在玩家周围随机位置生成
	if player != null and is_instance_valid(player):
		var random_offset = Vector2(randf_range(-200, 200), randf_range(-200, 200))
		evacuation_point.global_position = player.global_position + random_offset
	else:
		evacuation_point.global_position = Vector2.ZERO

	add_child(evacuation_point)

	# 显示提示
	GameManager.reward_obtained.emit("撤离点已出现！占领撤离点前往休息区域！")

## 增加游戏难度
func _increase_difficulty() -> void:
	if spawn_manager != null:
		spawn_manager.increase_difficulty(difficulty_multiplier)
		GameManager.reward_obtained.emit("敌人刷新频率已提升！")

## 更新倒计时显示
func _update_countdown() -> void:
	if countdown_label != null:
		var remaining_time: float = max(0.0, evacuation_time - _game_timer)
		countdown_label.text = "Evacuation: %.1fs" % remaining_time

## 生成初始占领点
func _spawn_initial_capture_points() -> void:
	if spawn_manager == null:
		return

	# 使用 SpawnManager 的方法生成多个占领点
	for i in range(initial_capture_points_count):
		spawn_manager.spawn_capture_point_immediate()

	# 显示提示
	GameManager.reward_obtained.emit("占领点已出现！占领3个点以获得奖励！")

## ========== 清理 ==========

func _exit_tree() -> void:
	# 断开信号连接
	if GameManager.player_died.is_connected(_on_player_died):
		GameManager.player_died.disconnect(_on_player_died)
	if GameManager.reward_obtained.is_connected(_on_reward_obtained):
		GameManager.reward_obtained.disconnect(_on_reward_obtained)
	if day_night_cycle_manager != null and day_night_cycle_manager.period_changed.is_connected(_on_period_changed):
		day_night_cycle_manager.period_changed.disconnect(_on_period_changed)
