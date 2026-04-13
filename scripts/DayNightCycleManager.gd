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

## ========== 事件调度（步骤8新增） ==========

## 已调度的事件列表 { event_data: SpecialEvent, trigger_at: float }
var _scheduled_events: Array = []
## 已触发的事件
var _triggered_events: Array = []
## 活跃的事件处理器
var _active_handlers: Array = []
## SpawnManager 引用（事件生成实体需要）
var _spawn_manager: SpawnManager = null

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

## 设置 SpawnManager 引用（事件调度用）
func set_spawn_manager(manager: SpawnManager) -> void:
	_spawn_manager = manager

## 调度事件池中的事件
func schedule_events(event_pool: Array[SpecialEvent], extra_events: Array = []) -> void:
	_scheduled_events.clear()
	_triggered_events.clear()

	var all_events: Array = []
	all_events.append_array(event_pool)
	all_events.append_array(extra_events)

	for event in all_events:
		if event == null or not event.is_valid():
			continue

		# 检查触发时段
		if not _is_event_period_match(event):
			continue

		# 按概率决定是否调度
		if randf() > event.trigger_probability:
			continue

		_scheduled_events.append({
			"event": event,
			"trigger_at": event.trigger_time
		})

		print("[Event] 事件已调度: %s (%s %.0fs 触发)" % [event.display_name, "白天" if _current_period == SpawnPhase.Period.DAY else "黑夜", event.trigger_time])

## 检查事件是否匹配当前时段
func _is_event_period_match(event: SpecialEvent) -> bool:
	if event.trigger_period == "BOTH":
		return true
	if event.trigger_period == "DAY" and _current_period == SpawnPhase.Period.DAY:
		return true
	if event.trigger_period == "NIGHT" and _current_period == SpawnPhase.Period.NIGHT:
		return true
	return false

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

	# 检查事件触发（步骤8新增）
	_check_event_triggers()

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

## ========== 事件触发逻辑 ==========

## 检查是否有事件需要触发
func _check_event_triggers() -> void:
	var to_remove: Array = []
	for scheduled in _scheduled_events:
		if _period_time >= scheduled["trigger_at"]:
			_trigger_event(scheduled["event"])
			to_remove.append(scheduled)
	for item in to_remove:
		_scheduled_events.erase(item)

## 触发事件
func _trigger_event(event: SpecialEvent) -> void:
	if _triggered_events.has(event.event_id):
		return

	_triggered_events.append(event.event_id)

	# 实例化事件处理器
	if event.handler_scene == null:
		return

	var handler = event.handler_scene.instantiate()
	if handler == null:
		return

	add_child(handler)
	_active_handlers.append(handler)

	# 连接完成信号
	if handler.has_signal("event_completed"):
		handler.event_completed.connect(_on_event_completed.bind(handler))

	# 启动事件
	if handler.has_method("start_event"):
		handler.start_event(event, _spawn_manager)

## 事件完成回调
func _on_event_completed(event_id: String, handler: Node) -> void:
	if handler and is_instance_valid(handler):
		_active_handlers.erase(handler)
		handler.queue_free()
