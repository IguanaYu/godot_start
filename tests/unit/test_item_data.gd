## ItemData单元测试
## 测试物品数据验证、效果应用等功能
extends GutTest

## 测试用的物品实例
var test_item: ItemData

## ========== 测试初始化和清理 ==========

## 每个测试前执行
func before_each():
	GameManager.reset_game()
	GameManager.reset_coins()
	GameManager.reset_health()
	# 创建默认测试物品
	test_item = ItemData.new()
	test_item.item_name = "测试物品"
	test_item.item_description = "这是一个测试物品"
	test_item.item_type = ItemData.ItemType.HEALTH_RESTORE
	test_item.item_value = 1.0
	test_item.price = 10

## 每个测试后执行
func after_each():
	test_item = null

## ========== 物品验证测试 ==========

## 测试有效物品应该通过验证
func test_valid_item_passes_validation():
	assert_true(test_item.is_valid(), "有效的物品应该通过验证")

## 测试空名称的物品无效
func test_item_with_empty_name_is_invalid():
	test_item.item_name = ""
	assert_false(test_item.is_valid(), "空名称的物品应该无效")

## 测试负价格的物品无效
func test_item_with_negative_price_is_invalid():
	test_item.price = -10
	assert_false(test_item.is_valid(), "负价格的物品应该无效")

## ========== 物品类型识别测试 ==========

## 测试最大生命值提升是永久物品
func test_max_health_up_is_permanent():
	test_item.item_type = ItemData.ItemType.MAX_HEALTH_UP
	assert_true(test_item.is_permanent(), "最大生命值提升应该是永久物品")
	assert_false(test_item.is_consumable(), "永久物品不应该是消耗品")

## 测试回血药水是消耗品
func test_health_restore_is_consumable():
	test_item.item_type = ItemData.ItemType.HEALTH_RESTORE
	assert_false(test_item.is_permanent(), "回血药水不应该是永久物品")
	assert_true(test_item.is_consumable(), "回血药水应该是消耗品")

## 测试速度提升是消耗品
func test_speed_boost_is_consumable():
	test_item.item_type = ItemData.ItemType.SPEED_BOOST_PERCENT
	assert_false(test_item.is_permanent(), "速度提升不应该是永久物品")
	assert_true(test_item.is_consumable(), "速度提升应该是消耗品")

## ========== 物品效果测试 ==========

## 测试回血物品效果
func test_health_restore_item():
	test_item.item_type = ItemData.ItemType.HEALTH_RESTORE
	test_item.item_value = 2.0

	# 先让玩家受伤
	GameManager.damage_player(2)
	assert_eq(GameManager.get_health(), 1, "应该剩余1点生命值")

	# 使用物品
	test_item.apply_to_player()
	assert_eq(GameManager.get_health(), 3, "恢复2点后应该是满血3点")

## 测试回血物品不会超过上限
func test_health_restore_does_not_exceed_max():
	test_item.item_type = ItemData.ItemType.HEALTH_RESTORE
	test_item.item_value = 5.0

	GameManager.damage_player(1)  # 剩余2血
	test_item.apply_to_player()
	assert_eq(GameManager.get_health(), 3, "恢复后不应该超过最大值3")

## 测试最大生命值提升效果
func test_max_health_up_increases_max_health():
	test_item.item_type = ItemData.ItemType.MAX_HEALTH_UP
	var old_max = GameManager.max_health

	test_item.apply_to_player()
	assert_eq(GameManager.max_health, old_max + 1, "最大生命值应该增加1")

## 测试速度百分比提升
func test_speed_boost_percent():
	test_item.item_type = ItemData.ItemType.SPEED_BOOST_PERCENT
	test_item.item_value = 10.0  # 10%

	var old_percent = GameManager.speed_boost_percent
	test_item.apply_to_player()
	assert_eq(GameManager.speed_boost_percent, old_percent + 10.0, "速度提升百分比应该增加10%")

