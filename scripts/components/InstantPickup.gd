## 即时拾取组件（InstantPickup.gd）
## 功能：检测玩家碰到区域时发出收集信号
## 用法：作为 Area2D 的子 Node 挂载
##
## 节点结构：
##   SomeEntity (Area2D)
##     ├── ...
##     └── InstantPickup (Node)

extends Node

class_name InstantPickup

## ========== 信号定义 ==========

## 玩家碰到时发出
signal collected(player: Player)

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	var area := get_parent() as Area2D
	if area:
		area.body_entered.connect(_on_body_entered)

## ========== 信号回调 ==========

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		collected.emit(body)
