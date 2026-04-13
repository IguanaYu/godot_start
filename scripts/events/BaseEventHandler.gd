## 事件处理器基类（BaseEventHandler.gd）
## 功能：定义事件处理器的标准接口
extends Node

class_name BaseEventHandler

## ========== 信号定义 ==========

## 事件完成时发出
signal event_completed(event_id: String)
## 事件清理完成时发出
signal event_cleaned_up(event_id: String)

## ========== 可配置变量 ==========

## 关联的事件数据
var event_data: SpecialEvent = null
## SpawnManager 引用（用于生成实体）
var spawn_manager: SpawnManager = null

## ========== 生命周期方法 ==========

## 启动事件
func start_event(data: SpecialEvent, manager: SpawnManager) -> void:
	event_data = data
	spawn_manager = manager
	print("[Event] 事件开始: %s" % data.display_name)
	_on_event_started()

## 子类重写：事件开始时的逻辑
func _on_event_started() -> void:
	pass

## 清理事件
func cleanup() -> void:
	_on_event_cleanup()
	event_cleaned_up.emit(event_data.event_id if event_data else "")
	print("[Event] 事件清理: %s" % (event_data.display_name if event_data else "unknown"))

## 子类重写：事件清理时的逻辑
func _on_event_cleanup() -> void:
	pass

## 完成事件
func _complete_event() -> void:
	event_completed.emit(event_data.event_id if event_data else "")
	print("[Event] 事件完成: %s" % (event_data.display_name if event_data else "unknown"))
