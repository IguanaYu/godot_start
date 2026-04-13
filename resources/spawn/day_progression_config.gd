## 天数递进配置 Resource
## 功能：定义天数如何影响挡位递进
extends Resource
class_name DayProgressionConfig

## ========== 递进参数 ==========

## 每隔多少天升一挡
@export var days_per_tier: int = 2
## 最大挡位索引（超过后不再递增）
@export var max_tier_index: int = 10
## 每挡难度增量
@export var difficulty_per_tier: float = 0.2
## 基础难度倍率
@export var base_difficulty: float = 1.0

## ========== 辅助方法 ==========

## 根据天数获取挡位索引
func get_tier_index_for_day(day_number: int) -> int:
	var index := (day_number - 1) / days_per_tier
	return mini(index, max_tier_index)

## 根据天数获取难度倍率
func get_difficulty_for_day(day_number: int) -> float:
	var tier = get_tier_index_for_day(day_number)
	return base_difficulty + tier * difficulty_per_tier

## 验证数据完整性
func is_valid() -> bool:
	return days_per_tier > 0
