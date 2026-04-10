## Player单元测试
## 测试玩家系统的属性、无敌状态、BUFF等功能
extends GutTest

## 测试用的玩家实例
var test_player: Player

## ========== 测试初始化和清理 ==========

## 每个测试前执行
func before_each():
	GameManager.selected_character_data = null
	GameManager.max_health = 3
	GameManager.max_health_bonus = 0
	GameManager.reset_game()
	GameManager.reset_coins()
	GameManager.reset_health()

	# 创建玩家实例
	test_player = Player.new()

## 每个测试后执行
func after_each():
	if test_player != null and is_instance_valid(test_player):
		test_player.queue_free()
	test_player = null

## ========== 基础属性测试 ==========

## 测试默认基础速度
func test_default_base_speed():
	assert_eq(test_player.base_speed, 200.0, "默认基础速度应该是200.0")

## 测试设置基础速度
func test_set_base_speed():
	test_player.base_speed = 300.0
	assert_eq(test_player.base_speed, 300.0, "基础速度应该是300.0")

## 测试默认加速度
func test_default_acceleration():
	assert_eq(test_player.acceleration, 1000.0, "默认加速度应该是1000.0")

## 测试设置加速度
func test_set_acceleration():
	test_player.acceleration = 1500.0
	assert_eq(test_player.acceleration, 1500.0, "加速度应该是1500.0")

## 测试默认摩擦力
func test_default_friction():
	assert_eq(test_player.friction, 1500.0, "默认摩擦力应该是1500.0")

## 测试设置摩擦力
func test_set_friction():
	test_player.friction = 2000.0
	assert_eq(test_player.friction, 2000.0, "摩擦力应该是2000.0")

## 测试默认无敌时间
func test_default_invincibility_duration():
	assert_eq(test_player.invincibility_duration, 1.5, "默认无敌时间应该是1.5秒")

## 测试设置无敌时间
func test_set_invincibility_duration():
	test_player.invincibility_duration = 2.0
	assert_eq(test_player.invincibility_duration, 2.0, "无敌时间应该是2.0秒")

## 测试默认闪烁间隔
func test_default_blink_interval():
	assert_eq(test_player.blink_interval, 0.1, "默认闪烁间隔应该是0.1秒")

## 测试设置闪烁间隔
func test_set_blink_interval():
	test_player.blink_interval = 0.2
	assert_eq(test_player.blink_interval, 0.2, "闪烁间隔应该是0.2秒")

## ========== 无敌状态测试 ==========

## 测试无敌星状态检查
func test_is_star_invincible_initially_false():
	# 初始状态应该不是无敌星
	assert_false(test_player.is_star_invincible(), "初始状态不应该处于无敌星")

## 测试设置无敌星状态（模拟）
func test_star_invincibility_method_exists():
	# 检查方法存在
	assert_true(test_player.has_method("start_star_invincibility"), "应该有start_star_invincibility方法")

## ========== BUFF系统测试 ==========

## 测试BUFF计时器字典初始化
func test_buff_timers_initialized():
	# BUFF计时器字典应该存在
	assert_not_null(test_player._buff_timers, "BUFF计时器字典应该存在")

## 测试速度倍数初始值
func test_speed_multiplier_initial_value():
	assert_eq(test_player._speed_multiplier, 1.0, "初始速度倍数应该是1.0")

## ========== 边界值测试 ==========

## 测试基础速度最大值
func test_base_speed_max_value():
	test_player.base_speed = 1000.0
	assert_eq(test_player.base_speed, 1000.0, "基础速度可以是1000.0")

## 测试基础速度最小值
func test_base_speed_min_value():
	test_player.base_speed = 0.0
	assert_eq(test_player.base_speed, 0.0, "基础速度可以是0.0")

## 测试加速度最大值
func test_acceleration_max_value():
	test_player.acceleration = 5000.0
	assert_eq(test_player.acceleration, 5000.0, "加速度可以是5000.0")

## 测试加速度最小值
func test_acceleration_min_value():
	test_player.acceleration = 0.0
	assert_eq(test_player.acceleration, 0.0, "加速度可以是0.0")

## 测试摩擦力最大值
func test_friction_max_value():
	test_player.friction = 5000.0
	assert_eq(test_player.friction, 5000.0, "摩擦力可以是5000.0")

## 测试摩擦力最小值
func test_friction_min_value():
	test_player.friction = 0.0
	assert_eq(test_player.friction, 0.0, "摩擦力可以是0.0")

## ========== 信号测试 ==========

## 测试信号定义
func test_signals_defined():
	# 检查信号是否正确定义
	assert_true(test_player.has_signal("player_took_damage"), "应该有player_took_damage信号")
	assert_true(test_player.has_signal("player_died"), "应该有player_died信号")

## ========== 方法存在性测试 ==========

## 测试关键方法存在
func test_key_methods_exist():
	var required_methods = [
		"take_damage",
		"start_star_invincibility",
		"_start_invincibility",
		"_end_invincibility",
		"_handle_movement",
		"_toggle_sprite_visibility"
	]

	for method_name in required_methods:
		assert_true(test_player.has_method(method_name), "应该有方法: " + method_name)

## ========== 交互系统测试 ==========

## 测试交互对象列表初始化
func test_nearby_interactables_initialized():
	# 附近可交互对象列表应该存在
	assert_not_null(test_player._nearby_interactables, "附近可交互对象列表应该存在")
	assert_eq(test_player._nearby_interactables.size(), 0, "初始时应该没有附近的对象")

## ========== 速度计算测试 ==========

## 测试初始当前速度
func test_initial_current_speed():
	assert_eq(test_player._current_speed, 200.0, "初始当前速度应该是200.0")

## 测试设置当前速度
func test_set_current_speed():
	test_player._current_speed = 250.0
	assert_eq(test_player._current_speed, 250.0, "当前速度应该是250.0")

## ========== 特殊值测试 ==========

## 测试零基础速度
func test_zero_base_speed():
	test_player.base_speed = 0.0
	assert_eq(test_player.base_speed, 0.0, "基础速度可以是0")

## 测试负数无敌时间（边界情况）
func test_negative_invincibility_duration():
	test_player.invincibility_duration = -1.0
	assert_eq(test_player.invincibility_duration, -1.0, "无敌时间可以是负数（虽然不合理）")

## 测试非常大的摩擦力
func test_very_large_friction():
	test_player.friction = 999999.0
	assert_eq(test_player.friction, 999999.0, "摩擦力可以是很大的值")
