## GameManager单元测试
## 测试金币、生命值等核心游戏管理功能
extends GutTest

## ========== 测试初始化和清理 ==========

## 每个测试前执行
func before_each():
	GameManager.reset_game()
	GameManager.reset_coins()
	GameManager.reset_health()

## 每个测试后执行
func after_each():
	pass

## ========== 金币管理测试 ==========

## 测试初始金币为0
func test_initial_coins_is_zero():
	assert_eq(GameManager.get_coins(), 0, "游戏开始时金币应该为0")

## 测试增加金币
func test_add_coins():
	GameManager.add_coins(10)
	assert_eq(GameManager.get_coins(), 10, "增加10金币后应该是10")

	GameManager.add_coins(5)
	assert_eq(GameManager.get_coins(), 15, "再增加5金币后应该是15")

## 测试重置金币
func test_reset_coins():
	GameManager.add_coins(100)
	GameManager.reset_coins()
	assert_eq(GameManager.get_coins(), 0, "重置后金币应该为0")

## 测试增加负数金币不应该减少金币
func test_add_negative_coins_does_not_decrease():
	var initial_coins = GameManager.get_coins()
	GameManager.add_coins(-10)
	assert_eq(GameManager.get_coins(), initial_coins, "增加负数金币不应该减少金币")

## 测试连续增加金币
func test_add_coins_multiple_times():
	for i in range(10):
		GameManager.add_coins(1)
	assert_eq(GameManager.get_coins(), 10, "连续增加10次1金币应该是10")

## ========== 生命值管理测试 ==========

## 测试初始生命值
func test_initial_health():
	var health = GameManager.get_health()
	assert_true(health > 0, "初始生命值应该大于0")
	assert_eq(health, 3, "默认初始生命值应该是3")

## 测试玩家受伤
func test_damage_player():
	GameManager.damage_player(1)
	assert_eq(GameManager.get_health(), 2, "受伤1点后应该剩余2点生命值")

	GameManager.damage_player(1)
	assert_eq(GameManager.get_health(), 1, "再受伤1点后应该剩余1点生命值")

## 测试玩家恢复生命值
func test_heal_player():
	GameManager.damage_player(2)  # 剩余1血
	GameManager.heal_player(1)
	assert_eq(GameManager.get_health(), 2, "恢复1点后应该是2点生命值")

## 测试生命值不超过上限
func test_health_does_not_exceed_max():
	GameManager.reset_health()
	GameManager.heal_player(10)
	assert_eq(GameManager.get_health(), 3, "生命值不应该超过最大值3")

## 测试生命值降为0
func test_health_reaches_zero():
	GameManager.damage_player(3)
	assert_eq(GameManager.get_health(), 0, "受伤3点后生命值应该是0")

## 测试重置生命值
func test_reset_health():
	GameManager.damage_player(2)
	GameManager.reset_health()
	var health = GameManager.get_health()
	assert_true(health > 0, "重置后生命值应该大于0")

## 测试在0血时不能再受伤
func test_cannot_damage_when_health_is_zero():
	GameManager.damage_player(5)  # 降到0血
	var health_before = GameManager.get_health()
	GameManager.damage_player(1)
	assert_eq(GameManager.get_health(), health_before, "0血时不应该再减少生命值")

## 测试先受伤再恢复
func test_damage_then_heal():
	GameManager.damage_player(2)  # 剩余1血
	GameManager.heal_player(2)    # 应该恢复到3血
	assert_eq(GameManager.get_health(), 3, "1血恢复2点应该到3血上限")

## ========== 音量管理测试 ==========

## 测试设置主音量
func test_set_master_volume():
	GameManager.set_master_volume(0.5)
	assert_eq(GameManager.get_master_volume(), 0.5, "主音量应该是0.5")

## 测试音量限制在上限1.0
func test_master_volume_clamped_to_max():
	GameManager.set_master_volume(1.5)
	assert_eq(GameManager.get_master_volume(), 1.0, "主音量应该限制在1.0")

## 测试音量限制在下限0.0
func test_master_volume_clamped_to_min():
	GameManager.set_master_volume(-0.5)
	assert_eq(GameManager.get_master_volume(), 0.0, "主音量应该限制在0.0")

## 测试设置音效音量
func test_set_sfx_volume():
	GameManager.set_sfx_volume(0.7)
	assert_eq(GameManager.get_sfx_volume(), 0.7, "音效音量应该是0.7")

## 测试设置音乐音量
func test_set_music_volume():
	GameManager.set_music_volume(0.9)
	assert_eq(GameManager.get_music_volume(), 0.9, "音乐音量应该是0.9")

## ========== 背包管理测试 ==========

## 测试添加物品到背包
func test_add_item_to_inventory():
	var test_item = ItemData.new()
	test_item.item_name = "测试物品"
	GameManager.add_item_to_inventory(test_item)

	var items = GameManager.get_inventory_items()
	assert_eq(items.size(), 1, "背包中应该有1个物品")

## 测试从背包移除物品
func test_remove_item_from_inventory():
	var test_item = ItemData.new()
	test_item.item_name = "测试物品"
	GameManager.add_item_to_inventory(test_item)

	GameManager.remove_item_from_inventory(0)
	var items = GameManager.get_inventory_items()
	assert_eq(items.size(), 0, "移除后背包应该为空")

## 测试清空背包
func test_clear_inventory():
	var test_item = ItemData.new()
	test_item.item_name = "测试物品"
	GameManager.add_item_to_inventory(test_item)

	GameManager.clear_inventory()
	var items = GameManager.get_inventory_items()
	assert_eq(items.size(), 0, "清空后背包应该为空")

## ========== 统计信息测试 ==========

## 测试获取统计摘要
func test_get_stats_summary():
	var stats = GameManager.get_stats_summary()
	assert_true(stats.length() > 0, "统计摘要不应该为空")
	assert_true(stats.contains("金币"), "统计摘要应该包含金币信息")
	assert_true(stats.contains("生命"), "统计摘要应该包含生命值信息")
