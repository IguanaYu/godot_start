## 可交互对象基类（Interactable.gd）
## 功能：处理玩家交互检测、E键提示显示、通用交互逻辑
## 节点结构：Area2D (根节点)
##   ├── Sprite2D (外观)
##   ├── CollisionShape2D (碰撞体)
##   ├── InteractionArea (Area2D) - 玩家检测范围
##   │   └── CollisionShape2D
##   └── PromptLabel (Label) - E键交互提示

extends Area2D

class_name Interactable

## ========== 信号定义 ==========

## 当被交互时发出
signal interacted(player: Node2D)

## ========== 可配置变量 ==========

## 交互提示文本
@export var interaction_prompt: String = "按 E 交互"
## 交互检测范围（圆形半径）
@export var interaction_range: float = 80.0

## ========== 私有变量 ==========

## 玩家是否在交互范围内
var _is_in_range: bool = false
## E键提示标签
var _prompt_label: Label = null
## 提示动画时间
var _prompt_time: float = 0.0

## ========== 节点引用 ==========

## 精灵节点
@onready var sprite: Sprite2D = $Sprite2D
## 碰撞形状
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
## 交互检测区域
@onready var interaction_area: Area2D = $InteractionArea
## 交互检测碰撞形状
@onready var interaction_collision: CollisionShape2D = $InteractionArea/CollisionShape2D

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	# 添加到可交互对象组，便于Player查找
	add_to_group("interactables")

	# 设置交互区域的碰撞层（NPC自身的碰撞层在场景中设置）
	interaction_area.collision_layer = 0
	# 检测玩家：假设Player在第0层
	interaction_area.collision_mask = 1

	# 连接交互区域的信号
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

	# 创建E键提示标签
	_create_prompt_label()

	# 设置碰撞形状为圆形
	if interaction_collision.shape is CircleShape2D:
		(interaction_collision.shape as CircleShape2D).radius = interaction_range

## ========== 处理逻辑 ==========

func _process(delta: float) -> void:
	# 更新提示标签动画
	if _is_in_range and _prompt_label != null:
		_update_prompt_animation(delta)

## ========== E键提示系统 ==========

## 创建提示标签
func _create_prompt_label() -> void:
	_prompt_label = Label.new()
	_prompt_label.text = "[E] " + interaction_prompt
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_font_size_override("font_size", 16)
	_prompt_label.add_theme_color_override("font_color", Color.WHITE)
	_prompt_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt_label.add_theme_constant_override("outline_size", 3)
	_prompt_label.z_index = 100  # 确保显示在最上层
	_prompt_label.visible = false

	add_child(_prompt_label)

## 更新提示动画（上下漂浮效果）
func _update_prompt_animation(delta: float) -> void:
	_prompt_time += delta

	# 使用sin函数实现上下漂浮
	var float_offset = sin(_prompt_time * 3.0) * 10.0  # 振幅10像素
	_prompt_label.position = Vector2(0, -80 + float_offset)

## 显示提示
func _show_prompt() -> void:
	if _prompt_label != null:
		_prompt_label.visible = true

## 隐藏提示
func _hide_prompt() -> void:
	if _prompt_label != null:
		_prompt_label.visible = false

## ========== 交互逻辑 ==========

## 是否可以交互（虚方法，子类可重写）
func can_interact() -> bool:
	return _is_in_range

## 交互逻辑（虚方法，子类必须重写）
func interact() -> void:
	GameConsole.warn("Interactable.interact() called but not overridden in subclass: %s" % name)

## ========== 信号回调 ==========

## 检测到玩家进入交互范围
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_is_in_range = true
		_show_prompt()

## 检测到玩家离开交互范围
func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_is_in_range = false
		_hide_prompt()

## ========== 公共方法 ==========

## 设置交互提示文本
func set_interaction_prompt(text: String) -> void:
	interaction_prompt = text
	if _prompt_label != null:
		_prompt_label.text = "[E] " + text

## 获取是否在范围内
func is_in_range() -> bool:
	return _is_in_range
