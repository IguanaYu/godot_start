## 金币脚本（Coin.gd）
## 功能：处理金币的生命周期和拾取逻辑
## 节点结构：Area2D (根节点)
##   ├── Sprite2D (金币精灵)
##   ├── CollisionShape2D (碰撞体)
##   └── Timer (生命周期计时器)

extends Area2D

class_name Coin

## ========== 可配置变量 ==========

## 金币生命周期（秒），生成后存活时间
@export var lifetime: float = 15.0
## 金币价值（默认为1）
@export var coin_value: int = 1
## 旋转动画速度
@export var rotation_speed: float = 180.0  # 度/秒
## 浮动动画参数
@export var float_amplitude: float = 10.0  # 浮动幅度（像素）
@export var float_frequency: float = 2.0   # 浮动频率（Hz）

## ========== 私有变量 ==========

## 初始Y位置
var _initial_y: float = 0.0
## 浮动动画计时器
var _float_timer: float = 0.0
## 是否来自金币雨（来自金币雨的金币可能有特殊效果）
var _is_from_coin_rain: bool = false

## ========== 节点引用 ==========

## 精灵节点引用
@onready var sprite: Sprite2D = $Sprite2D
## 碰撞形状引用
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
## 生命周期计时器引用
@onready var lifetime_timer: Timer = $LifetimeTimer

## ========== 属性设置 ==========

## 设置是否来自金币雨
var is_from_coin_rain: bool:
	get:
		return _is_from_coin_rain
	set(value):
		_is_from_coin_rain = value
		# 金币雨生成的金币可以有特殊视觉效果
		if _is_from_coin_rain:
			sprite.modulate = Color.GOLD

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	# 记录初始位置
	_initial_y = global_position.y

	# 连接信号
	body_entered.connect(_on_body_entered)
	lifetime_timer.timeout.connect(_on_lifetime_timer_timeout)

	# 启动生命周期计时器
	lifetime_timer.wait_time = lifetime
	lifetime_timer.start()

	# 启用碰撞检测（仅检测玩家）
	collision_layer = 0
	collision_mask = 1 << 0  # 第0层是玩家层

## ========== 物理处理 ==========

func _physics_process(delta: float) -> void:
	# 旋转动画
	rotation_degrees += rotation_speed * delta

	# 浮动动画
	_float_timer += delta
	var offset: float = sin(_float_timer * float_frequency * TAU) * float_amplitude
	global_position.y = _initial_y + offset

## ========== 拾取逻辑 ==========

## 当玩家拾取金币时调用
func _on_collected() -> void:
	# 增加金币数量
	GameManager.add_coins(coin_value)

	# 播放拾取音效（如果有）
	# $CollectionSound.play()

	# 队列释放
	queue_free()

## ========== 信号回调 ==========

## 检测到碰撞体进入
func _on_body_entered(body: Node2D) -> void:
	# 检查碰撞体是否是玩家
	if body is Player:
		_on_collected()

## 生命周期计时器超时
func _on_lifetime_timer_timeout() -> void:
	queue_free()

## ========== 公共方法 ==========

## 获取金币价值
func get_value() -> int:
	return coin_value

## 设置金币价值
func set_value(value: int) -> void:
	coin_value = value
