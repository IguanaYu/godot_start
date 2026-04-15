## 宝箱脚本（Chest.gd）
## 功能：处理宝箱的拾取逻辑和随机奖励池
## 节点结构：Area2D (根节点)
##   ├── Sprite2D (宝箱精灵)
##   ├── CollisionShape2D (碰撞体)
##   ├── AnimationPlayer (开箱动画，可选)
##   └── InstantPickup (拾取组件)

extends Area2D

class_name Chest

## ========== 奖励类型枚举 ==========

enum RewardType {
	SPEED_BOOST,      # 移速提升
	HEAL,             # 恢复生命
	WEALTH,           # 财富（+3金币）
	STAR_INVINCIBLE,  # 无敌星
	COIN_RAIN,        # 金币雨
	HOLY_LIGHT        # 圣光涌动
}

## ========== 可配置变量 ==========

## 是否已开启
var _is_opened: bool = false
## 拾取组件
var _pickup: InstantPickup

## ========== 节点引用 ==========

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	# 创建并挂载 InstantPickup 组件
	_pickup = InstantPickup.new()
	_pickup.name = "InstantPickup"
	add_child(_pickup)
	_pickup.collected.connect(_on_collected)

	# 启用碰撞检测（仅检测玩家）
	collision_layer = 0
	collision_mask = 1 << 0  # 第0层是玩家层

## ========== 拾取逻辑 ==========

func _on_collected(_player: Player) -> void:
	if _is_opened:
		return

	_is_opened = true

	# 播放开箱动画（如果有）
	if animation_player != null:
		animation_player.play("open")

	# 随机选择并发放奖励
	_grant_random_reward()

	# 队列释放（延迟一点点让动画播放）
	await get_tree().create_timer(0.5).timeout
	queue_free()

## ========== 奖励系统 ==========

func _grant_random_reward() -> void:
	var reward_type: RewardType = randi() % RewardType.size()

	match reward_type:
		RewardType.SPEED_BOOST:
			_grant_speed_boost()
		RewardType.HEAL:
			_grant_heal()
		RewardType.WEALTH:
			_grant_wealth()
		RewardType.STAR_INVINCIBLE:
			_grant_star_invincible()
		RewardType.COIN_RAIN:
			_grant_coin_rain()
		RewardType.HOLY_LIGHT:
			_grant_holy_light()

func _grant_speed_boost() -> void:
	var duration: float = 10.0
	GameManager.apply_buff("speed_boost")
	GameManager.reward_obtained.emit("移速提升！速度 +30%%，持续 %.0f 秒" % duration)

func _grant_heal() -> void:
	var heal_amount: int = 1
	GameManager.heal_player(heal_amount)

func _grant_wealth() -> void:
	var coin_amount: int = 3
	GameManager.add_coins(coin_amount)
	GameManager.reward_obtained.emit("财富！获得 %d 金币" % coin_amount)

func _grant_star_invincible() -> void:
	var duration: float = 10.0
	GameManager.apply_buff("star_invincible")
	GameManager.reward_obtained.emit("无敌星！无敌且秒杀敌人，持续 %.0f 秒" % duration)

func _grant_coin_rain() -> void:
	var duration: float = GameManager.coin_rain_duration
	GameManager.start_coin_rain()
	GameManager.reward_obtained.emit("金币雨！持续 %.0f 秒" % duration)

func _grant_holy_light() -> void:
	GameManager.clear_all_enemies()

## ========== 公共方法 ==========

func is_opened() -> bool:
	return _is_opened

func set_reward_type(reward_type: RewardType) -> void:
	pass
