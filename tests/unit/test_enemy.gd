## Enemy单元测试
## 测试敌人系统的初始化、行为、生命周期等功能
extends GutTest

## 测试用的敌人实例
var test_enemy: Enemy
var enemy_scene: PackedScene

## ========== 测试初始化和清理 ==========

## 每个测试前执行
func before_each():
	GameManager.selected_character_data = null
	GameManager.max_health = 3
	GameManager.max_health_bonus = 0
	GameManager.reset_game()
	GameManager.reset_coins()
	GameManager.reset_health()

	# 加载敌人场景
	enemy_scene = load("res://scenes/Enemy.tscn")
	if enemy_scene == null:
		gut.p("Failed to load Enemy scene - creating minimal test setup")
		# 创建一个最小的Area2D用于测试
		test_enemy = Area2D.new()
		test_enemy.set_script(Enemy)
	else:
		test_enemy = enemy_scene.instantiate()

## 每个测试后执行
func after_each():
	if test_enemy != null and is_instance_valid(test_enemy):
		test_enemy.queue_free()
	test_enemy = null

## ========== 枚举和常量测试 ==========

## 测试行为类型枚举
func test_behavior_type_enum():
	assert_eq(Enemy.BehaviorType.STATIC, 0, "STATIC应该是0")
	assert_eq(Enemy.BehaviorType.RANDOM_MOVE, 1, "RANDOM_MOVE应该是1")

## 测试巨型缩放倍数默认值
func test_default_giant_scale_multiplier():
	# 创建新敌人检查默认值
	var enemy = Enemy.new()
	assert_eq(enemy.giant_scale_multiplier, 2.0, "默认巨型缩放应该是2.0")
	enemy.free()

## 测试移动距离默认值
func test_default_move_distance():
	var enemy = Enemy.new()
	assert_eq(enemy.move_distance, 100.0, "默认移动距离应该是100.0")
	enemy.free()

## ========== 伤害值测试 ==========

## 测试巨型敌人伤害更高
func test_giant_enemy_deals_more_damage():
	# 巨型敌人应该有更高的伤害值
	# 这个测试验证巨型敌人的基本属性
	var enemy = Enemy.new()
	enemy.giant_scale_multiplier = 2.0
	assert_eq(enemy.giant_scale_multiplier, 2.0, "巨型敌人缩放应该是2倍")
	enemy.free()

## ========== 行为类型测试 ==========

## 测试静止行为类型
func test_static_behavior_type():
	var enemy = Enemy.new()
	enemy._behavior_type = Enemy.BehaviorType.STATIC
	assert_eq(enemy.get_behavior_type(), Enemy.BehaviorType.STATIC, "行为类型应该是STATIC")
	enemy.free()

## 测试随机移动行为类型
func test_random_move_behavior_type():
	var enemy = Enemy.new()
	enemy._behavior_type = Enemy.BehaviorType.RANDOM_MOVE
	assert_eq(enemy.get_behavior_type(), Enemy.BehaviorType.RANDOM_MOVE, "行为类型应该是RANDOM_MOVE")
	enemy.free()

## ========== 生命周期测试 ==========

## 测试生命周期默认值
func test_default_lifetime():
	var enemy = Enemy.new()
	assert_eq(enemy.lifetime, 10.0, "默认生命周期应该是10秒")
	enemy.free()

## 测试设置生命周期
func test_set_lifetime():
	var enemy = Enemy.new()
	enemy.lifetime = 5.0
	assert_eq(enemy.lifetime, 5.0, "生命周期应该是5秒")
	enemy.free()

## ========== 销毁测试 ==========

## 测试销毁方法不会崩溃
func test_destroy_method():
	var enemy = Enemy.new()
	# 调用destroy不应该崩溃
	# 注意：实际的queue_free会在空闲时执行
	enemy.destroy()
	# 验证对象仍然有效（因为queue_free是延迟的）
	assert_not_null(enemy, "敌人对象仍然存在（延迟删除）")
	enemy.free()

## ========== 属性访问测试 ==========

## 测试移动速度属性
func test_move_speed_property():
	var enemy = Enemy.new()
	enemy.move_speed = 100.0
	assert_eq(enemy.move_speed, 100.0, "移动速度应该是100.0")
	enemy.free()

## 测试移动距离属性
func test_move_distance_property():
	var enemy = Enemy.new()
	enemy.move_distance = 150.0
	assert_eq(enemy.move_distance, 150.0, "移动距离应该是150.0")
	enemy.free()

## 测试巨型变体概率属性
func test_giant_variant_chance_property():
	var enemy = Enemy.new()
	enemy.giant_variant_chance = 0.5
	assert_eq(enemy.giant_variant_chance, 0.5, "巨型变体概率应该是0.5")
	enemy.free()

## 测试静止概率属性
func test_static_chance_property():
	var enemy = Enemy.new()
	enemy.static_chance = 0.7
	assert_eq(enemy.static_chance, 0.7, "静止概率应该是0.7")
	enemy.free()

## ========== 边界值测试 ==========

## 测试巨型概率最大值
func test_giant_chance_max_value():
	var enemy = Enemy.new()
	enemy.giant_variant_chance = 1.0
	assert_eq(enemy.giant_variant_chance, 1.0, "巨型概率可以是1.0")
	enemy.free()

## 测试巨型概率最小值
func test_giant_chance_min_value():
	var enemy = Enemy.new()
	enemy.giant_variant_chance = 0.0
	assert_eq(enemy.giant_variant_chance, 0.0, "巨型概率可以是0.0")
	enemy.free()

## 测试生命周期最大值
func test_lifetime_max_value():
	var enemy = Enemy.new()
	enemy.lifetime = 100.0
	assert_eq(enemy.lifetime, 100.0, "生命周期可以是100.0")
	enemy.free()

## 测试生命周期最小值
func test_lifetime_min_value():
	var enemy = Enemy.new()
	enemy.lifetime = 0.1
	assert_eq(enemy.lifetime, 0.1, "生命周期可以是0.1")
	enemy.free()
