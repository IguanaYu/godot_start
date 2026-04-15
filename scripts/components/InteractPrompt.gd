## 交互提示组件（InteractPrompt.gd）
## 功能：处理 E 键交互的范围检测和提示显示
## 用法：在实体的 _ready() 中创建并 add_child
##
## 组件会自动查找父节点下已有的 InteractionArea，
## 如果没有则创建新的。适用于未来新增 NPC 实体。
##
## 现有 NPC（ShopNPC、MapSelectNPC、LevelExitNPC）仍使用 Interactable 基类，
## 无需迁移。新 NPC 使用此组件即可。

extends Node

class_name InteractPrompt

## ========== 信号定义 ==========

## 玩家进入交互范围
signal player_entered()
## 玩家离开交互范围
signal player_exited()

## ========== 可配置变量 ==========

## 交互提示文本
var prompt_text: String = "按 E 交互"
## 交互检测范围（圆形半径）
var range_radius: float = 80.0

## ========== 私有变量 ==========

## 玩家是否在交互范围内
var _player_in_range: bool = false
## E键提示标签
var _prompt_label: Label = null
## 提示动画时间
var _prompt_time: float = 0.0
## 检测区域
var _interaction_area: Area2D = null

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	_setup_interaction_area()
	_create_prompt_label()

func _process(delta: float) -> void:
	# 更新提示标签动画
	if _player_in_range and _prompt_label != null:
		_prompt_time += delta
		var float_offset = sin(_prompt_time * 3.0) * 10.0
		_prompt_label.position = Vector2(0, -80 + float_offset)

## ========== 初始化 ==========

## 设置交互检测区域
func _setup_interaction_area() -> void:
	# 尝试使用父节点已有的 InteractionArea
	var parent := get_parent()
	if parent:
		_interaction_area = parent.get_node_or_null("InteractionArea")

	# 如果没有现成的，创建一个新的
	if _interaction_area == null:
		_interaction_area = Area2D.new()
		_interaction_area.name = "InteractionArea"
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = range_radius
		shape.shape = circle
		_interaction_area.add_child(shape)
		parent.add_child(_interaction_area)

	_interaction_area.collision_layer = 0
	_interaction_area.collision_mask = 1  # 检测玩家层
	_interaction_area.body_entered.connect(_on_body_entered)
	_interaction_area.body_exited.connect(_on_body_exited)

## 创建提示标签
func _create_prompt_label() -> void:
	_prompt_label = Label.new()
	_prompt_label.text = "[E] " + prompt_text
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_font_size_override("font_size", 16)
	_prompt_label.add_theme_color_override("font_color", Color.WHITE)
	_prompt_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt_label.add_theme_constant_override("outline_size", 3)
	_prompt_label.z_index = 100
	_prompt_label.visible = false
	add_child(_prompt_label)

## ========== 显示控制 ==========

func _show_prompt() -> void:
	if _prompt_label != null:
		_prompt_label.visible = true

func _hide_prompt() -> void:
	if _prompt_label != null:
		_prompt_label.visible = false

## ========== 信号回调 ==========

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_in_range = true
		_show_prompt()
		player_entered.emit()

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_in_range = false
		_hide_prompt()
		player_exited.emit()

## ========== 公共方法 ==========

func is_player_in_range() -> bool:
	return _player_in_range

func set_prompt_text(text: String) -> void:
	prompt_text = text
	if _prompt_label != null:
		_prompt_label.text = "[E] " + text
