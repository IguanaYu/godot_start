## 进度占领组件（ProgressCapture.gd）
## 功能：处理站区域累计进度的通用逻辑
## 用法：在实体的 _ready() 中创建并 add_child，或作为场景子节点挂载
##
## 组件通过 get_parent() 获取父 Area2D，自动连接 body_entered/exited 信号
## 进度条通过以下方式查找（按优先级）：
##   1. 实体调用 set_progress_bar() 手动指定
##   2. 父节点下查找名为 "ProgressBar" 的子节点

extends Node

class_name ProgressCapture

## ========== 信号定义 ==========

## 占领完成时发出
signal completed()

## ========== 可配置变量 ==========

## 进度增长速度（每秒）
var capture_rate: float = 20.0
## 离开后衰减速度（每秒）
var decay_rate: float = 10.0

## ========== 私有变量 ==========

## 当前进度（0-100）
var _progress: float = 0.0
## 玩家是否在区域内
var _player_inside: bool = false
## 是否已完成
var _done: bool = false
## 进度条引用
var _progress_bar: ProgressBar = null

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	# 获取父 Area2D 并连接信号
	var area := get_parent() as Area2D
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)

		# 如果还没手动设置进度条，尝试在父节点中查找
		if _progress_bar == null:
			_progress_bar = area.get_node_or_null("ProgressBar")

	# 初始隐藏进度条
	if _progress_bar:
		_progress_bar.visible = false

func _process(delta: float) -> void:
	if _done:
		return

	# 累计或衰减进度
	if _player_inside:
		_progress = minf(_progress + capture_rate * delta, 100.0)
	else:
		_progress = maxf(_progress - decay_rate * delta, 0.0)

	# 更新进度条
	if _progress_bar:
		_progress_bar.value = _progress

	# 检查完成
	if _progress >= 100.0:
		_done = true
		completed.emit()

## ========== 信号回调 ==========

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_inside = true
		if _progress_bar:
			_progress_bar.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_inside = false
		_progress = 0.0
		if _progress_bar:
			_progress_bar.value = 0
			_progress_bar.visible = false

## ========== 公共方法 ==========

## 手动设置进度条引用
func set_progress_bar(bar: ProgressBar) -> void:
	_progress_bar = bar

## 配置速率
func set_rates(capture: float, decay: float) -> void:
	capture_rate = capture
	decay_rate = decay

## 获取当前进度（0-100）
func get_progress() -> float:
	return _progress

## 获取是否已完成
func is_completed() -> bool:
	return _done

## 获取玩家是否在区域内
func is_player_inside() -> bool:
	return _player_inside
