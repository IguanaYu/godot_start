## 敌人脚本（Enemy.gd）
## 功能：处理敌人的生命周期、随机行为（大小和移动模式）、触碰玩家的伤害逻辑及被秒杀逻辑
## 节点结构：Area2D (根节点)
##   ├── Sprite2D (敌人精灵)
##   ├── CollisionShape2D (碰撞体)
##   └── Timer (生命周期计时器)

extends Area2D

class_name Enemy

## ========== 敌人行为类型枚举 ==========

enum BehaviorType {
	STATIC,        # 原地不动
	RANDOM_MOVE    # 随机移动
}

## ========== 可配置变量 ==========

## 敌人生命周期（秒），生成后存活时间
@export var lifetime: float = 10.0
## 随机移动的最大距离
@export var move_distance: float = 100.0
## 随机移动的移动速度
@export var move_speed: float = 50.0
## 巨型变体的概率（0.0 - 1.0）
@export var giant_variant_chance: float = 0.2
## 巨型敌人的缩放倍数
@export var giant_scale_multiplier: float = 2.0
## 行为类型概率（类型A：静止，类型B：移动）
@export var static_chance: float = 0.5

## ========== 私有变量 ==========

## 当前行为类型
var _behavior_type: BehaviorType = BehaviorType.STATIC
## 是否是巨型变体
var _is_giant: bool = false
## 移动目标位置
var _target_position: Vector2
## 移动状态（true = 移动中，false = 等待）
var _is_moving: bool = false
## 等待计时器
var _wait_timer: float = 0.0
## 等待时间范围
var _wait_time_range: Vector2 = Vector2(1.0, 3.0)

## ========== 节点引用 ==========

## 精灵节点引用
@onready var sprite: Sprite2D = $Sprite2D
## 碰撞形状引用
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
## 生命周期计时器引用
@onready var lifetime_timer: Timer = $LifetimeTimer

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	# 注册到 GameManager
	GameManager.register_enemy(self)

	# 连接信号
	body_entered.connect(_on_body_entered)
	lifetime_timer.timeout.connect(_on_lifetime_timer_timeout)

	# 初始化敌人
	_initialize_enemy()

	# 启动生命周期计时器
	lifetime_timer.wait_time = lifetime
	lifetime_timer.start()

## ========== 物理处理 ==========

func _physics_process(delta: float) -> void:
	# 根据行为类型执行对应逻辑
	match _behavior_type:
		BehaviorType.RANDOM_MOVE:
			_process_random_move(delta)
		BehaviorType.STATIC:
			pass  # 静止类型不需要处理

## ========== 敌人初始化 ==========

## 初始化敌人属性
func _initialize_enemy() -> void:
	# 随机决定是否是巨型变体
	_is_giant = randf() < giant_variant_chance

	if _is_giant:
		scale = Vector2.ONE * giant_scale_multiplier
		# 巨型敌人颜色偏红
		sprite.modulate = Color.RED

	# 随机选择行为类型
	if randf() < static_chance:
		_behavior_type = BehaviorType.STATIC
	else:
		_behavior_type = BehaviorType.RANDOM_MOVE
		_pick_random_target_position()

## ========== 随机移动逻辑 ==========

## 选择随机目标位置
func _pick_random_target_position() -> void:
	var random_angle: float = randf() * TAU  # TAU = 2 * PI
	var random_distance: float = randf() * move_distance
	_target_position = global_position + Vector2.from_angle(random_angle) * random_distance
	_is_moving = true

## 处理随机移动
func _process_random_move(delta: float) -> void:
	if _is_moving:
		# 向目标位置移动
		var direction: Vector2 = (_target_position - global_position).normalized()
		global_position += direction * move_speed * delta

		# 检查是否到达目标位置
		if global_position.distance_to(_target_position) < 5.0:
			_is_moving = false
			_wait_timer = randf_range(_wait_time_range.x, _wait_time_range.y)
	else:
		# 等待一段时间后选择新目标
		_wait_timer -= delta
		if _wait_timer <= 0:
			_pick_random_target_position()

## ========== 销毁逻辑 ==========

## 销毁敌人
func destroy() -> void:
	# 从 GameManager 中移除
	GameManager.unregister_enemy(self)

	# 队列释放（安全删除）
	queue_free()

## ========== 信号回调 ==========

## 检测到碰撞体进入
func _on_body_entered(body: Node2D) -> void:
	# 检查碰撞体是否是玩家
	if body is Player:
		var player: Player = body as Player

		# 只有在玩家不是无敌星状态下才造成伤害
		# 无敌星状态下，玩家会在 Player.gd 中直接销毁我们
		if not player.is_star_invincible():
			player.take_damage(1)

## 生命周期计时器超时
func _on_lifetime_timer_timeout() -> void:
	destroy()

## ========== 公共方法 ==========

## 获取当前是否是巨型变体
func is_giant() -> bool:
	return _is_giant

## 获取当前行为类型
func get_behavior_type() -> BehaviorType:
	return _behavior_type
