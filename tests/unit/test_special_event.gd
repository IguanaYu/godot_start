## SpecialEvent 单元测试
## 测试特殊事件的属性和校验逻辑
extends GutTest

const SpecialEventScript = preload("res://resources/spawn/special_event.gd")

## ========== 默认值测试 ==========

func test_defaults():
	var event = SpecialEventScript.new()
	assert_eq(event.event_id, "", "默认 event_id 应为空字符串")
	assert_eq(event.display_name, "", "默认 display_name 应为空字符串")
	assert_eq(event.description, "", "默认 description 应为空字符串")
	assert_eq(event.handler_scene, null, "默认 handler_scene 应为 null")
	assert_eq(event.trigger_period, "BOTH", "默认 trigger_period 应为 BOTH")
	assert_eq(event.trigger_time, 10.0, "默认 trigger_time 应为 10.0")
	assert_eq(event.trigger_probability, 0.5, "默认 trigger_probability 应为 0.5")

## ========== is_valid 测试 ==========

func test_is_valid_defaults():
	var event = SpecialEventScript.new()
	assert_false(event.is_valid(), "默认值（空 ID、空名称、无场景）应无效")

func test_is_valid_empty_id():
	var event = SpecialEventScript.new()
	event.display_name = "测试事件"
	event.handler_scene = PackedScene.new()
	assert_false(event.is_valid(), "空 event_id 应无效")

func test_is_valid_empty_display_name():
	var event = SpecialEventScript.new()
	event.event_id = "test_event"
	event.handler_scene = PackedScene.new()
	assert_false(event.is_valid(), "空 display_name 应无效")

func test_is_valid_no_handler_scene():
	var event = SpecialEventScript.new()
	event.event_id = "test_event"
	event.display_name = "测试事件"
	assert_false(event.is_valid(), "无 handler_scene 应无效")

func test_is_valid_complete():
	var event = SpecialEventScript.new()
	event.event_id = "test_event"
	event.display_name = "测试事件"
	event.handler_scene = PackedScene.new()
	assert_true(event.is_valid(), "完整配置应有效")

func test_is_valid_with_all_fields():
	var event = SpecialEventScript.new()
	event.event_id = "boss_invasion"
	event.display_name = "Boss入侵"
	event.description = "一个强大的Boss出现了！"
	event.handler_scene = PackedScene.new()
	event.trigger_period = "NIGHT"
	event.trigger_time = 15.0
	event.trigger_probability = 0.3
	assert_true(event.is_valid(), "所有字段都设置后应有效")
