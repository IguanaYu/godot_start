## SpawnManager 单元测试
## 测试数据驱动的刷新管理器
extends GutTest

const SpawnManagerScript = preload("res://scripts/SpawnManager.gd")
const SpawnEntryScript = preload("res://resources/spawn/spawn_entry.gd")
const SpawnPhaseScript = preload("res://resources/spawn/spawn_phase.gd")

var _manager
var _parent: Node2D

func before_each():
	_parent = Node2D.new()
	add_child(_parent)

	_manager = SpawnManagerScript.new()
	_parent.add_child(_manager)

	# 确保 GameManager 有 player 引用
	if GameManager.player == null:
		var fake_player = CharacterBody2D.new()
		fake_player.global_position = Vector2(400, 300)
		add_child(fake_player)
		GameManager.player = fake_player

	# 等待 _ready 完成
	await wait_frames(1)

func after_each():
	if _manager and is_instance_valid(_manager):
		_manager.queue_free()
	if _parent and is_instance_valid(_parent):
		_parent.queue_free()
	await wait_frames(1)

## ========== 配置测试 ==========

## 测试 configure 正确设置阶段
func test_configure_sets_phase():
	var phase = _create_test_phase()
	_manager.configure(phase)
	assert_eq(_manager.get_current_phase(), phase, "configure 后应设置当前阶段")

## 测试 configure 无 zone 时使用默认 zone
func test_configure_default_zone():
	var phase = _create_test_phase()
	_manager.configure(phase)
	assert_not_null(_manager._default_zone, "应有默认 zone")

## ========== 暂停/恢复测试 ==========

## 测试 pause_spawning 停止处理
func test_pause_spawning():
	_manager.pause_spawning()
	assert_false(_manager.is_processing(), "暂停后不应在处理")

## 测试 resume_spawning 恢复处理
func test_resume_spawning():
	_manager.pause_spawning()
	_manager.resume_spawning()
	assert_true(_manager.is_processing(), "恢复后应在处理")

## ========== 难度测试 ==========

## 测试 increase_difficulty 设置倍率
func test_increase_difficulty():
	_manager.increase_difficulty(2.0)
	assert_eq(_manager._difficulty_multiplier, 2.0, "难度倍率应为 2.0")

## ========== 金币雨测试 ==========

## 测试 start_coin_rain
func test_start_coin_rain():
	_manager.start_coin_rain(10.0, 0.5)
	assert_true(_manager._is_coin_rain_active, "金币雨应激活")
	assert_eq(_manager._coin_rain_duration, 10.0, "持续时间为 10.0")
	assert_eq(_manager._coin_rain_interval, 0.5, "间隔为 0.5")

## 测试 stop_coin_rain
func test_stop_coin_rain():
	_manager.start_coin_rain(10.0)
	_manager.stop_coin_rain()
	assert_false(_manager._is_coin_rain_active, "金币雨应停止")

## 测试重复启动金币雨不重置
func test_start_coin_rain_no_double_start():
	_manager.start_coin_rain(10.0)
	var original_time = _manager._coin_rain_time_left
	_manager.start_coin_rain(20.0)  # 尝试再次启动
	assert_eq(_manager._coin_rain_duration, 10.0, "不应重置金币雨参数")

## ========== 解锁条目测试 ==========

## 测试 unlock_entry
func test_unlock_entry():
	var phase = _create_test_phase_with_disabled()
	_manager.configure(phase)
	_manager.unlock_entry("disabled_entry")
	assert_true(_manager._unlocked_entries.has("disabled_entry"), "应记录解锁的条目")

## ========== 辅助方法 ==========

## 创建测试用的 SpawnPhase（包含一个 coin 条目）
func _create_test_phase() -> SpawnPhase:
	var phase = SpawnPhaseScript.new()
	phase.phase_id = "test_day"
	phase.period = 0  # Period.DAY

	var entry = SpawnEntryScript.new()
	entry.entry_id = "test_coin"
	entry.entity_type = "coin"
	entry.collectible_data = CollectibleData.new()
	entry.collectible_data.display_name = "测试金币"
	entry.spawn_interval = 5.0
	entry.max_in_scene = 30
	phase.entries.append(entry)

	return phase

## 创建包含禁用条目的测试 SpawnPhase
func _create_test_phase_with_disabled() -> SpawnPhase:
	var phase = SpawnPhase.new()
	phase.phase_id = "test_day"
	phase.period = SpawnPhase.Period.DAY

	var enabled_entry = SpawnEntryScript.new()
	enabled_entry.entry_id = "enabled_entry"
	enabled_entry.entity_type = "coin"
	enabled_entry.collectible_data = CollectibleData.new()
	enabled_entry.collectible_data.display_name = "金币"
	enabled_entry.spawn_interval = 5.0
	phase.entries.append(enabled_entry)

	var disabled_entry = SpawnEntryScript.new()
	disabled_entry.entry_id = "disabled_entry"
	disabled_entry.entity_type = "coin"
	disabled_entry.collectible_data = CollectibleData.new()
	disabled_entry.collectible_data.display_name = "特殊金币"
	disabled_entry.spawn_interval = 3.0
	disabled_entry.enabled = false
	phase.entries.append(disabled_entry)

	return phase
