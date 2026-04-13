## 刷新区域脚本（SpawnZone.gd）
## 功能：定义刷新位置计算方式，支持4种定位模式
## 节点结构：Marker2D (根节点)
##   └── 可选子 Marker2D 节点（FIXED 模式使用）

extends Marker2D

class_name SpawnZone

## ========== 区域类型枚举 ==========

enum ZoneType {
	PLAYER_RELATIVE,  ## 围绕玩家随机偏移（复刻现有 _get_random_spawn_position）
	AREA_RANDOM,      ## 在 zone_rect 范围内随机
	SEMI_RANDOM,      ## 按概率混合 PLAYER_RELATIVE 和 AREA_RANDOM
	FIXED             ## 从子节点 Marker2D 中随机选一个
}

## ========== 可配置变量 ==========

## 区域唯一标识
@export var zone_id: String = ""
## 区域定位模式
@export var zone_mode: ZoneType = ZoneType.PLAYER_RELATIVE
## AREA_RANDOM / SEMI_RANDOM 模式的范围矩形
@export var zone_rect: Rect2 = Rect2(-500, -500, 1000, 1000)
## SEMI_RANDOM 模式中使用 PLAYER_RELATIVE 的概率（0.0 ~ 1.0）
@export var player_bias: float = 0.7

## ========== 公共方法 ==========

## 获取一个刷新位置
## 参数：
##   min_offset: 最小偏移距离（PLAYER_RELATIVE 模式使用）
##   max_offset: 最大偏移距离（PLAYER_RELATIVE 模式使用）
func get_spawn_position(min_offset: float = 50.0, max_offset: float = 300.0) -> Vector2:
	match zone_mode:
		ZoneType.PLAYER_RELATIVE:
			return _player_relative(min_offset, max_offset)
		ZoneType.AREA_RANDOM:
			return _area_random()
		ZoneType.SEMI_RANDOM:
			return _semi_random(min_offset, max_offset)
		ZoneType.FIXED:
			return _fixed()
	return global_position

## ========== 私有方法 ==========

## 围绕玩家随机偏移（复刻 Spawner._get_random_spawn_position）
func _player_relative(min_off: float, max_off: float) -> Vector2:
	var player_pos: Vector2 = Vector2.ZERO
	if GameManager.player != null and is_instance_valid(GameManager.player):
		player_pos = GameManager.player.global_position

	var angle: float = randf() * TAU
	var dist: float = randf_range(min_off, max_off)
	return player_pos + Vector2.from_angle(angle) * dist

## 在 zone_rect 范围内随机
func _area_random() -> Vector2:
	return Vector2(
		randf_range(zone_rect.position.x, zone_rect.end.x),
		randf_range(zone_rect.position.y, zone_rect.end.y)
	)

## 按概率混合 PLAYER_RELATIVE 和 AREA_RANDOM
func _semi_random(min_off: float, max_off: float) -> Vector2:
	if randf() < player_bias:
		return _player_relative(min_off, max_off)
	return _area_random()

## 从子节点 Marker2D 中随机选一个
func _fixed() -> Vector2:
	var markers: Array = get_children().filter(func(c): return c is Marker2D)
	if markers.is_empty():
		return global_position
	return markers[randi() % markers.size()].global_position
