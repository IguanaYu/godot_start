## 地图配置 Resource
## 功能：聚合所有刷新相关的配置，作为地图的顶层配置
extends Resource
class_name MapConfig

## ========== 地图标识 ==========

## 地图名称
@export var map_name: String = ""
## 地图描述
@export var description: String = ""
## 解锁所需天数
@export var min_unlock_day: int = 1
## 地图场景
@export var level_scene: PackedScene = null

## ========== 刷新配置 ==========

## 该地图可用的昼夜挡位列表
@export var tiers: Array[DayNightTier] = []
## 白天阶段配置
@export var day_phase: SpawnPhase = null
## 黑夜阶段配置
@export var night_phase: SpawnPhase = null

## ========== 天数递进 ==========

## 天数递进配置
@export var progression: DayProgressionConfig = null

## ========== 事件 ==========

## 可用的事件池
@export var event_pool: Array[SpecialEvent] = []

## ========== 辅助方法 ==========

## 根据天数获取对应的挡位
func get_tier_for_day(day_number: int) -> DayNightTier:
	if tiers.is_empty():
		return null

	# 根据递进配置计算挡位索引
	var tier_index := 0
	if progression != null:
		tier_index = progression.get_tier_index_for_day(day_number)
	else:
		# 无递进配置时，简单递增
		tier_index = mini(day_number - 1, tiers.size() - 1)

	# 限制在有效范围内
	tier_index = clampi(tier_index, 0, tiers.size() - 1)
	return tiers[tier_index]

## 验证数据完整性
func is_valid() -> bool:
	return map_name != "" and not tiers.is_empty() and day_phase != null
