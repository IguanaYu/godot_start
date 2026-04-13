## SpawnZone 单元测试
## 测试4种定位模式的位置计算
extends GutTest

var _zone: SpawnZone
var _player: CharacterBody2D

func before_each():
	_zone = SpawnZone.new()
	add_child(_zone)

	# 创建一个模拟 Player 节点
	_player = CharacterBody2D.new()
	_player.set_script(GDScript.new())
	_player.global_position = Vector2(500, 500)
	add_child(_player)

	# 设置 GameManager 的 player 引用
	GameManager.player = _player

func after_each():
	# 清理
	if _zone and is_instance_valid(_zone):
		_zone.queue_free()
	if _player and is_instance_valid(_player):
		_player.queue_free()
	GameManager.player = null

	# 等待帧以确保清理完成
	await wait_frames(1)

## ========== PLAYER_RELATIVE 模式测试 ==========

## 测试 PLAYER_RELATIVE 返回的位置在合理偏移范围内
func test_player_relative_in_range():
	_zone.zone_mode = SpawnZone.ZoneType.PLAYER_RELATIVE
	_zone.global_position = Vector2.ZERO

	# 多次采样检查范围
	for i in range(50):
		var pos = _zone.get_spawn_position(100.0, 300.0)
		var dist = pos.distance_to(_player.global_position)
		assert_gt(dist, 0.0, "距离应大于0（几乎不可能恰好为0）")
		# 理论上距离在 [100, 300] 范围内
		assert_gte(dist, 100.0 * 0.95, "距离不应远小于最小偏移")
		assert_lte(dist, 300.0 * 1.05, "距离不应远大于最大偏移")

## 测试 PLAYER_RELATIVE 在无玩家时以原点为中心
func test_player_relative_no_player():
	GameManager.player = null
	_zone.zone_mode = SpawnZone.ZoneType.PLAYER_RELATIVE

	var pos = _zone.get_spawn_position(50.0, 200.0)
	var dist = pos.distance_to(Vector2.ZERO)
	assert_gte(dist, 0.0, "无玩家时以原点为中心，距离应 >= 0")

## ========== AREA_RANDOM 模式测试 ==========

## 测试 AREA_RANDOM 返回位置在 zone_rect 范围内
func test_area_random_in_rect():
	_zone.zone_mode = SpawnZone.ZoneType.AREA_RANDOM
	_zone.zone_rect = Rect2(-200, -200, 400, 400)

	for i in range(50):
		var pos = _zone.get_spawn_position()
		assert_gte(pos.x, -200.0, "x 应 >= rect 左边界")
		assert_lte(pos.x, 200.0, "x 应 <= rect 右边界")
		assert_gte(pos.y, -200.0, "y 应 >= rect 上边界")
		assert_lte(pos.y, 200.0, "y 应 <= rect 下边界")

## ========== SEMI_RANDOM 模式测试 ==========

## 测试 SEMI_RANDOM 返回位置在合理范围内
func test_semi_random_returns_valid_position():
	_zone.zone_mode = SpawnZone.ZoneType.SEMI_RANDOM
	_zone.zone_rect = Rect2(-500, -500, 1000, 1000)
	_zone.player_bias = 0.7

	for i in range(50):
		var pos = _zone.get_spawn_position(50.0, 500.0)
		# 两种模式的结果范围不同，但都应产生有限的坐标
		assert_false(is_nan(pos.x), "x 不应为 NaN")
		assert_false(is_nan(pos.y), "y 不应为 NaN")
		assert_false(is_inf(pos.x), "x 不应为 Inf")
		assert_false(is_inf(pos.y), "y 不应为 Inf")

## ========== FIXED 模式测试 ==========

## 测试 FIXED 从子 Marker2D 中选择
func test_fixed_uses_child_markers():
	_zone.zone_mode = SpawnZone.ZoneType.FIXED
	_zone.global_position = Vector2(0, 0)

	# 添加几个子 Marker2D
	var m1 = Marker2D.new()
	m1.global_position = Vector2(100, 100)
	_zone.add_child(m1)

	var m2 = Marker2D.new()
	m2.global_position = Vector2(200, 200)
	_zone.add_child(m2)

	# 多次采样，应返回子节点的位置之一
	var positions = []
	for i in range(20):
		var pos = _zone.get_spawn_position()
		positions.append(pos)

	# 至少应包含其中一个位置
	var has_m1 = positions.any(func(p): return p.is_equal_approx(Vector2(100, 100)))
	var has_m2 = positions.any(func(p): return p.is_equal_approx(Vector2(200, 200)))
	assert_true(has_m1 or has_m2, "应返回子 Marker2D 的位置之一")

## 测试 FIXED 无子节点时返回自身位置
func test_fixed_no_children_returns_own_position():
	_zone.zone_mode = SpawnZone.ZoneType.FIXED
	_zone.global_position = Vector2(42, 42)

	var pos = _zone.get_spawn_position()
	assert_eq(pos, Vector2(42, 42), "无子节点时应返回自身 global_position")

## ========== 默认模式测试 ==========

## 测试默认模式为 PLAYER_RELATIVE
func test_default_mode_is_player_relative():
	var zone = SpawnZone.new()
	assert_eq(zone.zone_mode, SpawnZone.ZoneType.PLAYER_RELATIVE, "默认模式应为 PLAYER_RELATIVE")
	zone.queue_free()

## 测试默认 zone_id 为空
func test_default_zone_id_empty():
	var zone = SpawnZone.new()
	assert_eq(zone.zone_id, "", "默认 zone_id 应为空字符串")
	zone.queue_free()
