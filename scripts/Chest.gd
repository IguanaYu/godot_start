## 宝箱脚本（Chest.gd）
## 功能：处理宝箱的拾取逻辑和随机奖励池
## 节点结构：Area2D (根节点)
##   ├── Sprite2D (宝箱精灵)
##   ├── CollisionShape2D (碰撞体)
##   └── AnimationPlayer (开箱动画，可选)

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

## ========== 节点引用 ==========

## 精灵节点引用
@onready var sprite: Sprite2D = $Sprite2D
## 碰撞形状引用
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
## 动画播放器引用（可选）
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	# 连接信号
	body_entered.connect(_on_body_entered)

	# 启用碰撞检测（仅检测玩家）
	collision_layer = 0
	collision_mask = 1 << 0  # 第0层是玩家层

## ========== 拾取逻辑 ==========

## 当玩家拾取宝箱时调用
func _on_collected() -> void:
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

## 随机发放奖励
func _grant_random_reward() -> void:
	# 随机选择一个奖励类型
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

## 发放移速提升奖励
func _grant_speed_boost() -> void:
	var duration: float = 10.0
	GameManager.apply_buff("speed_boost")
	GameManager.reward_obtained.emit("移速提升！速度 +30%%，持续 %.0f 秒" % duration)

## 发放恢复生命奖励
func _grant_heal() -> void:
	var heal_amount: int = 1
	GameManager.heal_player(heal_amount)

## 发放财富奖励
func _grant_wealth() -> void:
	var coin_amount: int = 3
	GameManager.add_coins(coin_amount)
	GameManager.reward_obtained.emit("财富！获得 %d 金币" % coin_amount)

## 发放无敌星奖励
func _grant_star_invincible() -> void:
	var duration: float = 10.0
	GameManager.apply_buff("star_invincibility")
	GameManager.reward_obtained.emit("无敌星！无敌且秒杀敌人，持续 %.0f 秒" % duration)

## 发放金币雨奖励
func _grant_coin_rain() -> void:
	var duration: float = GameManager.coin_rain_duration
	GameManager.start_coin_rain()
	GameManager.reward_obtained.emit("金币雨！持续 %.0f 秒" % duration)

## 发放圣光涌动奖励
func _grant_holy_light() -> void:
	GameManager.clear_all_enemies()

## ========== 信号回调 ==========

## 检测到碰撞体进入
func _on_body_entered(body: Node2D) -> void:
	# 检查碰撞体是否是玩家
	if body is Player:
		_on_collected()

## ========== 公共方法 ==========

## 获取是否已开启
func is_opened() -> bool:
	return _is_opened

## 手动设置奖励类型（用于测试或特殊场景）
func set_reward_type(reward_type: RewardType) -> void:
	# 如果需要固定奖励类型，可以存储这个变量
	# 在 _grant_random_reward() 中检查并使用
	pass
