## 撤离区域脚本（EvacuationArea.gd）
## 功能：站区域累计进度占领，完成后切换到休息场景
## 节点结构：Area2D (根节点)
##   ├── AreaSprite (范围指示器)
##   ├── Sprite2D (图标)
##   ├── CollisionShape2D (碰撞体)
##   └── ProgressBar (进度条)

extends Area2D

class_name EvacuationArea

## ========== 信号定义 ==========

## 撤离点占领完成时发出
signal evacuation_area_captured()

## ========== 可配置变量 ==========

## 占领完成金币奖励
@export var bonus_coins: int = 10

## ========== 私有变量 ==========

## 进度占领组件
var _capture: ProgressCapture

## ========== 节点引用 ==========

@onready var area_sprite: Sprite2D = $AreaSprite if has_node("AreaSprite") else null
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	# 创建并挂载 ProgressCapture 组件
	_capture = ProgressCapture.new()
	_capture.name = "ProgressCapture"
	_capture.set_progress_bar($ProgressBar if has_node("ProgressBar") else null)
	add_child(_capture)
	_capture.completed.connect(_on_capture_done)

	# 设置紫色主题
	if area_sprite:
		area_sprite.modulate = Color(0.5, 0, 0.5, 0.5)
	if sprite:
		sprite.modulate = Color.PURPLE

## ========== 占领完成 ==========

func _on_capture_done() -> void:
	# 发放占领奖励
	GameManager.add_coins(bonus_coins)

	# 发出撤离点占领完成信号
	evacuation_area_captured.emit()

	# 显示完成提示
	GameManager.reward_obtained.emit("撤离点占领成功！即将撤离...")

	# 延迟后切换场景
	await get_tree().create_timer(1.0).timeout

	var game_root = get_tree().current_scene
	if game_root and game_root.has_method("switch_to_rest_area"):
		game_root.switch_to_rest_area()
	else:
		push_error("EvacuationArea: 无法获取 GameRoot 实例")
