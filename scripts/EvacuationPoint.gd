## 撤离点脚本（EvacuationPoint.gd）
## 功能：处理撤离点的占领逻辑，占领完成后切换到休息场景
## 节点结构：Area2D (根节点)
##   ├── Sprite2D (撤离点视觉区域 - 紫色半透明圆形)
##   ├── CollisionShape2D (碰撞体 - 圆形)
##   └── ProgressBar (进度条)

extends Area2D

class_name EvacuationPoint

## ========== 信号定义 ==========

## 占领进度变化时发出（参数：当前进度 0-100）
signal capture_progress_changed(progress: int)
## 撤离点占领完成时发出
signal evacuation_point_captured()

## ========== 可配置变量 ==========

## 玩家在撤离点内时每秒增加的进度
@export var capture_rate: float = 25.0
## 玩家离开撤离点时每秒减少的进度
@export var decay_rate: float = 15.0
## 占领成功奖励的金币数量
@export var capture_bonus_coins: int = 10

## ========== 私有变量 ==========

## 当前占领进度（0-100）
var _capture_progress: float = 0.0
## 玩家是否在撤离点内
var _player_inside: bool = false
## 是否已被占领完成
var _is_completed: bool = false

## ========== 节点引用 ==========

## 精灵节点引用
@onready var sprite: Sprite2D = $Sprite2D
## 碰撞形状引用
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
## 进度条引用
@onready var progress_bar: ProgressBar = $ProgressBar

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	# 连接信号
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# 启用碰撞检测（仅检测玩家）
	collision_layer = 0
	collision_mask = 1 << 0  # 第0层是玩家层

	# 初始化撤离点外观
	_initialize_appearance()

## 初始化撤离点外观
func _initialize_appearance() -> void:
	# 设置撤离点颜色为紫色（区别于CapturePoint的蓝色）
	if sprite != null:
		sprite.modulate = Color.PURPLE

## ========== 处理逻辑 ==========

func _process(delta: float) -> void:
	if _is_completed:
		return

	# 处理占领进度
	if _player_inside:
		# 玩家在撤离点内，增加进度
		_capture_progress += capture_rate * delta
	else:
		# 玩家离开撤离点，减少进度
		_capture_progress -= decay_rate * delta

	# 限制进度范围
	_capture_progress = clamp(_capture_progress, 0.0, 100.0)

	# 更新视觉显示
	_update_visuals()

	# 发出进度变化信号
	capture_progress_changed.emit(int(_capture_progress))

	# 检查是否占领完成
	if _capture_progress >= 100.0:
		_complete_capture()

## ========== 占领逻辑 ==========

## 完成占领
func _complete_capture() -> void:
	if _is_completed:
		return

	_is_completed = true

	# 发放占领奖励
	_grant_capture_bonus()

	# 更新视觉
	if sprite != null:
		sprite.modulate = Color.GOLD

	# 显示完成提示
	GameManager.reward_obtained.emit("撤离点占领成功！即将撤离...")

	# 延迟后切换场景（RestArea已有Player实例）
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/RestArea.tscn")

## 发放占领完成奖励
func _grant_capture_bonus() -> void:
	# 增加金币
	GameManager.add_coins(capture_bonus_coins)

## 更新视觉效果
func _update_visuals() -> void:
	# 更新进度条
	if progress_bar != null:
		progress_bar.value = _capture_progress

	# 更新精灵颜色（根据进度从紫色渐变到金色）
	if sprite != null:
		var progress_ratio: float = _capture_progress / 100.0
		var base_color: Color = Color.PURPLE
		var target_color: Color = Color.GOLD
		sprite.modulate = base_color.lerp(target_color, progress_ratio)

## ========== 信号回调 ==========

## 检测到碰撞体进入
func _on_body_entered(body: Node2D) -> void:
	# 检查碰撞体是否是玩家
	if body is Player:
		_player_inside = true

## 检测到碰撞体离开
func _on_body_exited(body: Node2D) -> void:
	# 检查碰撞体是否是玩家
	if body is Player:
		_player_inside = false

## ========== 公共方法 ==========

## 获取当前占领进度（0-100）
func get_capture_progress() -> int:
	return int(_capture_progress)

## 获取是否已完成占领
func is_completed() -> bool:
	return _is_completed

## 获取玩家是否在撤离点内
func is_player_inside() -> bool:
	return _player_inside
