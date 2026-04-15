## DayProgressionConfig 单元测试
## 测试天数递进配置的属性和计算逻辑
extends GutTest

const DayProgressionConfigScript = preload("res://resources/spawn/day_progression_config.gd")

## ========== 默认值测试 ==========

func test_defaults():
	var config = DayProgressionConfigScript.new()
	assert_eq(config.days_per_tier, 2, "默认 days_per_tier 应为 2")
	assert_eq(config.max_tier_index, 10, "默认 max_tier_index 应为 10")
	assert_eq(config.difficulty_per_tier, 0.2, "默认 difficulty_per_tier 应为 0.2")
	assert_eq(config.base_difficulty, 1.0, "默认 base_difficulty 应为 1.0")

## ========== is_valid 测试 ==========

func test_is_valid_defaults():
	var config = DayProgressionConfigScript.new()
	assert_true(config.is_valid(), "默认值应有效")

func test_is_valid_zero_days_per_tier():
	var config = DayProgressionConfigScript.new()
	config.days_per_tier = 0
	assert_false(config.is_valid(), "days_per_tier 为 0 应无效")

func test_is_valid_negative_days_per_tier():
	var config = DayProgressionConfigScript.new()
	config.days_per_tier = -1
	assert_false(config.is_valid(), "days_per_tier 为负数应无效")

## ========== get_tier_index_for_day 测试 ==========

func test_tier_index_day_1():
	var config = DayProgressionConfigScript.new()
	config.days_per_tier = 2
	assert_eq(config.get_tier_index_for_day(1), 0, "第1天 → tier 0")

func test_tier_index_day_2():
	var config = DayProgressionConfigScript.new()
	config.days_per_tier = 2
	assert_eq(config.get_tier_index_for_day(2), 0, "第2天 → tier 0")

func test_tier_index_day_3():
	var config = DayProgressionConfigScript.new()
	config.days_per_tier = 2
	assert_eq(config.get_tier_index_for_day(3), 1, "第3天 → tier 1")

func test_tier_index_day_5():
	var config = DayProgressionConfigScript.new()
	config.days_per_tier = 2
	assert_eq(config.get_tier_index_for_day(5), 2, "第5天 → tier 2")

func test_tier_index_clamped():
	var config = DayProgressionConfigScript.new()
	config.days_per_tier = 2
	config.max_tier_index = 2
	assert_eq(config.get_tier_index_for_day(100), 2, "第100天应 clamp 到 max_tier_index 2")

func test_tier_index_days_per_tier_1():
	var config = DayProgressionConfigScript.new()
	config.days_per_tier = 1
	assert_eq(config.get_tier_index_for_day(1), 0, "每1天升一挡，第1天 → tier 0")
	assert_eq(config.get_tier_index_for_day(2), 1, "每1天升一挡，第2天 → tier 1")
	assert_eq(config.get_tier_index_for_day(3), 2, "每1天升一挡，第3天 → tier 2")

func test_tier_index_days_per_tier_3():
	var config = DayProgressionConfigScript.new()
	config.days_per_tier = 3
	assert_eq(config.get_tier_index_for_day(1), 0, "每3天升一挡，第1天 → tier 0")
	assert_eq(config.get_tier_index_for_day(3), 0, "每3天升一挡，第3天 → tier 0")
	assert_eq(config.get_tier_index_for_day(4), 1, "每3天升一挡，第4天 → tier 1")
	assert_eq(config.get_tier_index_for_day(7), 2, "每3天升一挡，第7天 → tier 2")

## ========== get_difficulty_for_day 测试 ==========

func test_difficulty_day_1():
	var config = DayProgressionConfigScript.new()
	config.base_difficulty = 1.0
	config.difficulty_per_tier = 0.2
	assert_eq(config.get_difficulty_for_day(1), 1.0, "第1天难度应为 1.0")

func test_difficulty_day_3():
	var config = DayProgressionConfigScript.new()
	config.base_difficulty = 1.0
	config.difficulty_per_tier = 0.2
	config.days_per_tier = 2
	assert_eq(config.get_difficulty_for_day(3), 1.2, "第3天（tier 1）难度应为 1.2")

func test_difficulty_day_5():
	var config = DayProgressionConfigScript.new()
	config.base_difficulty = 1.0
	config.difficulty_per_tier = 0.2
	config.days_per_tier = 2
	assert_eq(config.get_difficulty_for_day(5), 1.4, "第5天（tier 2）难度应为 1.4")

func test_difficulty_custom_base():
	var config = DayProgressionConfigScript.new()
	config.base_difficulty = 2.0
	config.difficulty_per_tier = 0.5
	config.days_per_tier = 1
	assert_eq(config.get_difficulty_for_day(1), 2.0, "自定义基础：第1天难度应为 2.0")
	assert_eq(config.get_difficulty_for_day(3), 3.0, "自定义基础：第3天（tier 2）难度应为 3.0")
