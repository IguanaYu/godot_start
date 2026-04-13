## 刷新阶段 Resource
## 功能：定义一组 SpawnEntry 组成的刷新阶段（白天/黑夜）
extends Resource
class_name SpawnPhase

## ========== 阶段标识 ==========

## 阶段唯一 ID
@export var phase_id: String = ""

## ========== 阶段类型 ==========

enum Period { DAY, NIGHT }

## 昼夜时段
@export var period: Period = Period.DAY

## ========== 刷新条目列表 ==========

## 该阶段包含的所有刷新条目
@export var entries: Array[SpawnEntry] = []

## ========== 辅助方法 ==========

## 获取所有已启用且有效的刷新条目
func get_enabled_entries() -> Array[SpawnEntry]:
	var result: Array[SpawnEntry] = []
	for entry in entries:
		if entry.enabled and entry.is_valid():
			result.append(entry)
	return result

## 根据 entry_id 查找条目
func get_entry_by_id(entry_id: String) -> SpawnEntry:
	for entry in entries:
		if entry.entry_id == entry_id:
			return entry
	return null

## 验证数据完整性
func is_valid() -> bool:
	if phase_id == "":
		return false
	if entries.is_empty():
		return false
	return true
