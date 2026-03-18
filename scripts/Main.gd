## 主场景控制器脚本（Main.gd）
## 功能：管理主场景的初始化和游戏流程
## 节点结构：Node2D (根节点)
##   ├── Player (玩家实例)
##   ├── Spawner (生成器实例)
##   ├── Camera2D (摄像机跟随玩家)
##   ├── CanvasLayer
##   │   └── UI (用户界面 - HUD、血量、积分显示等)
##   └── ColorRect / Sprite2D (背景)

extends Node2D

class_name Main

## ========== 可配置变量 ==========

## 是否在游戏启动时自动开始
@export var auto_start: bool = true
## 背景颜色
@export var background_color: Color = Color(0.1, 0.1, 0.15, 1.0)

## ========== 节点引用 ==========

## 玩家节点引用
@onready var player: Player = $Player
## 生成器节点引用
@onready var spawner: Spawner = $Spawner
## 摄像机节点引用
@onready var camera: Camera2D = $Camera2D
## UI 容器引用
@onready var ui_canvas: CanvasLayer = $UI
## 背景节点引用
@onready var background: ColorRect = $Background

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	# 设置 GameManager 的主场景引用
	GameManager.main_scene = self

	# 设置背景颜色
	if background != null:
		background.color = background_color

	# 设置摄像机跟随玩家
	if camera != null and player != null:
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 5.0

	# 连接 GameManager 信号
	GameManager.player_died.connect(_on_player_died)
	GameManager.reward_obtained.connect(_on_reward_obtained)

	# 如果自动开始，初始化游戏
	if auto_start:
		start_game()

## 开始游戏
func start_game() -> void:
	# 重置游戏状态
	GameManager.reset_game()

	# 确保生成器正在运行
	if spawner != null:
		spawner.resume_spawning()

## 游戏结束
func game_over() -> void:
	# 暂停生成器
	if spawner != null:
		spawner.pause_spawning()

	# 显示游戏结束界面
	_show_game_over_screen()

## 重新开始游戏
func restart_game() -> void:
	# 重新加载当前场景
	get_tree().reload_current_scene()

## ========== 信号回调 ==========

## 玩家死亡
func _on_player_died() -> void:
	game_over()

## 获得奖励
func _on_reward_obtained(reward_text: String) -> void:
	# 在 UI 上显示奖励提示
	_show_reward_popup(reward_text)

## ========== UI 显示 ==========

## 显示游戏结束界面
func _show_game_over_screen() -> void:
	# 这里可以添加游戏结束 UI 的显示逻辑
	print("游戏结束！")

## 显示奖励提示
func _show_reward_popup(reward_text: String) -> void:
	# 这里可以添加奖励提示的显示逻辑
	print("奖励: %s" % reward_text)

## ========== 物理处理 ==========

func _physics_process(delta: float) -> void:
	# 如果摄像机需要手动跟随玩家
	if camera != null and player != null:
		# Camera2D 会自动跟随，但如果你需要手动控制：
		# camera.global_position = player.global_position
		pass

## ========== 输入处理 ==========

func _input(event: InputEvent) -> void:
	# 按下 R 键重新开始
	if event.is_action_pressed("ui_restart"):
		restart_game()

	# 按下 ESC 键暂停/恢复游戏
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

## 暂停/恢复游戏
func toggle_pause() -> void:
	var tree: SceneTree = get_tree()
	tree.paused = not tree.paused