## 测试金币刷新几率提升
func test_coin_spawn_rate_up():
	test_item.item_type = ItemData.ItemType.COIN_SPAWN_RATE_UP
	test_item.item_value = 5.0  # 5%

	var old_rate = GameManager.coin_spawn_rate_bonus
	test_item.apply_to_player()
	assert_eq(GameManager.coin_spawn_rate_bonus, old_rate + 5.0, "金币刷新几率应该增加5%")

## 测试敌人刷新几率减少
func test_enemy_spawn_rate_down():
	test_item.item_type = ItemData.ItemType.ENEMY_SPAWN_RATE_DOWN
	test_item.item_value = 5.0  # 5%

	var old_rate = GameManager.enemy_spawn_rate_penalty
	test_item.apply_to_player()
	assert_eq(GameManager.enemy_spawn_rate_penalty, old_rate + 5.0, "敌人刷新减少应该增加5%")

## 测试钻石刷新几率提升
func test_diamond_spawn_rate_up():
	test_item.item_type = ItemData.ItemType.DIAMOND_SPAWN_RATE_UP
	test_item.item_value = 3.0  # 3%

	var old_rate = GameManager.diamond_spawn_rate_bonus
	test_item.apply_to_player()
	assert_eq(GameManager.diamond_spawn_rate_bonus, old_rate + 3.0, "钻石刷新几率应该增加3%")

## ========== 描述文本测试 ==========

## 测试回血物品的描述文本
func test_health_restore_description():
	test_item.item_type = ItemData.ItemType.HEALTH_RESTORE
	test_item.item_description = "生命药水"
	test_item.item_value = 2.0

	var desc = test_item.get_display_description()
	assert_true(desc.contains("生命药水"), "描述应该包含物品名称")
	assert_true(desc.contains("恢复生命值"), "描述应该说明效果")
	assert_true(desc.contains("2"), "描述应该包含数值")

## 测试速度提升物品的描述文本
func test_speed_boost_description():
	test_item.item_type = ItemData.ItemType.SPEED_BOOST_PERCENT
	test_item.item_description = "速度强化"
	test_item.item_value = 15.0

	var desc = test_item.get_display_description()
	assert_true(desc.contains("速度强化"), "描述应该包含物品名称")
	assert_true(desc.contains("速度增加"), "描述应该说明效果")
	assert_true(desc.contains("15"), "描述应该包含数值")
	assert_true(desc.contains("%"), "描述应该包含百分号")

## 测试最大生命值提升的描述文本
func test_max_health_up_description():
	test_item.item_type = ItemData.ItemType.MAX_HEALTH_UP
	test_item.item_description = "生命上限提升"

	var desc = test_item.get_display_description()
	assert_true(desc.contains("生命上限提升"), "描述应该包含物品名称")
	assert_true(desc.contains("生命值上限"), "描述应该说明效果")
	assert_true(desc.contains("+1"), "描述应该说明增加1点")

## ========== 物品堆叠测试 ==========

## 测试物品堆叠数设置
func test_item_stack_size():
	test_item.stack_size = 99
	assert_eq(test_item.stack_size, 99, "物品堆叠数应该是99")

## ========== PurchaseData转换测试 ==========

## 测试转换为PurchaseData
func test_to_purchase_data():
	var purchase_data = test_item.to_purchase_data()

	assert_not_null(purchase_data, "转换后的PurchaseData不应该为null")
	assert_eq(purchase_data.option_name, "测试物品", "物品名称应该一致")
	assert_eq(purchase_data.price, 10, "价格应该一致")
	assert_not_null(purchase_data.custom_data, "自定义数据不应该为null")

## 测试从PurchaseData恢复ItemData
func test_from_purchase_data():
	var purchase_data = test_item.to_purchase_data()
	var restored_item = ItemData.from_purchase_data(purchase_data)

	assert_not_null(restored_item, "恢复的ItemData不应该为null")
	assert_eq(restored_item.item_name, "测试物品", "物品名称应该一致")
	assert_eq(restored_item.price, 10, "价格应该一致")

## 测试空PurchaseData无法恢复
func test_from_empty_purchase_data_returns_null():
	var empty_data = PurchaseData.new()
	var restored_item = ItemData.from_purchase_data(empty_data)

	assert_null(restored_item, "空的PurchaseData应该返回null")
