## 撤离区域脚本（EvacuationArea.gd）
## 功能：占领完成后切换到休息场景
## 继承自 BaseArea

extends BaseArea

class_name EvacuationArea

## ========== 信号定义 ==========

## 撤离点占领完成时发出
signal evacuation_area_captured()

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	super._ready()

	# 连接占领完成信号
	capture_area_completed.connect(_on_base_capture_completed)

## ========== 虚函数重写 ==========

## 初始化外观 - 设置紫色主题
func _initialize_appearance() -> void:
	if area_sprite != null:
		area_sprite.modulate = Color(0.5, 0, 0.5, 0.5)
	if sprite != null:
		sprite.modulate = Color.PURPLE

## 占领完成后的行为
func _on_capture_completed() -> void:
	# 发放占领奖励
	_grant_capture_bonus()

## ========== 私有方法 ==========

## 基础占领完成回调
func _on_base_capture_completed() -> void:
	# 发出撤离点占领完成信号
	evacuation_area_captured.emit()

	# 显示完成提示
	GameManager.reward_obtained.emit("撤离点占领成功！即将撤离...")

	# 延迟后切换场景（RestArea已有Player实例）
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/RestArea.tscn")

## 发放占领完成奖励
func _grant_capture_bonus() -> void:
	# 增加金币
	GameManager.add_coins(capture_bonus_coins)
