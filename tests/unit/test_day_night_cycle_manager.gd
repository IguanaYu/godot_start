## DayNightCycleManager 单元测试
## 测试昼夜循环的计时和切换逻辑
extends GutTest

var _manager: DayNightCycleManager

func before_each():
	_manager = DayNightCycleManager.new()
	add_child(_manager)

func after_each():
	if _manager and is_instance_valid(_manager):
		_manager.queue_free()
	await wait_frames(1)

## ========== 默认值测试 ==========

func test_default_state():
	assert_eq(_manager.get_current_period(), SpawnPhase.Period.DAY, "默认应为白天")
	assert_eq(_manager.get_difficulty_multiplier(), 1.0, "默认倍率应为 1.0")
	assert_false(_manager._is_running, "默认不应运行")

## ========== start_cycle 测试 ==========

func test_start_cycle():
	var tier = DayNightTier.new()
	tier.day_duration = 10.0
	tier.night_duration = 5.0
	tier.difficulty_multiplier = 1.5

	_manager.start_cycle(tier)

	assert_true(_manager._is_running, "启动后应运行")
	assert_eq(_manager.get_current_period(), SpawnPhase.Period.DAY, "启动后应为白天")
	assert_eq(_manager.get_difficulty_multiplier(), 1.5, "倍率应为 1.5")

## ========== stop_cycle 测试 ==========

func test_stop_cycle():
	var tier = DayNightTier.new()
	_manager.start_cycle(tier)
	_manager.stop_cycle()
	assert_false(_manager._is_running, "停止后不应运行")

## ========== 时段切换测试 ==========

func test_period_switch_day_to_night():
	var tier = DayNightTier.new()
	tier.day_duration = 0.1  # 很短的白天方便测试
	tier.night_duration = 0.1

	_manager.start_cycle(tier)
	assert_eq(_manager.get_current_period(), SpawnPhase.Period.DAY, "初始为白天")

	# 模拟时间流逝
	_manager._process(0.2)
	assert_eq(_manager.get_current_period(), SpawnPhase.Period.NIGHT, "白天结束应切换到黑夜")

## ========== period_changed 信号测试 ==========

func test_period_changed_signal():
	var tier = DayNightTier.new()
	tier.day_duration = 0.05
	tier.night_duration = 0.05

	_manager.start_cycle(tier)

	# 监听信号
	var signal_received = [false]
	var period_value = [-1]
	_manager.period_changed.connect(func(p):
		signal_received[0] = true
		period_value[0] = p
	)

	# 触发切换
	_manager._process(0.1)

	assert_true(signal_received[0], "应发出 period_changed 信号")
	assert_eq(period_value[0], SpawnPhase.Period.NIGHT, "应切换到黑夜")

## ========== get_period_time_remaining 测试 ==========

func test_period_time_remaining():
	var tier = DayNightTier.new()
	tier.day_duration = 10.0
	tier.night_duration = 5.0

	_manager.start_cycle(tier)
	_manager._period_time = 3.0

	var remaining = _manager.get_period_time_remaining()
	assert_eq(remaining, 7.0, "剩余时间应为 7.0")

## ========== 背景色测试 ==========

func test_background_colors():
	var bg = ColorRect.new()
	add_child(bg)

	_manager.set_background(bg)

	var tier = DayNightTier.new()
	tier.day_duration = 1.0
	tier.night_duration = 1.0

	_manager.start_cycle(tier)
	assert_eq(_manager._target_bg_color, _manager.day_color, "白天目标颜色应为 day_color")

	# 切换到黑夜
	_manager._process(1.5)
	assert_eq(_manager._target_bg_color, _manager.night_color, "黑夜目标颜色应为 night_color")

	bg.queue_free()
