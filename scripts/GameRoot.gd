## GameRoot 脚本（GameRoot.gd）
## 功能：管理全局常驻 Player 和关卡切换
## 节点结构：Node2D (根节点)
##   ├── Player (常驻玩家实例)
##   ├── LevelContainer (关卡容器)
##   ├── GlobalUI (全局UI层)
##   └── Background (背景层)

extends Node2D

## ========== 信号定义 ==========

## 关卡加载完成时发出（参数：关卡名称）
signal level_loaded(level_name: String)
## 关卡卸载开始时发出（参数：关卡名称）
signal level_unloading(level_name: String)

## ========== 可配置变量 ==========

## 首个加载的关卡路径
@export var first_level_path: String = "res://scenes/levels/MainLevel.tscn"
## 背景颜色
@export var background_color: Color = Color(0.1, 0.1, 0.15, 1.0)
## 是否在启动时自动加载首个关卡
@export var auto_load_first_level: bool = true

## ========== 节点引用 ==========

## 玩家节点引用
@onready var player: Player = $Player
## 关卡容器引用
@onready var level_container: Node2D = $LevelContainer
## 全局UI引用
@onready var global_ui: CanvasLayer = $GlobalUI
## 背景节点引用
@onready var background: ColorRect = $Background
## 血条引用
@onready var hp_bar: ProgressBar = $GlobalUI/HPBar
## 金币标签引用
@onready var coin_label: Label = $GlobalUI/CoinLabel

## ========== 私有变量 ==========

## 当前加载的关卡实例
var _current_level: Node2D = null
## 当前关卡名称
var _current_level_name: String = ""
## 关卡加载是否正在进行
var _is_loading_level: bool = false

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	# 设置背景颜色
	if background != null:
		background.color = background_color

	# 初始化 Player
	_initialize_player()

	# 初始化全局UI
	_initialize_global_ui()

	# 连接 GameManager 信号
	_connect_game_manager_signals()

	# 自动加载首个关卡
	if auto_load_first_level:
		# 使用 call_deferred 确保 Player 完全初始化后再加载关卡
		call_deferred("load_level", first_level_path)

## ========== Player 初始化 ==========

## 初始化玩家
func _initialize_player() -> void:
	if player == null:
		push_error("GameRoot: Player 节点未找到！")
		return

	# 应用角色数据（如果已选择）
	_apply_character_data_to_player()

	# 设置 GameManager 的玩家引用
	GameManager.player = player

	# 连接玩家信号
	if player.has_signal("player_died") and not player.player_died.is_connected(_on_player_died):
		player.player_died.connect(_on_player_died)

	# 确保 Player 的 Camera2D 设置正确
	var camera: Camera2D = player.get_node_or_null("Camera2D")
	if camera != null:
		camera.enabled = true
		camera.make_current()

## 应用角色数据到玩家
func _apply_character_data_to_player() -> void:
	if GameManager.selected_character_data == null:
		print("GameRoot: GameManager.selected_character_data 为 null，无法应用角色数据")
		return

	if player.has_method("_apply_character_data"):
		player._apply_character_data()
		print("GameRoot: 角色数据已应用到 Player")

## ========== 全局 UI 初始化 ==========

## 初始化全局UI
func _initialize_global_ui() -> void:
	# 连接 GameManager 信号以更新 UI
	if GameManager.has_signal("coins_changed") and not GameManager.coins_changed.is_connected(_on_coins_changed):
		GameManager.coins_changed.connect(_on_coins_changed)

	if GameManager.has_signal("health_changed") and not GameManager.health_changed.is_connected(_on_health_changed):
		GameManager.health_changed.connect(_on_health_changed)

	if GameManager.has_signal("reward_obtained") and not GameManager.reward_obtained.is_connected(_on_reward_obtained):
		GameManager.reward_obtained.connect(_on_reward_obtained)

	# 初始化UI显示
	_update_ui()

## ========== 信号连接 ==========

## 连接 GameManager 信号
func _connect_game_manager_signals() -> void:
	if GameManager.has_signal("player_died") and not GameManager.player_died.is_connected(_on_player_died):
		GameManager.player_died.connect(_on_player_died)

## ========== UI 更新 ==========

## 更新UI显示
func _update_ui() -> void:
	_on_coins_changed(GameManager.get_coins())
	_on_health_changed(GameManager.get_health())

## 金币变化回调
func _on_coins_changed(coins: int) -> void:
	if coin_label != null:
		coin_label.text = "Coins: %d" % coins

