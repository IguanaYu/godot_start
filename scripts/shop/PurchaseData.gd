## 购买选项数据类（PurchaseData.gd）
## 功能：统一的购买/选项数据格式
## 用于：商店、地图选择、设施升级等多种购买场景

class_name PurchaseData extends Resource

## ========== 可导出变量 ==========

## 选项名称
@export var option_name: String = ""
## 描述
@export var description: String = ""
## 价格
@export var price: int = 0
## 图标（可选）
@export var icon: Texture2D
## 是否已购买（一次性购买）
@export var purchased: bool = false
## 购买次数限制（0=无限）
@export var max_purchases: int = 0
## 当前购买次数
@export var current_purchases: int = 0
## 自定义数据（用于地图ID、升级等级等扩展用途）
@export var custom_data: Dictionary = {}

## ========== 公共方法 ==========

## 是否可购买
func is_purchasable() -> bool:
	# 检查购买次数限制
	if max_purchases > 0 and current_purchases >= max_purchases:
		return false
	# 检查是否已购买（一次性购买）
	if purchased:
		return false
	return true

## 标记为已购买
func mark_purchased() -> void:
	purchased = true
	current_purchases += 1

## 增加购买次数
func increment_purchases() -> void:
	current_purchases += 1

## 重置购买状态
func reset() -> void:
	purchased = false
	current_purchases = 0

## 获取显示价格
func get_display_price() -> String:
	return "%d 金币" % price

## 获取完整描述（包含价格信息）
func get_full_description() -> String:
	var result = description
	if price > 0:
		result += "\n价格: %d 金币" % price
	if max_purchases > 0:
		var remaining = max_purchases - current_purchases
		result += "\n剩余购买次数: %d" % remaining
	return result
