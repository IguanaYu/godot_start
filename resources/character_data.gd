## 角色数据Resource类
## 功能：存储角色的静态属性配置
extends Resource
class_name CharacterData

## ========== 角色基础信息 ==========

## 角色显示名称
@export var character_name: String = ""
## 角色描述
@export_multiline var description: String = ""

## ========== 角色属性 ==========

## 最大生命值
@export var max_health: int = 3
## 初始生命值（可以为1表示困难模式，-1表示使用max_health）
@export var starting_health: int = -1
## 移动速度
@export var speed: float = 200.0

## ========== 视觉资源 ==========

## 角色动画帧资源（包含idle和run动画）
@export var sprite_frames: SpriteFrames = null

## ========== 辅助方法 ==========

## 获取实际初始生命值
func get_initial_health() -> int:
	return starting_health if starting_health > 0 else max_health

## 验证数据完整性
func is_valid() -> bool:
	return character_name != "" and sprite_frames != null