## 生命值变化回调
func _on_health_changed(health: int) -> void:
	if hp_bar != null:
		hp_bar.value = float(health) / float(GameManager.max_health) * 100.0

## 奖励获得回调
func _on_reward_obtained(reward_text: String) -> void:
	print("奖励: %s" % reward_text)
	# TODO: 添加奖励弹出UI

## ========== 关卡管理 ==========

## 加载关卡
func load_level(level_path: String) -> void:
	if _is_loading_level:
		push_warning("GameRoot: 关卡加载正在进行中，跳过重复调用")
		return

	_is_loading_level = true
	print("GameRoot: [1] 开始加载关卡: %s" % level_path)

	# 卸载当前关卡
	if _current_level != null:
		print("GameRoot: [2] 卸载当前关卡: %s" % _current_level_name)
		await unload_current_level_async()

	# 加载新关卡
	print("GameRoot: [3] 开始加载新关卡")
	await load_new_level_async(level_path)

	_is_loading_level = false
	print("GameRoot: [4] 关卡加载完成，标志已重置")

## 卸载当前关卡（异步版本）
func unload_current_level_async() -> void:
	if _current_level == null:
		return

	print("GameRoot: 卸载关卡: %s" % _current_level_name)

	# 发出卸载信号
	level_unloading.emit(_current_level_name)

	# 移除关卡
	_current_level.queue_free()
	await _current_level.tree_exited
	_current_level = null
	_current_level_name = ""
	print("GameRoot: 关卡已卸载")

## 加载新关卡（异步版本）
func load_new_level_async(level_path: String) -> void:
	# 加载关卡场景
	var level_packed = load(level_path) as PackedScene
	if level_packed == null:
		push_error("GameRoot: 无法加载关卡场景：%s" % level_path)
		_is_loading_level = false
		return

	# 实例化关卡
	_current_level = level_packed.instantiate() as Node2D
	if _current_level == null:
		push_error("GameRoot: 关卡场景根节点不是 Node2D")
		_is_loading_level = false
		return

	# 设置关卡名称
	_current_level_name = level_path.get_file().get_basename()

	# 将关卡添加到容器（会触发 _ready）
	level_container.add_child(_current_level)
	print("GameRoot: 关卡实例已添加到容器")

	# 等待一帧，确保 _ready 完成
	await get_tree().physics_frame
	print("GameRoot: 关卡 _ready 已完成")

	# 初始化关卡
	_initialize_loaded_level()

	# 发出加载完成信号
	level_loaded.emit(_current_level_name)
	print("GameRoot: 关卡加载完成: %s" % _current_level_name)

## 初始化已加载的关卡
func _initialize_loaded_level() -> void:
	if _current_level == null:
		return

	# 如果关卡有出生点，重置玩家位置
	if _current_level.has_method("get_player_spawn_point"):
		var spawn_point: Marker2D = _current_level.get_player_spawn_point()
		if spawn_point != null:
			player.global_position = spawn_point.global_position
			print("GameRoot: 玩家位置已重置到: %s" % player.global_position)

	# 如果关卡有初始化方法，调用它
	if _current_level.has_method("initialize_level"):
		_current_level.initialize_level(self)
		print("GameRoot: 关卡初始化完成")

	# 更新 GameManager 的主场景引用
	if _current_level.has_method("get_spawner"):
		GameManager.main_scene = _current_level

## ========== 场景切换公共接口 ==========

## 切换到主关卡
func switch_to_main_level() -> void:
	load_level("res://scenes/levels/MainLevel.tscn")

## 切换到休息区域
func switch_to_rest_area() -> void:
	load_level("res://scenes/levels/RestAreaLevel.tscn")

## 重置当前关卡
func restart_current_level() -> void:
	if _current_level_name != "":
		var level_path = "res://scenes/levels/%s.tscn" % _current_level_name
		load_level(level_path)

## ========== 辅助方法 ==========

## 获取当前加载的关卡（供 GameManager 等使用）
func get_current_level() -> Node2D:
	return _current_level

## ========== 信号回调 ==========

## 玩家死亡回调
func _on_player_died() -> void:
	print("GameRoot: 玩家死亡")
	# TODO: 显示游戏结束界面

## ========== 输入处理 ==========

func _input(event: InputEvent) -> void:
	# 按下 R 键重新开始当前关卡
	if event.is_action_pressed("ui_restart"):
		restart_current_level()

	# 按下 ESC 键暂停/恢复游戏
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

## 暂停/恢复游戏
func toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
