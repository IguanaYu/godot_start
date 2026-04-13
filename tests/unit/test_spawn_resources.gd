## Spawn Resource 单元测试
## 测试 SpawnEntry、SpawnPhase、DayNightTier 的属性和校验逻辑
extends GutTest

## ========== SpawnEntry 测试 ==========

## 测试 SpawnEntry 默认值
func test_spawn_entry_defaults():
	var entry = SpawnEntry.new()
	assert_eq(entry.entry_id, "", "默认 entry_id 应为空字符串")
	assert_eq(entry.entity_type, "", "默认 entity_type 应为空字符串")
	assert_eq(entry.scene, null, "默认 scene 应为 null")
	assert_eq(entry.collectible_data, null, "默认 collectible_data 应为 null")
	assert_eq(entry.spawn_interval, 5.0, "默认 spawn_interval 应为 5.0")
	assert_eq(entry.max_in_scene, 30, "默认 max_in_scene 应为 30")
	assert_eq(entry.enabled, true, "默认 enabled 应为 true")
	assert_eq(entry.is_cumulative_timer, false, "默认 is_cumulative_timer 应为 false")

## 测试 SpawnEntry is_valid — 空 entry_id
func test_spawn_entry_invalid_empty_id():
	var entry = SpawnEntry.new()
	entry.entity_type = "coin"
	entry.scene = PackedScene.new()
	assert_false(entry.is_valid(), "空 entry_id 应该无效")

## 测试 SpawnEntry is_valid — 空 entity_type
func test_spawn_entry_invalid_empty_type():
	var entry = SpawnEntry.new()
	entry.entry_id = "test_coin"
	entry.scene = PackedScene.new()
	assert_false(entry.is_valid(), "空 entity_type 应该无效")

## 测试 SpawnEntry is_valid — 无场景也无数据
func test_spawn_entry_invalid_no_scene_no_data():
	var entry = SpawnEntry.new()
	entry.entry_id = "test_coin"
	entry.entity_type = "coin"
	assert_false(entry.is_valid(), "无 scene 也无 collectible_data 应该无效")

## 测试 SpawnEntry is_valid — 有 scene 无 collectible_data
func test_spawn_entry_valid_with_scene():
	var entry = SpawnEntry.new()
	entry.entry_id = "test_enemy"
	entry.entity_type = "enemy"
	entry.scene = PackedScene.new()
	assert_true(entry.is_valid(), "有 scene 应该有效")

## 测试 SpawnEntry is_valid — 有 collectible_data 无 scene
func test_spawn_entry_valid_with_collectible_data():
	var entry = SpawnEntry.new()
	entry.entry_id = "test_coin"
	entry.entity_type = "coin"
	entry.collectible_data = CollectibleData.new()
	entry.collectible_data.display_name = "金币"
	assert_true(entry.is_valid(), "有 collectible_data 应该有效")

## 测试 SpawnEntry is_valid — 完整有效
func test_spawn_entry_valid_complete():
	var entry = SpawnEntry.new()
	entry.entry_id = "coin"
	entry.entity_type = "coin"
	entry.scene = PackedScene.new()
	entry.collectible_data = CollectibleData.new()
	entry.spawn_interval = 3.0
	entry.max_in_scene = 20
	assert_true(entry.is_valid(), "完整配置应该有效")

## 测试 SpawnEntry get_display_name — 有 collectible_data
func test_spawn_entry_display_name_from_collectible():
	var entry = SpawnEntry.new()
	entry.entry_id = "coin"
	entry.collectible_data = CollectibleData.new()
	entry.collectible_data.display_name = "金币"
	assert_eq(entry.get_display_name(), "金币", "应返回 collectible_data 的 display_name")

## 测试 SpawnEntry get_display_name — 无 collectible_data
func test_spawn_entry_display_name_fallback_to_id():
	var entry = SpawnEntry.new()
	entry.entry_id = "my_coin"
	assert_eq(entry.get_display_name(), "my_coin", "无 collectible_data 时应返回 entry_id")

## ========== SpawnPhase 测试 ==========

## 测试 SpawnPhase 默认值
func test_spawn_phase_defaults():
	var phase = SpawnPhase.new()
	assert_eq(phase.phase_id, "", "默认 phase_id 应为空字符串")
	assert_eq(phase.period, SpawnPhase.Period.DAY, "默认 period 应为 DAY")
	assert_eq(phase.entries.size(), 0, "默认 entries 应为空数组")

## 测试 SpawnPhase is_valid — 空 phase_id
func test_spawn_phase_invalid_empty_id():
	var phase = SpawnPhase.new()
	var entry = SpawnEntry.new()
	entry.entry_id = "coin"
	entry.entity_type = "coin"
	entry.scene = PackedScene.new()
	phase.entries.append(entry)
	assert_false(phase.is_valid(), "空 phase_id 应该无效")

