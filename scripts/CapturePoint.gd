## 占领据点脚本（CapturePoint.gd）
## 功能：处理玩家进出检测和占领进度计算逻辑
## 节点结构：Area2D (根节点)
##   ├── Sprite2D (据点视觉区域 - 半透明圆形)
##   ├── CollisionShape2D (碰撞体 - 圆形)
##   ├── ColorRect (进度条背景，可选)
##   └── ProgressBar (进度条，可选)

extends Area2D

class_name CapturePoint

## ========== 信号定义 ==========

## 占领进度变化时发出（参数：当前进度 0-100）
signal capture_progress_changed(progress: int)
## 占领完成时发出
signal capture_completed()

## ========== 可配置变量 ==========

## 玩家在据点内时每秒增加的进度
@export var capture_rate: float = 20.0
## 玩家离开据点时每秒减少的进度
@export var decay_rate: float = 10.0
## 玩家在据点内时每秒获得的积分
@export var score_per_second: float = 1.0
## 占领成功后获得的积分奖励
@export var capture_bonus_score: int = 5
## 占领成功奖励的金币数量
@export var capture_bonus_coins: int = 5
## 进度计分计时器（秒）
@export var score_interval: float = 1.0

## ========== 私有变量 ==========

## 当前占领进度（0-100）
var _capture_progress: float = 0.0
## 玩家是否在据点内
var _player_inside: bool = false
## 积分计时器
var _score_timer: float = 0.0
## 是否已被占领完成
var _is_completed: bool = false

## ========== 节点引用 ==========

## 精灵节点引用
@onready var sprite: Sprite2D = $Sprite2D
## 碰撞形状引用
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
## 进度条引用（可选）
@onready var progress_bar: ProgressBar = $ProgressBar if has_node("ProgressBar") else null

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	# 注册到 GameManager
	GameManager.register_capture_point(self)

	# 连接信号
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# 启用碰撞检测（仅检测玩家）
	collision_layer = 0
	collision_mask = 1 << 0  # 第0层是玩家层

	# 初始化据点外观
	_initialize_appearance()

## 初始化据点外观
func _initialize_appearance() -> void:
	# 设置据点颜色（未占领时为蓝色，可以根据进度改变颜色）
	if sprite != null:
		sprite.modulate = Color.BLUE

## ========== 处理逻辑 ==========

func _process(delta: float) -> void:
	if _is_completed:
		return

	# 处理占领进度
	if _player_inside:
		# 玩家在据点内，增加进度
		_capture_progress += capture_rate * delta

		# 处理积分计时器
		_score_timer += delta
		if _score_timer >= score_interval:
			_score_timer = 0.0
			_grant_in_zone_score()
	else:
		# 玩家离开据点，减少进度
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

	# 发出占领完成信号
	capture_completed.emit()

	# 更新视觉
	if sprite != null:
		sprite.modulate = Color.GOLD

	# 延迟后销毁
	await get_tree().create_timer(0.5).timeout
	queue_free()

## 发放区域内积分奖励
func _grant_in_zone_score() -> void:
	GameManager.add_coins(int(score_per_second))

## 发放占领完成奖励
func _grant_capture_bonus() -> void:
	# 增加金币和积分
	GameManager.add_coins(capture_bonus_coins)
	GameManager.reward_obtained.emit("占领成功！获得 %d 金币" % capture_bonus_coins)

## 更新视觉效果
func _update_visuals() -> void:
	# 更新进度条
	if progress_bar != null:
		progress_bar.value = _capture_progress

	# 更新精灵颜色（根据进度从蓝色渐变到金色）
	if sprite != null:
		var progress_ratio: float = _capture_progress / 100.0
		var base_color: Color = Color.BLUE
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

## ========== 清理 ==========

func _exit_tree() -> void:
	# 从 GameManager 中移除
	GameManager.unregister_capture_point(self)

## ========== 公共方法 ==========

## 获取当前占领进度（0-100）
func get_capture_progress() -> int:
	return int(_capture_progress)

## 获取是否已完成占领
func is_completed() -> bool:
	return _is_completed

## 获取玩家是否在据点内
func is_player_inside() -> bool:
	return _player_inside
