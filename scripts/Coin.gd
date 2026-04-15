## 金币脚本（Coin.gd）
## 功能：处理金币的生命周期和拾取逻辑
## 节点结构：Area2D (根节点)
##   ├── Sprite2D (金币精灵)
##   ├── CollisionShape2D (碰撞体)
##   ├── Timer (生命周期计时器)
##   └── InstantPickup (拾取组件)

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
## 是否来自金币雨
var _is_from_coin_rain: bool = false
## 拾取组件
var _pickup: InstantPickup

## ========== 节点引用 ==========

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var lifetime_timer: Timer = $LifetimeTimer

## ========== 属性设置 ==========

var is_from_coin_rain: bool:
	get:
		return _is_from_coin_rain
	set(value):
		_is_from_coin_rain = value
		if _is_from_coin_rain:
			sprite.modulate = Color.GOLD

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	# 记录初始位置
	_initial_y = global_position.y

	# 创建并挂载 InstantPickup 组件
	_pickup = InstantPickup.new()
	_pickup.name = "InstantPickup"
	add_child(_pickup)
	_pickup.collected.connect(_on_collected)

	# 启动生命周期计时器
	lifetime_timer.wait_time = lifetime
	lifetime_timer.timeout.connect(queue_free)
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

func _on_collected(_player: Player) -> void:
	# 增加金币数量
	GameManager.add_coins(coin_value)
	# 队列释放
	queue_free()

## ========== 公共方法 ==========

func get_value() -> int:
	return coin_value

func set_value(value: int) -> void:
	coin_value = value
