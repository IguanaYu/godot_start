## 基础区域脚本（BaseArea.gd）
## 功能：提供所有区域类型的共同功能
## 节点结构：Area2D (根节点)
##   ├── AreaSprite (范围指示器 - 半透明圆形)
##   ├── Sprite2D (图标贴图 - 支持旋转)
##   ├── CollisionShape2D (碰撞体 - 圆形)
##   └── ProgressBar (进度条)

@tool
extends Area2D

class_name BaseArea

## ========== 信号定义 ==========

## 占领进度变化时发出（参数：当前进度 0-100）
signal capture_progress_changed(progress: int)
## 占领完成时发出
signal capture_area_completed()

## ========== 可配置变量 ==========

## 进度系统参数
@export var capture_rate: float = 20.0
@export var decay_rate: float = 10.0

## 旋转系统参数
@export var base_rotation_speed: float = 90.0
@export var max_rotation_speed_multiplier: float = 2.0
@export var decay_rotation_speed: float = 45.0

## 奖励参数
@export var capture_bonus_coins: int = 10

## ========== 私有变量 ==========

## 当前占领进度（0-100）
var _capture_progress: float = 0.0
## 玩家是否在区域内
var _player_inside: bool = false
## 是否已完成占领
var _is_completed: bool = false
## 当前旋转角度（度）
var _current_rotation: float = 0.0

## ========== 节点引用 ==========

## 范围指示器精灵节点引用
@onready var area_sprite: Sprite2D = $AreaSprite
## 精灵节点引用（图标）
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

	# 初始化区域外观
	_initialize_appearance()

## 编辑器中每帧检查参数变化
func _process(delta: float) -> void:
	# 编辑器模式：跳过游戏逻辑
	if Engine.is_editor_hint():
		return

	# 游戏模式：正常逻辑
	if _is_completed:
		return

	# 处理占领进度
	if _player_inside:
		# 玩家在区域内，增加进度
		_capture_progress += capture_rate * delta
	else:
		# 玩家离开区域，减少进度
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

	# 更新图标旋转
	_update_sprite_rotation(delta)

## ========== 核心功能 ==========

## 更新图标旋转
func _update_sprite_rotation(delta: float) -> void:
	if sprite == null:
		return

	# 玩家在区域内：顺时针旋转，速度随进度增加
	if _player_inside:
		var progress_ratio: float = _capture_progress / 100.0
		var speed_multiplier: float = 1.0 + (max_rotation_speed_multiplier - 1.0) * progress_ratio
		var current_speed: float = base_rotation_speed * speed_multiplier
		_current_rotation += current_speed * delta  # 顺时针：正数

	# 玩家离开区域，进度>0时：逆时针旋转，固定速度
	elif _capture_progress > 0:
		_current_rotation -= decay_rotation_speed * delta  # 逆时针：负数

	# 进度归零：不旋转
	else:
		return  # 保持当前角度，不旋转

	# 应用旋转
	sprite.rotation_degrees = _current_rotation

## 初始化区域外观（虚函数，子类重写）
func _initialize_appearance() -> void:
	pass

## 完成占领
func _complete_capture() -> void:
	if _is_completed:
		return

	_is_completed = true

	# 更新视觉为金色
	if area_sprite != null:
		area_sprite.modulate = Color.GOLD
	if sprite != null:
		sprite.modulate = Color.GOLD

	# 发出占领完成信号
	capture_area_completed.emit()

	# 调用子类重写的完成逻辑
	_on_capture_completed()

## 占领完成后的行为（虚函数，子类重写）
func _on_capture_completed() -> void:
	pass

## 更新视觉效果
func _update_visuals() -> void:
	# 更新进度条
	if progress_bar != null:
		progress_bar.value = _capture_progress

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

## 获取玩家是否在区域内
func is_player_inside() -> bool:
	return _player_inside
