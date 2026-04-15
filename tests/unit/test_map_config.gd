## MapConfig 单元测试
## 测试地图配置的属性、校验和天数挡位查询逻辑
extends GutTest

const MapConfigScript = preload("res://resources/spawn/map_config.gd")
const DayNightTierScript = preload("res://resources/spawn/day_night_tier.gd")
const DayProgressionConfigScript = preload("res://resources/spawn/day_progression_config.gd")
const SpawnPhaseScript = preload("res://resources/spawn/spawn_phase.gd")

## ========== 默认值测试 ==========

func test_defaults():
	var config = MapConfigScript.new()
	assert_eq(config.map_name, "", "默认 map_name 应为空字符串")
	assert_eq(config.description, "", "默认 description 应为空字符串")
	assert_eq(config.min_unlock_day, 1, "默认 min_unlock_day 应为 1")
	assert_eq(config.tiers.size(), 0, "默认 tiers 应为空数组")
	assert_eq(config.day_phase, null, "默认 day_phase 应为 null")
	assert_eq(config.night_phase, null, "默认 night_phase 应为 null")
	assert_eq(config.progression, null, "默认 progression 应为 null")
	assert_eq(config.event_pool.size(), 0, "默认 event_pool 应为空数组")

## ========== is_valid 测试 ==========

func test_is_valid_empty_name():
	var config = MapConfigScript.new()
	var tier = DayNightTierScript.new()
	config.tiers.append(tier)
	config.day_phase = SpawnPhaseScript.new()
	assert_false(config.is_valid(), "空 map_name 应无效")

func test_is_valid_empty_tiers():
	var config = MapConfigScript.new()
	config.map_name = "森林"
	config.day_phase = SpawnPhaseScript.new()
	assert_false(config.is_valid(), "空 tiers 应无效")

func test_is_valid_no_day_phase():
	var config = MapConfigScript.new()
	config.map_name = "森林"
	var tier = DayNightTierScript.new()
	config.tiers.append(tier)
	assert_false(config.is_valid(), "无 day_phase 应无效")

func test_is_valid_complete():
	var config = MapConfigScript.new()
	config.map_name = "森林"
	var tier = DayNightTierScript.new()
	config.tiers.append(tier)
	config.day_phase = SpawnPhaseScript.new()
	assert_true(config.is_valid(), "完整配置应有效")

## ========== get_tier_for_day 测试 ==========

func test_get_tier_for_day_empty_tiers():
	var config = MapConfigScript.new()
	var result = config.get_tier_for_day(1)
	assert_null(result, "空 tiers 应返回 null")

func test_get_tier_for_day_single_tier():
	var config = MapConfigScript.new()
	var tier = DayNightTierScript.new()
	tier.tier_index = 0
	config.tiers.append(tier)

	var result = config.get_tier_for_day(1)
	assert_eq(result, tier, "第1天应返回 tier 0")

	result = config.get_tier_for_day(10)
	assert_eq(result, tier, "第10天也只有1个tier，应返回同一个")

func test_get_tier_for_day_with_progression():
	var config = MapConfigScript.new()

	# 添加3个tiers
	for i in range(3):
		var tier = DayNightTierScript.new()
		tier.tier_index = i
		config.tiers.append(tier)

	# 设置递进：每2天升一挡
	var prog = DayProgressionConfigScript.new()
	prog.days_per_tier = 2
	config.progression = prog

	# 第1天 → tier_index 0
	var result = config.get_tier_for_day(1)
	assert_eq(result.tier_index, 0, "第1天挡位应为 0")

	# 第2天 → tier_index 0
	result = config.get_tier_for_day(2)
	assert_eq(result.tier_index, 0, "第2天挡位应为 0")

	# 第3天 → tier_index 1
	result = config.get_tier_for_day(3)
	assert_eq(result.tier_index, 1, "第3天挡位应为 1")

	# 第5天 → tier_index 2
	result = config.get_tier_for_day(5)
	assert_eq(result.tier_index, 2, "第5天挡位应为 2")

	# 第7天 → tier_index 2（clamp到最大）
	result = config.get_tier_for_day(7)
	assert_eq(result.tier_index, 2, "第7天应 clamp 到最大 tier_index 2")

func test_get_tier_for_day_no_progression():
	var config = MapConfigScript.new()

	# 添加3个tiers
	for i in range(3):
		var tier = DayNightTierScript.new()
		tier.tier_index = i
		config.tiers.append(tier)

	# 无递进配置，简单递增
	# 第1天 → day_number-1=0 → tier 0
	var result = config.get_tier_for_day(1)
	assert_eq(result.tier_index, 0, "第1天挡位应为 0")

	# 第3天 → day_number-1=2 → tier 2
	result = config.get_tier_for_day(3)
	assert_eq(result.tier_index, 2, "第3天挡位应为 2")

	# 第5天 → day_number-1=4 → clamp到2
	result = config.get_tier_for_day(5)
	assert_eq(result.tier_index, 2, "第5天应 clamp 到 tier 2")
