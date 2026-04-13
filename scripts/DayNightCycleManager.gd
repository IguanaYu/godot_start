## 昼夜循环管理器脚本（DayNightCycleManager.gd）
## 功能：管理昼夜循环计时，触发昼夜切换信号
## 节点结构：Node (普通节点，添加到 MainLevel 场景树)

extends Node

class_name DayNightCycleManager

## ========== 信号定义 ==========

## 时段切换时发出（白天↔黑夜）
signal period_changed(period: SpawnPhase.Period)
## 挡位切换时发出
signal tier_changed(old_tier: DayNightTier, new_tier: DayNightTier)
## 每秒更新时发出（可用于UI倒计时）
signal time_updated(period: SpawnPhase.Period, time_in_period: float, total_period_duration: float)

## ========== 可配置变量 ==========

## 背景色 - 白天
@export var day_color: Color = Color(0.1, 0.1, 0.15, 1.0)
## 背景色 - 黑夜
@export var night_color: Color = Color(0.05, 0.05, 0.08, 1.0)
## 颜色过渡速度（越大越快）
@export var color_transition_speed: float = 2.0

## ========== 私有变量 ==========

## 当前挡位
var _current_tier: DayNightTier = null
## 当前时段
var _current_period: SpawnPhase.Period = SpawnPhase.Period.DAY
## 当前时段内已过时间
var _period_time: float = 0.0
## 是否正在运行
var _is_running: bool = false
## 背景节点引用（用于视觉过渡）
var _background: ColorRect = null
## 当前背景颜色
var _current_bg_color: Color = Color(0.1, 0.1, 0.15, 1.0)
## 目标背景颜色
var _target_bg_color: Color = Color(0.1, 0.1, 0.15, 1.0)

## ========== 公共方法 ==========

## 启动昼夜循环
func start_cycle(tier: DayNightTier) -> void:
	_current_tier = tier
	_current_period = SpawnPhase.Period.DAY
	_period_time = 0.0
	_is_running = true
	_target_bg_color = day_color
	_current_bg_color = day_color

	if _background != null:
		_background.color = day_color

	print("[DayNight] 昼夜循环启动, 白天 %.0fs / 黑夜 %.0fs" % [tier.day_duration, tier.night_duration])

## 停止昼夜循环
func stop_cycle() -> void:
	_is_running = false

## 设置背景节点引用
func set_background(bg: ColorRect) -> void:
	_background = bg

## 获取当前时段
func get_current_period() -> SpawnPhase.Period:
	return _current_period

## 获取当前难度倍率
func get_difficulty_multiplier() -> float:
	if _current_tier == null:
		return 1.0
	return _current_tier.difficulty_multiplier

## 获取当前时段剩余时间
func get_period_time_remaining() -> float:
	if _current_tier == null:
		return 0.0
	var duration = _get_current_period_duration()
	return max(0.0, duration - _period_time)

## 获取当前时段总时长
func _get_current_period_duration() -> float:
	if _current_tier == null:
		return 0.0
	if _current_period == SpawnPhase.Period.DAY:
		return _current_tier.day_duration
	return _current_tier.night_duration

## ========== Godot 生命周期函数 ==========

func _process(delta: float) -> void:
	if not _is_running or _current_tier == null:
		return

	# 推进时间
	_period_time += delta

	# 更新背景颜色渐变
	_update_bg_color(delta)

	# 检查时段切换
	var duration = _get_current_period_duration()
	if _period_time >= duration:
		_switch_period()

	# 发出时间更新信号
	time_updated.emit(_current_period, _period_time, duration)

## ========== 私有方法 ==========

## 切换时段
func _switch_period() -> void:
	var old_period = _current_period
	_period_time = 0.0

	if _current_period == SpawnPhase.Period.DAY:
		_current_period = SpawnPhase.Period.NIGHT
		_target_bg_color = night_color
		print("[DayNight] 切换到黑夜")
	else:
		_current_period = SpawnPhase.Period.DAY
		_target_bg_color = day_color
		print("[DayNight] 切换到白天")

	period_changed.emit(_current_period)

## 更新背景颜色渐变
func _update_bg_color(delta: float) -> void:
	if _background == null:
		return

	_current_bg_color = _current_bg_color.lerp(_target_bg_color, color_transition_speed * delta)
	_background.color = _current_bg_color
