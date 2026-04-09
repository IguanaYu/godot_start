## 角色数据Resource类
## 功能：存储角色的静态属性配置
extends Resource
class_name CharacterData

## 预加载能力类（避免循环依赖）
const CharacterAbility = preload("res://scripts/abilities/CharacterAbility.gd")

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

## ========== 角色移动属性 ==========

## 加速度（像素/秒²）
@export var acceleration: float = 1000.0
## 摩擦力（像素/秒²）
@export var friction: float = 1500.0

## ========== 角色初始资源 ==========

## 初始金币数量
@export var starting_coins: int = 0

## ========== 角色特殊能力 ==========

## 角色的特殊能力列表
@export var abilities: Array[CharacterAbility] = []

## ========== 辅助方法 ==========

## 获取实际初始生命值
func get_initial_health() -> int:
	return starting_health if starting_health > 0 else max_health

## 验证数据完整性
func is_valid() -> bool:
	return character_name != "" and sprite_frames != null

## 获取所有启用的能力
func get_enabled_abilities() -> Array[CharacterAbility]:
	var enabled: Array[CharacterAbility] = []
	for ability in abilities:
		if ability != null and ability.is_enabled:
			enabled.append(ability)
	return enabled
