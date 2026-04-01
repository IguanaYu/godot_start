## 下一关入口NPC脚本（LevelExitNPC.gd）
## 功能：处理返回主场景的交互
## 节点结构：继承自 Interactable

extends "res://scripts/Interactable.gd"

class_name LevelExitNPC

## ========== 信号定义 ==========

## 返回主场景时发出
signal returned_to_main()

## ========== 可配置变量 ==========

## 下一关名称
@export var next_level_name: String = "Main"

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	# 调用父类的_ready
	super._ready()

	# 设置交互提示
	set_interaction_prompt("返回游戏")

## ========== 交互逻辑 ==========

## 重写交互方法
func interact() -> void:
	# 发出返回主场景信号
	returned_to_main.emit()
