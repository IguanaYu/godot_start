## 休息场景脚本（RestArea.gd）
## 功能：管理休息场景，包含商店和出口NPC
## 节点结构：Node2D (根节点)
##   ├── PlayerSpawn (玩家出生点)
##   ├── NPCsContainer (NPC容器)
##   ├── Background (背景)
##   └── UI (CanvasLayer - 商店和背包UI)

extends Node2D

class_name RestArea

## ========== 可配置变量 ==========

## 背景颜色
@export var background_color: Color = Color(0.15, 0.1, 0.2, 1.0)

## ========== 节点引用 ==========

## 玩家出生点
@onready var player_spawn: Marker2D = $PlayerSpawn
## NPC容器
@onready var npcs_container: Node2D = $NPCsContainer
## 背景节点
@onready var background: ColorRect = $Background
## 商店NPC
@onready var shop_npc: Node = $NPCsContainer/ShopNPC
## 出口NPC
@onready var level_exit_npc: Node = $NPCsContainer/LevelExitNPC
## 商店UI面板
@onready var shop_panel: Panel = $UI/ShopPanel
## 背包UI面板
@onready var inventory_panel: Panel = $UI/InventoryPanel
## 背包按钮
@onready var inventory_button: Button = $UI/InventoryButton

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	# 设置背景颜色
	if background != null:
		background.color = background_color

	# 设置玩家位置
	_setup_player()

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

## 设置玩家位置
func _setup_player() -> void:
	var player = GameManager.player
	if player != null and is_instance_valid(player) and player_spawn != null:
		player.global_position = player_spawn.global_position

## 设置NPC
func _setup_npcs() -> void:
	# NPC已经通过场景放置，这里可以做一些初始化设置
	if shop_npc != null:
		shop_npc.shop_panel = shop_panel

	if level_exit_npc != null:
		level_exit_npc.connect("returned_to_main", _on_returned_to_main)

## 返回到主场景
func _on_returned_to_main() -> void:
	# 应用永久性增益
	GameManager.apply_permanent_bonuses()

	# 切换回Main场景
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

## 背包按钮按下
func _on_inventory_button_pressed() -> void:
	if inventory_panel != null:
		inventory_panel.visible = not inventory_panel.visible

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
