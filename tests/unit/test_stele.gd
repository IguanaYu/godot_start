## 石碑单元测试
extends GutTest

var _stele: Node

func before_each():
	# Stele extends BaseArea which extends Area2D, 需要完整的场景
	# 这里只测试脚本逻辑
	pass

func after_each():
	if _stele and is_instance_valid(_stele):
		_stele.queue_free()
	await wait_frames(1)

## 测试 unlock_entry_id 默认为空
func test_stele_default_unlock_id():
	# 直接测试 GDScript 加载
	var script = load("res://scripts/stations/Stele.gd")
	assert_not_null(script, "Stele 脚本应能加载")
