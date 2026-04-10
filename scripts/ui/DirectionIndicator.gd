## 方向指引管理器脚本
## 功能：管理所有方向箭头的显示和更新
extends Control
class_name DirectionIndicator

## ========== 配置 ==========

## 默认箭头颜色
@export var default_arrow_color: Color = Color.YELLOW
## 边缘边距
@export var edge_padding: float = 40.0

## ========== 私有变量 ==========

## 活动箭头字典：target -> {arrow, color, show_dist, hide_dist, priority}
var _active_indicators: Dictionary = {}
## 玩家引用
var _player: Player
## 摄像机引用
var _camera: Camera2D

## ========== 节点引用 ==========

## 箭头场景预加载
@onready var arrow_scene: PackedScene = preload("res://scenes/ui/DirectionArrow.tscn")

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	# 获取玩家引用
	call_deferred("_setup_player_reference")

func _process(delta: float) -> void:
	if _player == null or _camera == null:
		return

	_update_all_indicators()

## ========== 设置方法 ==========

func _setup_player_reference() -> void:
	"""设置玩家和摄像机引用"""
	_player = GameManager.player
	if _player != null:
		_camera = _player.get_node("Camera2D")

## ========== 公共方法 ==========

## 添加方向指引
func add_indicator(target: Node2D, color: Color, show_distance: float, hide_distance: float, priority: int) -> void:
	if _active_indicators.has(target):
		return

	# 创建箭头
	var arrow: Control = arrow_scene.instantiate()
	add_child(arrow)

	# 存储引用
	_active_indicators[target] = {
		"arrow": arrow,
		"color": color,
		"show_dist": show_distance,
		"hide_dist": hide_distance,
		"priority": priority
	}

## 移除方向指引
func remove_indicator(target: Node2D) -> void:
	if not _active_indicators.has(target):
		return

	var data = _active_indicators[target]
	data["arrow"].queue_free()
	_active_indicators.erase(target)

## 更新所有箭头状态
func update_indicators() -> void:
	_update_all_indicators()

## ========== 私有方法 ==========

func _update_all_indicators() -> void:
	"""更新所有箭头"""
	var viewport_size = get_viewport_rect().size
	var screen_center = _camera.get_screen_center_position()

	# 按优先级排序
	var sorted_targets = _active_indicators.keys()
	sorted_targets.sort_custom(func(a, b): return _active_indicators[a]["priority"] > _active_indicators[b]["priority"])

	for target in sorted_targets:
		if not is_instance_valid(target):
			remove_indicator(target)
			continue

		var data = _active_indicators[target]
		var arrow = data["arrow"]

		# 计算距离
		var distance = target.global_position.distance_to(_player.global_position)

		# 判断可见性
		if distance < data["hide_dist"]:
			arrow.visible = false
			continue
		elif distance >= data["show_dist"]:
			arrow.visible = true

		# 计算屏幕位置
		var result = _calculate_arrow_position(target.global_position, screen_center, viewport_size)
		arrow.position = result["position"] + viewport_size / 2.0
		arrow.rotation_degrees = result["rotation"]

		# 设置颜色
		if arrow.has_method("set_arrow_color"):
			arrow.set_arrow_color(data["color"])

func _calculate_arrow_position(target_pos: Vector2, screen_center: Vector2, viewport_size: Vector2) -> Dictionary:
	"""计算箭头位置和角度"""
	var direction = target_pos - screen_center
	var distance = direction.length()

	# 判断目标是否在屏幕内
	var half_viewport = viewport_size / 2.0
	var in_screen_x = abs(direction.x) < half_viewport.x
	var in_screen_y = abs(direction.y) < half_viewport.y

	# 如果在屏幕内，不显示箭头
	if in_screen_x and in_screen_y:
		return {"visible": false, "position": Vector2.ZERO, "rotation": 0.0}

	# 标准化方向
	direction = direction.normalized()

	# 计算边缘位置
	var padding = edge_padding
	var half_size = half_viewport - Vector2(padding, padding)

	var edge_pos = Vector2.ZERO
	if abs(direction.x) > abs(direction.y):
		edge_pos.x = sign(direction.x) * half_size.x
		edge_pos.y = direction.y * half_size.x / abs(direction.x)
	else:
		edge_pos.x = direction.x * half_size.y / abs(direction.y)
		edge_pos.y = sign(direction.y) * half_size.y

	edge_pos.x = clamp(edge_pos.x, -half_size.x, half_size.x)
	edge_pos.y = clamp(edge_pos.y, -half_size.y, half_size.y)

	# 计算角度
	var angle = rad_to_deg(direction.angle())

	return {"visible": true, "position": edge_pos, "rotation": angle}
