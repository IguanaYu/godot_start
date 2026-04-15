## 地图选择NPC脚本（MapSelectNPC.gd）
## 功能：与玩家交互，打开地图选择界面
## 继承：Interactable

extends "res://scripts/Interactable.gd"

class_name MapSelectNPC

## ========== 信号定义 ==========

## 玩家选择了一张地图时发出
signal map_selected(map_config: MapConfig)

## ========== 可配置变量 ==========

## 可选地图配置列表
@export var available_maps: Array[MapConfig] = []

## ========== 私有变量 ==========

## 地图选择面板引用
var _map_select_panel: Control = null

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	super._ready()
	set_interaction_prompt("选择地图")

## ========== 公共方法 ==========

## 设置面板引用
func set_panel(panel: Control) -> void:
	_map_select_panel = panel
	if _map_select_panel.has_signal("map_chosen"):
		_map_select_panel.map_chosen.connect(_on_map_chosen)

## ========== 交互逻辑 ==========

## 重写交互方法
func interact() -> void:
	if _map_select_panel == null:
		return

	# 收集已解锁的地图
	var unlocked: Array = []
	for mc in available_maps:
		if GameManager.current_day_number >= mc.min_unlock_day:
			unlocked.append(mc)

	if unlocked.is_empty():
		push_warning("MapSelectNPC: 没有已解锁的地图")
		return

	_map_select_panel.show_with_maps(unlocked)

## ========== 信号回调 ==========

func _on_map_chosen(mc: MapConfig) -> void:
	map_selected.emit(mc)
