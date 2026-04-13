## 事件系统单元测试
extends GutTest

var _handler: BaseEventHandler

func before_each():
	_handler = BaseEventHandler.new()
	add_child(_handler)

func after_each():
	if _handler and is_instance_valid(_handler):
		_handler.queue_free()
	await wait_frames(1)

## ========== BaseEventHandler 测试 ==========

func test_start_event_sets_data():
	var event = SpecialEvent.new()
	event.event_id = "test"
	event.display_name = "测试事件"

	_handler.start_event(event, null)
	assert_eq(_handler.event_data, event, "事件数据应被设置")
	assert_eq(_handler.event_data.display_name, "测试事件", "显示名称应正确")

func test_cleanup_emits_signal():
	var event = SpecialEvent.new()
	event.event_id = "test_cleanup"
	_handler.start_event(event, null)

	var signal_received = [false]
	_handler.event_cleaned_up.connect(func(id):
		signal_received[0] = true
		assert_eq(id, "test_cleanup", "清理信号应包含事件ID")
	)

	_handler.cleanup()
	assert_true(signal_received[0], "应发出 event_cleaned_up 信号")

## ========== SpecialEvent 测试 ==========

func test_special_event_valid():
	var event = SpecialEvent.new()
	event.event_id = "coin_rain"
	event.display_name = "金币雨"
	event.handler_scene = PackedScene.new()
	assert_true(event.is_valid(), "完整配置应该有效")

func test_special_event_invalid_no_id():
	var event = SpecialEvent.new()
	event.display_name = "金币雨"
	event.handler_scene = PackedScene.new()
	assert_false(event.is_valid(), "无 event_id 应该无效")

func test_special_event_invalid_no_scene():
	var event = SpecialEvent.new()
	event.event_id = "coin_rain"
	event.display_name = "金币雨"
	assert_false(event.is_valid(), "无 handler_scene 应该无效")
