## 刷新条目 Resource
## 功能：定义单个可刷新实体的所有参数
extends Resource
class_name SpawnEntry

## ========== 基础标识 ==========

## 条目唯一 ID
@export var entry_id: String = ""
## 实体类型标识："enemy", "coin", "capture_point", "chest", "giant_coin", "red_key"
@export var entity_type: String = ""

## ========== 场景引用 ==========

## 实体场景（敌人、宝箱等直接使用场景）
@export var scene: PackedScene = null
## 收集品数据（金币、占领点、巨型金币、红钥匙等使用 CollectibleData）
@export var collectible_data: CollectibleData = null

## ========== 刷新参数 ==========

## 刷新间隔（秒）
@export var spawn_interval: float = 5.0
## 场景中该类实体的最大数量
@export var max_in_scene: int = 30
## 每次刷新的最小数量
@export var spawn_count_min: int = 1
## 每次刷新的最大数量
@export var spawn_count_max: int = 5

## ========== 位置参数 ==========

## 生成位置最小偏移（像素）
@export var min_offset: float = 50.0
## 生成位置最大偏移（像素）
@export var max_offset: float = 300.0
## 使用的 SpawnZone ID（空字符串 = 默认玩家相对位置）
@export var zone_id: String = ""

## ========== 计时器类型 ==========

## 是否启用
@export var enabled: bool = true
## 首次生成延迟（秒，0 = 无额外延迟）
@export var start_delay: float = 0.0
## 是否为正计时器（true = 累计时间达到间隔后触发，如巨型金币/红钥匙；false = 倒计时器，如普通敌人/金币）
@export var is_cumulative_timer: bool = false

## ========== 辅助方法 ==========

## 验证数据完整性
func is_valid() -> bool:
	if entry_id == "":
		return false
	if entity_type == "":
		return false
	if scene == null and collectible_data == null:
		return false
	return true

## 获取显示名称（用于日志）
func get_display_name() -> String:
	if collectible_data != null and collectible_data.display_name != "":
		return collectible_data.display_name
	return entry_id
