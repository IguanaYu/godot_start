## 特殊事件 Resource
## 功能：定义可触发的特殊事件
extends Resource
class_name SpecialEvent

## ========== 事件标识 ==========

## 事件唯一 ID
@export var event_id: String = ""
## 事件显示名称
@export var display_name: String = ""
## 事件描述
@export var description: String = ""

## ========== 触发配置 ==========

## 事件处理器场景
@export var handler_scene: PackedScene = null
## 触发时段（DAY / NIGHT / BOTH）
@export var trigger_period: String = "BOTH"
## 触发时间偏移（秒，从时段开始计时）
@export var trigger_time: float = 10.0
## 触发概率（0.0 ~ 1.0）
@export var trigger_probability: float = 0.5

## ========== 辅助方法 ==========

## 验证数据完整性
func is_valid() -> bool:
	return event_id != "" and display_name != "" and handler_scene != null