## 测试 SpawnPhase is_valid — 空 entries
func test_spawn_phase_invalid_empty_entries():
	var phase = SpawnPhase.new()
	phase.phase_id = "day"
	assert_false(phase.is_valid(), "空 entries 应该无效")

## 测试 SpawnPhase is_valid — 有效
func test_spawn_phase_valid():
	var phase = SpawnPhase.new()
	phase.phase_id = "day"
	var entry = SpawnEntry.new()
	entry.entry_id = "coin"
	entry.entity_type = "coin"
	entry.scene = PackedScene.new()
	phase.entries.append(entry)
	assert_true(phase.is_valid(), "有 phase_id 和 entries 应该有效")

## 测试 SpawnPhase get_enabled_entries — 过滤禁用和无效条目
func test_spawn_phase_get_enabled_entries_filters():
	var phase = SpawnPhase.new()
	phase.phase_id = "day"

	# 有效且启用的条目
	var valid_entry = SpawnEntry.new()
	valid_entry.entry_id = "coin"
	valid_entry.entity_type = "coin"
	valid_entry.scene = PackedScene.new()
	phase.entries.append(valid_entry)

	# 禁用的条目
	var disabled_entry = SpawnEntry.new()
	disabled_entry.entry_id = "enemy"
	disabled_entry.entity_type = "enemy"
	disabled_entry.scene = PackedScene.new()
	disabled_entry.enabled = false
	phase.entries.append(disabled_entry)

	# 无效的条目（无 scene 也无 data）
	var invalid_entry = SpawnEntry.new()
	invalid_entry.entry_id = "bad"
	invalid_entry.entity_type = "bad"
	phase.entries.append(invalid_entry)

	var enabled = phase.get_enabled_entries()
	assert_eq(enabled.size(), 1, "应只有 1 个有效且启用的条目")
	assert_eq(enabled[0].entry_id, "coin", "唯一启用的条目应为 coin")

## 测试 SpawnPhase get_entry_by_id
func test_spawn_phase_get_entry_by_id():
	var phase = SpawnPhase.new()
	phase.phase_id = "day"

	var coin_entry = SpawnEntry.new()
	coin_entry.entry_id = "coin"
	coin_entry.entity_type = "coin"
	coin_entry.scene = PackedScene.new()
	phase.entries.append(coin_entry)

	var enemy_entry = SpawnEntry.new()
	enemy_entry.entry_id = "enemy"
	enemy_entry.entity_type = "enemy"
	enemy_entry.scene = PackedScene.new()
	phase.entries.append(enemy_entry)

	var found = phase.get_entry_by_id("enemy")
	assert_not_null(found, "应找到 enemy 条目")
	assert_eq(found.entry_id, "enemy", "找到的条目 ID 应为 enemy")

	var not_found = phase.get_entry_by_id("nonexistent")
	assert_null(not_found, "不存在的 ID 应返回 null")

## ========== DayNightTier 测试 ==========

## 测试 DayNightTier 默认值
func test_day_night_tier_defaults():
	var tier = DayNightTier.new()
	assert_eq(tier.tier_index, 0, "默认 tier_index 应为 0")
	assert_eq(tier.day_duration, 40.0, "默认 day_duration 应为 40.0")
	assert_eq(tier.night_duration, 20.0, "默认 night_duration 应为 20.0")
	assert_eq(tier.difficulty_multiplier, 1.0, "默认 difficulty_multiplier 应为 1.0")

## 测试 DayNightTier is_valid — 有效
func test_day_night_tier_valid():
	var tier = DayNightTier.new()
	assert_true(tier.is_valid(), "默认值应该有效")

## 测试 DayNightTier is_valid — 零 day_duration
func test_day_night_tier_invalid_zero_day():
	var tier = DayNightTier.new()
	tier.day_duration = 0.0
	tier.night_duration = 20.0
	assert_false(tier.is_valid(), "day_duration 为 0 应该无效")

## 测试 DayNightTier is_valid — 零 night_duration
func test_day_night_tier_invalid_zero_night():
	var tier = DayNightTier.new()
	tier.day_duration = 40.0
	tier.night_duration = 0.0
	assert_false(tier.is_valid(), "night_duration 为 0 应该无效")

## 测试 DayNightTier is_valid — 负数时长
func test_day_night_tier_invalid_negative():
	var tier = DayNightTier.new()
	tier.day_duration = -10.0
	tier.night_duration = 20.0
	assert_false(tier.is_valid(), "负数 day_duration 应该无效")

## 测试 DayNightTier get_total_cycle_duration
func test_day_night_tier_total_cycle():
	var tier = DayNightTier.new()
	tier.day_duration = 30.0
	tier.night_duration = 15.0
	assert_eq(tier.get_total_cycle_duration(), 45.0, "总周期应为 45.0 秒")
