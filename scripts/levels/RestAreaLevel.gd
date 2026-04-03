## 休息区关卡脚本（RestAreaLevel.gd）
## 功能：管理休息区场景，包含商店和出口NPC
## 节点结构：Node2D (根节点)
##   ├── PlayerSpawn (玩家出生点)
##   ├── NPCsContainer (NPC容器)
##   ├── Background (背景)
##   └── LevelUI (CanvasLayer - 商店和背包UI)

extends "res://scripts/levels/BaseLevel.gd"

## ========== 可配置变量 ==========

## 背景颜色
@export var background_color: Color = Color(0.15, 0.1, 0.2, 1.0)

## ========== 节点引用 ==========

## NPC容器
@onready var npcs_container: Node2D = $NPCsContainer
## 背景节点
@onready var background: ColorRect = $Background
## 商店NPC
@onready var shop_npc: Node = $NPCsContainer/ShopNPC
## 出口NPC
@onready var level_exit_npc: Node = $NPCsContainer/LevelExitNPC
## 商店UI面板
@onready var shop_panel: Panel = $LevelUI/ShopPanel
## 背包UI面板
@onready var inventory_panel: Panel = $LevelUI/InventoryPanel
## 背包按钮
@onready var inventory_button: Button = $LevelUI/InventoryButton

## ========== 标准接口实现 ==========

## 获取玩家出生点
func get_player_spawn_point() -> Marker2D:
	return $PlayerSpawn

## 初始化关卡（由 GameRoot 调用）
func initialize_level(game_root: Node2D) -> void:
	# 设置玩家引用
	player = game_root.player

	# 设置背景颜色
	if background != null:
		background.color = background_color

	# 设置NPC
	_setup_npcs()

	# 隐藏UI面板
	if shop_panel != null:
		shop_panel.visible = false
	if inventory_panel != null:
		inventory_panel.visible = false

	# 连接按钮信号
	if inventory_button != null:
		inventory_button.pressed.connect(_on_inventory_button_pressed)

	# 连接背包面板关闭按钮信号
	var inventory_close_button = inventory_panel.get_node_or_null("VBoxContainer/CloseButton")
	if inventory_close_button != null:
		inventory_close_button.pressed.connect(_on_inventory_close_pressed)

	print("RestAreaLevel: 关卡初始化完成")

## ========== 设置NPC ==========

func _setup_npcs() -> void:
	# NPC已经通过场景放置，这里可以做一些初始化设置
	if shop_npc != null:
		shop_npc.shop_panel = shop_panel

	if level_exit_npc != null:
		if level_exit_npc.has_signal("returned_to_main"):
			level_exit_npc.returned_to_main.connect(_on_returned_to_main)

## ========== 返回到主关卡 ==========

func _on_returned_to_main() -> void:
	# 应用永久性增益
	GameManager.apply_permanent_bonuses()

	# 通过 GameRoot 切换回主关卡
	var game_root = get_tree().current_scene
	if game_root and game_root.has_method("switch_to_main_level"):
		game_root.switch_to_main_level()
	else:
		push_error("RestAreaLevel: 无法获取 GameRoot 实例")

## ========== UI 事件处理 ==========

## 背包按钮按下
func _on_inventory_button_pressed() -> void:
	if inventory_panel != null:
		inventory_panel.visible = not inventory_panel.visible

## 背包关闭按钮按下
func _on_inventory_close_pressed() -> void:
	if inventory_panel != null:
		inventory_panel.visible = false

## ========== 输入处理 ==========

func _input(event: InputEvent) -> void:
	# 按Tab键切换背包显示
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		if inventory_panel != null:
			inventory_panel.visible = not inventory_panel.visible

	# 按ESC键关闭所有UI
	if event.is_action_pressed("ui_cancel"):
		if shop_panel != null and shop_panel.visible:
			shop_panel.visible = false
		elif inventory_panel != null and inventory_panel.visible:
			inventory_panel.visible = false

## ========== 清理 ==========

func _exit_tree() -> void:
	# 断开信号连接
	if level_exit_npc != null and level_exit_npc.has_signal("returned_to_main"):
		if level_exit_npc.returned_to_main.is_connected(_on_returned_to_main):
			level_exit_npc.returned_to_main.disconnect(_on_returned_to_main)
