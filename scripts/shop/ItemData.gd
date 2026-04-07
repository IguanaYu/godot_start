## 物品数据Resource类
## 功能：定义游戏中的各种物品属性和效果
extends Resource
class_name ItemData

## ========== 物品类型枚举 ==========

enum ItemType {
	SPEED_BOOST_PERCENT,      # 速度增加百分比
	HEALTH_RESTORE,           # 回血
	MAX_HEALTH_UP,            # 血量上限+1
	COIN_SPAWN_RATE_UP,       # 金币刷新几率+
	ENEMY_SPAWN_RATE_DOWN,    # 减少敌人刷新
	DIAMOND_SPAWN_RATE_UP     # 钻石刷新几率+
}

## ========== 物品基础信息 ==========

## 物品名称
@export var item_name: String = ""
## 物品描述
@export_multiline var item_description: String = ""
## 物品图标
@export var item_icon: Texture2D = null

## ========== 物品属性 ==========

## 物品类型
@export var item_type: ItemType = ItemType.SPEED_BOOST_PERCENT
## 物品数值（如5表示5%或5滴血）
@export var item_value: float = 0.0
## 物品价格
@export var price: int = 10
## 最大堆叠数
@export var stack_size: int = 99

## ========== 辅助方法 ==========

## 获取显示用的描述文本
func get_display_description() -> String:
	match item_type:
		ItemType.SPEED_BOOST_PERCENT:
			return "%s\n速度增加 +%.0f%%" % [item_description, item_value]
		ItemType.HEALTH_RESTORE:
			return "%s\n恢复生命值 +%.0f" % [item_description, item_value]
		ItemType.MAX_HEALTH_UP:
			return "%s\n生命值上限 +1" % item_description
		ItemType.COIN_SPAWN_RATE_UP:
			return "%s\n金币刷新几率 +%.0f%%" % [item_description, item_value]
		ItemType.ENEMY_SPAWN_RATE_DOWN:
			return "%s\n敌人刷新几率 -%.0f%%" % [item_description, item_value]
		ItemType.DIAMOND_SPAWN_RATE_UP:
			return "%s\n钻石刷新几率 +%.0f%%" % [item_description, item_value]
		_:
			return item_description

## 应用物品效果到玩家
func apply_to_player() -> void:
	match item_type:
		ItemType.SPEED_BOOST_PERCENT:
			# 永久增加速度百分比
			GameManager.speed_boost_percent += item_value
			if GameManager.player != null and is_instance_valid(GameManager.player):
				GameManager.player.base_speed *= (1.0 + item_value / 100.0)

		ItemType.HEALTH_RESTORE:
			# 恢复生命值
			GameManager.heal_player(int(item_value))

		ItemType.MAX_HEALTH_UP:
			# 增加血量上限
			GameManager.max_health_bonus += 1
			GameManager.max_health += 1

		ItemType.COIN_SPAWN_RATE_UP:
			# 增加金币刷新几率（存储，暂无实际效果）
			GameManager.coin_spawn_rate_bonus += item_value

		ItemType.ENEMY_SPAWN_RATE_DOWN:
			# 减少敌人刷新几率（存储，暂无实际效果）
			GameManager.enemy_spawn_rate_penalty += item_value

		ItemType.DIAMOND_SPAWN_RATE_UP:
			# 增加钻石刷新几率（存储，暂无实际效果）
			GameManager.diamond_spawn_rate_bonus += item_value

## 是否是永久性增益（使用后不消失）
func is_permanent() -> bool:
	return item_type == ItemType.MAX_HEALTH_UP

## 是否是消耗品（使用后消失）
func is_consumable() -> bool:
	return item_type != ItemType.MAX_HEALTH_UP

## 验证数据完整性
func is_valid() -> bool:
	return item_name != "" and price >= 0

## ========== PurchaseData适配方法 ==========

## 转换为PurchaseData格式（用于购买系统）
func to_purchase_data() -> PurchaseData:
	var data = PurchaseData.new()
	data.option_name = item_name
	data.description = get_display_description()
	data.price = price
	data.icon = item_icon
	# 将ItemData引用存入custom_data，以便购买后可以调用apply_to_player()
	data.custom_data = {"item_resource": self}
	return data

## 从PurchaseData创建ItemData（静态方法）
static func from_purchase_data(data: PurchaseData) -> ItemData:
	if data == null or data.custom_data.is_empty():
		return null
	return data.custom_data.get("item_resource") as ItemData
