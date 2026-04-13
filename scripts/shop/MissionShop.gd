## 任务商店脚本（MissionShop.gd）
## 功能：让玩家在休息区选择额外任务/事件
extends Node2D

## ========== 信号定义 ==========

## 任务被接受时发出
signal mission_accepted(event: SpecialEvent)

## ========== 可配置变量 ==========

## 可选任务列表
@export var available_missions: Array[SpecialEvent] = []

## ========== 私有变量 ==========

## UI 面板引用
var _mission_panel: Panel = null

## ========== 初始化 ==========

## 设置任务面板
func setup_panel(panel: Panel) -> void:
	_mission_panel = panel
	_refresh_mission_list()

## 刷新任务列表
func _refresh_mission_list() -> void:
	if _mission_panel == null:
		return

	# 清空现有内容
	var vbox = _mission_panel.get_node_or_null("VBoxContainer")
	if vbox == null:
		return

	for child in vbox.get_children():
		if child is Button:
			vbox.remove_child(child)
			child.queue_free()

	# 创建任务按钮
	for mission in available_missions:
		if mission == null:
			continue
		# 检查是否已接受
		if GameManager.accepted_missions.has(mission):
			continue

		var btn = Button.new()
		btn.text = "%s: %s" % [mission.display_name, mission.description]
		btn.pressed.connect(_on_mission_button_pressed.bind(mission))
		vbox.add_child(btn)

## 任务按钮点击
func _on_mission_button_pressed(mission: SpecialEvent) -> void:
	GameManager.accept_mission(mission)
	mission_accepted.emit(mission)
	_refresh_mission_list()
	print("[MissionShop] 接受任务: %s" % mission.display_name)

## 显示任务面板
func show_panel() -> void:
	_refresh_mission_list()
	if _mission_panel != null:
		_mission_panel.visible = true

## 隐藏任务面板
func hide_panel() -> void:
	if _mission_panel != null:
		_mission_panel.visible = false
