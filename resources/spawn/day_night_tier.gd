## 昼夜挡位 Resource
## 功能：定义一个昼夜循环的难度挡位（白天/黑夜时长 + 难度倍率）
extends Resource
class_name DayNightTier

## ========== 挡位标识 ==========

## 挡位索引（从 0 开始递增）
@export var tier_index: int = 0

## ========== 时长配置 ==========

## 白天持续时长（秒）
@export var day_duration: float = 40.0
## 黑夜持续时长（秒）
@export var night_duration: float = 20.0

## ========== 难度配置 ==========

## 难度倍率（影响敌人刷新频率等）
@export var difficulty_multiplier: float = 1.0

## ========== 辅助方法 ==========

## 获取一个完整周期时长
func get_total_cycle_duration() -> float:
	return day_duration + night_duration

## 验证数据完整性
func is_valid() -> bool:
	return day_duration > 0.0 and night_duration > 0.0
