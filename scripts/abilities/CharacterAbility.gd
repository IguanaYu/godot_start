## 角色特殊能力Resource类
## 功能：定义角色的各种特殊能力和被动技能
extends Resource
class_name CharacterAbility

## ========== 能力触发条件枚举 ==========

enum TriggerType {
	ON_COIN_COLLECT,      # 收集金币时（累计计数）
	ON_COIN_THRESHOLD,    # 金币总数达到阈值
	ON_HEALTH_LOW,        # 血量低时
	ON_DAMAGE_TAKEN,      # 受伤时
	ON_KILL_ENEMY,        # 击杀敌人时
	ON_LEVEL_START        # 关卡开始时
}

## ========== 能力基础信息 ==========

## 能力名称
@export var ability_name: String = ""
## 能力描述
@export_multiline var ability_description: String = ""
## 触发类型
@export var trigger_type: TriggerType = TriggerType.ON_COIN_COLLECT
## 是否启用
@export var is_enabled: bool = true

## ========== 触发条件参数 ==========

## 触发阈值（如收集多少金币）
@export var trigger_threshold: int = 10

## ========== 能力冷却 ==========

## 冷却时间（秒）
@export var cooldown: float = 0.0
var _last_triggered: float = -9999.0

## ========== 能力效果数据 ==========

## 效果类型（heal, coins, speed, invincibility, clear_enemies）
@export var effect_type: String = "heal"
## 效果数值
@export var effect_value: float = 1.0
## 效果持续时间（秒，0表示瞬间效果）
@export var effect_duration: float = 0.0

## ========== 内部状态 ==========

## 内部计数器（用于累计计数）
var _internal_counter: int = 0

## ========== 公共方法 ==========

## 验证能力配置
func is_valid() -> bool:
	return ability_name != ""

## 检查是否可以触发
func can_trigger() -> bool:
	if not is_enabled:
		return false
	if cooldown > 0:
		var time_since_last = Time.get_ticks_msec() / 1000.0 - _last_triggered
		if time_since_last < cooldown:
			return false
	return true

## 触发能力
func trigger(context: Dictionary = {}) -> void:
	if not can_trigger():
		return

	_last_triggered = Time.get_ticks_msec() / 1000.0
	_apply_effect(context)

## 累计计数（用于累计触发类型）
func add_to_counter(amount: int = 1) -> void:
	_internal_counter += amount
	if _internal_counter >= trigger_threshold:
		if can_trigger():
			trigger({"counter": _internal_counter})
			_internal_counter = 0  # 重置计数

## 重置计数器
func reset_counter() -> void:
	_internal_counter = 0

## 获取显示用的描述文本
func get_display_description() -> String:
	var desc = ability_description
	if trigger_threshold > 0:
		match trigger_type:
			TriggerType.ON_COIN_COLLECT:
				desc += "\n每收集 %d 个金币触发" % trigger_threshold
			TriggerType.ON_COIN_THRESHOLD:
				desc += "\n金币总数每达到 %d 的倍数时触发" % trigger_threshold
			TriggerType.ON_HEALTH_LOW:
				desc += "\n血量低于 %d%% 时触发" % trigger_threshold
			TriggerType.ON_DAMAGE_TAKEN:
				if trigger_threshold > 0:
					desc += "\n每受到 %d 次伤害触发" % trigger_threshold
				else:
					desc += "\n每次受伤时触发"
			TriggerType.ON_KILL_ENEMY:
				if trigger_threshold > 0:
					desc += "\n每击杀 %d 个敌人触发" % trigger_threshold
				else:
					desc += "\n每击杀一个敌人触发"
			TriggerType.ON_LEVEL_START:
				desc += "\n每个关卡开始时触发"
	return desc

## ========== 私有方法 ==========

## 应用效果
func _apply_effect(context: Dictionary) -> void:
	match effect_type:
		"heal":
			GameManager.heal_player(int(effect_value))
		"coins":
			GameManager.add_coins(int(effect_value))
		"speed":
			if effect_duration > 0:
				GameManager.apply_buff("speed_boost")
			else:
				# 永久速度提升
				if GameManager.player != null and is_instance_valid(GameManager.player):
					GameManager.player.base_speed *= (1.0 + effect_value / 100.0)
		"invincibility":
			if GameManager.player != null and is_instance_valid(GameManager.player):
				GameManager.player.start_star_invincibility(effect_duration)
		"clear_enemies":
			GameManager.clear_all_enemies()
		_:
			push_warning("Unknown effect type: %s" % effect_type)
